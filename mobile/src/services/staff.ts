import { supabase } from '../lib/supabase';

export interface StaffMember {
  id: string;
  tenant_id: string;
  full_name: string;
  phone: string | null;
  staff_role_id: string | null;
  role: string;
  allow_terminal_login: boolean;
  is_active: boolean;
  hashed_pin?: string | null;
  temp_pin?: string | null;
  wallet_id?: string | null;
  current_balance?: number;
  created_at: string;
  updated_at: string;
}

export interface DevicePairing {
  id: string;
  tenant_id: string;
  device_sl?: number;
  device_name: string;
  pairing_code: string;
  unpair_code?: string;
  status: string;
  paired_at: string | null;
  created_at: string;
  is_paired_device?: boolean;
}

export interface StaffRole {
  id: string;
  tenant_id: string;
  name: string;
  description: string | null;
  is_system_role: boolean;
  created_at: string;
}

/**
 * Fetch or create wallet for a given staff member ID
 */
export async function ensureStaffWallet(tenantId: string, staffId: string): Promise<{ wallet_id: string | null; current_balance: number }> {
  try {
    const { data: walletData } = await supabase
      .from('staff_wallets')
      .select('id, current_balance')
      .eq('staff_id', staffId)
      .maybeSingle();

    if (walletData?.id) {
      return {
        wallet_id: walletData.id,
        current_balance: Number(walletData.current_balance || 0),
      };
    }

    const { data: newWallet, error: walletError } = await supabase
      .from('staff_wallets')
      .insert({ tenant_id: tenantId, staff_id: staffId })
      .select('id, current_balance')
      .single();

    if (walletError) {
      console.warn('Failed to insert staff wallet:', walletError.message);
      return { wallet_id: null, current_balance: 0 };
    }

    return {
      wallet_id: newWallet?.id || null,
      current_balance: Number(newWallet?.current_balance || 0),
    };
  } catch (err: any) {
    console.warn('ensureStaffWallet exception:', err?.message || err);
    return { wallet_id: null, current_balance: 0 };
  }
}

/**
 * Fetch staff members for a given tenant
 */
export async function getStaffMembers(tenantId: string): Promise<StaffMember[]> {
  const { data, error } = await supabase
    .from('staff_members')
    .select('*, staff_roles(name), staff_wallets(id, current_balance)')
    .eq('tenant_id', tenantId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching staff members:', error.message);
    throw error;
  }

  return (data || []).map((item: any) => {
    const walletObj = Array.isArray(item.staff_wallets) ? item.staff_wallets[0] : item.staff_wallets;
    return {
      ...item,
      role: item.staff_roles?.name || 'Staff',
      wallet_id: walletObj?.id || null,
      current_balance: Number(walletObj?.current_balance || 0),
    };
  });
}

/**
 * Create a new staff member
 */
export async function createStaffMember(staff: {
  tenant_id: string;
  full_name: string;
  role: string;
  phone: string;
  allow_terminal_login: boolean;
}): Promise<StaffMember> {
  const { data: roleId, error: roleError } = await supabase.rpc('get_or_create_staff_role', {
    p_tenant_id: staff.tenant_id,
    p_role_name: staff.role,
  });

  if (roleError) {
    console.error('Error resolving staff role:', roleError.message);
    throw roleError;
  }

  const { data, error } = await supabase
    .from('staff_members')
    .insert({
      tenant_id: staff.tenant_id,
      full_name: staff.full_name,
      staff_role_id: roleId,
      phone: staff.phone,
      allow_terminal_login: staff.allow_terminal_login,
    })
    .select('*, staff_roles(name)')
    .single();

  if (error) {
    console.error('Error creating staff member:', error.message);
    throw error;
  }

  const item = data as any;
  const walletInfo = await ensureStaffWallet(staff.tenant_id, item.id);

  return {
    ...item,
    role: item.staff_roles?.name || staff.role,
    wallet_id: walletInfo.wallet_id,
    current_balance: walletInfo.current_balance,
  };
}

/**
 * Update an existing staff member
 */
export async function updateStaffMember(
  staffId: string,
  updates: {
    full_name?: string;
    phone?: string;
    role?: string;
    allow_terminal_login?: boolean;
    is_active?: boolean;
  }
): Promise<StaffMember> {
  let staffRoleId: string | undefined;

  if (updates.role) {
    const { data: staffData, error: fetchError } = await supabase
      .from('staff_members')
      .select('tenant_id')
      .eq('id', staffId)
      .single();

    if (fetchError) {
      console.error('Error fetching staff member tenant:', fetchError.message);
      throw fetchError;
    }

    const { data: roleId, error: roleError } = await supabase.rpc('get_or_create_staff_role', {
      p_tenant_id: staffData.tenant_id,
      p_role_name: updates.role,
    });

    if (roleError) {
      console.error('Error resolving staff role:', roleError.message);
      throw roleError;
    }

    staffRoleId = roleId;
  }

  const dbUpdates: any = {};
  if (updates.full_name !== undefined) dbUpdates.full_name = updates.full_name;
  if (updates.phone !== undefined) dbUpdates.phone = updates.phone;
  if (updates.allow_terminal_login !== undefined)
    dbUpdates.allow_terminal_login = updates.allow_terminal_login;
  if (updates.is_active !== undefined) dbUpdates.is_active = updates.is_active;

  if (staffRoleId !== undefined) {
    dbUpdates.staff_role_id = staffRoleId;
  }

  const { data, error } = await supabase
    .from('staff_members')
    .update(dbUpdates)
    .eq('id', staffId)
    .select('*, staff_roles(name)')
    .single();

  if (error) {
    console.error('Error updating staff member:', error.message);
    throw error;
  }

  const item = data as any;
  return {
    ...item,
    role: item.staff_roles?.name || updates.role || 'Staff',
  };
}

/**
 * Reset a staff member's terminal PIN (generates 4-digit temp PIN)
 */
export async function resetStaffPin(staffId: string): Promise<string> {
  const { data, error } = await supabase.rpc('reset_staff_pin', {
    p_staff_id: staffId,
  });

  if (error) {
    console.error('Error calling reset_staff_pin:', error.message);
    throw error;
  }
  return data as string;
}

/**
 * Fetch staff roles for a tenant
 */
export async function getStaffRoles(tenantId: string): Promise<StaffRole[]> {
  const { data, error } = await supabase
    .from('staff_roles')
    .select('*')
    .eq('tenant_id', tenantId)
    .order('name', { ascending: true });

  if (error) {
    console.error('Error fetching staff roles:', error.message);
    throw error;
  }
  return data || [];
}

export interface KioskStaff {
  id: string;
  fullName: string;
  role: string;
  permissions?: Record<string, unknown>;
}

/**
 * Fetch staff list accessible on a paired POS terminal device
 */
export async function fetchPairedDeviceStaff(deviceToken: string, tenantId: string): Promise<KioskStaff[]> {
  const { data, error } = await supabase.rpc('get_paired_device_staff', {
    p_device_token: deviceToken,
    p_tenant_id: tenantId,
  });

  if (error) {
    console.error('Error fetching paired device staff:', error.message);
    throw error;
  }

  return ((data as { id: string; full_name: string; role: string }[]) || []).map((item) => ({
    id: item.id,
    fullName: item.full_name,
    role: item.role,
  }));
}

/**
 * Verify a staff member's PIN on a paired terminal device
 */
export async function verifyStaffPin(
  deviceToken: string,
  tenantId: string,
  staffId: string,
  pin: string
): Promise<{
  success: boolean;
  setupRequired?: boolean;
  staff?: KioskStaff;
  message?: string;
}> {
  const { data, error } = await supabase.rpc('verify_staff_pin', {
    p_device_token: deviceToken,
    p_tenant_id: tenantId,
    p_pin: pin,
  });

  if (error) {
    console.error('Error verifying staff PIN:', error.message);
    return { success: false, message: error.message };
  }

  const res = data as {
    success: boolean;
    setup_required?: boolean;
    staff_id?: string;
    full_name?: string;
    role?: string;
    permissions?: Record<string, unknown>;
    message?: string;
  };

  if (!res.success) {
    return { success: false, message: res.message || 'Verification failed' };
  }

  if (res.staff_id !== staffId) {
    return { success: false, message: 'PIN does not match the selected staff member.' };
  }

  const staff: KioskStaff = {
    id: res.staff_id,
    fullName: res.full_name || 'Staff',
    role: res.role || 'Cashier',
    permissions: res.permissions,
  };

  return {
    success: true,
    setupRequired: !!res.setup_required,
    staff,
  };
}

/**
 * Set or update a staff member's private PIN after temp PIN entry
 */
export async function setStaffPin(
  deviceToken: string,
  tenantId: string,
  staffId: string,
  tempPin: string,
  newPin: string
): Promise<boolean> {
  const { data, error } = await supabase.rpc('set_staff_pin', {
    p_device_token: deviceToken,
    p_tenant_id: tenantId,
    p_staff_id: staffId,
    p_temp_pin: tempPin,
    p_new_pin: newPin,
  });

  if (error) {
    console.error('Error setting staff PIN:', error.message);
    throw error;
  }

  return !!data;
}

/**
 * Fetch device pairings and active paired hardware devices for a tenant from database
 */
export async function getDevicePairings(tenantId: string): Promise<DevicePairing[]> {
  try {
    // 1. Fetch pending pairing codes (unexpired)
    const { data: pendingData, error: pendingErr } = await supabase
      .from('device_pairings')
      .select('*')
      .eq('tenant_id', tenantId)
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (pendingErr) console.warn('Error fetching pending device pairings:', pendingErr.message);

    // 2. Fetch active paired devices
    const { data: pairedData, error: pairedErr } = await supabase
      .from('paired_devices')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('paired_at', { ascending: false });

    if (pairedErr) console.warn('Error fetching paired devices:', pairedErr.message);

    const pendingList: DevicePairing[] = (pendingData || []).map((p: any) => ({
      id: p.id,
      tenant_id: p.tenant_id,
      device_name: p.device_name,
      pairing_code: p.pairing_code,
      status: 'pending',
      paired_at: null,
      created_at: p.created_at || new Date().toISOString(),
      is_paired_device: false,
    }));

    const pairedList: DevicePairing[] = (pairedData || []).map((p: any) => {
      return {
        id: p.id,
        tenant_id: p.tenant_id,
        device_sl: p.device_sl || 1,
        device_name: p.device_name,
        pairing_code: p.pairing_code || p.unpair_code || '123456',
        unpair_code: p.unpair_code,
        status: p.is_active ? 'active' : 'inactive',
        paired_at: p.paired_at,
        created_at: p.paired_at || new Date().toISOString(),
        is_paired_device: true,
      };
    });

    return [...pendingList, ...pairedList];
  } catch (err: any) {
    console.error('Error fetching device pairings:', err);
    return [];
  }
}

/**
 * Delete or disconnect a device pairing from database
 */
export async function deleteDevicePairing(id: string, isPairedDevice: boolean = false): Promise<void> {
  const table = isPairedDevice ? 'paired_devices' : 'device_pairings';
  const { error } = await supabase
    .from(table)
    .delete()
    .eq('id', id);

  if (error) {
    console.error(`Error deleting from ${table}:`, error.message);
    throw error;
  }
}

/**
 * Generate a 6-digit device pairing code for POS terminals
 */
export async function generatePairingCode(tenantId: string, deviceName: string): Promise<string> {
  const { data, error } = await supabase.rpc('generate_pairing_code', {
    p_tenant_id: tenantId,
    p_device_name: deviceName,
  });

  if (error) {
    console.error('Error calling generate_pairing_code:', error.message);
    throw error;
  }
  return data as string;
}

/**
 * Disconnect a paired device and issue a fresh 6-digit pairing PIN code for re-pairing
 */
export async function refreshDeviceToken(tenantId: string, deviceId: string): Promise<string> {
  const { data, error } = await supabase.rpc('prepare_device_repair', {
    p_tenant_id: tenantId,
    p_device_id: deviceId,
  });

  if (error) {
    console.error('Error calling prepare_device_repair:', error.message);
    throw error;
  }
  return data as string;
}

/**
 * Unpair device using a 6-digit unpair code
 */
export async function unpairDeviceWithCode(deviceToken: string, unpairCode: string): Promise<{ success: boolean; message?: string }> {
  try {
    const { data, error } = await supabase.rpc('unpair_device_with_code', {
      p_device_token: deviceToken,
      p_unpair_code: unpairCode,
    });
    if (error) {
      return { success: false, message: error.message };
    }
    return { success: true };
  } catch (err: any) {
    return { success: false, message: err?.message || 'Failed to unpair device' };
  }
}
