import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '../boot/supabase';
import { useTenantStore } from './tenant';
import { useKioskStore } from './kiosk';

export interface OperationalSession {
  id: string;
  tenant_id: string;
  shift_id: string;
  business_date: string;
  status: 'open' | 'closed';
  opening_cash: number;
  closing_cash: number | null;
  expected_cash: number | null;
  variance: number | null;
  opened_by_staff_id: string;
  closed_by_staff_id: string | null;
  opened_by_user_id: string | null;
  closed_by_user_id: string | null;
  opened_at: string;
  closed_at: string | null;
  notes: string | null;
  shifts?: { name: string; start_time: string; end_time: string } | null;
}

function resolveTenantId(): string | null {
  return useTenantStore().activeTenant?.id ?? useKioskStore().tenantId ?? null;
}

export const useSessionStore = defineStore('session', () => {
  const activeSession = ref<OperationalSession | null>(null);
  const loading = ref(false);
  const lastError = ref<string | null>(null);

  const hasActiveSession = computed(() => activeSession.value?.status === 'open');

  async function fetchActiveSession() {
    const tenantId = resolveTenantId();
    if (!tenantId) {
      activeSession.value = null;
      return;
    }
    loading.value = true;
    lastError.value = null;
    try {
      const kiosk = useKioskStore();
      if (kiosk.deviceToken) {
        const { data, error } = await supabase.rpc('get_open_session', {
          p_tenant_id: tenantId,
          p_device_token: kiosk.deviceToken,
        });
        if (error) throw error;
        activeSession.value = (data as OperationalSession | null) ?? null;
      } else {
        const { data, error } = await supabase
          .from('sessions')
          .select('*, shifts(name, start_time, end_time)')
          .eq('tenant_id', tenantId)
          .eq('status', 'open')
          .maybeSingle();
        if (error) throw error;
        activeSession.value = data;
      }
    } catch (e) {
      lastError.value = e instanceof Error ? e.message : 'Failed to load session';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function openSession(params: {
    shiftId: string;
    openingCash: number;
    businessDate?: string;
    deviceToken: string;
    staffId: string;
  }) {
    loading.value = true;
    lastError.value = null;
    try {
      const { data, error } = await supabase.rpc('open_session', {
        p_device_token: params.deviceToken,
        p_staff_id: params.staffId,
        p_shift_id: params.shiftId,
        p_opening_cash: params.openingCash,
        p_business_date: params.businessDate ?? undefined,
      });
      if (error) throw error;
      await fetchActiveSession();
      return data as string;
    } catch (e) {
      lastError.value = e instanceof Error ? e.message : 'Open session failed';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function closeSession(params: {
    sessionId: string;
    closingCash: number;
    notes?: string;
    deviceToken: string;
    staffId: string;
  }) {
    loading.value = true;
    lastError.value = null;
    try {
      const { data, error } = await supabase.rpc('close_session', {
        p_device_token: params.deviceToken,
        p_staff_id: params.staffId,
        p_session_id: params.sessionId,
        p_closing_cash: params.closingCash,
        p_notes: params.notes ?? null,
      });
      if (error) throw error;
      activeSession.value = null;
      return data as unknown as { expected_cash: number; variance: number; status: string }[];
    } catch (e) {
      lastError.value = e instanceof Error ? e.message : 'Close session failed';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function reopenSession(sessionId: string) {
    loading.value = true;
    lastError.value = null;
    try {
      const { error } = await supabase.rpc('reopen_session', {
        p_session_id: sessionId,
      });
      if (error) throw error;
      await fetchActiveSession();
    } catch (e) {
      lastError.value = e instanceof Error ? e.message : 'Reopen session failed';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  function clearSession() {
    activeSession.value = null;
    lastError.value = null;
  }

  return {
    activeSession,
    loading,
    lastError,
    hasActiveSession,
    fetchActiveSession,
    openSession,
    closeSession,
    reopenSession,
    clearSession,
  };
});
