-- Terminal self-unpair + workspace re-pair (invalidate token + new pairing code)

-- 1. unpair_device: kiosk clears its own paired_devices row by token
create or replace function public.unpair_device(
  p_device_token text,
  p_tenant_id uuid default null
)
returns boolean
security definer
set search_path = public
language plpgsql
as $$
begin
  if p_device_token is null or length(trim(p_device_token)) = 0 then
    return false;
  end if;

  delete from public.paired_devices
  where device_token = trim(p_device_token)
    and (p_tenant_id is null or tenant_id = p_tenant_id);

  -- Idempotent: missing row still counts as success for local cleanup
  return true;
end;
$$;

-- 2. prepare_device_repair: owner disconnects device + issues fresh pairing code
create or replace function public.prepare_device_repair(
  p_tenant_id uuid,
  p_device_id uuid
)
returns text
security definer
set search_path = public
language plpgsql
as $$
declare
  v_device_name text;
  v_code text;
begin
  if not (public.is_tenant_owner(p_tenant_id) or public.is_superadmin()) then
    raise exception 'Unauthorized operation.' using errcode = '42501';
  end if;

  select device_name into v_device_name
  from public.paired_devices
  where id = p_device_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'Device not found.' using errcode = 'P0002';
  end if;

  delete from public.paired_devices
  where id = p_device_id and tenant_id = p_tenant_id;

  v_code := lpad((floor(random() * 900000) + 100000)::text, 6, '0');

  delete from public.device_pairings
  where tenant_id = p_tenant_id and device_name = v_device_name;

  insert into public.device_pairings (tenant_id, pairing_code, device_name, expires_at)
  values (p_tenant_id, v_code, v_device_name, now() + interval '30 minutes');

  return v_code;
end;
$$;

grant execute on function public.unpair_device(text, uuid) to anon, authenticated;
grant execute on function public.prepare_device_repair(uuid, uuid) to authenticated;
