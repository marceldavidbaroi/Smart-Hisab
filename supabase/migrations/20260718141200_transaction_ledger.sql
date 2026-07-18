-- Migration: Create Transaction Ledger table and associated functions / RLS / triggers
-- Created At: 2026-07-18 14:12:00

-- 1. Create transaction_ledger table
create table public.transaction_ledger (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  session_id uuid references public.sessions(id) on delete set null,
  type text not null check (type in ('inflow', 'outflow')),
  category text not null check (
    category in (
      'POS', 'Debt Collection', 'Raw Materials', 'Supplier Payout',
      'Payroll', 'Staff Advance', 'Bazar Discrepancy', 'Bazar Surplus',
      'Overhead', 'Manual Inflow', 'Manual Outflow'
    )
  ),
  amount numeric(12, 2) not null check (amount >= 0),
  payment_method text not null check (
    payment_method in ('cash', 'bank_transfer', 'mobile_wallet')
  ),
  operator_user_id uuid references auth.users(id) on delete set null,
  operator_staff_id uuid references public.staff_members(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Indexes for Performance & Search
create index idx_transaction_ledger_tenant_id
  on public.transaction_ledger (tenant_id);

create index idx_transaction_ledger_session_id
  on public.transaction_ledger (session_id);

create index idx_transaction_ledger_operator_user_id
  on public.transaction_ledger (operator_user_id);

create index idx_transaction_ledger_operator_staff_id
  on public.transaction_ledger (operator_staff_id);

create index idx_transaction_ledger_created_at
  on public.transaction_ledger (created_at desc);

create index idx_transaction_ledger_type_cat
  on public.transaction_ledger (tenant_id, type, category);

create index idx_transaction_ledger_tenant_created
  on public.transaction_ledger (tenant_id, created_at desc);

-- 3. RLS Helper & Policies
alter table public.transaction_ledger enable row level security;

create or replace function public.get_ledger_read_scope(p_tenant_id uuid)
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
    v_permissions->'modules'->'financial_ledger'->>'ledger_read',
    'none'
  );
end;
$$;

create policy "Users can view ledger entries by read scope"
  on public.transaction_ledger for select
  using (
    exists (
      select 1 from public.user_profiles
      where id = auth.uid() and is_superadmin = true
    )
    or public.get_ledger_read_scope(tenant_id) = 'all'
    or (
      public.get_ledger_read_scope(tenant_id) = 'self'
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

create policy "Users can insert ledger when manual write allowed"
  on public.transaction_ledger for insert
  with check (
    public.has_module_permission(tenant_id, 'financial_ledger', 'ledger_write_manual')
  );

create policy "Ledger entries cannot be updated"
  on public.transaction_ledger for update
  using (false);

create policy "Ledger entries cannot be deleted"
  on public.transaction_ledger for delete
  using (false);

-- 4. Triggers for Immutability & Session Lock
create or replace function public.block_ledger_modifications()
returns trigger
language plpgsql
as $$
begin
  raise exception
    'Immutable Ledger Rule: updates and deletions of ledger transactions are prohibited.'
    using errcode = 'P0001';
  return null;
end;
$$;

create trigger enforce_ledger_immutability
before update or delete on public.transaction_ledger
for each row
execute function public.block_ledger_modifications();

create trigger check_transaction_session_lock
before insert or update or delete on public.transaction_ledger
for each row
execute function public.enforce_closed_session_lock();

-- 5. RPC Implementations
create or replace function public.post_ledger_entry(
  p_tenant_id uuid,
  p_session_id uuid,
  p_type text,
  p_category text,
  p_amount numeric,
  p_payment_method text,
  p_operator_user_id uuid default null,
  p_operator_staff_id uuid default null,
  p_notes text default null
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

  if p_category not in (
    'POS', 'Debt Collection', 'Raw Materials', 'Supplier Payout',
    'Payroll', 'Staff Advance', 'Bazar Discrepancy', 'Bazar Surplus',
    'Overhead', 'Manual Inflow', 'Manual Outflow'
  ) then
    raise exception 'Invalid ledger category.' using errcode = '22023';
  end if;

  insert into public.transaction_ledger (
    tenant_id, session_id, type, category, amount, payment_method,
    operator_user_id, operator_staff_id, notes
  )
  values (
    p_tenant_id, p_session_id, p_type, p_category, p_amount, p_payment_method,
    p_operator_user_id, p_operator_staff_id, p_notes
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.log_manual_ledger_entry(
  p_tenant_id uuid,
  p_session_id uuid,
  p_type text,
  p_category text,
  p_amount numeric,
  p_payment_method text,
  p_notes text default null
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  if not public.has_module_permission(p_tenant_id, 'financial_ledger', 'ledger_write_manual') then
    raise exception 'Permission denied: ledger_write_manual.' using errcode = '42501';
  end if;

  if p_category not in ('Overhead', 'Manual Inflow', 'Manual Outflow') then
    raise exception 'Manual entries must use Overhead, Manual Inflow, or Manual Outflow.'
      using errcode = '22023';
  end if;

  if p_category = 'Manual Inflow' and p_type <> 'inflow' then
    raise exception 'Manual Inflow requires type inflow.' using errcode = '22023';
  end if;

  if p_category in ('Manual Outflow', 'Overhead') and p_type <> 'outflow' then
    raise exception 'Overhead / Manual Outflow require type outflow.' using errcode = '22023';
  end if;

  return public.post_ledger_entry(
    p_tenant_id,
    p_session_id,
    p_type,
    p_category,
    p_amount,
    p_payment_method,
    auth.uid(),
    null,
    p_notes
  );
end;
$$;

create or replace function public.get_tenant_financial_summary(
  p_tenant_id uuid,
  p_start_date timestamptz,
  p_end_date timestamptz
)
returns table (
  total_inflow numeric(12, 2),
  total_outflow numeric(12, 2),
  net_profit_loss numeric(12, 2),
  outstanding_receivables numeric(12, 2),
  outstanding_payables numeric(12, 2),
  cash_sales_pos numeric(12, 2),
  market_expenses numeric(12, 2),
  payroll_expenses numeric(12, 2)
)
security definer
stable
set search_path = public
language plpgsql
as $$
declare
  v_inflow numeric(12, 2) := 0;
  v_outflow numeric(12, 2) := 0;
  v_receivables numeric(12, 2) := 0;
  v_payables numeric(12, 2) := 0;
  v_pos numeric(12, 2) := 0;
  v_market numeric(12, 2) := 0;
  v_payroll numeric(12, 2) := 0;
begin
  if not public.has_module_permission(p_tenant_id, 'financial_ledger', 'dashboard_read') then
    raise exception 'Permission denied: dashboard_read.' using errcode = '42501';
  end if;

  select
    coalesce(sum(case when type = 'inflow' then amount else 0 end), 0),
    coalesce(sum(case when type = 'outflow' then amount else 0 end), 0),
    coalesce(sum(case when category = 'POS' then amount else 0 end), 0),
    coalesce(sum(case when category = 'Raw Materials' then amount else 0 end), 0),
    coalesce(sum(case when category = 'Payroll' then amount else 0 end), 0)
  into v_inflow, v_outflow, v_pos, v_market, v_payroll
  from public.transaction_ledger
  where tenant_id = p_tenant_id
    and created_at >= p_start_date
    and created_at <= p_end_date;

  if to_regclass('public.customers') is not null then
    execute format(
      'select coalesce(sum(outstanding_balance), 0) from public.customers where tenant_id = %L',
      p_tenant_id
    ) into v_receivables;
  end if;

  if to_regclass('public.suppliers') is not null then
    execute format(
      'select coalesce(sum(outstanding_balance), 0) from public.suppliers where tenant_id = %L',
      p_tenant_id
    ) into v_payables;
  end if;

  return query
  select
    v_inflow,
    v_outflow,
    (v_inflow - v_outflow),
    v_receivables,
    v_payables,
    v_pos,
    v_market,
    v_payroll;
end;
$$;

create or replace function public.get_cash_register_running_balance(
  p_tenant_id uuid,
  p_session_id uuid
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
  from public.sessions
  where id = p_session_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'Session not found.' using errcode = 'P0002';
  end if;

  select coalesce(sum(amount), 0) into v_inflow
  from public.transaction_ledger
  where tenant_id = p_tenant_id
    and session_id = p_session_id
    and type = 'inflow'
    and payment_method = 'cash';

  select coalesce(sum(amount), 0) into v_outflow
  from public.transaction_ledger
  where tenant_id = p_tenant_id
    and session_id = p_session_id
    and type = 'outflow'
    and payment_method = 'cash';

  return (v_opening + v_inflow - v_outflow);
end;
$$;

create or replace function public.get_daily_financial_breakdown(
  p_tenant_id uuid,
  p_start_date date,
  p_end_date date
)
returns table (
  transaction_date date,
  total_inflow numeric(12, 2),
  total_outflow numeric(12, 2),
  net_profit numeric(12, 2),
  pos_sales numeric(12, 2),
  debt_collections numeric(12, 2),
  raw_materials numeric(12, 2),
  payroll_expenses numeric(12, 2),
  supplier_payouts numeric(12, 2),
  staff_advances numeric(12, 2),
  bazar_discrepancies numeric(12, 2),
  bazar_surpluses numeric(12, 2),
  overhead_expenses numeric(12, 2),
  manual_inflows numeric(12, 2),
  manual_outflows numeric(12, 2)
)
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  if not public.has_module_permission(p_tenant_id, 'financial_ledger', 'dashboard_read') then
    raise exception 'Permission denied: dashboard_read.' using errcode = '42501';
  end if;

  return query
  select
    (tl.created_at at time zone 'UTC')::date as transaction_date,
    coalesce(sum(case when tl.type = 'inflow' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.type = 'outflow' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.type = 'inflow' then tl.amount else 0 end), 0)
      - coalesce(sum(case when tl.type = 'outflow' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'POS' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Debt Collection' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Raw Materials' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Payroll' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Supplier Payout' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Staff Advance' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Bazar Discrepancy' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Bazar Surplus' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Overhead' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Manual Inflow' then tl.amount else 0 end), 0),
    coalesce(sum(case when tl.category = 'Manual Outflow' then tl.amount else 0 end), 0)
  from public.transaction_ledger tl
  where tl.tenant_id = p_tenant_id
    and (tl.created_at at time zone 'UTC')::date >= p_start_date
    and (tl.created_at at time zone 'UTC')::date <= p_end_date
  group by (tl.created_at at time zone 'UTC')::date
  order by 1 desc;
end;
$$;

-- 6. Execute Grants
grant execute on function public.log_manual_ledger_entry(uuid, uuid, text, text, numeric, text, text)
  to authenticated;

grant execute on function public.get_tenant_financial_summary(uuid, timestamptz, timestamptz)
  to authenticated;

grant execute on function public.get_daily_financial_breakdown(uuid, date, date)
  to authenticated;

grant execute on function public.get_cash_register_running_balance(uuid, uuid)
  to authenticated;

-- Internal helper: no grant to anon/authenticated (called only from other definer RPCs)
revoke all on function public.post_ledger_entry(
  uuid, uuid, text, text, numeric, text, uuid, uuid, text
) from public;

-- 7. Update Default Roles' JSONB Permissions
update public.tenant_roles
set permissions = jsonb_set(
  permissions,
  '{modules,financial_ledger}',
  '{"ledger_read": "all", "ledger_write_manual": false, "dashboard_read": true}'::jsonb
)
where tenant_id is null and name = 'Admin';

update public.tenant_roles
set permissions = jsonb_set(
  permissions,
  '{modules,financial_ledger}',
  '{"ledger_read": "self", "ledger_write_manual": false, "dashboard_read": false}'::jsonb
)
where tenant_id is null and name = 'Member';

update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,financial_ledger}',
  '{"session_ledger_read": true, "cash_balance_read": true}'::jsonb
)
where tenant_id is null and name = 'Manager';

update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,financial_ledger}',
  '{"session_ledger_read": true, "cash_balance_read": true}'::jsonb
)
where tenant_id is null and name = 'Cashier';

update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,financial_ledger}',
  '{"session_ledger_read": false, "cash_balance_read": false}'::jsonb
)
where tenant_id is null and name = 'Staff';
