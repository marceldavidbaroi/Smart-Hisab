-- Invite by email: add pending seat (or immediate member if user exists).
-- On login, claim_pending_invitations maps pending emails → tenant_members.

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
  v_email text;
  v_token text;
  v_existing_user_id uuid;
begin
  -- Owner, Admin, or platform superadmin
  if not (
    public.is_tenant_owner(p_tenant_id)
    or exists (
      select 1
      from public.tenant_members m
      join public.tenant_roles r on m.role_id = r.id
      where m.tenant_id = p_tenant_id
        and m.user_id = auth.uid()
        and m.status = 'active'
        and r.name = 'Admin'
    )
  ) then
    raise exception 'Only tenant owners, admins, or platform superadmins can invite users.';
  end if;

  v_email := lower(trim(p_email));
  if v_email is null or v_email = '' then
    raise exception 'A valid email address is required.';
  end if;

  if not exists (
    select 1 from public.tenant_roles
    where id = p_role_id and (tenant_id = p_tenant_id or tenant_id is null)
  ) then
    raise exception 'Invalid role selected for this tenant.';
  end if;

  if exists (
    select 1
    from public.tenant_members m
    join auth.users u on m.user_id = u.id
    where m.tenant_id = p_tenant_id
      and lower(u.email) = v_email
      and m.status = 'active'
  ) then
    raise exception 'User is already an active member of this tenant.';
  end if;

  select id into v_existing_user_id
  from auth.users
  where lower(email) = v_email
  limit 1;

  -- Clear any prior pending invite for this email + tenant
  delete from public.tenant_invitations
  where tenant_id = p_tenant_id
    and lower(email) = v_email
    and status = 'pending';

  if v_existing_user_id is not null then
    insert into public.tenant_members (tenant_id, user_id, role_id, status)
    values (p_tenant_id, v_existing_user_id, p_role_id, 'active')
    on conflict (tenant_id, user_id) do update
    set role_id = excluded.role_id, status = 'active';

    return 'member_added';
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');

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
    v_email,
    p_role_id,
    v_token,
    auth.uid(),
    now() + interval '1 year',
    'pending'
  );

  return 'pending';
end;
$$;

create or replace function public.claim_pending_invitations()
returns integer
security definer
set search_path = public
language plpgsql
as $$
declare
  v_user_id uuid;
  v_email text;
  v_count integer := 0;
  v_inv record;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return 0;
  end if;

  select lower(email) into v_email from auth.users where id = v_user_id;
  if v_email is null or v_email = '' then
    return 0;
  end if;

  for v_inv in
    select id, tenant_id, role_id
    from public.tenant_invitations
    where status = 'pending'
      and lower(email) = v_email
  loop
    insert into public.tenant_members (tenant_id, user_id, role_id, status)
    values (v_inv.tenant_id, v_user_id, v_inv.role_id, 'active')
    on conflict (tenant_id, user_id) do update
    set role_id = excluded.role_id, status = 'active';

    update public.tenant_invitations
    set status = 'accepted'
    where id = v_inv.id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

grant execute on function public.invite_user(uuid, text, uuid) to authenticated;
grant execute on function public.claim_pending_invitations() to authenticated;

-- Allow Admin (not only Owner) to manage invitation rows from the client
drop policy if exists "Owners and superadmins can manage invitations" on public.tenant_invitations;

create policy "Owners admins and superadmins can manage invitations"
  on public.tenant_invitations
  for all
  using (
    public.is_tenant_owner(tenant_id)
    or exists (
      select 1
      from public.tenant_members m
      join public.tenant_roles r on m.role_id = r.id
      where m.tenant_id = tenant_invitations.tenant_id
        and m.user_id = auth.uid()
        and m.status = 'active'
        and r.name = 'Admin'
    )
  )
  with check (
    public.is_tenant_owner(tenant_id)
    or exists (
      select 1
      from public.tenant_members m
      join public.tenant_roles r on m.role_id = r.id
      where m.tenant_id = tenant_invitations.tenant_id
        and m.user_id = auth.uid()
        and m.status = 'active'
        and r.name = 'Admin'
    )
  );
