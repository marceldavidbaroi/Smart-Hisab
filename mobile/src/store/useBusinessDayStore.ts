import { create } from 'zustand';
import { supabase } from '@/lib/supabase';

export interface BusinessDay {
  id: string;
  tenant_id: string;
  business_date: string;
  status: 'open' | 'closed';
  opening_cash: number;
  closing_cash?: number | null;
  expected_cash?: number | null;
  variance?: number | null;
  opened_by_staff_id?: string | null;
  closed_by_staff_id?: string | null;
  opened_at: string;
  closed_at?: string | null;
  notes?: string | null;
}

interface BusinessDayState {
  activeDay: BusinessDay | null;
  isLoading: boolean;
  error: string | null;

  fetchActiveDay: (tenantId: string) => Promise<BusinessDay | null>;
  startDay: (params: {
    tenantId: string;
    deviceToken?: string | null;
    staffId?: string | null;
    openingCash: number;
  }) => Promise<string>;
  endDay: (params: {
    tenantId: string;
    deviceToken?: string | null;
    staffId?: string | null;
    dayId: string;
    closingCash: number;
    notes?: string;
  }) => Promise<{ expected_cash: number; variance: number; status: string }>;
  resumeDay: (params: {
    tenantId: string;
    deviceToken?: string | null;
    staffId?: string | null;
    dayId: string;
  }) => Promise<void>;
}

export const useBusinessDayStore = create<BusinessDayState>((set, get) => ({
  activeDay: null,
  isLoading: false,
  error: null,

  fetchActiveDay: async (tenantId: string) => {
    set({ isLoading: true, error: null });
    try {
      const { data, error } = await supabase
        .from('business_days')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('status', 'open')
        .order('opened_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) throw error;
      set({ activeDay: data || null, isLoading: false });
      return data || null;
    } catch (err: any) {
      console.warn('[fetchActiveDay] error:', err.message || err);
      set({ error: err.message || 'Failed to fetch active business day', isLoading: false });
      return null;
    }
  },

  startDay: async ({ tenantId, deviceToken, staffId, openingCash }) => {
    set({ isLoading: true, error: null });
    try {
      if (openingCash < 0) {
        throw new Error('Opening cash amount cannot be negative.');
      }

      // If device token & staff ID are provided, call start_business_day RPC
      if (deviceToken && staffId) {
        const { data, error } = await supabase.rpc('start_business_day', {
          p_device_token: deviceToken,
          p_staff_id: staffId,
          p_opening_cash: openingCash,
        });
        if (error) throw error;

        // Fetch newly created day record
        await get().fetchActiveDay(tenantId);
        return data as string;
      }

      // Direct insert for authenticated manager user
      const { data: userRes } = await supabase.auth.getUser();
      const userId = userRes.user?.id;

      const { data, error } = await supabase
        .from('business_days')
        .insert({
          tenant_id: tenantId,
          business_date: new Date().toISOString().split('T')[0],
          status: 'open',
          opening_cash: openingCash,
          opened_by_user_id: userId,
          opened_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) throw error;

      set({ activeDay: data, isLoading: false });
      return data.id;
    } catch (err: any) {
      const msg = err.message || 'Failed to start business day';
      set({ error: msg, isLoading: false });
      throw new Error(msg);
    }
  },

  endDay: async ({ tenantId, deviceToken, staffId, dayId, closingCash, notes }) => {
    set({ isLoading: true, error: null });
    try {
      if (closingCash < 0) {
        throw new Error('Closing cash amount cannot be negative.');
      }

      if (deviceToken && staffId) {
        const { data, error } = await supabase.rpc('end_business_day', {
          p_device_token: deviceToken,
          p_staff_id: staffId,
          p_day_id: dayId,
          p_closing_cash: closingCash,
          p_notes: notes || null,
        });

        if (error) throw error;
        set({ activeDay: null, isLoading: false });
        return data?.[0] || data;
      }

      // Direct manager update
      const { data: userRes } = await supabase.auth.getUser();
      const userId = userRes.user?.id;

      // Calculate expected cash
      const { data: dayData } = await supabase
        .from('business_days')
        .select('opening_cash')
        .eq('id', dayId)
        .single();

      const openingCash = dayData?.opening_cash || 0;

      const { data: ledgerInflows } = await supabase
        .from('transaction_ledger')
        .select('amount')
        .eq('business_day_id', dayId)
        .eq('type', 'inflow')
        .eq('payment_method', 'cash');

      const { data: ledgerOutflows } = await supabase
        .from('transaction_ledger')
        .select('amount')
        .eq('business_day_id', dayId)
        .eq('type', 'outflow')
        .eq('payment_method', 'cash');

      const totalInflow = (ledgerInflows || []).reduce((acc, row) => acc + (row.amount || 0), 0);
      const totalOutflow = (ledgerOutflows || []).reduce((acc, row) => acc + (row.amount || 0), 0);

      const expectedCash = openingCash + totalInflow - totalOutflow;
      const variance = closingCash - expectedCash;

      const { error: updateErr } = await supabase
        .from('business_days')
        .update({
          status: 'closed',
          closing_cash: closingCash,
          expected_cash: expectedCash,
          variance: variance,
          closed_by_user_id: userId,
          closed_at: new Date().toISOString(),
          notes: notes || null,
        })
        .eq('id', dayId);

      if (updateErr) throw updateErr;

      set({ activeDay: null, isLoading: false });
      return { expected_cash: expectedCash, variance, status: 'closed' };
    } catch (err: any) {
      const msg = err.message || 'Failed to end business day';
      set({ error: msg, isLoading: false });
      throw new Error(msg);
    }
  },

  resumeDay: async ({ tenantId, deviceToken, staffId, dayId }) => {
    set({ isLoading: true, error: null });
    try {
      if (deviceToken && staffId) {
        const { error } = await supabase.rpc('resume_business_day', {
          p_device_token: deviceToken,
          p_staff_id: staffId,
          p_day_id: dayId,
        });
        if (error) throw error;
        await get().fetchActiveDay(tenantId);
        return;
      }

      const { error } = await supabase
        .from('business_days')
        .update({
          status: 'open',
          closed_at: null,
          closing_cash: null,
        })
        .eq('id', dayId);

      if (error) throw error;
      await get().fetchActiveDay(tenantId);
    } catch (err: any) {
      const msg = err.message || 'Failed to resume business day';
      set({ error: msg, isLoading: false });
      throw new Error(msg);
    }
  },
}));
