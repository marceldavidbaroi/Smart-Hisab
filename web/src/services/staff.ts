import { supabase } from '../boot/supabase';
import type { Database } from '../types/supabase';

export type StaffMember = Database['public']['Tables']['staff_members']['Row'];
export type DevicePairing = Database['public']['Tables']['device_pairings']['Row'];

/**
 * Fetch all staff members for a specific tenant
 */
export async function getStaffMembers(tenantId: string): Promise<StaffMember[]> {
  const { data, error } = await supabase
    .from('staff_members')
    .select('*')
    .eq('tenant_id', tenantId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching staff members:', error.message);
    throw error;
  }
  return data || [];
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
  const { data, error } = await supabase
    .from('staff_members')
    .insert(staff)
    .select()
    .single();

  if (error) {
    console.error('Error creating staff member:', error.message);
    throw error;
  }
  return data;
}

/**
 * Update an existing staff member's profile or configuration flags
 */
export async function updateStaffMember(
  staffId: string,
  updates: Partial<Omit<StaffMember, 'id' | 'tenant_id' | 'created_at' | 'updated_at'>>
): Promise<StaffMember> {
  const { data, error } = await supabase
    .from('staff_members')
    .update(updates)
    .eq('id', staffId)
    .select()
    .single();

  if (error) {
    console.error('Error updating staff member:', error.message);
    throw error;
  }
  return data;
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
