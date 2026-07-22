// web/src/stores/customers.ts
import { ref } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '../boot/supabase';
import { useTenantStore } from './tenant';
import { useKioskStore } from './kiosk';

export type CustomerCategory = 'contract_worker' | 'walk_in_baki';

export interface Customer {
  id: string;
  tenant_id: string;
  full_name: string;
  category: CustomerCategory;
  phone: string | null;
  outstanding_balance: number;
  contract_daily_rate: number | null;
  contract_shifts: string[] | null;
  factory_unit: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface DailyAttendance {
  id: string;
  customer_id: string;
  session_id: string;
  business_date: string;
  attended_shifts: string[];
  rate_applied: number;
}

function resolveTenantId(): string | null {
  return useTenantStore().activeTenant?.id ?? useKioskStore().tenantId ?? null;
}

export const useCustomersStore = defineStore('customers', () => {
  const customers = ref<Customer[]>([]);
  const attendanceToday = ref<DailyAttendance[]>([]);
  const sessionBakiTransactions = ref<
    {
      id: string;
      customer_id: string;
      customer_name: string;
      items_description: string;
      amount: number;
      created_at: string;
      staff_name: string | null;
    }[]
  >([]);
  const loading = ref(false);
  const lastError = ref<string | null>(null);

  async function fetchCustomers(
    filters: {
      category?: CustomerCategory | undefined;
      activeOnly?: boolean | undefined;
      search?: string | undefined;
    } = {},
  ) {
    const tenantId = resolveTenantId();
    if (!tenantId) return;
    loading.value = true;
    lastError.value = null;
    try {
      const kiosk = useKioskStore();
      let rows: Customer[] = [];

      if (kiosk.deviceToken && kiosk.currentStaff?.id) {
        const { data, error } = await supabase.rpc('list_customers', {
          p_tenant_id: tenantId,
          p_device_token: kiosk.deviceToken,
          p_staff_id: kiosk.currentStaff.id,
          p_active_only: filters.activeOnly !== false,
        });
        if (error) throw error;
        rows = (data ?? []) as Customer[];
      } else {
        let q = supabase
          .from('customers')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('full_name', { ascending: true });

        if (filters.category) {
          q = q.eq('category', filters.category);
        }
        if (filters.activeOnly !== false) {
          q = q.eq('is_active', true);
        }
        if (filters.search) {
          q = q.or(`full_name.ilike.%${filters.search}%,phone.ilike.%${filters.search}%`);
        }

        const { data, error } = await q;
        if (error) throw error;
        rows = (data ?? []) as Customer[];
      }

      if (filters.category) {
        rows = rows.filter((c) => c.category === filters.category);
      }
      if (filters.search) {
        const s = filters.search.toLowerCase();
        rows = rows.filter(
          (c) =>
            c.full_name.toLowerCase().includes(s) || (c.phone && c.phone.toLowerCase().includes(s)),
        );
      }

      customers.value = rows;
    } catch (e) {
      lastError.value = e instanceof Error ? e.message : 'Failed to load customers';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function upsertCustomer(
    payload: Partial<Customer> & { full_name: string; category: CustomerCategory },
  ) {
    const tenantId = resolveTenantId();
    if (!tenantId) throw new Error('No active tenant');
    const row = { ...payload, tenant_id: tenantId };
    const { error } = payload.id
      ? await supabase.from('customers').update(row).eq('id', payload.id)
      : await supabase.from('customers').insert(row);
    if (error) throw error;
    await fetchCustomers();
  }

  async function fetchAttendanceForDate(businessDate: string) {
    const tenantId = resolveTenantId();
    if (!tenantId) return;
    const kiosk = useKioskStore();
    if (kiosk.deviceToken && kiosk.currentStaff?.id) {
      const { data, error } = await supabase.rpc('list_attendance_for_date', {
        p_tenant_id: tenantId,
        p_device_token: kiosk.deviceToken,
        p_staff_id: kiosk.currentStaff.id,
        p_business_date: businessDate,
      });
      if (error) throw error;
      attendanceToday.value = (data ?? []) as DailyAttendance[];
    } else {
      const { data, error } = await supabase
        .from('customer_daily_attendance')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('business_date', businessDate);
      if (error) throw error;
      attendanceToday.value = (data ?? []) as DailyAttendance[];
    }
  }

  async function toggleAttendance(params: {
    customerId: string;
    sessionId: string;
    shiftName: string;
    businessDate: string;
    deviceToken?: string | null | undefined;
    staffId?: string | null | undefined;
  }) {
    const tenantId = resolveTenantId();
    if (!tenantId) throw new Error('No active tenant');
    const { data, error } = await supabase.rpc('toggle_contract_attendance', {
      p_tenant_id: tenantId,
      p_customer_id: params.customerId,
      p_session_id: params.sessionId,
      p_shift_name: params.shiftName,
      p_device_token: params.deviceToken ?? null,
      p_staff_id: params.staffId ?? null,
    });
    if (error) throw error;

    const res = (Array.isArray(data) ? data[0] : data) as unknown as {
      action_taken: string;
      new_balance: number;
    };

    // Update customer balance locally
    const customer = customers.value.find((c) => c.id === params.customerId);
    if (customer) {
      customer.outstanding_balance = Number(res.new_balance);
    }

    // Update attendance list locally
    const recordIdx = attendanceToday.value.findIndex((a) => a.customer_id === params.customerId);
    if (res.action_taken === 'added_first_present') {
      const dailyRate = customer ? customer.contract_daily_rate || 0 : 0;
      attendanceToday.value.push({
        id: Math.random().toString(36).substring(7),
        customer_id: params.customerId,
        session_id: params.sessionId,
        business_date: params.businessDate,
        attended_shifts: [params.shiftName],
        rate_applied: dailyRate,
      });
    } else if (res.action_taken === 'added_shift' && recordIdx !== -1) {
      const record = attendanceToday.value[recordIdx];
      if (record) record.attended_shifts.push(params.shiftName);
    } else if (res.action_taken === 'removed_shift' && recordIdx !== -1) {
      const record = attendanceToday.value[recordIdx];
      if (record) {
        record.attended_shifts = record.attended_shifts.filter((s) => s !== params.shiftName);
      }
    } else if (res.action_taken === 'removed_last_present' && recordIdx !== -1) {
      attendanceToday.value.splice(recordIdx, 1);
    }

    return res;
  }

  async function recordBaki(params: {
    customerId: string;
    sessionId: string;
    itemsDescription: string;
    amount: number;
    deviceToken?: string | null | undefined;
    staffId?: string | null | undefined;
    businessDate?: string | null | undefined;
  }) {
    const tenantId = resolveTenantId();
    if (!tenantId) throw new Error('No active tenant');
    const { data, error } = await supabase.rpc('record_baki_transaction', {
      p_tenant_id: tenantId,
      p_customer_id: params.customerId,
      p_session_id: params.sessionId,
      p_items_description: params.itemsDescription,
      p_amount: params.amount,
      p_device_token: params.deviceToken ?? null,
      p_staff_id: params.staffId ?? null,
      p_business_date: params.businessDate ?? null,
    });
    if (error) throw error;
    return data as number;
  }

  async function recordCollection(params: {
    customerId: string;
    sessionId: string | null;
    amount: number;
    paymentMethod: string;
    notes?: string | undefined;
    deviceToken?: string | null | undefined;
    staffId?: string | null | undefined;
    collectedAt?: string | null | undefined;
  }) {
    const tenantId = resolveTenantId();
    if (!tenantId) throw new Error('No active tenant');
    const { data, error } = await supabase.rpc('record_customer_collection', {
      p_tenant_id: tenantId,
      p_customer_id: params.customerId,
      p_session_id: params.sessionId,
      p_amount: params.amount,
      p_payment_method: params.paymentMethod,
      p_notes: params.notes ?? null,
      p_device_token: params.deviceToken ?? null,
      p_staff_id: params.staffId ?? null,
      p_collected_at: params.collectedAt ?? null,
    });
    if (error) throw error;
    return data as number;
  }

  async function fetchSessionBakiTransactions(sessionId: string) {
    const tenantId = resolveTenantId();
    if (!tenantId) return;
    const kiosk = useKioskStore();
    if (kiosk.deviceToken && kiosk.currentStaff?.id) {
      const { data, error } = await supabase.rpc('list_session_baki_transactions', {
        p_tenant_id: tenantId,
        p_device_token: kiosk.deviceToken,
        p_staff_id: kiosk.currentStaff.id,
        p_session_id: sessionId,
      });
      if (error) throw error;
      sessionBakiTransactions.value = data ?? [];
    } else {
      const { data, error } = await supabase
        .from('baki_transactions')
        .select('*, customers(full_name)')
        .eq('tenant_id', tenantId)
        .eq('session_id', sessionId)
        .order('created_at', { ascending: false });
      if (error) throw error;
      sessionBakiTransactions.value = (data ?? []).map((b) => ({
        id: b.id,
        customer_id: b.customer_id,
        customer_name: b.customers?.full_name || 'Unknown',
        items_description: b.items_description,
        amount: b.amount,
        created_at: b.created_at,
        staff_name: null,
      }));
    }
  }

  function clearCustomers() {
    customers.value = [];
    attendanceToday.value = [];
    sessionBakiTransactions.value = [];
    lastError.value = null;
  }

  function clearAttendanceToday() {
    attendanceToday.value = [];
    sessionBakiTransactions.value = [];
  }

  return {
    customers,
    attendanceToday,
    sessionBakiTransactions,
    loading,
    lastError,
    fetchCustomers,
    upsertCustomer,
    fetchAttendanceForDate,
    toggleAttendance,
    recordBaki,
    recordCollection,
    fetchSessionBakiTransactions,
    clearCustomers,
    clearAttendanceToday,
  };
});
