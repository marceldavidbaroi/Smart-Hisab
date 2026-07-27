-- Migration: Tenant Device SL (Auto-increment per tenant), Fixed Unpair Code (6-digit), and Unpair Validation RPC

-- 1. Add device_sl and unpair_code columns if missing
alter table public.paired_devices 
  add column if not exists device_sl integer,
  add column if not exists unpair_code text;

-- Backfill device_sl for existing rows if any
do $$
declare
  r record;
  v_sl integer;
begin
  for r in select distinct tenant_id from public.paired_devices where device_sl is null loop
    v_sl := 1;
    for r in select id from public.paired_devices where tenant_id = r.tenant_id order by paired_at asc loop
      update public.paired_devices 
      set device_sl = v_sl,
          unpair_code = coalesce(unpair_code, lpad((floor(random() * 900000) + 100000)::text, 6, '0'))
      where id = r.id;
      v_sl := v_sl + 1;
    end loop;
  end loop;
end $$;

-- 2. Function to compute next device_sl for tenant
create or replace function public.get_next_device_sl(p_tenant_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max integer;
begin
  select coalesce(max(device_sl), 0) into v_max
  from public.paired_devices
  where tenant_id = p_tenant_id;
  return v_max + 1;
end;
$$;

-- 3. Update verify_pairing_code to assign auto-incremented device_sl and fixed 6-digit unpair_code
create or replace function public.verify_pairing_code(
  p_code text,
  p_device_name text
)
returns jsonb
security definer
set search_path = public, extensions
language plpgsql
as $$
declare
  v_pairing record;
  v_tenant record;
  v_token text;
  v_unpair_code text;
  v_next_sl integer;
begin
  p_code := trim(p_code);

  select id, tenant_id, expires_at 
  into v_pairing 
  from public.device_pairings 
  where pairing_code = p_code;

  if not found then
    return jsonb_build_object('success', false, 'message', 'Invalid pairing code.');
  end if;

  if v_pairing.expires_at < now() then
    delete from public.device_pairings where id = v_pairing.id;
    return jsonb_build_object('success', false, 'message', 'Pairing code has expired.');
  end if;

  select id, name, slug into v_tenant 
  from public.tenants 
  where id = v_pairing.tenant_id;

  -- Generate secure cryptographic device token
  v_token := encode(gen_random_bytes(32), 'hex');

  -- Generate fixed 6-digit unpair code
  v_unpair_code := lpad((floor(random() * 900000) + 100000)::text, 6, '0');

  -- Get next tenant device serial number
  select coalesce(max(device_sl), 0) + 1 into v_next_sl
  from public.paired_devices
  where tenant_id = v_pairing.tenant_id;

  -- Insert into active paired devices
  insert into public.paired_devices (tenant_id, device_sl, device_name, device_token, unpair_code)
  values (v_pairing.tenant_id, v_next_sl, p_device_name, v_token, v_unpair_code);

  -- Invalidate pairing code
  delete from public.device_pairings where id = v_pairing.id;

  return jsonb_build_object(
    'success', true,
    'device_token', v_token,
    'tenant_id', v_tenant.id,
    'tenant_name', v_tenant.name,
    'tenant_slug', v_tenant.slug,
    'device_sl', v_next_sl
  );
end;
$$;

-- 4. RPC for kiosk device to unpair using 6-digit unpair key
create or replace function public.unpair_device_with_code(
  p_device_token text,
  p_unpair_code text
)
returns jsonb
security definer
set search_path = public
language plpgsql
as $$
declare
  v_device record;
begin
  if p_device_token is null or length(trim(p_device_token)) = 0 then
    return jsonb_build_object('success', false, 'message', 'Device token is missing.');
  end if;

  select id, unpair_code into v_device
  from public.paired_devices
  where device_token = trim(p_device_token);

  if not found then
    -- Device was already deleted/unpaired
    return jsonb_build_object('success', true, 'message', 'Device already unpaired.');
  end if;

  if trim(p_unpair_code) != v_device.unpair_code then
    return jsonb_build_object('success', false, 'message', 'Invalid unpair key code.');
  end if;

  delete from public.paired_devices where id = v_device.id;

  return jsonb_build_object('success', true, 'message', 'Device successfully unpaired.');
end;
$$;

grant execute on function public.unpair_device_with_code(text, text) to anon, authenticated;
