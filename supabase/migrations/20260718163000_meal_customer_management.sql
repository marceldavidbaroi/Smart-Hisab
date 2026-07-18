-- Migration: Meal & Customer Management (Phase 1)

-- 1. Create Tables

-- Customers Table
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade not null,
  full_name text not null,
  category text not null check (category in ('contract_worker', 'walk_in_baki')),
  phone text,
  outstanding_balance numeric(12,2) not null default 0.00,
  contract_daily_rate numeric(12,2) check (contract_daily_rate >= 0),
  contract_shifts text[],
  factory_unit text,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint check_contract_worker_rate check (
    (category = 'contract_worker' and contract_daily_rate is not null) or
    (category = 'walk_in_baki')
  )
);

-- Customer Daily Attendance Table
create table public.customer_daily_attendance (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade not null,
  customer_id uuid references public.customers(id) on delete cascade not null,
  session_id uuid references public.sessions(id) on delete restrict not null,
  business_date date not null,
  attended_shifts text[] not null,
  rate_applied numeric(12,2) not null check (rate_applied >= 0),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Baki Transactions Table
create table public.baki_transactions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade not null,
  customer_id uuid references public.customers(id) on delete cascade not null,
  session_id uuid references public.sessions(id) on delete restrict not null,
  business_date date not null,
  items_description text not null,
  amount numeric(12,2) not null check (amount > 0),
  created_by_staff_id uuid references public.staff_members(id) on delete set null,
  created_by_user_id uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Customer Collections Table
create table public.customer_collections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade not null,
  customer_id uuid references public.customers(id) on delete cascade not null,
  session_id uuid references public.sessions(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  payment_method text not null check (payment_method in ('cash', 'mobile_wallet', 'bank_transfer')),
  collected_by_user_id uuid references auth.users(id) on delete set null,
  collected_by_staff_id uuid references public.staff_members(id) on delete set null,
  collected_at timestamp with time zone not null default now(),
  notes text,
  created_at timestamp with time zone not null default now(),
  constraint check_cash_session check (
    (payment_method = 'cash' and session_id is not null) or
    (payment_method <> 'cash')
  ),
  constraint check_collector check (
    collected_by_user_id is not null or collected_by_staff_id is not null
  )
);

-- 2. Indexes

create unique index unique_customer_attendance_per_date
  on public.customer_daily_attendance (tenant_id, customer_id, business_date);

create index idx_customers_tenant_id on public.customers (tenant_id);
create index idx_customers_tenant_active on public.customers (tenant_id, is_active);
create index idx_customers_tenant_category on public.customers (tenant_id, category);

create index idx_cust_attendance_session on public.customer_daily_attendance (session_id);
create index idx_cust_attendance_customer on public.customer_daily_attendance (customer_id);
create index idx_cust_attendance_date on public.customer_daily_attendance (business_date);

create index idx_baki_transactions_session on public.baki_transactions (session_id);
create index idx_baki_transactions_customer on public.baki_transactions (customer_id);

create index idx_customer_collections_session on public.customer_collections (session_id);
create index idx_customer_collections_customer on public.customer_collections (customer_id);

-- 3. Triggers for updated_at

create trigger set_customers_updated_at before update on public.customers for each row execute procedure public.set_updated_at();
create trigger set_customer_daily_attendance_updated_at before update on public.customer_daily_attendance for each row execute procedure public.set_updated_at();
create trigger set_baki_transactions_updated_at before update on public.baki_transactions for each row execute procedure public.set_updated_at();

-- 4. Outstanding Balance Sync Trigger

create or replace function public.sync_customer_outstanding_balance()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
declare
  v_diff numeric := 0.00;
  v_customer_id uuid;
begin
  if TG_OP = 'INSERT' then
    v_customer_id := NEW.customer_id;
    if TG_TABLE_NAME = 'customer_daily_attendance' then
      v_diff := NEW.rate_applied;
    elsif TG_TABLE_NAME = 'baki_transactions' then
      v_diff := NEW.amount;
    elsif TG_TABLE_NAME = 'customer_collections' then
      v_diff := -NEW.amount;
    end if;
  elsif TG_OP = 'UPDATE' then
    v_customer_id := NEW.customer_id;
    if TG_TABLE_NAME = 'customer_daily_attendance' then
      v_diff := NEW.rate_applied - OLD.rate_applied;
    elsif TG_TABLE_NAME = 'baki_transactions' then
      v_diff := NEW.amount - OLD.amount;
    elsif TG_TABLE_NAME = 'customer_collections' then
      v_diff := OLD.amount - NEW.amount;
    end if;
  elsif TG_OP = 'DELETE' then
    v_customer_id := OLD.customer_id;
    if TG_TABLE_NAME = 'customer_daily_attendance' then
      v_diff := -OLD.rate_applied;
    elsif TG_TABLE_NAME = 'baki_transactions' then
      v_diff := -OLD.amount;
    elsif TG_TABLE_NAME = 'customer_collections' then
      v_diff := OLD.amount;
    end if;
  end if;

  update public.customers
  set outstanding_balance = outstanding_balance + v_diff,
      updated_at = now()
  where id = v_customer_id;

  return null;
end;
$$;

create trigger sync_balance_daily_attendance
after insert or update or delete on public.customer_daily_attendance
for each row execute function public.sync_customer_outstanding_balance();

create trigger sync_balance_baki
after insert or update or delete on public.baki_transactions
for each row execute function public.sync_customer_outstanding_balance();

create trigger sync_balance_collections
after insert or update or delete on public.customer_collections
for each row execute function public.sync_customer_outstanding_balance();

-- 5. Lock Triggers (Closed Session)

create trigger check_customer_daily_attendance_lock
before insert or update or delete
on public.customer_daily_attendance
for each row
execute function public.enforce_closed_session_lock();

create trigger check_baki_transactions_lock
before insert or update or delete
on public.baki_transactions
for each row
execute function public.enforce_closed_session_lock();

create or replace function public.enforce_collection_session_lock()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
declare
  v_session_status text;
begin
  if TG_OP = 'DELETE' then
    if OLD.session_id is not null then
      select status into v_session_status from public.sessions where id = OLD.session_id;
      if v_session_status = 'closed' then
        raise exception 'Collection locked. Associated session % is closed.', OLD.session_id using errcode = 'P0001';
      end if;
    end if;
    return OLD;
  end if;

  if NEW.session_id is not null then
    select status into v_session_status from public.sessions where id = NEW.session_id;
    if v_session_status = 'closed' then
      raise exception 'Collection locked. Associated session % is closed.', NEW.session_id using errcode = 'P0001';
    end if;
  end if;
  return NEW;
end;
$$;

create trigger check_customer_collections_lock
before insert or update or delete
on public.customer_collections
for each row
execute function public.enforce_collection_session_lock();

-- 6. RPC Functions

-- toggle_contract_attendance
create or replace function public.toggle_contract_attendance(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,
  p_shift_name text,
  p_device_token text default null,
  p_staff_id uuid default null
)
returns table (
  action_taken text,
  new_balance numeric
)
security definer
set search_path = public
language plpgsql
as $$
declare
  v_session_status text;
  v_business_date date;
  v_daily_rate numeric;
  v_attended_shifts text[];
  v_action text;
  v_updated_balance numeric;
begin
  -- Validate permission
  if p_staff_id is not null then
    -- Validate device token is active and matches the tenant
    if not exists (
      select 1 from public.paired_devices
      where device_token = p_device_token
        and tenant_id = p_tenant_id
        and is_active = true
    ) then
      raise exception 'Invalid or inactive device.' using errcode = '42501';
    end if;

    -- Validate staff exists, belongs to tenant, and is active
    if not exists (
      select 1 from public.staff_members
      where id = p_staff_id
        and tenant_id = p_tenant_id
        and is_active = true
    ) then
      raise exception 'Invalid staff member for tenant.' using errcode = '42501';
    end if;

    if not public.has_staff_permission(p_staff_id, 'meal_management', 'attendance_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'attendance_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  -- Validate session status
  select status, business_date into v_session_status, v_business_date
  from public.sessions
  where id = p_session_id and tenant_id = p_tenant_id;

  if v_session_status is null then
    raise exception 'Session does not exist.' using errcode = 'P0002';
  elsif v_session_status = 'closed' then
    raise exception 'Cannot edit attendance. Operational session is closed.' using errcode = 'P0001';
  end if;

  -- Get customer configuration
  select contract_daily_rate into v_daily_rate
  from public.customers
  where id = p_customer_id and tenant_id = p_tenant_id
    and category = 'contract_worker' and is_active = true;

  if v_daily_rate is null then
    raise exception 'Customer is not registered as a contract worker or has no daily rate configured.' using errcode = 'P0003';
  end if;

  -- Toggle shift attendance
  select attended_shifts into v_attended_shifts
  from public.customer_daily_attendance
  where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = v_business_date;

  if v_attended_shifts is null then
    insert into public.customer_daily_attendance (
      tenant_id, customer_id, session_id, business_date, attended_shifts, rate_applied
    ) values (
      p_tenant_id, p_customer_id, p_session_id, v_business_date, array[p_shift_name], v_daily_rate
    );
    v_action := 'added_first_present';
  else
    if p_shift_name = any(v_attended_shifts) then
      v_attended_shifts := array_remove(v_attended_shifts, p_shift_name);
      if cardinality(v_attended_shifts) = 0 then
        delete from public.customer_daily_attendance
        where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = v_business_date;
        v_action := 'removed_last_present';
      else
        update public.customer_daily_attendance
        set attended_shifts = v_attended_shifts
        where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = v_business_date;
        v_action := 'removed_shift';
      end if;
    else
      v_attended_shifts := array_append(v_attended_shifts, p_shift_name);
      update public.customer_daily_attendance
      set attended_shifts = v_attended_shifts
      where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = v_business_date;
      v_action := 'added_shift';
    end if;
  end if;

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return query select v_action, v_updated_balance;
end;
$$;

-- record_baki_transaction
create or replace function public.record_baki_transaction(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,
  p_items_description text,
  p_amount numeric,
  p_device_token text default null,
  p_staff_id uuid default null
)
returns numeric
security definer
set search_path = public
language plpgsql
as $$
declare
  v_session_status text;
  v_business_date date;
  v_updated_balance numeric;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = '22023';
  end if;
  if p_items_description is null or length(trim(p_items_description)) = 0 then
    raise exception 'Items description is required.' using errcode = '22023';
  end if;

  -- Validate permission
  if p_staff_id is not null then
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

    if not public.has_staff_permission(p_staff_id, 'meal_management', 'baki_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'baki_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  -- Validate session status
  select status, business_date into v_session_status, v_business_date
  from public.sessions
  where id = p_session_id and tenant_id = p_tenant_id;

  if v_session_status is null then
    raise exception 'Session does not exist.' using errcode = 'P0002';
  elsif v_session_status = 'closed' then
    raise exception 'Cannot record credit. Operational session is closed.' using errcode = 'P0001';
  end if;

  insert into public.baki_transactions (
    tenant_id, customer_id, session_id, business_date,
    items_description, amount, created_by_staff_id, created_by_user_id
  ) values (
    p_tenant_id, p_customer_id, p_session_id, v_business_date,
    trim(p_items_description), p_amount, p_staff_id, auth.uid()
  );

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return v_updated_balance;
end;
$$;

-- record_customer_collection
create or replace function public.record_customer_collection(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null,
  p_device_token text default null,
  p_staff_id uuid default null
)
returns numeric
security definer
set search_path = public
language plpgsql
as $$
declare
  v_session_status text;
  v_updated_balance numeric;
  v_collection_id uuid;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = '22023';
  end if;
  if p_payment_method not in ('cash', 'mobile_wallet', 'bank_transfer') then
    raise exception 'Invalid payment method.' using errcode = '22023';
  end if;

  -- Validate permission
  if p_staff_id is not null then
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

    if not public.has_staff_permission(p_staff_id, 'meal_management', 'collections_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'collections_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  -- Validate session status if cash
  if p_payment_method = 'cash' then
    if p_session_id is null then
      raise exception 'Session ID is required for cash collections.' using errcode = '22023';
    end if;
    select status into v_session_status
    from public.sessions
    where id = p_session_id and tenant_id = p_tenant_id;
    if v_session_status is null then
      raise exception 'Session not found.' using errcode = 'P0002';
    elsif v_session_status = 'closed' then
      raise exception 'Cannot collect cash during a closed operational session.' using errcode = 'P0001';
    end if;
  end if;

  insert into public.customer_collections (
    tenant_id, customer_id, session_id, amount, payment_method,
    collected_by_user_id, collected_by_staff_id, collected_at, notes
  ) values (
    p_tenant_id, p_customer_id, p_session_id, p_amount, p_payment_method,
    case when p_staff_id is null then auth.uid() else null end,
    p_staff_id, now(), p_notes
  )
  returning id into v_collection_id;

  perform public.post_ledger_entry(
    p_tenant_id := p_tenant_id,
    p_session_id := p_session_id,
    p_type := 'inflow',
    p_category := 'Debt Collection',
    p_amount := p_amount,
    p_payment_method := p_payment_method,
    p_operator_user_id := case when p_staff_id is null then auth.uid() else null end,
    p_operator_staff_id := p_staff_id,
    p_notes := coalesce(p_notes, 'Customer collection ' || v_collection_id::text)
  );

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return v_updated_balance;
end;
$$;

-- 7. Row Level Security Policies

alter table public.customers enable row level security;
alter table public.customer_daily_attendance enable row level security;
alter table public.baki_transactions enable row level security;
alter table public.customer_collections enable row level security;

-- Customers Policies
create policy "Users can view customers in their tenant"
  on public.customers for select
  using (public.has_module_permission(tenant_id, 'meal_management', 'customer_read'));

create policy "Users can manage customers in their tenant"
  on public.customers for all
  using (public.has_module_permission(tenant_id, 'meal_management', 'customer_write'))
  with check (public.has_module_permission(tenant_id, 'meal_management', 'customer_write'));

-- Attendance Policies
create policy "Users can view attendance in their tenant"
  on public.customer_daily_attendance for select
  using (public.has_module_permission(tenant_id, 'meal_management', 'attendance_read'));

create policy "Users can manage attendance in their tenant"
  on public.customer_daily_attendance for all
  using (public.has_module_permission(tenant_id, 'meal_management', 'attendance_write'))
  with check (public.has_module_permission(tenant_id, 'meal_management', 'attendance_write'));

-- Baki Policies
create policy "Users can view baki in their tenant"
  on public.baki_transactions for select
  using (public.has_module_permission(tenant_id, 'meal_management', 'baki_read'));

create policy "Users can manage baki in their tenant"
  on public.baki_transactions for all
  using (public.has_module_permission(tenant_id, 'meal_management', 'baki_write'))
  with check (public.has_module_permission(tenant_id, 'meal_management', 'baki_write'));

-- Collections Policies
create policy "Users can view collections in their tenant"
  on public.customer_collections for select
  using (public.has_module_permission(tenant_id, 'meal_management', 'collections_read'));

create policy "Users can manage collections in their tenant"
  on public.customer_collections for all
  using (public.has_module_permission(tenant_id, 'meal_management', 'collections_write'))
  with check (public.has_module_permission(tenant_id, 'meal_management', 'collections_write'));

-- 8. Seed Feature Flag & Permissions

-- Update all tenant roles (system and tenant-specific) for Admin
update public.tenant_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "customer_write": true, "attendance_read": true, "attendance_write": true, "baki_read": true, "baki_write": true, "collections_read": true, "collections_write": true, "statement_read": true}'::jsonb
)
where name = 'Admin';

-- Update all tenant roles (system and tenant-specific) for Member
update public.tenant_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "customer_write": false, "attendance_read": true, "attendance_write": false, "baki_read": true, "baki_write": false, "collections_read": true, "collections_write": false, "statement_read": true}'::jsonb
)
where name = 'Member';

-- Update all staff roles (system and tenant-specific) for Manager and Cashier
update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "attendance_read": true, "attendance_write": true, "baki_read": true, "baki_write": true, "collections_read": true, "collections_write": true}'::jsonb
)
where name in ('Manager', 'Cashier');

-- Disable features protection trigger temporarily to update existing tenant settings
alter table public.tenant_settings disable trigger protect_tenant_settings_features;

-- Seed feature flag for existing tenants
update public.tenant_settings
set enabled_features = enabled_features || '{"meal-management": true}'::jsonb;

-- Re-enable features protection trigger
alter table public.tenant_settings enable trigger protect_tenant_settings_features;

-- 9. Grants

grant execute on function public.toggle_contract_attendance(uuid, uuid, uuid, text, text, uuid) to authenticated;
grant execute on function public.record_baki_transaction(uuid, uuid, uuid, text, numeric, text, uuid) to authenticated;
grant execute on function public.record_customer_collection(uuid, uuid, uuid, numeric, text, text, text, uuid) to authenticated;
