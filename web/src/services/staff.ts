import { supabase } from '../boot/supabase';
import type { Database } from '../types/supabase';

export type StaffMember = Database['public']['Tables']['staff_members']['Row'] & {
  role: string;
};
export type DevicePairing = Database['public']['Tables']['device_pairings']['Row'];

type DbStaffMemberWithRole = Database['public']['Tables']['staff_members']['Row'] & {
  staff_roles: { name: string } | null;
};

/**
 * Fetch all staff members for a specific tenant
 */
export async function getStaffMembers(tenantId: string): Promise<StaffMember[]> {
  const { data, error } = await supabase
    .from('staff_members')
    .select('*, staff_roles(name)')
    .eq('tenant_id', tenantId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching staff members:', error.message);
    throw error;
  }

  const rawList = (data || []) as unknown as DbStaffMemberWithRole[];
  return rawList.map((item) => ({
    ...item,
    role: item.staff_roles?.name || 'Staff',
  }));
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
  // Resolve role string to staff_role_id using database function
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

  const typedData = data as unknown as DbStaffMemberWithRole;

  return {
    ...typedData,
    role: typedData.staff_roles?.name || staff.role,
  };
}

/**
 * Update an existing staff member's profile or configuration flags
 */
export async function updateStaffMember(
  staffId: string,
  updates: Partial<Omit<StaffMember, 'id' | 'tenant_id' | 'created_at' | 'updated_at'>>,
): Promise<StaffMember> {
  let staffRoleId: string | undefined;

  if (updates.role) {
    // Retrieve staff tenant_id to resolve role
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

  const dbUpdates: Database['public']['Tables']['staff_members']['Update'] = {};

  if (updates.full_name !== undefined) dbUpdates.full_name = updates.full_name;
  if (updates.phone !== undefined) dbUpdates.phone = updates.phone;
  if (updates.allow_terminal_login !== undefined)
    dbUpdates.allow_terminal_login = updates.allow_terminal_login;
  if (updates.is_active !== undefined) dbUpdates.is_active = updates.is_active;
  if (updates.hashed_pin !== undefined) dbUpdates.hashed_pin = updates.hashed_pin;
  if (updates.temp_pin !== undefined) dbUpdates.temp_pin = updates.temp_pin;

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

  const typedData = data as unknown as DbStaffMemberWithRole;

  return {
    ...typedData,
    role: typedData.staff_roles?.name || updates.role || 'Staff',
  };
}

/**
 * Reset a staff member's PIN code.
 * Calls the `reset_staff_pin` Postgres function, which generates a random 4-digit temporary PIN.
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
 * Generate a 6-digit device pairing code for a specific device name.
 * Calls the `generate_pairing_code` Postgres function.
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
