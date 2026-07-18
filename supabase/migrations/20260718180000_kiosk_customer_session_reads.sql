-- Kiosk-safe reads + anon grants for meal/customer floor ops
-- Root cause: workspace RLS (has_module_permission) blocks paired-device anon clients.

-- 1. list_customers (kiosk)
create or replace function public.list_customers(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_active_only boolean default true
)
returns setof public.customers
security definer
set search_path = public
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.paired_devices
    where device_token = p_device_token
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.staff_members
    where id = p_staff_id
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid staff member for tenant.' using errcode = '42501';
  end if;

  if not public.has_staff_permission(p_staff_id, 'meal_management', 'customer_read') then
    raise exception 'Permission denied.' using errcode = '42501';
  end if;

  return query
  select c.*
  from public.customers c
  where c.tenant_id = p_tenant_id
    and (not p_active_only or c.is_active = true)
  order by c.full_name asc;
end;
$$;

-- 2. get_open_session (kiosk)
create or replace function public.get_open_session(
  p_tenant_id uuid,
  p_device_token text
)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_row jsonb;
begin
  if not exists (
    select 1 from public.paired_devices
    where device_token = p_device_token
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  select to_jsonb(s) || jsonb_build_object(
    'shifts', (
      select jsonb_build_object(
        'name', sh.name,
        'start_time', sh.start_time,
        'end_time', sh.end_time
      )
      from public.shifts sh
      where sh.id = s.shift_id
    )
  )
  into v_row
  from public.sessions s
  where s.tenant_id = p_tenant_id
    and s.status = 'open'
  limit 1;

  return v_row;
end;
$$;

-- 3. list_active_shifts (kiosk — open dialog / customer form)
create or replace function public.list_active_shifts(
  p_tenant_id uuid,
  p_device_token text
)
returns table (id uuid, name text, start_time time, end_time time)
security definer
set search_path = public
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.paired_devices
    where device_token = p_device_token
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  return query
  select sh.id, sh.name, sh.start_time, sh.end_time
  from public.shifts sh
  where sh.tenant_id = p_tenant_id
    and sh.is_active = true
  order by sh.name asc;
end;
$$;

-- 4. get_enabled_features (kiosk — tenant_settings RLS is workspace-only)
create or replace function public.get_enabled_features(
  p_tenant_id uuid,
  p_device_token text
)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_features jsonb;
begin
  if not exists (
    select 1 from public.paired_devices
    where device_token = p_device_token
      and tenant_id = p_tenant_id
      and is_active = true
  ) then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  select enabled_features into v_features
  from public.tenant_settings
  where tenant_id = p_tenant_id;

  return coalesce(v_features, '{}'::jsonb);
end;
$$;

-- 5. Grants — match open_session (anon + authenticated)
grant execute on function public.list_customers(uuid, text, uuid, boolean) to anon, authenticated;
grant execute on function public.get_open_session(uuid, text) to anon, authenticated;
grant execute on function public.list_active_shifts(uuid, text) to anon, authenticated;
grant execute on function public.get_enabled_features(uuid, text) to anon, authenticated;
grant execute on function public.upsert_customer(uuid, text, text, text, numeric, text[], text, boolean, uuid, text, uuid) to anon, authenticated;
grant execute on function public.toggle_contract_attendance(uuid, uuid, uuid, text, text, uuid) to anon, authenticated;
grant execute on function public.record_baki_transaction(uuid, uuid, uuid, text, numeric, text, uuid) to anon, authenticated;
grant execute on function public.record_customer_collection(uuid, uuid, uuid, numeric, text, text, text, uuid) to anon, authenticated;
