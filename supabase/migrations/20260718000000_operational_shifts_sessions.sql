-- Migration: Operational Shifts & Sessions (Phase 1)

-- 1. Create staff_roles Table
create table public.staff_roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  name text not null,
  description text,
  permissions jsonb not null default '{}'::jsonb,
  is_system_role boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Unique constraints
create unique index unique_system_staff_role on public.staff_roles (name) where tenant_id is null;
create unique index unique_tenant_staff_role on public.staff_roles (tenant_id, name) where tenant_id is not null;

-- Seed system roles
insert into public.staff_roles (id, tenant_id, name, description, permissions, is_system_role)
values 
  (
    '00000000-0000-0000-0000-000000000001',
    null,
    'Manager',
    'System manager role with permission to open and close sessions',
    '{"modules": {"kiosk": {"log_pos": true, "log_expense": true, "log_advance": true, "view_active_session": true}, "operational_shifts": {"sessions_open": true, "sessions_close": true, "sessions_reopen": false}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    null,
    'Cashier',
    'System cashier role with permission to record POS and expenses',
    '{"modules": {"kiosk": {"log_pos": true, "log_expense": true, "log_advance": false, "view_active_session": true}, "operational_shifts": {"sessions_open": false, "sessions_close": false, "sessions_reopen": false}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    null,
    'Staff',
    'System staff role with permission to view session status',
    '{"modules": {"kiosk": {"log_pos": false, "log_expense": false, "log_advance": false, "view_active_session": true}, "operational_shifts": {"sessions_open": false, "sessions_close": false, "sessions_reopen": false}}}'::jsonb,
    true
  );

-- Trigger for staff_roles updated_at
create trigger set_staff_roles_updated_at before update on public.staff_roles for each row execute procedure public.set_updated_at();

-- 2. Alter staff_members Table
alter table public.staff_members add column staff_role_id uuid references public.staff_roles(id);
alter table public.staff_members add column user_id uuid references auth.users(id);

-- Backfill staff_members.staff_role_id from free-text role
update public.staff_members
set staff_role_id = case 
  when lower(trim(role)) = 'manager' then '00000000-0000-0000-0000-000000000001'::uuid
  when lower(trim(role)) = 'cashier' then '00000000-0000-0000-0000-000000000002'::uuid
  else '00000000-0000-0000-0000-000000000003'::uuid
end;

-- Make staff_role_id not null
alter table public.staff_members alter column staff_role_id set not null;

-- Drop role column
alter table public.staff_members drop column role;

-- Add index on staff_role_id
create index idx_staff_members_role_id on public.staff_members(staff_role_id);
create index idx_staff_members_user_id on public.staff_members(user_id);


-- 3. Create shifts Table
create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index idx_shifts_tenant_id on public.shifts(tenant_id);
create trigger set_shifts_updated_at before update on public.shifts for each row execute procedure public.set_updated_at();


-- 4. Create sessions Table
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  shift_id uuid not null references public.shifts(id),
  business_date date not null,
  status text not null check (status in ('open', 'closed')),
  opening_cash numeric(12,2) not null default 0,
  closing_cash numeric(12,2),
  expected_cash numeric(12,2),
  variance numeric(12,2),
  opened_by_staff_id uuid not null references public.staff_members(id),
  closed_by_staff_id uuid references public.staff_members(id),
  opened_by_user_id uuid references auth.users(id),
  closed_by_user_id uuid references auth.users(id),
  opened_at timestamp with time zone not null default now(),
  closed_at timestamp with time zone,
  notes text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Unique index to prevent multiple active sessions per tenant
create unique index unique_active_session_per_tenant
  on public.sessions (tenant_id)
  where (status = 'open');

create index idx_sessions_tenant_id on public.sessions(tenant_id);
create index idx_sessions_shift_id on public.sessions(shift_id);
create index idx_sessions_business_date on public.sessions(business_date);
create index idx_sessions_status on public.sessions(tenant_id, status);
create index idx_sessions_opened_by_staff on public.sessions(opened_by_staff_id);
create index idx_sessions_closed_by_staff on public.sessions(closed_by_staff_id);

create trigger set_sessions_updated_at before update on public.sessions for each row execute procedure public.set_updated_at();


-- 5. Helper & Permission Functions

-- has_module_permission: Checks if user profile (Auth) has workspace permission
create or replace function public.has_module_permission(
  p_tenant_id uuid,
  p_module_name text,
  p_permission_name text
)
returns boolean
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_permissions jsonb;
begin
  if exists (
    select 1 from public.user_profiles
    where id = (select auth.uid()) and is_superadmin = true
  ) then
    return true;
  end if;

  select r.permissions into v_permissions
  from public.tenant_members m
  join public.tenant_roles r on m.role_id = r.id
  where m.tenant_id = p_tenant_id
    and m.user_id = (select auth.uid())
    and m.status = 'active';

  if v_permissions is null then
    return false;
  end if;

  if coalesce((v_permissions->>'all')::boolean, false) = true then
    return true;
  end if;

  return coalesce(
    (v_permissions->'modules'->p_module_name->>p_permission_name)::boolean,
    false
  );
end;
$$;

-- get_session_read_scope: Determines active session read scope
create or replace function public.get_session_read_scope(p_tenant_id uuid)
returns text
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_permissions jsonb;
begin
  if exists (
    select 1 from public.user_profiles
    where id = (select auth.uid()) and is_superadmin = true
  ) then
    return 'all';
  end if;

  select r.permissions into v_permissions
  from public.tenant_members m
  join public.tenant_roles r on m.role_id = r.id
  where m.tenant_id = p_tenant_id
    and m.user_id = (select auth.uid())
    and m.status = 'active';

  if v_permissions is null then
    return 'none';
  end if;

  if coalesce((v_permissions->>'all')::boolean, false) = true then
    return 'all';
  end if;

  return coalesce(
    v_permissions->'modules'->'operational_shifts'->>'sessions_read',
    'none'
  );
end;
$$;

-- has_staff_permission: Checks if terminal/kiosk staff has specific kiosk role permission
create or replace function public.has_staff_permission(
  p_staff_id uuid,
  p_module_name text,
  p_permission_name text
)
returns boolean
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_permissions jsonb;
begin
  select sr.permissions into v_permissions
  from public.staff_members sm
  join public.staff_roles sr on sm.staff_role_id = sr.id
  where sm.id = p_staff_id
    and sm.is_active = true;

  if v_permissions is null then
    return false;
  end if;

  return coalesce(
    (v_permissions->'modules'->p_module_name->>p_permission_name)::boolean,
    false
  );
end;
$$;

-- get_or_create_staff_role: Atomic helper to resolve staff role name to staff_role_id
create or replace function public.get_or_create_staff_role(
  p_tenant_id uuid,
  p_role_name text
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_role_id uuid;
  v_clean_name text;
begin
  v_clean_name := trim(p_role_name);
  
  -- 1. Check system roles (tenant_id is null) case-insensitively
  select id into v_role_id
  from public.staff_roles
  where tenant_id is null
    and lower(name) = lower(v_clean_name);
    
  if v_role_id is not null then
    return v_role_id;
  end if;

  -- 2. Check tenant-specific roles case-insensitively
  select id into v_role_id
  from public.staff_roles
  where tenant_id = p_tenant_id
    and lower(name) = lower(v_clean_name);
    
  if v_role_id is not null then
    return v_role_id;
  end if;

  -- 3. Create a new tenant-specific role with default 'Staff' permissions
  insert into public.staff_roles (tenant_id, name, permissions, is_system_role)
  values (
    p_tenant_id,
    v_clean_name,
    coalesce(
      (select permissions from public.staff_roles where tenant_id is null and name = 'Staff'),
      '{}'::jsonb
    ),
    false
  )
  returning id into v_role_id;

  return v_role_id;
end;
$$;


-- 6. Row Level Security (RLS) Policies

-- staff_roles RLS Policies
alter table public.staff_roles enable row level security;

create policy "Tenant members can view staff roles"
  on public.staff_roles for select
  using (
    tenant_id is null or public.is_tenant_member(tenant_id)
  );

create policy "Owners and superadmins can manage staff roles"
  on public.staff_roles for all
  using (
    (tenant_id is not null and (public.is_tenant_owner(tenant_id) or public.is_superadmin()))
  )
  with check (
    (tenant_id is not null and (public.is_tenant_owner(tenant_id) or public.is_superadmin()))
  );

-- shifts RLS Policies
alter table public.shifts enable row level security;

create policy "Users can view shifts in their tenant"
  on public.shifts for select
  using (
    public.has_module_permission(tenant_id, 'operational_shifts', 'shifts_config_read')
  );

create policy "Users can manage shifts in their tenant"
  on public.shifts for all
  using (
    public.has_module_permission(tenant_id, 'operational_shifts', 'shifts_config_write')
  )
  with check (
    public.has_module_permission(tenant_id, 'operational_shifts', 'shifts_config_write')
  );

-- sessions RLS Policies
alter table public.sessions enable row level security;

create policy "Users can view sessions in their tenant"
  on public.sessions for select
  using (
    public.get_session_read_scope(tenant_id) = 'all'
    or (
      public.get_session_read_scope(tenant_id) = 'self'
      and opened_by_staff_id in (
        select id from public.staff_members
        where user_id = (select auth.uid()) and tenant_id = sessions.tenant_id
      )
    )
  );

create policy "Users can open sessions in their tenant via Auth"
  on public.sessions for insert
  with check (
    public.has_module_permission(tenant_id, 'operational_shifts', 'shifts_config_write')
    or coalesce(
      (select (r.permissions->>'all')::boolean
       from public.tenant_members m
       join public.tenant_roles r on m.role_id = r.id
       where m.tenant_id = sessions.tenant_id
         and m.user_id = (select auth.uid())
         and m.status = 'active'),
      false
    )
  );

create policy "Users can update sessions in their tenant via Auth"
  on public.sessions for update
  using (
    public.has_module_permission(tenant_id, 'operational_shifts', 'sessions_reopen')
  )
  with check (
    status = 'open'
    or public.has_module_permission(tenant_id, 'operational_shifts', 'sessions_reopen')
  );


-- 7. Kiosk RPC Implementations

-- open_session RPC
create or replace function public.open_session(
  p_device_token text,
  p_staff_id uuid,
  p_shift_id uuid,
  p_opening_cash numeric,
  p_business_date date default current_date
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_session_id uuid;
begin
  select pd.tenant_id into v_tenant_id
  from public.paired_devices pd
  where pd.device_token = p_device_token
    and pd.is_active = true;

  if v_tenant_id is null then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.staff_members sm
    where sm.id = p_staff_id
      and sm.tenant_id = v_tenant_id
      and sm.is_active = true
      and sm.allow_terminal_login = true
  ) then
    raise exception 'Invalid staff for device tenant.' using errcode = '42501';
  end if;

  if not public.has_staff_permission(p_staff_id, 'operational_shifts', 'sessions_open') then
    raise exception 'Permission denied: sessions_open.' using errcode = '42501';
  end if;

  if p_opening_cash is null or p_opening_cash < 0 then
    raise exception 'opening_cash must be >= 0.' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.shifts
    where id = p_shift_id and tenant_id = v_tenant_id and is_active = true
  ) then
    raise exception 'Invalid or inactive shift for tenant.' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.sessions
    where tenant_id = v_tenant_id and status = 'open'
  ) then
    raise exception 'Cannot open session. There is already an active session for this tenant.'
      using errcode = 'P0001';
  end if;

  insert into public.sessions (
    tenant_id, shift_id, business_date, status,
    opening_cash, opened_by_staff_id, opened_at
  ) values (
    v_tenant_id, p_shift_id, p_business_date, 'open',
    p_opening_cash, p_staff_id, now()
  )
  returning id into v_session_id;

  return v_session_id;
end;
$$;

-- calculate_expected_cash RPC
create or replace function public.calculate_expected_cash(p_session_id uuid)
returns numeric
security definer
set search_path = public
language plpgsql
as $$
declare
  v_opening_cash numeric := 0;
  v_inflow numeric := 0;
  v_outflow numeric := 0;
begin
  select opening_cash into v_opening_cash
  from public.sessions
  where id = p_session_id;

  if not found then
    raise exception 'Session not found.' using errcode = 'P0002';
  end if;

  if to_regclass('public.transaction_ledger') is not null then
    execute $q$
      select coalesce(sum(amount), 0)
      from public.transaction_ledger
      where session_id = $1 and type = 'inflow' and payment_method = 'cash'
    $q$ into v_inflow using p_session_id;

    execute $q$
      select coalesce(sum(amount), 0)
      from public.transaction_ledger
      where session_id = $1 and type = 'outflow' and payment_method = 'cash'
    $q$ into v_outflow using p_session_id;
  end if;

  return v_opening_cash + v_inflow - v_outflow;
end;
$$;

-- close_session RPC
create or replace function public.close_session(
  p_device_token text,
  p_staff_id uuid,
  p_session_id uuid,
  p_closing_cash numeric,
  p_notes text default null
)
returns table (
  expected_cash numeric,
  variance numeric,
  status text
)
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_device_tenant uuid;
  v_expected numeric;
  v_variance numeric;
  v_session_status text;
begin
  select pd.tenant_id into v_device_tenant
  from public.paired_devices pd
  where pd.device_token = p_device_token;

  if v_device_tenant is null then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  if not public.has_staff_permission(p_staff_id, 'operational_shifts', 'sessions_close') then
    raise exception 'Permission denied: sessions_close.' using errcode = '42501';
  end if;

  select s.tenant_id, s.status into v_tenant_id, v_session_status
  from public.sessions s
  where s.id = p_session_id;

  if not found then
    raise exception 'Session not found.' using errcode = 'P0002';
  end if;

  if v_tenant_id <> v_device_tenant then
    raise exception 'Session tenant mismatch.' using errcode = '42501';
  end if;

  if v_session_status = 'closed' then
    raise exception 'Session is already closed.' using errcode = 'P0001';
  end if;

  if p_closing_cash is null or p_closing_cash < 0 then
    raise exception 'closing_cash must be >= 0.' using errcode = '22023';
  end if;

  v_expected := public.calculate_expected_cash(p_session_id);
  v_variance := p_closing_cash - v_expected;

  update public.sessions
  set
    status = 'closed',
    closing_cash = p_closing_cash,
    expected_cash = v_expected,
    variance = v_variance,
    closed_by_staff_id = p_staff_id,
    closed_at = now(),
    notes = p_notes,
    updated_at = now()
  where id = p_session_id;

  return query
  select s.expected_cash, s.variance, s.status
  from public.sessions s
  where s.id = p_session_id;
end;
$$;

-- enforce_closed_session_lock helper
create or replace function public.enforce_closed_session_lock()
returns trigger
language plpgsql
as $$
declare
  v_session_status text;
  v_target_session uuid;
begin
  if TG_OP = 'DELETE' then
    v_target_session := OLD.session_id;
  else
    v_target_session := NEW.session_id;
  end if;

  if v_target_session is null then
    return coalesce(NEW, OLD);
  end if;

  select status into v_session_status
  from public.sessions
  where id = v_target_session;

  if v_session_status = 'closed' then
    raise exception
      'Transaction is locked. The associated operational session % has been closed.',
      v_target_session
      using errcode = 'P0001';
  end if;

  return coalesce(NEW, OLD);
end;
$$;


create or replace function public.reopen_session(
  p_session_id uuid
)
returns void
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_session_status text;
begin
  -- 1. Fetch session details
  select tenant_id, status into v_tenant_id, v_session_status
  from public.sessions
  where id = p_session_id;

  if not found then
    raise exception 'Session not found.' using errcode = 'P0002';
  end if;

  -- 2. Verify workspace permission (using auth.uid())
  if not (
    exists (
      select 1 from public.user_profiles
      where id = auth.uid() and is_superadmin = true
    ) or public.has_module_permission(v_tenant_id, 'operational_shifts', 'sessions_reopen')
  ) then
    raise exception 'Permission denied: sessions_reopen.' using errcode = '42501';
  end if;

  -- 3. Check session status
  if v_session_status = 'open' then
    raise exception 'Session is already open.' using errcode = 'P0001';
  end if;

  -- 4. Check if there is already another active session open for the tenant
  if exists (
    select 1 from public.sessions
    where tenant_id = v_tenant_id and status = 'open'
  ) then
    raise exception 'Cannot reopen session. There is already another active session open for this tenant.'
      using errcode = 'P0001';
  end if;

  -- 5. Reopen session
  update public.sessions
  set
    status = 'open',
    closing_cash = null,
    expected_cash = null,
    variance = null,
    closed_by_staff_id = null,
    closed_by_user_id = null,
    closed_at = null,
    notes = null,
    updated_at = now()
  where id = p_session_id;
end;
$$;


-- 8. RPC Grants
grant execute on function public.open_session(text, uuid, uuid, numeric, date) to anon, authenticated;
grant execute on function public.close_session(text, uuid, uuid, numeric, text) to anon, authenticated;
grant execute on function public.calculate_expected_cash(uuid) to authenticated;
grant execute on function public.has_staff_permission(uuid, text, text) to authenticated;
grant execute on function public.reopen_session(uuid) to authenticated;


-- 9. Update Default Tenant Roles' permissions JSONB
update public.tenant_roles
set permissions = jsonb_set(
  permissions,
  '{modules,operational_shifts}',
  '{"shifts_config_read": true, "shifts_config_write": true, "sessions_read": "all", "sessions_reopen": true}'::jsonb
)
where tenant_id is null and name = 'Admin';

update public.tenant_roles
set permissions = jsonb_set(
  permissions,
  '{modules,operational_shifts}',
  '{"shifts_config_read": true, "shifts_config_write": false, "sessions_read": "self", "sessions_reopen": false}'::jsonb
)
where tenant_id is null and name = 'Member';


-- 10. Update existing get_paired_device_staff and verify_staff_pin function logic to join staff_roles for backwards compatibility
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
  select sm.id, sm.full_name, sr.name as role
  from public.staff_members sm
  join public.staff_roles sr on sm.staff_role_id = sr.id
  where sm.tenant_id = p_tenant_id and sm.is_active = true and sm.allow_terminal_login = true
  order by sm.full_name asc;
end;
$$;

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

  -- We loop to find the correct staff member matching the PIN
  for v_staff in 
    select sm.id, sm.full_name, sr.name as role, sr.permissions, sm.hashed_pin, sm.temp_pin
    from public.staff_members sm
    join public.staff_roles sr on sm.staff_role_id = sr.id
    where sm.tenant_id = p_tenant_id and sm.is_active = true and sm.allow_terminal_login = true
  loop
    -- Check if it matches the temporary PIN
    if v_staff.temp_pin is not null and v_staff.temp_pin = p_pin then
      return jsonb_build_object(
        'success', true,
        'setup_required', true,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'permissions', v_staff.permissions
      );
    end if;

    -- Check if it matches the hashed private PIN
    if v_staff.hashed_pin is not null and v_staff.hashed_pin = crypt(p_pin, v_staff.hashed_pin) then
      return jsonb_build_object(
        'success', true,
        'setup_required', false,
        'staff_id', v_staff.id,
        'full_name', v_staff.full_name,
        'role', v_staff.role,
        'permissions', v_staff.permissions
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
    select sm.id, sm.full_name, sr.name as role, sr.permissions, sm.hashed_pin, sm.temp_pin
    from public.staff_members sm
    join public.staff_roles sr on sm.staff_role_id = sr.id
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
        'role', v_staff.role,
        'permissions', v_staff.permissions
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
        'role', v_staff.role,
        'permissions', v_staff.permissions
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
