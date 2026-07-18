// web/src/stores/customers.ts
import { ref } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '../boot/supabase';
import { useTenantStore } from './tenant';

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

export const useCustomersStore = defineStore('customers', () => {
  const customers = ref<Customer[]>([]);
  const attendanceToday = ref<DailyAttendance[]>([]);
  const loading = ref(false);
  const lastError = ref<string | null>(null);

  async function fetchCustomers(
    filters: {
      category?: CustomerCategory | undefined;
      activeOnly?: boolean | undefined;
      search?: string | undefined;
    } = {},
  ) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) return;
    loading.value = true;
    lastError.value = null;
    try {
      let q = supabase
        .from('customers')
        .select('*')
        .eq('tenant_id', tenant.id)
        .order('full_name', { ascending: true });

      if (filters.category) {
        q = q.eq('category', filters.category);
      }
      if (filters.activeOnly !== false) {
        q = q.eq('is_active', true);
      }
      if (filters.search) {
        q = q.ilike('full_name', `%${filters.search}%`);
      }

      const { data, error } = await q;
      if (error) throw error;
      customers.value = (data ?? []) as Customer[];
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
    const tenant = useTenantStore().activeTenant;
    if (!tenant) throw new Error('No active tenant');
    const row = { ...payload, tenant_id: tenant.id };
    const { error } = payload.id
      ? await supabase.from('customers').update(row).eq('id', payload.id)
      : await supabase.from('customers').insert(row);
    if (error) throw error;
    await fetchCustomers();
  }

  async function fetchAttendanceForDate(businessDate: string) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) return;
    const { data, error } = await supabase
      .from('customer_daily_attendance')
      .select('*')
      .eq('tenant_id', tenant.id)
      .eq('business_date', businessDate);
    if (error) throw error;
    attendanceToday.value = (data ?? []) as DailyAttendance[];
  }

  async function toggleAttendance(params: {
    customerId: string;
    sessionId: string;
    shiftName: string;
    deviceToken?: string | null | undefined;
    staffId?: string | null | undefined;
  }) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) throw new Error('No active tenant');
    const { data, error } = await supabase.rpc('toggle_contract_attendance', {
      p_tenant_id: tenant.id,
      p_customer_id: params.customerId,
      p_session_id: params.sessionId,
      p_shift_name: params.shiftName,
      p_device_token: params.deviceToken ?? null,
      p_staff_id: params.staffId ?? null,
    });
    if (error) throw error;

    const res = data as unknown as { action_taken: string; new_balance: number };

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
        business_date: new Date().toISOString().split('T')[0] || '',
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
  }) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) throw new Error('No active tenant');
    const { data, error } = await supabase.rpc('record_baki_transaction', {
      p_tenant_id: tenant.id,
      p_customer_id: params.customerId,
      p_session_id: params.sessionId,
      p_items_description: params.itemsDescription,
      p_amount: params.amount,
      p_device_token: params.deviceToken ?? null,
      p_staff_id: params.staffId ?? null,
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
  }) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) throw new Error('No active tenant');
    const { data, error } = await supabase.rpc('record_customer_collection', {
      p_tenant_id: tenant.id,
      p_customer_id: params.customerId,
      p_session_id: params.sessionId,
      p_amount: params.amount,
      p_payment_method: params.paymentMethod,
      p_notes: params.notes ?? null,
      p_device_token: params.deviceToken ?? null,
      p_staff_id: params.staffId ?? null,
    });
    if (error) throw error;
    return data as number;
  }

  function clearCustomers() {
    customers.value = [];
    attendanceToday.value = [];
    lastError.value = null;
  }

  return {
    customers,
    attendanceToday,
    loading,
    lastError,
    fetchCustomers,
    upsertCustomer,
    fetchAttendanceForDate,
    toggleAttendance,
    recordBaki,
    recordCollection,
    clearCustomers,
  };
});
