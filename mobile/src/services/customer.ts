import { supabase } from '../lib/supabase';
import { fetchPairedDeviceStaff } from './staff';

export interface Customer {
  id: string;
  tenant_id: string;
  full_name: string;
  category?: string | null;
  phone: string | null;
  outstanding_balance: number;
  contract_daily_rate: number | null;
  contract_shifts: string[] | null;
  factory_unit: string | null;
  is_active: boolean;
  wallet_id?: string | null;
  created_at: string;
  updated_at: string;
}

export interface FetchCustomersFilters {
  activeOnly?: boolean;
  search?: string;
  deviceToken?: string | null;
  staffId?: string | null;
}

export interface CreateCustomerInput {
  tenant_id: string;
  full_name: string;
  phone?: string | null;
  contract_daily_rate?: number | null;
  contract_shifts?: string[] | null;
  factory_unit?: string | null;
}

/**
 * Fetch or create wallet for a given customer ID
 */
export async function ensureCustomerWallet(tenantId: string, customerId: string): Promise<string | null> {
  try {
    const { data: walletData } = await supabase
      .from('customer_wallets')
      .select('id')
      .eq('customer_id', customerId)
      .maybeSingle();

    if (walletData?.id) {
      return walletData.id;
    }

    const { data: newWallet, error: walletError } = await supabase
      .from('customer_wallets')
      .insert({ tenant_id: tenantId, customer_id: customerId })
      .select('id')
      .single();

    if (walletError) {
      console.warn('Failed to insert customer wallet:', walletError.message);
      return null;
    }

    return newWallet?.id || null;
  } catch (err: any) {
    console.warn('ensureCustomerWallet exception:', err?.message || err);
    return null;
  }
}

/**
 * Fetch customers for a given tenant ID
 */
export async function getCustomers(
  tenantId: string,
  filters: FetchCustomersFilters = {}
): Promise<Customer[]> {
  let customersList: Customer[] = [];
  let directError: any = null;

  const deviceTokenToUse = filters.deviceToken || 'demo_device_token';
  let staffIdToUse = filters.staffId;

  // If deviceToken exists and staffId is not yet provided, resolve staffId from paired device staff
  if (deviceTokenToUse && !staffIdToUse) {
    try {
      const staffList = await fetchPairedDeviceStaff(deviceTokenToUse, tenantId);
      if (staffList && staffList.length > 0) {
        staffIdToUse = staffList[0].id;
        console.log('[getCustomers] Auto-resolved staffId from paired device staff:', staffIdToUse);
      }
    } catch (e: any) {
      console.warn('[getCustomers] Auto-resolving paired device staff failed:', e?.message || e);
    }
  }

  // 1. If deviceToken and staffId are available, invoke `list_customers` RPC first
  if (deviceTokenToUse && staffIdToUse) {
    try {
      console.log('[getCustomers] Invoking list_customers RPC with staffId:', staffIdToUse, 'deviceToken:', deviceTokenToUse);
      const { data, error } = await supabase.rpc('list_customers', {
        p_tenant_id: tenantId,
        p_device_token: deviceTokenToUse,
        p_staff_id: staffIdToUse,
        p_active_only: filters.activeOnly !== false,
      });

      if (error) {
        console.warn('[getCustomers] list_customers RPC returned error:', error.message, error);
      } else if (data && data.length > 0) {
        let list = data as Customer[];
        if (filters.search) {
          const s = filters.search.trim().toLowerCase();
          list = list.filter(
            (c: any) =>
              (c.full_name && c.full_name.toLowerCase().includes(s)) ||
              (c.phone && c.phone.includes(s))
          );
        }
        console.log('[getCustomers] Successfully fetched customers via list_customers RPC, count:', list.length);
        return list.map((c: any) => ({
          ...c,
          outstanding_balance: Number(c.outstanding_balance || 0),
        }));
      } else {
        console.log('[getCustomers] list_customers RPC returned empty array:', data);
      }
    } catch (err: any) {
      console.warn('[getCustomers] list_customers RPC exception:', err?.message || err);
    }
  }

  // 2. Direct table query (for standard authenticated user session)
  try {
    let query = supabase
      .from('customers')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('full_name', { ascending: true });

    if (filters.activeOnly !== false) {
      query = query.eq('is_active', true);
    }

    if (filters.search) {
      const s = filters.search.trim();
      if (s) {
        query = query.or(`full_name.ilike.%${s}%,phone.ilike.%${s}%`);
      }
    }

    const { data, error } = await query;
    console.log('[getCustomers Direct Query]', { tenantId, count: data?.length || 0, error });

    if (error) {
      directError = error;
      console.warn('[getCustomers Direct Query Error]', error.message, error);
    } else if (data && data.length > 0) {
      customersList = data as Customer[];
    }
  } catch (err: any) {
    directError = err;
    console.warn('[getCustomers Direct Query Exception]', err?.message || err);
  }

  // 3. Fallback to `get_terminal_customers` RPC if direct query failed or returned 0 rows
  if (customersList.length === 0) {
    try {
      console.log('[getCustomers] Attempting RPC get_terminal_customers for tenantId:', tenantId);
      const { data: rpcData, error: rpcError } = await supabase.rpc('get_terminal_customers', {
        p_tenant_id: tenantId,
      });

      if (rpcError) {
        console.warn('[getCustomers] RPC get_terminal_customers returned error:', rpcError.message, rpcError);
      } else if (rpcData && rpcData.length > 0) {
        let list = rpcData as Customer[];
        if (filters.activeOnly !== false) {
          list = list.filter((c: any) => c.is_active !== false);
        }
        if (filters.search) {
          const s = filters.search.trim().toLowerCase();
          list = list.filter(
            (c: any) =>
              (c.full_name && c.full_name.toLowerCase().includes(s)) ||
              (c.phone && c.phone.includes(s))
          );
        }
        customersList = list;
      }
    } catch (rpcErr: any) {
      console.warn('[getCustomers] RPC get_terminal_customers error:', rpcErr?.message || rpcErr);
    }
  }

  return customersList.map((c: any) => ({
    ...c,
    outstanding_balance: Number(c.outstanding_balance || 0),
  }));
}

/**
 * Create a new customer in Supabase customers table without requiring category
 */
export async function createCustomer(input: CreateCustomerInput): Promise<Customer> {
  const insertPayload: any = {
    tenant_id: input.tenant_id,
    full_name: input.full_name,
    phone: input.phone || null,
    factory_unit: input.factory_unit || null,
    contract_daily_rate: input.contract_daily_rate ?? null,
    contract_shifts: input.contract_shifts || null,
    is_active: true,
  };

  let createdCustomerRaw: any = null;

  const { data, error } = await supabase
    .from('customers')
    .insert(insertPayload)
    .select()
    .single();

  if (error) {
    console.warn('Direct customer insert failed, attempting RPC create_terminal_customer fallback:', error.message);
    const { data: rpcData, error: rpcError } = await supabase.rpc('create_terminal_customer', {
      p_tenant_id: input.tenant_id,
      p_full_name: input.full_name,
      p_phone: input.phone || null,
      p_factory_unit: input.factory_unit || null,
      p_contract_daily_rate: input.contract_daily_rate ?? null,
    });

    if (rpcError) {
      console.error('Error calling create_terminal_customer RPC:', rpcError.message);
      throw rpcError;
    }

    createdCustomerRaw = rpcData;
  } else {
    createdCustomerRaw = data;
  }

  const walletId = await ensureCustomerWallet(input.tenant_id, createdCustomerRaw.id);

  return {
    ...createdCustomerRaw,
    outstanding_balance: Number(createdCustomerRaw.outstanding_balance || 0),
    wallet_id: walletId,
  };
}

export interface CustomerStatementItem {
  unique_id: string;
  event_date: string;
  event_type: 'attendance' | 'baki' | 'collection';
  description: string;
  amount: number;
  method?: string | null;
  notes?: string | null;
  business_day_id?: string | null;
}

/**
 * Get active open business day ID for a tenant
 */
export async function getActiveBusinessDayId(tenantId: string): Promise<string | null> {
  try {
    const { data, error } = await supabase
      .from('business_days')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('status', 'open')
      .order('opened_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      console.warn('[getActiveBusinessDayId] Error fetching open day:', error.message);
      return null;
    }
    return data?.id || null;
  } catch (err: any) {
    console.warn('[getActiveBusinessDayId] Exception:', err?.message || err);
    return null;
  }
}

export async function toggleContractAttendance(params: {
  tenantId: string;
  customerId: string;
  shiftName?: string;
  dailyRate?: number | null;
  deviceToken?: string | null;
  staffId?: string | null;
}): Promise<{ action_taken: string; new_balance: number }> {
  const { data, error } = await supabase.rpc('toggle_contract_attendance', {
    p_tenant_id: params.tenantId,
    p_customer_id: params.customerId,
    p_device_token: params.deviceToken || 'demo_device_token',
    p_staff_id: params.staffId || null,
    p_daily_rate: params.dailyRate || null,
  });

  if (error) {
    console.error('[toggleContractAttendance] RPC Error:', error.message);
    throw error;
  }

  const result = Array.isArray(data) ? data[0] : data;
  return {
    action_taken: result?.action_taken || 'toggled',
    new_balance: Number(result?.new_balance || 0),
  };
}

export interface AttendanceRecord {
  id: string;
  tenant_id: string;
  customer_id: string;
  business_day_id: string;
  business_date: string;
  attended_shifts: string[];
  rate_applied: number;
  created_at: string;
}

/**
 * Fetch attendance list for a specific customer
 */
export async function getCustomerAttendanceList(
  tenantId: string,
  customerId: string
): Promise<AttendanceRecord[]> {
  try {
    const { data, error } = await supabase
      .from('customer_daily_attendance')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('customer_id', customerId)
      .order('business_date', { ascending: false });

    if (error) {
      console.warn('[getCustomerAttendanceList] Error fetching attendance:', error.message);
      return [];
    }

    return (data || []).map((row: any) => ({
      ...row,
      rate_applied: Number(row.rate_applied || 0),
    }));
  } catch (err: any) {
    console.warn('[getCustomerAttendanceList] Exception:', err?.message || err);
    return [];
  }
}

export async function recordBakiTransaction(params: {
  tenantId: string;
  customerId: string;
  itemsDescription: string;
  amount: number;
  deviceToken?: string | null;
  staffId?: string | null;
}): Promise<number> {
  const { data, error } = await supabase.rpc('record_baki_transaction', {
    p_tenant_id: params.tenantId,
    p_customer_id: params.customerId,
    p_items_description: params.itemsDescription,
    p_amount: params.amount,
    p_device_token: params.deviceToken || 'demo_device_token',
    p_staff_id: params.staffId || null,
  });

  if (error) {
    console.error('[recordBakiTransaction] RPC Error:', error.message);
    throw error;
  }

  return Number(data || 0);
}

/**
 * Get customer statement (transactions for last N days)
 */
export async function getCustomerStatement(params: {
  tenantId: string;
  customerId: string;
  daysCount?: number;
  deviceToken?: string | null;
  staffId?: string | null;
}): Promise<CustomerStatementItem[]> {
  const days = params.daysCount || 30;
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);
  const cutoffStr = cutoffDate.toISOString().split('T')[0];

  // 1. Try RPC call first
  try {
    const payload: any = {
      p_tenant_id: params.tenantId,
      p_customer_id: params.customerId,
      p_days_count: days,
    };
    if (params.deviceToken && params.deviceToken !== 'demo_device_token') {
      payload.p_device_token = params.deviceToken;
    }
    if (params.staffId) {
      payload.p_staff_id = params.staffId;
    }

    const { data, error } = await supabase.rpc('get_customer_statement_kiosk', payload);

    if (!error && data) {
      return (data || []).map((item: any) => ({
        ...item,
        amount: Number(item.amount || 0),
      }));
    } else if (error) {
      console.warn('[getCustomerStatement] RPC returned error, attempting fallback query:', error.message);
    }
  } catch (err: any) {
    console.warn('[getCustomerStatement] RPC exception, attempting fallback query:', err?.message || err);
  }

  // 2. Direct table queries fallback (for standard authenticated user session)
  try {
    const [attRes, bakiRes, colRes] = await Promise.all([
      supabase
        .from('customer_daily_attendance')
        .select('*')
        .eq('tenant_id', params.tenantId)
        .eq('customer_id', params.customerId)
        .gte('business_date', cutoffStr),
      supabase
        .from('baki_transactions')
        .select('*')
        .eq('tenant_id', params.tenantId)
        .eq('customer_id', params.customerId)
        .gte('business_date', cutoffStr),
      supabase
        .from('customer_collections')
        .select('*')
        .eq('tenant_id', params.tenantId)
        .eq('customer_id', params.customerId)
        .gte('collected_at', cutoffDate.toISOString()),
    ]);

    const items: CustomerStatementItem[] = [];

    if (attRes.data) {
      attRes.data.forEach((a: any) => {
        items.push({
          unique_id: `att-${a.id}`,
          event_date: a.business_date,
          event_type: 'attendance',
          description: 'Daily contract charge',
          amount: Number(a.rate_applied || 0),
          business_day_id: a.business_day_id,
        });
      });
    }

    if (bakiRes.data) {
      bakiRes.data.forEach((b: any) => {
        items.push({
          unique_id: `baki-${b.id}`,
          event_date: b.business_date,
          event_type: 'baki',
          description: b.items_description,
          amount: Number(b.amount || 0),
          business_day_id: b.business_day_id,
        });
      });
    }

    if (colRes.data) {
      colRes.data.forEach((c: any) => {
        items.push({
          unique_id: `col-${c.id}`,
          event_date: c.collected_at,
          event_type: 'collection',
          description: 'Collection',
          amount: Number(c.amount || 0),
          method: c.payment_method,
          notes: c.notes,
          business_day_id: c.business_day_id,
        });
      });
    }

    items.sort((a, b) => new Date(b.event_date).getTime() - new Date(a.event_date).getTime());
    return items;
  } catch (fallbackErr: any) {
    console.error('[getCustomerStatement] Fallback query failed:', fallbackErr?.message || fallbackErr);
    return [];
  }
}
export async function updateCustomerDailyRate(customerId: string, dailyRate: number): Promise<void> {
  const { error } = await supabase
    .from('customers')
    .update({ contract_daily_rate: dailyRate })
    .eq('id', customerId);

  if (error) {
    console.error('Failed to update customer daily rate:', error.message);
    throw error;
  }
}
