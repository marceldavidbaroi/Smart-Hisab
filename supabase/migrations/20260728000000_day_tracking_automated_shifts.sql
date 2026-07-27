-- Migration: Day Tracking & Automated Shifts (Replaces Sessions)

-- 1. Create business_days Table
create table public.business_days (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
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

-- Active day constraint: only one open day per tenant at a time
create unique index unique_active_day_per_tenant
  on public.business_days (tenant_id)
  where (status = 'open');

create index idx_business_days_tenant_id on public.business_days(tenant_id);
create index idx_business_days_date on public.business_days(business_date);

create trigger set_business_days_updated_at 
before update on public.business_days 
for each row execute procedure public.set_updated_at();

-- 2. Alter Dependent Tables
-- transaction_ledger
alter table public.transaction_ledger drop column if exists session_id cascade;
alter table public.transaction_ledger add column business_day_id uuid references public.business_days(id) on delete set null;
alter table public.transaction_ledger add column shift_id uuid references public.shifts(id) on delete set null;

create index idx_transaction_ledger_business_day on public.transaction_ledger(business_day_id);
create index idx_transaction_ledger_shift on public.transaction_ledger(shift_id);

-- customer_daily_attendance
alter table public.customer_daily_attendance drop column if exists session_id cascade;
alter table public.customer_daily_attendance add column business_day_id uuid references public.business_days(id) on delete restrict;
alter table public.customer_daily_attendance add column shift_id uuid references public.shifts(id) on delete restrict;

create index idx_cust_attendance_day on public.customer_daily_attendance (business_day_id);

-- baki_transactions
alter table public.baki_transactions drop column if exists session_id cascade;
alter table public.baki_transactions add column business_day_id uuid references public.business_days(id) on delete restrict;
alter table public.baki_transactions add column shift_id uuid references public.shifts(id) on delete restrict;

create index idx_baki_transactions_day on public.baki_transactions (business_day_id);

-- customer_collections
alter table public.customer_collections drop column if exists session_id cascade;
alter table public.customer_collections add column business_day_id uuid references public.business_days(id) on delete restrict;
alter table public.customer_collections add column shift_id uuid references public.shifts(id) on delete restrict;

-- Re-add check constraint for cash payments
alter table public.customer_collections 
add constraint check_cash_business_day check (
  (payment_method = 'cash' and business_day_id is not null) or
  (payment_method <> 'cash')
);

create index idx_customer_collections_day on public.customer_collections (business_day_id);

-- 3. Drop Sessions Table and old RPCs
drop table if exists public.sessions cascade;

do $$
declare
  r record;
begin
  for r in (
    select p.oid::regprocedure as func_signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'open_session',
        'close_session',
        'reopen_session',
        'calculate_expected_cash',
        'post_ledger_entry',
        'log_pos_sale',
        'record_baki_transaction',
        'record_customer_collection',
        'toggle_contract_attendance',
        'edit_pos_sale',
        'enforce_closed_session_lock',
        'get_session_read_scope',
        'get_ledger_read_scope',
        'list_session_ledger_entries',
        'get_cash_register_running_balance',
        'get_cash_register_running_balance_kiosk'
      )
  ) loop
    execute 'drop function if exists ' || r.func_signature || ' cascade';
  end loop;
end $$;

-- 4. New Day Tracking / Shift Helpers
create or replace function public.get_current_shift(p_tenant_id uuid)
returns uuid
language plpgsql
security definer
stable
as $$
declare
  v_shift_id uuid;
  v_current_time time := current_time;
begin
  select id into v_shift_id
  from public.shifts
  where tenant_id = p_tenant_id
    and is_active = true
    and (
      (start_time <= end_time and v_current_time >= start_time and v_current_time <= end_time)
      or
      (start_time > end_time and (v_current_time >= start_time or v_current_time <= end_time))
    )
  order by created_at asc
  limit 1;
  return v_shift_id;
end;
$$;

create or replace function public.get_active_business_day(p_tenant_id uuid)
returns uuid
language plpgsql
security definer
stable
as $$
declare
  v_day_id uuid;
begin
  select id into v_day_id
  from public.business_days
  where tenant_id = p_tenant_id
    and status = 'open'
  limit 1;
  return v_day_id;
end;
$$;

-- 5. Business Day Operations
create or replace function public.start_business_day(
  p_device_token text,
  p_staff_id uuid,
  p_opening_cash numeric
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_day_id uuid;
  v_last_day_status text;
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

  -- Ensure no day is currently open
  if exists (
    select 1 from public.business_days
    where tenant_id = v_tenant_id and status = 'open'
  ) then
    raise exception 'Cannot start day. A business day is already open.' using errcode = 'P0001';
  end if;

  -- Ensure the latest day is closed before starting a new one
  select status into v_last_day_status
  from public.business_days
  where tenant_id = v_tenant_id
  order by created_at desc
  limit 1;

  if v_last_day_status = 'open' then
    raise exception 'Previous day must be closed before starting a new one.' using errcode = 'P0001';
  end if;

  insert into public.business_days (
    tenant_id, business_date, status,
    opening_cash, opened_by_staff_id, opened_at
  ) values (
    v_tenant_id, current_date, 'open',
    p_opening_cash, p_staff_id, now()
  )
  returning id into v_day_id;

  return v_day_id;
end;
$$;

create or replace function public.calculate_expected_cash(p_day_id uuid)
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
  from public.business_days
  where id = p_day_id;

  if not found then
    raise exception 'Business day not found.' using errcode = 'P0002';
  end if;

  select coalesce(sum(amount), 0) into v_inflow
  from public.transaction_ledger
  where business_day_id = p_day_id and type = 'inflow' and payment_method = 'cash';

  select coalesce(sum(amount), 0) into v_outflow
  from public.transaction_ledger
  where business_day_id = p_day_id and type = 'outflow' and payment_method = 'cash';

  return v_opening_cash + v_inflow - v_outflow;
end;
$$;

create or replace function public.end_business_day(
  p_device_token text,
  p_staff_id uuid,
  p_day_id uuid,
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
  v_day_status text;
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

  select bd.tenant_id, bd.status into v_tenant_id, v_day_status
  from public.business_days bd
  where bd.id = p_day_id;

  if not found then
    raise exception 'Business day not found.' using errcode = 'P0002';
  end if;

  if v_tenant_id <> v_device_tenant then
    raise exception 'Tenant mismatch.' using errcode = '42501';
  end if;

  if v_day_status = 'closed' then
    raise exception 'Business day is already closed.' using errcode = 'P0001';
  end if;

  if p_closing_cash is null or p_closing_cash < 0 then
    raise exception 'closing_cash must be >= 0.' using errcode = '22023';
  end if;

  v_expected := public.calculate_expected_cash(p_day_id);
  v_variance := p_closing_cash - v_expected;

  update public.business_days
  set
    status = 'closed',
    closing_cash = p_closing_cash,
    expected_cash = v_expected,
    variance = v_variance,
    closed_by_staff_id = p_staff_id,
    closed_at = now(),
    notes = p_notes,
    updated_at = now()
  where id = p_day_id;

  return query
  select bd.expected_cash, bd.variance, bd.status
  from public.business_days bd
  where bd.id = p_day_id;
end;
$$;

create or replace function public.resume_business_day(
  p_device_token text,
  p_staff_id uuid,
  p_day_id uuid
)
returns void
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_day_status text;
  v_business_date date;
begin
  select pd.tenant_id into v_tenant_id
  from public.paired_devices pd
  where pd.device_token = p_device_token
    and pd.is_active = true;

  if v_tenant_id is null then
    raise exception 'Invalid or inactive device.' using errcode = '42501';
  end if;

  if not public.has_staff_permission(p_staff_id, 'operational_shifts', 'sessions_open') then
    raise exception 'Permission denied: sessions_open (resume).' using errcode = '42501';
  end if;

  select status, business_date into v_day_status, v_business_date
  from public.business_days
  where id = p_day_id and tenant_id = v_tenant_id;

  if not found then
    raise exception 'Business day not found.' using errcode = 'P0002';
  end if;

  if v_day_status = 'open' then
    raise exception 'Day is already open.' using errcode = 'P0001';
  end if;
  
  if v_business_date <> current_date then
    raise exception 'Cannot resume a day from a past date. Start a new day instead.' using errcode = 'P0001';
  end if;
  
  if exists (
    select 1 from public.business_days
    where tenant_id = v_tenant_id and status = 'open'
  ) then
    raise exception 'Cannot resume. Another day is already open.' using errcode = 'P0001';
  end if;

  update public.business_days
  set
    status = 'open',
    closing_cash = null,
    expected_cash = null,
    variance = null,
    closed_by_staff_id = null,
    closed_at = null,
    notes = null,
    updated_at = now()
  where id = p_day_id;
end;
$$;

-- 6. Lock Triggers Re-implementation
create or replace function public.enforce_closed_day_lock()
returns trigger
language plpgsql
as $$
declare
  v_status text;
  v_target_day uuid;
begin
  if TG_OP = 'DELETE' then
    v_target_day := OLD.business_day_id;
  else
    v_target_day := NEW.business_day_id;
  end if;

  if v_target_day is null then
    return coalesce(NEW, OLD);
  end if;

  select status into v_status
  from public.business_days
  where id = v_target_day;

  if v_status = 'closed' then
    raise exception 'Transaction is locked. The associated business day is closed.' using errcode = 'P0001';
  end if;

  return coalesce(NEW, OLD);
end;
$$;

create trigger check_transaction_day_lock
before insert or update or delete on public.transaction_ledger
for each row execute function public.enforce_closed_day_lock();

create trigger check_customer_daily_attendance_day_lock
before insert or update or delete on public.customer_daily_attendance
for each row execute function public.enforce_closed_day_lock();

create trigger check_baki_transactions_day_lock
before insert or update or delete on public.baki_transactions
for each row execute function public.enforce_closed_day_lock();

create trigger check_customer_collections_day_lock
before insert or update or delete on public.customer_collections
for each row execute function public.enforce_closed_day_lock();

-- 7. Rewrite Shared Helpers
create or replace function public.get_day_read_scope(p_tenant_id uuid)
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
    where id = auth.uid() and is_superadmin = true
  ) then
    return 'all';
  end if;

  select r.permissions into v_permissions
  from public.tenant_members m
  join public.tenant_roles r on m.role_id = r.id
  where m.tenant_id = p_tenant_id
    and m.user_id = auth.uid()
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



-- 8. Post Ledger Entry Refactor
create or replace function public.post_ledger_entry(
  p_tenant_id uuid,
  p_business_day_id uuid,
  p_type text,
  p_category text,
  p_amount numeric,
  p_payment_method text,
  p_operator_user_id uuid default null,
  p_operator_staff_id uuid default null,
  p_notes text default null,
  p_shift_id uuid default null
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_id uuid;
begin
  if p_type not in ('inflow', 'outflow') then
    raise exception 'Invalid transaction type.' using errcode = '22023';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero.' using errcode = '22023';
  end if;

  if p_payment_method not in ('cash', 'bank_transfer', 'mobile_wallet') then
    raise exception 'Invalid payment method.' using errcode = '22023';
  end if;

  insert into public.transaction_ledger (
    tenant_id, business_day_id, shift_id, type, category, amount, payment_method,
    operator_user_id, operator_staff_id, notes
  )
  values (
    p_tenant_id, p_business_day_id, p_shift_id, p_type, p_category, p_amount, p_payment_method,
    p_operator_user_id, p_operator_staff_id, p_notes
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- 9. Transaction RPCs

-- POS Sale
create or replace function public.log_pos_sale(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_day_id uuid;
  v_shift_id uuid;
  v_id uuid;
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'kiosk', 'log_pos') then
    raise exception 'Permission denied: log_pos.' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero.' using errcode = '22023';
  end if;

  if p_payment_method not in ('cash', 'mobile_wallet') then
    raise exception 'POS payment method must be cash or mobile_wallet (online).' using errcode = '22023';
  end if;

  -- Auto-resolve day and shift
  v_day_id := public.get_active_business_day(p_tenant_id);
  
  if v_day_id is null and p_payment_method = 'cash' then
    raise exception 'No active business day found. Start the day first.' using errcode = 'P0001';
  end if;

  v_shift_id := public.get_current_shift(p_tenant_id);

  v_id := public.post_ledger_entry(
    p_tenant_id := p_tenant_id,
    p_business_day_id := v_day_id,
    p_type := 'inflow',
    p_category := 'POS',
    p_amount := p_amount,
    p_payment_method := p_payment_method,
    p_operator_user_id := null,
    p_operator_staff_id := p_staff_id,
    p_notes := p_notes,
    p_shift_id := v_shift_id
  );

  return v_id;
end;
$$;

-- Record Baki
create or replace function public.record_baki_transaction(
  p_tenant_id uuid,
  p_customer_id uuid,
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
  v_day_id uuid;
  v_shift_id uuid;
  v_updated_balance numeric;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = '22023';
  end if;
  if p_items_description is null or length(trim(p_items_description)) = 0 then
    raise exception 'Items description is required.' using errcode = '22023';
  end if;

  if p_staff_id is not null then
    perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);
    if not public.has_staff_permission(p_staff_id, 'meal_management', 'baki_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'baki_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  v_day_id := public.get_active_business_day(p_tenant_id);
  
  if v_day_id is null then
    raise exception 'No active business day found. Start the day first.' using errcode = 'P0001';
  end if;

  v_shift_id := public.get_current_shift(p_tenant_id);

  insert into public.baki_transactions (
    tenant_id, customer_id, business_day_id, shift_id, business_date,
    items_description, amount, created_by_staff_id, created_by_user_id
  ) values (
    p_tenant_id, p_customer_id, v_day_id, v_shift_id, current_date,
    trim(p_items_description), p_amount, p_staff_id, auth.uid()
  );

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return v_updated_balance;
end;
$$;

-- Record Collection
create or replace function public.record_customer_collection(
  p_tenant_id uuid,
  p_customer_id uuid,
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
  v_day_id uuid;
  v_shift_id uuid;
  v_updated_balance numeric;
  v_collection_id uuid;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero.' using errcode = '22023';
  end if;
  if p_payment_method not in ('cash', 'mobile_wallet', 'bank_transfer') then
    raise exception 'Invalid payment method.' using errcode = '22023';
  end if;

  if p_staff_id is not null then
    perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);
    if not public.has_staff_permission(p_staff_id, 'meal_management', 'collections_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'collections_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  if p_payment_method = 'cash' then
    v_day_id := public.get_active_business_day(p_tenant_id);
    if v_day_id is null then
      raise exception 'No active business day found. Start the day first.' using errcode = 'P0001';
    end if;
  end if;

  v_shift_id := public.get_current_shift(p_tenant_id);

  insert into public.customer_collections (
    tenant_id, customer_id, business_day_id, shift_id, amount, payment_method,
    collected_by_user_id, collected_by_staff_id, collected_at, notes
  ) values (
    p_tenant_id, p_customer_id, v_day_id, v_shift_id, p_amount, p_payment_method,
    case when p_staff_id is null then auth.uid() else null end,
    p_staff_id, now(), p_notes
  )
  returning id into v_collection_id;

  perform public.post_ledger_entry(
    p_tenant_id := p_tenant_id,
    p_business_day_id := v_day_id,
    p_type := 'inflow',
    p_category := 'Debt Collection',
    p_amount := p_amount,
    p_payment_method := p_payment_method,
    p_operator_user_id := case when p_staff_id is null then auth.uid() else null end,
    p_operator_staff_id := p_staff_id,
    p_notes := coalesce(p_notes, 'Customer collection ' || v_collection_id::text),
    p_shift_id := v_shift_id
  );

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return v_updated_balance;
end;
$$;

-- Toggle Attendance
create or replace function public.toggle_contract_attendance(
  p_tenant_id uuid,
  p_customer_id uuid,
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
  v_day_id uuid;
  v_shift_id uuid;
  v_shift_name text;
  v_daily_rate numeric;
  v_attended_shifts text[];
  v_action text;
  v_updated_balance numeric;
begin
  if p_staff_id is not null then
    perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);
    if not public.has_staff_permission(p_staff_id, 'meal_management', 'attendance_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'attendance_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  v_day_id := public.get_active_business_day(p_tenant_id);
  if v_day_id is null then
    raise exception 'No active business day found. Start the day first.' using errcode = 'P0001';
  end if;

  v_shift_id := public.get_current_shift(p_tenant_id);
  if v_shift_id is null then
    raise exception 'No active shift found.' using errcode = 'P0001';
  end if;

  select name into v_shift_name from public.shifts where id = v_shift_id;

  select contract_daily_rate into v_daily_rate
  from public.customers
  where id = p_customer_id and tenant_id = p_tenant_id
    and category = 'contract_worker' and is_active = true;

  if v_daily_rate is null then
    raise exception 'Customer is not registered as a contract worker or has no daily rate configured.' using errcode = 'P0003';
  end if;

  select attended_shifts into v_attended_shifts
  from public.customer_daily_attendance
  where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = current_date;

  if v_attended_shifts is null then
    insert into public.customer_daily_attendance (
      tenant_id, customer_id, business_day_id, shift_id, business_date, attended_shifts, rate_applied
    ) values (
      p_tenant_id, p_customer_id, v_day_id, v_shift_id, current_date, array[v_shift_name], v_daily_rate
    );
    v_action := 'added_first_present';
  else
    if v_shift_name = any(v_attended_shifts) then
      v_attended_shifts := array_remove(v_attended_shifts, v_shift_name);
      if cardinality(v_attended_shifts) = 0 then
        delete from public.customer_daily_attendance
        where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = current_date;
        v_action := 'removed_last_present';
      else
        update public.customer_daily_attendance
        set attended_shifts = v_attended_shifts
        where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = current_date;
        v_action := 'removed_shift';
      end if;
    else
      v_attended_shifts := array_append(v_attended_shifts, v_shift_name);
      update public.customer_daily_attendance
      set attended_shifts = v_attended_shifts
      where tenant_id = p_tenant_id and customer_id = p_customer_id and business_date = current_date;
      v_action := 'added_shift';
    end if;
  end if;

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return query select v_action, v_updated_balance;
end;
$$;

-- Edit POS Sale
create or replace function public.edit_pos_sale(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_ledger_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_row public.transaction_ledger%rowtype;
  v_day_status text;
  v_window interval;
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'kiosk', 'log_pos') then
    raise exception 'Permission denied: log_pos.' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero.' using errcode = '22023';
  end if;

  if p_payment_method not in ('cash', 'mobile_wallet') then
    raise exception 'POS payment method must be cash or mobile_wallet.' using errcode = '22023';
  end if;

  select * into v_row
  from public.transaction_ledger
  where id = p_ledger_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'Ledger entry not found.' using errcode = 'P0002';
  end if;

  if v_row.category <> 'POS' then
    raise exception 'Only POS transactions can be edited.' using errcode = '22023';
  end if;

  if v_row.business_day_id is null then
    raise exception 'POS entry has no associated business day.' using errcode = '22023';
  end if;

  select status into v_day_status
  from public.business_days
  where id = v_row.business_day_id and tenant_id = p_tenant_id;

  if v_day_status is null or v_day_status = 'closed' then
    raise exception 'Cannot edit POS after the business day is closed.' using errcode = 'P0001';
  end if;

  v_window := public.pos_edit_window_interval(p_tenant_id);
  if now() >= v_row.created_at + v_window then
    raise exception 'POS edit period has expired.' using errcode = 'P0001';
  end if;

  perform set_config('app.ledger_pos_edit', 'on', true);

  update public.transaction_ledger
  set
    amount = p_amount,
    payment_method = p_payment_method,
    notes = p_notes,
    updated_at = now()
  where id = p_ledger_id
    and tenant_id = p_tenant_id;

  perform set_config('app.ledger_pos_edit', '', true);

  return p_ledger_id;
exception
  when others then
    perform set_config('app.ledger_pos_edit', '', true);
    raise;
end;
$$;


create or replace function public.list_daily_ledger_entries(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_day_id uuid
)
returns setof public.transaction_ledger
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'financial_ledger', 'session_ledger_read') then
    raise exception 'Permission denied: session_ledger_read.' using errcode = '42501';
  end if;

  return query
  select tl.*
  from public.transaction_ledger tl
  where tl.tenant_id = p_tenant_id
    and tl.business_day_id = p_day_id
  order by tl.created_at desc;
end;
$$;

-- Running Balance Kiosk
create or replace function public.get_cash_register_running_balance(
  p_tenant_id uuid,
  p_day_id uuid
)
returns numeric(12, 2)
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_opening numeric(12, 2) := 0;
  v_inflow numeric(12, 2) := 0;
  v_outflow numeric(12, 2) := 0;
begin
  select coalesce(opening_cash, 0) into v_opening
  from public.business_days
  where id = p_day_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'Business day not found.' using errcode = 'P0002';
  end if;

  select coalesce(sum(amount), 0) into v_inflow
  from public.transaction_ledger
  where tenant_id = p_tenant_id
    and business_day_id = p_day_id
    and type = 'inflow'
    and payment_method = 'cash';

  select coalesce(sum(amount), 0) into v_outflow
  from public.transaction_ledger
  where tenant_id = p_tenant_id
    and business_day_id = p_day_id
    and type = 'outflow'
    and payment_method = 'cash';

  return (v_opening + v_inflow - v_outflow);
end;
$$;


create or replace function public.get_cash_register_running_balance_kiosk(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_day_id uuid
)
returns numeric(12, 2)
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'financial_ledger', 'cash_balance_read') then
    raise exception 'Permission denied: cash_balance_read.' using errcode = '42501';
  end if;

  return public.get_cash_register_running_balance(p_tenant_id, p_day_id);
end;
$$;

-- Grants
grant execute on function public.start_business_day(text, uuid, numeric) to anon, authenticated;
grant execute on function public.end_business_day(text, uuid, uuid, numeric, text) to anon, authenticated;
grant execute on function public.resume_business_day(text, uuid, uuid) to anon, authenticated;
grant execute on function public.get_current_shift(uuid) to anon, authenticated;
grant execute on function public.get_active_business_day(uuid) to anon, authenticated;
grant execute on function public.list_daily_ledger_entries(uuid, text, uuid, uuid) to anon, authenticated;

-- Ensure RLS on business_days
alter table public.business_days enable row level security;
create policy "Users can view business_days in their tenant"
  on public.business_days for select
  using (
    public.get_day_read_scope(tenant_id) = 'all'
    or (
      public.get_day_read_scope(tenant_id) = 'self'
      and opened_by_staff_id in (
        select id from public.staff_members
        where user_id = auth.uid() and tenant_id = business_days.tenant_id
      )
    )
  );

-- Adjust RLS on transaction_ledger
drop policy if exists "Users can view ledger entries by read scope" on public.transaction_ledger;
create policy "Users can view ledger entries by read scope"
  on public.transaction_ledger for select
  using (
    exists (
      select 1 from public.user_profiles
      where id = auth.uid() and is_superadmin = true
    )
    or public.get_day_read_scope(tenant_id) = 'all'
    or (
      public.get_day_read_scope(tenant_id) = 'self'
      and (
        operator_user_id = auth.uid()
        or operator_staff_id in (
          select id from public.staff_members
          where user_id = auth.uid()
            and tenant_id = transaction_ledger.tenant_id
        )
      )
    )
  );
