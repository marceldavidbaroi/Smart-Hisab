import { supabase } from '../boot/supabase';
import type { Database } from '../types/supabase';

// Export database model types
export type Tenant = Database['public']['Tables']['tenants']['Row'];
export type TenantSettings = Database['public']['Tables']['tenant_settings']['Row'];
export type TenantRole = Database['public']['Tables']['tenant_roles']['Row'];
export type TenantMember = Database['public']['Tables']['tenant_members']['Row'];
export type TenantInvitation = Database['public']['Tables']['tenant_invitations']['Row'];
export type TenantBilling = Database['public']['Tables']['tenant_billing']['Row'];
export type UserProfile = Database['public']['Tables']['user_profiles']['Row'];

// 1. Authentication Services
export async function signUpWithEmail(email: string, password: string, fullName: string) {
  return await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
      },
    },
  });
}

export async function signInWithEmail(email: string, password: string) {
  return await supabase.auth.signInWithPassword({
    email,
    password,
  });
}

export async function signInWithGoogle(redirectTo?: string) {
  return await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: redirectTo || window.location.origin,
    },
  });
}

export async function signOut() {
  return await supabase.auth.signOut();
}

// 2. Superadmin API (Platform Level)
export async function adminCreateTenant(params: {
  name: string;
  slug: string;
  ownerEmail: string;
  ownerId?: string;
  parentId?: string;
  enabledFeatures?: Record<string, boolean>;
  subscriptionTier?: string;
}) {
  const { data, error } = await supabase.rpc('admin_create_tenant', {
    p_name: params.name,
    p_slug: params.slug,
    p_owner_email: params.ownerEmail,
    p_owner_id: params.ownerId,
    p_parent_id: params.parentId,
    p_enabled_features: params.enabledFeatures,
    p_subscription_tier: params.subscriptionTier,
  });
  if (error) throw error;
  return data;
}

export async function adminAssignTenantOwner(tenantId: string, userId: string) {
  const { error } = await supabase.rpc('admin_assign_tenant_owner', {
    p_tenant_id: tenantId,
    p_user_id: userId,
  });
  if (error) throw error;
}

export async function adminToggleTenantFeatures(
  tenantId: string,
  features: Record<string, boolean>,
) {
  const { error } = await supabase.rpc('admin_toggle_tenant_features', {
    p_tenant_id: tenantId,
    p_features: features,
  });
  if (error) throw error;
}

export async function adminUpdateBilling(tenantId: string, tier: string, status: string) {
  const { error } = await supabase.rpc('admin_update_billing', {
    p_tenant_id: tenantId,
    p_tier: tier,
    p_status: status,
  });
  if (error) throw error;
}

// 3. Tenant & Member API (Tenant Level)
export async function getUserTenants(userId?: string) {
  let query = supabase.from('tenant_members').select(`
      id,
      status,
      joined_at,
      tenant_id,
      user_id,
      tenants (
        id,
        name,
        slug,
        parent_id,
        status
      ),
      tenant_roles (
        id,
        name,
        permissions
      )
    `);

  if (userId) {
    query = query.eq('user_id', userId);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data;
}

export async function getTenantSettings(tenantId: string) {
  const { data, error } = await supabase
    .from('tenant_settings')
    .select('*')
    .eq('tenant_id', tenantId)
    .single();
  if (error) throw error;
  return data;
}

export async function updateTenantSettings(
  tenantId: string,
  settings: { logo_url?: string | null; theme_color?: string | null; preferences?: unknown },
) {
  const { data, error } = await supabase
    .from('tenant_settings')
    .update(settings)
    .eq('tenant_id', tenantId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function getTenantMembers(tenantId: string) {
  const { data, error } = await supabase
    .from('tenant_members')
    .select(
      `
      id,
      status,
      joined_at,
      user_id,
      tenant_roles (
        id,
        name,
        description
      )
    `,
    )
    .eq('tenant_id', tenantId);
  if (error) throw error;

  if (data && data.length > 0) {
    const userIds = data.map((m) => m.user_id);
    const { data: profiles, error: profileError } = await supabase
      .from('user_profiles')
      .select('id, full_name, avatar_url')
      .in('id', userIds);

    if (profileError) throw profileError;

    return data.map((m) => ({
      ...m,
      user_profile: profiles?.find((p) => p.id === m.user_id) || null,
    }));
  }

  return [];
}

export async function removeMember(tenantId: string, userId: string) {
  const { error } = await supabase
    .from('tenant_members')
    .delete()
    .eq('tenant_id', tenantId)
    .eq('user_id', userId);
  if (error) throw error;
}

export async function inviteUser(tenantId: string, email: string, roleId: string) {
  const { data, error } = await supabase.rpc('invite_user', {
    p_tenant_id: tenantId,
    p_email: email,
    p_role_id: roleId,
  });
  if (error) throw error;
  return data;
}

export async function acceptInvitation(token: string) {
  const { data, error } = await supabase.rpc('accept_invitation', {
    p_token: token,
  });
  if (error) throw error;
  return data;
}

export async function getTenantInvitations(tenantId: string) {
  const { data, error } = await supabase
    .from('tenant_invitations')
    .select(
      `
      id,
      email,
      status,
      expires_at,
      created_at,
      tenant_roles (
        id,
        name,
        description
      )
    `,
    )
    .eq('tenant_id', tenantId)
    .eq('status', 'pending');
  if (error) throw error;
  return data;
}

export async function cancelInvitation(tenantId: string, invitationId: string) {
  const { error } = await supabase
    .from('tenant_invitations')
    .delete()
    .eq('tenant_id', tenantId)
    .eq('id', invitationId);
  if (error) throw error;
}

export async function getTenantRoles(tenantId: string) {
  const { data, error } = await supabase
    .from('tenant_roles')
    .select('*')
    .or(`tenant_id.eq.${tenantId},tenant_id.is.null`);
  if (error) throw error;
  return data;
}

export async function createTenantRole(
  tenantId: string,
  name: string,
  description: string,
  permissions: unknown,
) {
  const { data, error } = await supabase
    .from('tenant_roles')
    .insert({
      tenant_id: tenantId,
      name,
      description,
      permissions,
      is_system_role: false,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function assignMemberRole(tenantId: string, memberId: string, roleId: string) {
  const { data, error } = await supabase
    .from('tenant_members')
    .update({ role_id: roleId })
    .eq('tenant_id', tenantId)
    .eq('id', memberId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

// 4. Self-Service Tenant API
export async function createTenant(name: string, slug: string) {
  const { data, error } = await supabase.rpc('create_tenant', {
    p_name: name,
    p_slug: slug,
  });
  if (error) throw error;
  return data;
}

export async function deleteTenant(tenantId: string) {
  const { error } = await supabase.from('tenants').delete().eq('id', tenantId);
  if (error) throw error;
}
