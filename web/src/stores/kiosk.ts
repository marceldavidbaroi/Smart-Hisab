import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '../boot/supabase';

export interface KioskStaff {
  id: string;
  fullName: string;
  role: string;
  permissions?: Record<string, unknown> | undefined;
}

export const useKioskStore = defineStore('kiosk', () => {
  // State variables
  const deviceToken = ref<string | null>(localStorage.getItem('kiosk.device_token'));
  const tenantId = ref<string | null>(localStorage.getItem('kiosk.tenant_id'));
  const tenantSlug = ref<string | null>(localStorage.getItem('kiosk.tenant_slug'));
  const tenantName = ref<string | null>(localStorage.getItem('kiosk.tenant_name'));
  const deviceName = ref<string | null>(localStorage.getItem('kiosk.device_name'));

  const currentStaff = ref<KioskStaff | null>(null);
  const isSetupRequired = ref<boolean>(false);
  const failedPinMessage = ref<string | null>(null);
  const loading = ref<boolean>(false);

  // Online state tracking
  const isOnline = ref(typeof window !== 'undefined' ? navigator.onLine : true);
  if (typeof window !== 'undefined') {
    window.addEventListener('online', () => {
      isOnline.value = true;
    });
    window.addEventListener('offline', () => {
      isOnline.value = false;
    });
  }

  // Load staffList from local storage cache if available
  const cachedStaff =
    typeof window !== 'undefined' ? localStorage.getItem('kiosk.staff_list') : null;
  const staffList = ref<KioskStaff[]>(cachedStaff ? JSON.parse(cachedStaff) : []);

  // Getters
  const isDevicePaired = computed(() => !!deviceToken.value && !!tenantId.value);
  const isStaffAuthenticated = computed(() => !!currentStaff.value);

  // Actions
  async function pairDevice(pairingCode: string, nameOfDevice: string): Promise<boolean> {
    loading.value = true;
    try {
      const { data, error } = await supabase.rpc('verify_pairing_code', {
        p_code: pairingCode,
        p_device_name: nameOfDevice,
      });

      if (error) throw error;

      const res = data as {
        success: boolean;
        device_token?: string;
        tenant_id?: string;
        tenant_name?: string;
        tenant_slug?: string;
        message?: string;
      };

      if (!res.success) {
        throw new Error(res.message || 'Verification failed');
      }

      // Commit to state and storage
      deviceToken.value = res.device_token!;
      tenantId.value = res.tenant_id!;
      tenantSlug.value = res.tenant_slug!;
      tenantName.value = res.tenant_name!;
      deviceName.value = nameOfDevice;

      localStorage.setItem('kiosk.device_token', res.device_token!);
      localStorage.setItem('kiosk.tenant_id', res.tenant_id!);
      localStorage.setItem('kiosk.tenant_slug', res.tenant_slug!);
      localStorage.setItem('kiosk.tenant_name', res.tenant_name!);
      localStorage.setItem('kiosk.device_name', nameOfDevice);

      // Support legacy system compatibility by also writing to old keys if needed
      localStorage.setItem('device_token', res.device_token!);
      localStorage.setItem('device_tenant_id', res.tenant_id!);
      localStorage.setItem('device_tenant_name', res.tenant_name!);
      localStorage.setItem('device_tenant_slug', res.tenant_slug!);

      return true;
    } catch (err) {
      console.error('Device pairing error:', err);
      throw err;
    } finally {
      loading.value = false;
    }
  }

  async function fetchStaffList(): Promise<void> {
    loading.value = true;
    try {
      const { data, error } = await supabase.rpc('get_paired_device_staff', {
        p_device_token: deviceToken.value,
        p_tenant_id: tenantId.value,
      });

      if (error) throw error;

      staffList.value = ((data as { id: string; full_name: string; role: string }[]) || []).map(
        (item) => ({
          id: item.id,
          fullName: item.full_name,
          role: item.role,
        }),
      );

      // Cache the staff list
      localStorage.setItem('kiosk.staff_list', JSON.stringify(staffList.value));
    } catch (err) {
      console.error('Failed to fetch staff list, attempting to load from cache:', err);
      const error = err as { message?: string; code?: string };
      if (error.message?.includes('Unauthorized device token') || error.code === '42501') {
        unpairDevice();
        throw err;
      }
      const cached = localStorage.getItem('kiosk.staff_list');
      if (cached) {
        staffList.value = JSON.parse(cached);
      } else {
        throw err;
      }
    } finally {
      loading.value = false;
    }
  }

  async function loginStaff(
    staffId: string,
    pin: string,
  ): Promise<{ success: boolean; setupRequired?: boolean }> {
    loading.value = true;
    failedPinMessage.value = null;
    try {
      const { data, error } = await supabase.rpc('verify_staff_pin', {
        p_device_token: deviceToken.value,
        p_tenant_id: tenantId.value,
        p_pin: pin,
      });

      if (error) throw error;

      const res = data as {
        success: boolean;
        setup_required?: boolean;
        staff_id?: string;
        full_name?: string;
        role?: string;
        permissions?: Record<string, unknown>;
        message?: string;
        code?: string;
      };

      if (!res.success) {
        if (res.code === 'DEVICE_BLOCKED') {
          unpairDevice();
        }
        failedPinMessage.value = res.message || 'Verification failed';
        return { success: false };
      }

      if (res.staff_id !== staffId) {
        failedPinMessage.value = 'PIN does not match the selected staff member.';
        return { success: false };
      }

      if (res.setup_required) {
        isSetupRequired.value = true;
        currentStaff.value = {
          id: res.staff_id,
          fullName: res.full_name!,
          role: res.role!,
          permissions: res.permissions,
        };
        return { success: true, setupRequired: true };
      }

      currentStaff.value = {
        id: res.staff_id,
        fullName: res.full_name!,
        role: res.role!,
        permissions: res.permissions,
      };
      isSetupRequired.value = false;

      // Keep legacy keys updated
      localStorage.setItem('staff_session_id', res.staff_id);
      localStorage.setItem('staff_session_name', res.full_name!);
      localStorage.setItem('staff_session_role', res.role!);

      return { success: true, setupRequired: false };
    } catch (err) {
      console.error('PIN Login Exception:', err);
      failedPinMessage.value = 'Network error during authorization.';
      return { success: false };
    } finally {
      loading.value = false;
    }
  }

  async function setPrivatePin(staffId: string, tempPin: string, newPin: string): Promise<boolean> {
    loading.value = true;
    try {
      const { data, error } = await supabase.rpc('set_staff_pin', {
        p_device_token: deviceToken.value,
        p_tenant_id: tenantId.value,
        p_staff_id: staffId,
        p_temp_pin: tempPin,
        p_new_pin: newPin,
      });

      if (error) throw error;
      if (data) {
        isSetupRequired.value = false;
        return true;
      }
      return false;
    } catch (err) {
      console.error('Set Private PIN Error:', err);
      throw err;
    } finally {
      loading.value = false;
    }
  }

  function logoutStaff() {
    currentStaff.value = null;
    isSetupRequired.value = false;
    failedPinMessage.value = null;
    localStorage.removeItem('staff_session_id');
    localStorage.removeItem('staff_session_name');
    localStorage.removeItem('staff_session_role');
  }

  function hasStaffPermission(moduleName: string, permissionName: string): boolean {
    if (!currentStaff.value?.permissions) return false;
    const permissions = currentStaff.value.permissions;
    const mod = (permissions.modules as Record<string, Record<string, unknown>>)?.[moduleName];
    if (!mod) return false;
    return !!mod[permissionName];
  }

  function unpairDevice() {
    logoutStaff();
    deviceToken.value = null;
    tenantId.value = null;
    tenantSlug.value = null;
    tenantName.value = null;
    deviceName.value = null;

    localStorage.removeItem('kiosk.device_token');
    localStorage.removeItem('kiosk.tenant_id');
    localStorage.removeItem('kiosk.tenant_slug');
    localStorage.removeItem('kiosk.tenant_name');
    localStorage.removeItem('kiosk.device_name');

    // Remove legacy keys
    localStorage.removeItem('device_token');
    localStorage.removeItem('device_tenant_id');
    localStorage.removeItem('device_tenant_name');
    localStorage.removeItem('device_tenant_slug');
  }

  return {
    deviceToken,
    tenantId,
    tenantSlug,
    tenantName,
    deviceName,
    currentStaff,
    isSetupRequired,
    failedPinMessage,
    loading,
    isOnline,
    isDevicePaired,
    isStaffAuthenticated,
    staffList,
    fetchStaffList,
    pairDevice,
    loginStaff,
    hasStaffPermission,
    setPrivatePin,
    logoutStaff,
    unpairDevice,
  };
});
