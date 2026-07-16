import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '../boot/supabase';
import { getUserTenants, getTenantSettings } from '../services/multiTenant';
import type { Tenant, UserProfile } from '../services/multiTenant';
import type { User } from '@supabase/supabase-js';

export interface TenantMembership {
  id: string;
  status: string;
  joined_at: string;
  tenant_id: string;
  user_id: string;
  tenants: Tenant | null;
  tenant_roles: {
    id: string;
    name: string;
    permissions: unknown;
  } | null;
}

export interface SimplifiedTenantSettings {
  tenant_id: string;
  logo_url: string | null;
  theme_color: string | null;
  enabled_features: Record<string, boolean>;
  preferences: unknown;
  updated_at: string;
}

export const useTenantStore = defineStore('tenant', () => {
  // State
  const user = ref<User | null>(null);
  const userProfile = ref<UserProfile | null>(null);
  const myTenants = ref<TenantMembership[]>([]);
  const activeTenant = ref<Tenant | null>(null);
  const activeSettings = ref<SimplifiedTenantSettings | null>(null);
  const activeRole = ref<string | null>(null);
  const loading = ref(false);
  const initialized = ref(false);
  const isAdminSession = ref<boolean>(
    typeof window !== 'undefined' && localStorage.getItem('auth.is_admin_session') === 'true',
  );

  // Getters
  const isSuperadmin = computed(() => {
    return userProfile.value?.is_superadmin || false;
  });

  // Actions / Methods
  function hasTenantAccess(slug: string): boolean {
    if (userProfile.value?.is_superadmin) return true;
    return myTenants.value.some((m) => m.tenants?.slug === slug && m.status === 'active');
  }

  function isFeatureEnabled(feature: string): boolean {
    if (!activeSettings.value?.enabled_features) return false;
    return !!activeSettings.value.enabled_features[feature];
  }

  function hasPermission(moduleName: string, action: 'read' | 'write' = 'read'): boolean {
    if (userProfile.value?.is_superadmin) return true;
    if (!activeTenant.value) return false;

    const membership = myTenants.value.find((m) => m.tenants?.id === activeTenant.value?.id);
    if (!membership) return false;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const permissions = membership.tenant_roles?.permissions as Record<string, any> | null;
    if (!permissions) return false;

    if (permissions.all === true) return true;

    if (permissions.modules?.[moduleName]) {
      return !!permissions.modules[moduleName][action];
    }

    if (moduleName === 'settings' || moduleName === 'members') {
      return false;
    }
    return true;
  }

  async function loadUserProfileAndTenants() {
    if (!user.value) return;

    try {
      // Load user profile
      const { data: profile, error: profileErr } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.value.id)
        .single();

      if (profileErr) {
        console.error('Error loading user profile:', profileErr.message);
      } else {
        userProfile.value = profile;
      }

      // Load tenants user is member of
      const memberships = await getUserTenants(user.value.id);
      myTenants.value = ((memberships || []) as unknown as TenantMembership[]).map((m) => {
        const raw = m.tenants as unknown;
        if (Array.isArray(raw)) {
          return { ...m, tenants: (raw[0] as Tenant | null) ?? null };
        }
        return m;
      });
    } catch (err) {
      const error = err as Error;
      console.error('Error loading profile and tenants:', error.message);
    }
  }

  async function syncFromUser(sessionUser: User | null) {
    if (sessionUser) {
      user.value = sessionUser;
      await loadUserProfileAndTenants();
    } else {
      clearStore();
    }
    initialized.value = true;
  }

  async function initializeStore() {
    // Always re-sync session. An early return here broke email/OAuth login:
    // the route guard marks initialized=true while logged out, then LoginPage's
    // post-login initializeStore() was a no-op → empty store → blank/wrong redirect.
    loading.value = true;
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      await syncFromUser(session?.user ?? null);
    } catch (err) {
      const error = err as Error;
      console.error('Failed to initialize tenant store:', error.message);
      initialized.value = true;
    } finally {
      loading.value = false;
    }
  }

  async function setActiveTenantBySlug(slug: string) {
    if (activeTenant.value?.slug === slug) {
      return;
    }

    const membership = myTenants.value.find((m) => m.tenants?.slug === slug);

    if (membership) {
      activeTenant.value = membership.tenants;
      activeRole.value = membership.tenant_roles?.name || null;

      if (activeTenant.value) {
        localStorage.setItem('workspace.selected.tenant.id', activeTenant.value.id);
        try {
          const settings = await getTenantSettings(activeTenant.value.id);
          activeSettings.value = settings;
        } catch (err) {
          const error = err as Error;
          console.error('Failed to load tenant settings:', error.message);
          activeSettings.value = null;
        }
      }
    } else if (isSuperadmin.value) {
      const { data: tenant, error: tenantErr } = await supabase
        .from('tenants')
        .select('*')
        .eq('slug', slug)
        .single();

      if (!tenantErr && tenant) {
        activeTenant.value = tenant;
        activeRole.value = 'Superadmin';
        localStorage.setItem('workspace.selected.tenant.id', tenant.id);
        try {
          const settings = await getTenantSettings(tenant.id);
          activeSettings.value = settings;
        } catch (err) {
          const error = err as Error;
          console.error('Failed to load tenant settings for superadmin:', error.message);
          activeSettings.value = null;
        }
      } else {
        clearActiveTenant();
        throw new Error(`Tenant not found: ${slug}`);
      }
    } else {
      clearActiveTenant();
      throw new Error(`No access to tenant or tenant does not exist: ${slug}`);
    }
  }

  function clearActiveTenant() {
    activeTenant.value = null;
    activeSettings.value = null;
    activeRole.value = null;
    localStorage.removeItem('workspace.selected.tenant.id');
  }

  function setAdminSession(val: boolean) {
    isAdminSession.value = val;
    if (typeof window !== 'undefined') {
      if (val) {
        localStorage.setItem('auth.is_admin_session', 'true');
      } else {
        localStorage.removeItem('auth.is_admin_session');
      }
    }
  }

  function clearStore() {
    user.value = null;
    userProfile.value = null;
    myTenants.value = [];
    clearActiveTenant();
    isAdminSession.value = false;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth.is_admin_session');
    }
  }

  async function logout() {
    await supabase.auth.signOut();
    clearStore();
    initialized.value = false;
  }

  return {
    user,
    userProfile,
    myTenants,
    activeTenant,
    activeSettings,
    activeRole,
    loading,
    initialized,
    isSuperadmin,
    isAdminSession,
    setAdminSession,
    hasTenantAccess,
    isFeatureEnabled,
    hasPermission,
    initializeStore,
    syncFromUser,
    loadUserProfileAndTenants,
    setActiveTenantBySlug,
    clearActiveTenant,
    clearStore,
    logout,
  };
});
