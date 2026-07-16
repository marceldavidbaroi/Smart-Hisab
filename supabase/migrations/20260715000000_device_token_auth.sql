-- Migration: Device Token-Based Authentication & Verification (Phase 1)

-- Enable pgcrypto for password-hashing crypt functions (if not already enabled)
create extension if not exists pgcrypto;

-- 1. Create paired_devices Table
create table public.paired_devices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  device_name text not null,
  device_token text not null unique,
  is_active boolean not null default true,
  failed_attempts integer not null default 0,
  locked_until timestamp with time zone,
  paired_at timestamp with time zone not null default now(),
  last_active_at timestamp with time zone not null default now()
);

-- 2. Add Indexes
create index idx_paired_devices_token on public.paired_devices(device_token);
create index idx_paired_devices_tenant_id on public.paired_devices(tenant_id);

-- 3. Row-Level Security
alter table public.paired_devices enable row level security;

-- Policies for paired_devices
create policy "Tenant members can view paired devices" on public.paired_devices
  for select using (
    public.is_tenant_member(tenant_id)
  );

create policy "Owners and superadmins can manage paired devices" on public.paired_devices
  for all using (
    public.is_tenant_owner(tenant_id) or public.is_superadmin()
  ) with check (
    public.is_tenant_owner(tenant_id) or public.is_superadmin()
  );

-- 4. Database functions

-- generate_pairing_code: Generate active pairing code for terminal
create or replace function public.generate_pairing_code(
  p_tenant_id uuid,
  p_device_name text
)
returns text
security definer
set search_path = public
language plpgsql
as $$
declare
  v_code text;
begin
  if not (public.is_tenant_owner(p_tenant_id) or public.is_superadmin()) then
    raise exception 'Unauthorized operation.' using errcode = '42501';
  end if;

  -- Generate random 6-digit numeric string
  v_code := lpad((floor(random() * 900000) + 100000)::text, 6, '0');

  -- Remove prior pending pairings for the same device name
  delete from public.device_pairings 
  where tenant_id = p_tenant_id and device_name = p_device_name;

  insert into public.device_pairings (tenant_id, pairing_code, device_name, expires_at)
  values (p_tenant_id, v_code, p_device_name, now() + interval '30 minutes');

  return v_code;
end;
$$;

-- verify_pairing_code: Verify pairing code and register a paired device
drop function if exists public.verify_pairing_code(text, text);
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

  -- Insert into active paired devices
  insert into public.paired_devices (tenant_id, device_name, device_token)
  values (v_pairing.tenant_id, p_device_name, v_token);

  -- Invalidate pairing code
  delete from public.device_pairings where id = v_pairing.id;

  return jsonb_build_object(
    'success', true,
    'device_token', v_token,
    'tenant_id', v_tenant.id,
    'tenant_name', v_tenant.name,
    'tenant_slug', v_tenant.slug
  );
end;
$$;

-- get_paired_device_staff: Retrieve list of active staff members allowed to log in via terminal
create or replace function public.get_paired_device_staff(
  p_device_token text,
  p_tenant_id uuid
)
returns table (
  id uuid,
  full_name text,
  role text
)
security definer
set search_path = public
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.paired_devices 
    where tenant_id = p_tenant_id and device_token = p_device_token and is_active = true
  ) then
    raise exception 'Unauthorized device token.' using errcode = '42501';
  end if;

  update public.paired_devices 
  set last_active_at = now() 
  where device_token = p_device_token;

  return query
  select sm.id, sm.full_name, sm.role
  from public.staff_members sm
  where sm.tenant_id = p_tenant_id and sm.is_active = true and sm.allow_terminal_login = true
  order by sm.full_name asc;
end;
$$;

-- verify_staff_pin: Verify staff PIN and check/throttle brute-force attempts on the kiosk device
create or replace function public.verify_staff_pin(
  p_device_token text,
  p_tenant_id uuid,
  p_pin text
)
returns jsonb
security definer
set search_path = public, extensions
language plpgsql
as $$
declare
  v_device record;
  v_staff record;
begin
  -- 1. Check device status
  select id, is_active, failed_attempts, locked_until 
  into v_device 
  from public.paired_devices 
  where tenant_id = p_tenant_id and device_token = p_device_token;

  if not found or v_device.is_active = false then
    return jsonb_build_object(
      'success', false, 
      'code', 'DEVICE_BLOCKED', 
      'message', 'Device is disabled or unauthorized.'
    );
  end if;

  if v_device.locked_until is not null and v_device.locked_until > now() then
    return jsonb_build_object(
      'success', false, 
      'code', 'DEVICE_LOCKED', 
      'message', 'Device temporarily locked. Try again in ' || 
                  ceil(extract(epoch from (v_device.locked_until - now())) / 60) || ' mins.'
    );
  end if;

  p_pin := trim(p_pin);

  -- 2. Verify PIN
  for v_staff in 
    select sm.id, sm.full_name, sm.role, sm.hashed_pin, sm.temp_pin
    from public.staff_members sm
    where sm.tenant_id = p_tenant_id and sm.is_active = true and sm.allow_terminal_login = true
  loop
    -- Case A: Temporary PIN matches
    if v_staff.temp_pin is not null and v_staff.temp_pin = p_pin then
      update public.paired_devices 
      set failed_attempts = 0, locked_until = null, last_active_at = now() 
      where id = v_device.id;

      return jsonb_build_object(
        'success', true,
        'setup_required', true,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role
      );
    end if;

    -- Case B: Cryptographic PIN matches
    if v_staff.hashed_pin is not null and v_staff.hashed_pin = crypt(p_pin, v_staff.hashed_pin) then
      update public.paired_devices 
      set failed_attempts = 0, locked_until = null, last_active_at = now() 
      where id = v_device.id;

      return jsonb_build_object(
        'success', true,
        'setup_required', false,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role
      );
    end if;
  end loop;

  -- 3. Log Failure & Apply Throttle Rate Limit
  if v_device.failed_attempts + 1 >= 5 then
    update public.paired_devices 
    set failed_attempts = failed_attempts + 1, 
        locked_until = now() + interval '15 minutes', 
        last_active_at = now() 
    where id = v_device.id;
    return jsonb_build_object(
      'success', false, 
      'code', 'DEVICE_LOCKED', 
      'message', 'Too many invalid attempts. Device locked for 15 minutes.'
    );
  else
    update public.paired_devices 
    set failed_attempts = failed_attempts + 1, 
        last_active_at = now() 
    where id = v_device.id;
    return jsonb_build_object(
      'success', false, 
      'code', 'INVALID_PIN', 
      'message', 'Invalid PIN. Attempts remaining: ' || (5 - (v_device.failed_attempts + 1))
    );
  end if;
end;
$$;

-- set_staff_pin: Update a staff member's temporary PIN to a private PIN
create or replace function public.set_staff_pin(
  p_device_token text,
  p_tenant_id uuid,
  p_staff_id uuid,
  p_temp_pin text,
  p_new_pin text
)
returns boolean
security definer
set search_path = public, extensions
language plpgsql
as $$
declare
  v_current_temp_pin text;
  v_staff_tenant_id uuid;
begin
  -- 1. Device Token Authorization
  if not exists (
    select 1 from public.paired_devices 
    where tenant_id = p_tenant_id and device_token = p_device_token and is_active = true
  ) then
    raise exception 'Unauthorized device.' using errcode = '42501';
  end if;

  p_new_pin := trim(p_new_pin);
  if length(p_new_pin) != 4 or p_new_pin !~ '^\d{4}$' then
    raise exception 'PIN must be exactly 4 digits.' using errcode = 'P0002';
  end if;

  select sm.temp_pin, sm.tenant_id into v_current_temp_pin, v_staff_tenant_id
  from public.staff_members sm
  where sm.id = p_staff_id and sm.is_active = true and sm.allow_terminal_login = true;

  if not found then
    raise exception 'Staff member not found.' using errcode = 'P0003';
  end if;

  if v_staff_tenant_id != p_tenant_id then
    raise exception 'Mismatched tenant scope.' using errcode = 'P0004';
  end if;

  if v_current_temp_pin is null or v_current_temp_pin != trim(p_temp_pin) then
    raise exception 'Verification failed. Mismatched setup PIN.' using errcode = 'P0005';
  end if;

  update public.staff_members
  set hashed_pin = crypt(p_new_pin, gen_salt('bf')),
      temp_pin = null,
      updated_at = now()
  where id = p_staff_id;

  return true;
end;
$$;
