-- Migration: Device Pairing & PIN-Based Authentication Schema (Phase 4 Extension)

-- 1. Create tables

-- Create staff_members table
create table public.staff_members (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  full_name text not null,
  role text not null,
  phone text not null,
  is_active boolean not null default true,
  allow_terminal_login boolean not null default false,
  hashed_pin text,
  temp_pin text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint unique_tenant_staff_phone unique (tenant_id, phone)
);

-- Create device_pairings table
create table public.device_pairings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  pairing_code text not null unique,
  device_name text not null,
  expires_at timestamp with time zone not null,
  created_at timestamp with time zone not null default now()
);

-- 2. Add triggers for updated_at
create trigger set_staff_members_updated_at before update on public.staff_members for each row execute procedure public.set_updated_at();

-- 3. Add indexes for performance
create index idx_staff_members_tenant_id on public.staff_members(tenant_id);
create index idx_device_pairings_tenant_id on public.device_pairings(tenant_id);
create index idx_device_pairings_code on public.device_pairings(pairing_code);

-- 4. Enable Row Level Security (RLS)
alter table public.staff_members enable row level security;
alter table public.device_pairings enable row level security;

-- 5. Define RLS Policies

-- staff_members RLS Policies
create policy "Users can view staff in their own tenant" on public.staff_members
  for select using (
    public.is_tenant_member(tenant_id)
  );

create policy "Owners and superadmins can manage staff members" on public.staff_members
  for all using (
    public.is_tenant_owner(tenant_id) or public.is_superadmin()
  ) with check (
    public.is_tenant_owner(tenant_id) or public.is_superadmin()
  );

-- device_pairings RLS Policies
create policy "Owners and superadmins can view device pairings for their tenant" on public.device_pairings
  for select using (
    public.is_tenant_member(tenant_id)
  );

create policy "Owners and superadmins can manage device pairings" on public.device_pairings
  for all using (
    public.is_tenant_owner(tenant_id) or public.is_superadmin()
  ) with check (
    public.is_tenant_owner(tenant_id) or public.is_superadmin()
  );

-- 6. Helper & Authentication Functions

-- Generate temporary 4-digit setup PIN
create or replace function public.reset_staff_pin(
  p_staff_id uuid
)
returns text
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_temp_pin text;
begin
  -- Retrieve tenant ID
  select tenant_id into v_tenant_id from public.staff_members where id = p_staff_id;
  if not found then
    raise exception 'Staff member not found.';
  end if;

  -- Access Check: must be tenant owner or superadmin
  if not (public.is_tenant_owner(v_tenant_id) or public.is_superadmin()) then
    raise exception 'Only tenant owners or platform superadmins can reset PINs.';
  end if;

  -- Generate a random 4-digit PIN (1000 - 9999)
  v_temp_pin := (floor(random() * 9000) + 1000)::text;

  -- Update staff member record
  update public.staff_members
  set temp_pin = v_temp_pin,
      hashed_pin = null,
      updated_at = now()
  where id = p_staff_id;

  return v_temp_pin;
end;
$$;

-- Verify PIN and process login from Counter Mode Kiosk
create or replace function public.verify_staff_pin(
  p_tenant_id uuid,
  p_pin text
)
returns jsonb
security definer
set search_path = public, extensions
language plpgsql
as $$
declare
  v_staff record;
begin
  -- Clean up pin input
  p_pin := trim(p_pin);

  -- Fetch matching active staff member in this tenant
  select id, full_name, role, hashed_pin, temp_pin, allow_terminal_login
  into v_staff
  from public.staff_members
  where tenant_id = p_tenant_id and is_active = true and allow_terminal_login = true;

  -- We loop to find the correct staff member matching the PIN
  for v_staff in 
    select id, full_name, role, hashed_pin, temp_pin
    from public.staff_members
    where tenant_id = p_tenant_id and is_active = true and allow_terminal_login = true
  loop
    -- Check if it matches the temporary PIN
    if v_staff.temp_pin is not null and v_staff.temp_pin = p_pin then
      return jsonb_build_object(
        'success', true,
        'setup_required', true,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role
      );
    end if;

    -- Check if it matches the hashed private PIN
    if v_staff.hashed_pin is not null and v_staff.hashed_pin = crypt(p_pin, v_staff.hashed_pin) then
      return jsonb_build_object(
        'success', true,
        'setup_required', false,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role
      );
    end if;
  end loop;

  -- No match found
  return jsonb_build_object(
    'success', false,
    'message', 'Invalid PIN code.'
  );
end;
$$;

-- Setup private PIN using temporary PIN verification
create or replace function public.set_staff_pin(
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
begin
  -- Validate pin length
  p_new_pin := trim(p_new_pin);
  if length(p_new_pin) != 4 or p_new_pin !~ '^\d{4}$' then
    raise exception 'PIN must be exactly 4 digits.';
  end if;

  -- Retrieve and lock record
  select temp_pin into v_current_temp_pin
  from public.staff_members
  where id = p_staff_id and is_active = true and allow_terminal_login = true;

  if not found then
    raise exception 'Staff record not found or login access disabled.';
  end if;

  if v_current_temp_pin is null or v_current_temp_pin != trim(p_temp_pin) then
    raise exception 'Invalid temporary setup code verification.';
  end if;

  -- Hash and set new PIN, clearing temporary PIN
  update public.staff_members
  set hashed_pin = crypt(p_new_pin, gen_salt('bf')),
      temp_pin = null,
      updated_at = now()
  where id = p_staff_id;

  return true;
end;
$$;

-- Generate pairing code for terminal
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
  -- Access check: must be owner or superadmin
  if not (public.is_tenant_owner(p_tenant_id) or public.is_superadmin()) then
    raise exception 'Only tenant owners or platform superadmins can pair devices.';
  end if;

  -- Generate unique 6-digit code
  v_code := lpad((floor(random() * 900000) + 100000)::text, 6, '0');

  -- Delete existing pairings for this device name in the tenant
  delete from public.device_pairings
  where tenant_id = p_tenant_id and device_name = p_device_name;

  -- Insert new pairing code valid for 30 minutes
  insert into public.device_pairings (tenant_id, pairing_code, device_name, expires_at)
  values (p_tenant_id, v_code, p_device_name, now() + interval '30 minutes');

  return v_code;
end;
$$;

-- Verify pairing code from device/app
create or replace function public.verify_pairing_code(
  p_code text,
  p_device_name text
)
returns table (
  tenant_id uuid,
  tenant_name text,
  tenant_slug text,
  success boolean,
  message text
)
security definer
set search_path = public
language plpgsql
as $$
declare
  v_pairing record;
  v_tenant record;
begin
  p_code := trim(p_code);

  -- Retrieve pairing record
  select id, tenant_id, expires_at
  into v_pairing
  from public.device_pairings
  where pairing_code = p_code;

  if not found then
    return query select null::uuid, null::text, null::text, false, 'Invalid pairing code.'::text;
    return;
  end if;

  if v_pairing.expires_at < now() then
    -- Clean up expired pairing
    delete from public.device_pairings where id = v_pairing.id;
    return query select null::uuid, null::text, null::text, false, 'Pairing code has expired.'::text;
    return;
  end if;

  -- Retrieve tenant information
  select id, name, slug into v_tenant
  from public.tenants
  where id = v_pairing.tenant_id;

  -- Clean up verification code (one-time use)
  delete from public.device_pairings where id = v_pairing.id;

  return query select v_tenant.id, v_tenant.name, v_tenant.slug, true, 'Device paired successfully.'::text;
end;
$$;
