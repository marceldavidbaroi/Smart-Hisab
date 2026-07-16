-- Create admin_create_tenant stored procedure
create or replace function public.admin_create_tenant(
  p_name text,
  p_slug text,
  p_owner_email text,
  p_owner_id uuid default null,
  p_parent_id uuid default null,
  p_enabled_features jsonb default '{}'::jsonb,
  p_subscription_tier text default 'free'
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_owner_id uuid := p_owner_id;
begin
  -- 1. Check if caller is superadmin
  if not public.is_superadmin() then
    raise exception 'Only platform superadmins can provision tenants.';
  end if;

  -- 2. Validate input parameters
  if p_name is null or trim(p_name) = '' then
    raise exception 'Tenant name is required.';
  end if;
  if p_slug is null or trim(p_slug) = '' then
    raise exception 'Tenant slug is required.';
  end if;
  if (v_owner_id is null) and (p_owner_email is null or trim(p_owner_email) = '') then
    raise exception 'Either tenant owner ID or email is required.';
  end if;

  -- 3. Insert tenant record
  insert into public.tenants (name, slug, parent_id)
  values (p_name, p_slug, p_parent_id)
  returning id into v_tenant_id;

  -- 4. Insert default settings
  insert into public.tenant_settings (tenant_id, enabled_features)
  values (v_tenant_id, p_enabled_features);

  -- 5. Insert billing information
  insert into public.tenant_billing (tenant_id, subscription_tier)
  values (v_tenant_id, p_subscription_tier);

  -- 6. Resolve owner ID if not explicitly provided
  if v_owner_id is null and p_owner_email is not null then
    select id into v_owner_id from auth.users where email = p_owner_email;
  end if;

  -- 7. Associate owner with the tenant
  if v_owner_id is not null then
    -- User exists, insert directly into tenant_members with the Owner role
    insert into public.tenant_members (tenant_id, user_id, role_id, status)
    values (v_tenant_id, v_owner_id, '00000000-0000-0000-0000-000000000001', 'active')
    on conflict (tenant_id, user_id) do update
    set role_id = excluded.role_id, status = 'active';
  else
    -- User does not exist, create a pending invitation
    insert into public.tenant_invitations (
      tenant_id,
      email,
      role_id,
      token,
      invited_by,
      expires_at,
      status
    ) values (
      v_tenant_id,
      p_owner_email,
      '00000000-0000-0000-0000-000000000001', -- Owner role
      encode(gen_random_bytes(32), 'hex'),
      auth.uid(),
      now() + interval '7 days',
      'pending'
    );
  end if;

  return v_tenant_id;
end;
$$;

-- Create admin_assign_tenant_owner stored procedure
create or replace function public.admin_assign_tenant_owner(
  p_tenant_id uuid,
  p_user_id uuid
)
returns void
security definer
set search_path = public
language plpgsql
as $$
begin
  -- Check if caller is superadmin
  if not public.is_superadmin() then
    raise exception 'Only platform superadmins can assign tenant owners.';
  end if;

  -- Insert user as Tenant Owner
  insert into public.tenant_members (tenant_id, user_id, role_id, status)
  values (p_tenant_id, p_user_id, '00000000-0000-0000-0000-000000000001', 'active')
  on conflict (tenant_id, user_id) do update
  set role_id = '00000000-0000-0000-0000-000000000001', status = 'active';
end;
$$;

-- Create invite_user function
create or replace function public.invite_user(
  p_tenant_id uuid,
  p_email text,
  p_role_id uuid
)
returns text
security definer
set search_path = public
language plpgsql
as $$
declare
  v_token text;
begin
  -- 1. Access check: Caller must be a tenant owner or platform superadmin
  if not public.is_tenant_owner(p_tenant_id) then
    raise exception 'Only tenant owners or platform superadmins can invite users.';
  end if;

  -- 2. Validate email is not empty
  if p_email is null or trim(p_email) = '' then
    raise exception 'A valid email address is required.';
  end if;

  -- 3. Validate role exists and belongs to the tenant scope (or is a system default)
  if not exists (
    select 1 from public.tenant_roles
    where id = p_role_id and (tenant_id = p_tenant_id or tenant_id is null)
  ) then
    raise exception 'Invalid role selected for this tenant.';
  end if;

  -- 4. Check if user is already an active member of this tenant
  if exists (
    select 1 from public.tenant_members m
    join auth.users u on m.user_id = u.id
    where m.tenant_id = p_tenant_id and u.email = p_email and m.status = 'active'
  ) then
    raise exception 'User is already an active member of this tenant.';
  end if;

  -- 5. Generate secure random token
  v_token := encode(gen_random_bytes(32), 'hex');

  -- 6. Remove any existing pending invitations for this email + tenant
  delete from public.tenant_invitations
  where tenant_id = p_tenant_id and email = p_email and status = 'pending';

  -- 7. Insert new invitation record
  insert into public.tenant_invitations (
    tenant_id,
    email,
    role_id,
    token,
    invited_by,
    expires_at,
    status
  ) values (
    p_tenant_id,
    p_email,
    p_role_id,
    v_token,
    auth.uid(),
    now() + interval '7 days',
    'pending'
  );

  return v_token;
end;
$$;

-- Create accept_invitation function
create or replace function public.accept_invitation(
  p_token text
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_invitation record;
  v_user_email text;
  v_user_id uuid;
  v_member_id uuid;
begin
  -- 1. Ensure user is logged in
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'You must be logged in to accept an invitation.';
  end if;

  -- 2. Fetch logged-in user email
  select email into v_user_email from auth.users where id = v_user_id;

  -- 3. Fetch invitation record
  select * into v_invitation
  from public.tenant_invitations
  where token = p_token and status = 'pending' and expires_at > now();

  if not found then
    raise exception 'Invitation code is invalid or has expired.';
  end if;

  -- 4. Verify email match
  if lower(v_user_email) != lower(v_invitation.email) then
    raise exception 'This invitation was sent to %, but you are logged in as %.', v_invitation.email, v_user_email;
  end if;

  -- 5. Insert or update member record
  insert into public.tenant_members (tenant_id, user_id, role_id, status)
  values (v_invitation.tenant_id, v_user_id, v_invitation.role_id, 'active')
  on conflict (tenant_id, user_id) do update
  set role_id = excluded.role_id, status = 'active'
  returning id into v_member_id;

  -- 6. Mark invitation as accepted
  update public.tenant_invitations
  set status = 'accepted'
  where id = v_invitation.id;

  return v_member_id;
end;
$$;

-- Create admin_toggle_tenant_features function
create or replace function public.admin_toggle_tenant_features(
  p_tenant_id uuid,
  p_features jsonb
)
returns void
security definer
set search_path = public
language plpgsql
as $$
begin
  if not public.is_superadmin() then
    raise exception 'Only platform superadmins can change tenant features.';
  end if;

  insert into public.tenant_settings (tenant_id, enabled_features)
  values (p_tenant_id, p_features)
  on conflict (tenant_id) do update
  set enabled_features = public.tenant_settings.enabled_features || p_features;
end;
$$;

-- Create admin_update_billing function
create or replace function public.admin_update_billing(
  p_tenant_id uuid,
  p_tier text,
  p_status text
)
returns void
security definer
set search_path = public
language plpgsql
as $$
begin
  if not public.is_superadmin() then
    raise exception 'Only platform superadmins can change billing settings.';
  end if;

  insert into public.tenant_billing (tenant_id, subscription_tier, status)
  values (p_tenant_id, p_tier, p_status)
  on conflict (tenant_id) do update
  set subscription_tier = p_tier, status = p_status, updated_at = now();
end;
$$;

-- Create self-service create_tenant function
create or replace function public.create_tenant(
  p_name text,
  p_slug text
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'You must be logged in to create a workspace.';
  end if;

  -- 1. Create tenant
  insert into public.tenants (name, slug)
  values (p_name, p_slug)
  returning id into v_tenant_id;

  -- 2. Create tenant settings with default active modules
  insert into public.tenant_settings (tenant_id, enabled_features)
  values (v_tenant_id, '{"shift-sessions": true, "financial-ledger": true, "meal-management": true, "procurement": true, "staff-payroll": true}'::jsonb);

  -- 3. Create tenant billing record (default free tier)
  insert into public.tenant_billing (tenant_id, subscription_tier, status)
  values (v_tenant_id, 'free', 'active');

  -- 4. Create owner member mapping
  insert into public.tenant_members (tenant_id, user_id, role_id, status)
  values (v_tenant_id, v_user_id, '00000000-0000-0000-0000-000000000001', 'active');

  return v_tenant_id;
end;
$$;
