import { ref } from 'vue';
import { defineStore } from 'pinia';
import { supabase } from '../boot/supabase';
import { useTenantStore } from './tenant';

export interface LedgerEntry {
  id: string;
  tenant_id: string;
  session_id: string | null;
  type: 'inflow' | 'outflow';
  category: string;
  amount: number;
  payment_method: 'cash' | 'bank_transfer' | 'mobile_wallet';
  operator_user_id: string | null;
  operator_staff_id: string | null;
  notes: string | null;
  created_at: string;
  operator_staff?: { full_name: string } | null;
}

export interface FinancialSummary {
  total_inflow: number;
  total_outflow: number;
  net_profit_loss: number;
  outstanding_receivables: number;
  outstanding_payables: number;
  cash_sales_pos: number;
  market_expenses: number;
  payroll_expenses: number;
}

export const useLedgerStore = defineStore('ledger', () => {
  const entries = ref<LedgerEntry[]>([]);
  const summary = ref<FinancialSummary | null>(null);
  const cashBalance = ref<number | null>(null);
  const loading = ref(false);
  const lastError = ref<string | null>(null);

  async function fetchEntries(
    filters: {
      type?: string;
      category?: string;
      paymentMethod?: string;
      sessionId?: string;
      start?: string;
      end?: string;
      from?: number;
      to?: number;
    } = {},
  ) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) return;
    loading.value = true;
    lastError.value = null;
    try {
      let q = supabase
        .from('transaction_ledger')
        .select('*, operator_staff:staff_members!operator_staff_id(full_name)')
        .eq('tenant_id', tenant.id)
        .order('created_at', { ascending: false });

      if (filters.type) q = q.eq('type', filters.type);
      if (filters.category) q = q.eq('category', filters.category);
      if (filters.paymentMethod) q = q.eq('payment_method', filters.paymentMethod);
      if (filters.sessionId) q = q.eq('session_id', filters.sessionId);
      if (filters.start) q = q.gte('created_at', filters.start);
      if (filters.end) q = q.lte('created_at', filters.end);
      if (filters.from != null && filters.to != null) q = q.range(filters.from, filters.to);

      const { data, error } = await q;
      if (error) throw error;
      entries.value = (data ?? []) as LedgerEntry[];
    } catch (e) {
      lastError.value = e instanceof Error ? e.message : 'Failed to load ledger';
      throw e;
    } finally {
      loading.value = false;
    }
  }

  async function logManualEntry(params: {
    sessionId?: string | null;
    type: 'inflow' | 'outflow';
    category: string;
    amount: number;
    paymentMethod: string;
    notes?: string | null;
  }) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) throw new Error('No active tenant');
    loading.value = true;
    try {
      const { data, error } = await supabase.rpc('log_manual_ledger_entry', {
        p_tenant_id: tenant.id,
        p_session_id: params.sessionId ?? null,
        p_type: params.type,
        p_category: params.category,
        p_amount: params.amount,
        p_payment_method: params.paymentMethod,
        p_notes: params.notes ?? null,
      });
      if (error) throw error;
      await fetchEntries();
      return data as string;
    } finally {
      loading.value = false;
    }
  }

  async function fetchSummary(start: string, end: string) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) return;
    loading.value = true;
    try {
      const { data, error } = await supabase.rpc('get_tenant_financial_summary', {
        p_tenant_id: tenant.id,
        p_start_date: start,
        p_end_date: end,
      });
      if (error) throw error;
      summary.value = (Array.isArray(data) ? data[0] : data) as FinancialSummary;
    } finally {
      loading.value = false;
    }
  }

  async function fetchCashBalance(sessionId: string) {
    const tenant = useTenantStore().activeTenant;
    if (!tenant) return;
    const { data, error } = await supabase.rpc('get_cash_register_running_balance', {
      p_tenant_id: tenant.id,
      p_session_id: sessionId,
    });
    if (error) throw error;
    cashBalance.value = Number(data);
  }

  function clearLedger() {
    entries.value = [];
    summary.value = null;
    cashBalance.value = null;
    lastError.value = null;
  }

  return {
    entries,
    summary,
    cashBalance,
    loading,
    lastError,
    fetchEntries,
    logManualEntry,
    fetchSummary,
    fetchCashBalance,
    clearLedger,
  };
});
