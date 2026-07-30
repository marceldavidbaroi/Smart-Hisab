-- Migration: Master Entity Architecture Tables & Financial Reporting Engine
-- Implements entities specified in docs/master_entity_architecture.md

-- 1. staff_attendance Table
create table if not exists public.staff_attendance (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  business_day_id uuid references public.business_days(id) on delete set null,
  shift_id uuid references public.shifts(id) on delete set null,
  status text not null check (status in ('present', 'absent', 'half_day')),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists idx_staff_attendance_tenant on public.staff_attendance(tenant_id);
create index if not exists idx_staff_attendance_staff on public.staff_attendance(staff_id);
create index if not exists idx_staff_attendance_day on public.staff_attendance(business_day_id);

alter table public.staff_attendance enable row level security;

create policy "Staff attendance tenant access"
  on public.staff_attendance
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 2. salary_payouts Table
create table if not exists public.salary_payouts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  business_day_id uuid references public.business_days(id) on delete set null,
  amount numeric(12, 2) not null check (amount > 0),
  payment_mode text not null default 'cash' check (payment_mode in ('cash', 'bank', 'mobile_money')),
  notes text,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_salary_payouts_tenant on public.salary_payouts(tenant_id);
create index if not exists idx_salary_payouts_staff on public.salary_payouts(staff_id);
create index if not exists idx_salary_payouts_day on public.salary_payouts(business_day_id);

alter table public.salary_payouts enable row level security;

create policy "Salary payouts tenant access"
  on public.salary_payouts
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 3. customer_wallets Table
create table if not exists public.customer_wallets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_id uuid not null unique references public.customers(id) on delete cascade,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_customer_wallets_tenant on public.customer_wallets(tenant_id);

alter table public.customer_wallets enable row level security;

create policy "Customer wallets tenant access"
  on public.customer_wallets
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 4. wallet_entries Table
create table if not exists public.wallet_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  wallet_id uuid not null references public.customer_wallets(id) on delete cascade,
  business_day_id uuid references public.business_days(id) on delete set null,
  shift_id uuid references public.shifts(id) on delete set null,
  type text not null check (type in ('meal_charge', 'payment', 'adjustment')),
  amount numeric(12, 2) not null,
  reference_type text check (reference_type in ('meal_attendance', 'cash_collection', 'manual_adjustment')),
  reference_id uuid,
  notes text,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_wallet_entries_tenant on public.wallet_entries(tenant_id);
create index if not exists idx_wallet_entries_wallet on public.wallet_entries(wallet_id);
create index if not exists idx_wallet_entries_day on public.wallet_entries(business_day_id);

alter table public.wallet_entries enable row level security;

create policy "Wallet entries tenant access"
  on public.wallet_entries
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 5. meal_configs Table
create table if not exists public.meal_configs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  shift_id uuid references public.shifts(id) on delete set null,
  rate numeric(10, 2) not null check (rate >= 0),
  effective_from date not null default current_date,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_meal_configs_tenant on public.meal_configs(tenant_id);
create index if not exists idx_meal_configs_shift on public.meal_configs(shift_id);

alter table public.meal_configs enable row level security;

create policy "Meal configs tenant access"
  on public.meal_configs
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 6. meal_attendance Table
create table if not exists public.meal_attendance (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  business_day_id uuid references public.business_days(id) on delete set null,
  shift_id uuid references public.shifts(id) on delete set null,
  charge_amount numeric(10, 2) not null default 0,
  recorded_by_staff_id uuid references public.staff_members(id) on delete set null,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_meal_attendance_tenant on public.meal_attendance(tenant_id);
create index if not exists idx_meal_attendance_customer on public.meal_attendance(customer_id);
create index if not exists idx_meal_attendance_day on public.meal_attendance(business_day_id);

alter table public.meal_attendance enable row level security;

create policy "Meal attendance tenant access"
  on public.meal_attendance
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 7. day_entries Table
create table if not exists public.day_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  business_day_id uuid references public.business_days(id) on delete set null,
  shift_id uuid references public.shifts(id) on delete set null,
  entry_type text not null check (entry_type in ('inflow', 'outflow')),
  category text not null check (category in ('customer_payment', 'market_cost', 'canteen_expense', 'salary_outflow', 'misc_earn')),
  amount numeric(12, 2) not null check (amount > 0),
  reference_type text check (reference_type in ('wallet_entry', 'salary_payout', 'direct_expense', 'direct_income')),
  reference_id uuid,
  notes text,
  created_by_staff_id uuid references public.staff_members(id) on delete set null,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_day_entries_tenant on public.day_entries(tenant_id);
create index if not exists idx_day_entries_day on public.day_entries(business_day_id);
create index if not exists idx_day_entries_category on public.day_entries(category);

alter table public.day_entries enable row level security;

create policy "Day entries tenant access"
  on public.day_entries
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 8. day_notes Table
create table if not exists public.day_notes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  business_day_id uuid references public.business_days(id) on delete set null,
  note_type text not null check (note_type in ('market_list', 'general_note', 'issue')),
  content text not null,
  created_by_staff_id uuid references public.staff_members(id) on delete set null,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_day_notes_tenant on public.day_notes(tenant_id);
create index if not exists idx_day_notes_day on public.day_notes(business_day_id);

alter table public.day_notes enable row level security;

create policy "Day notes tenant access"
  on public.day_notes
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- 9. Financial Reporting Engine RPC Function
create or replace function public.get_financial_summary(
  p_tenant_id uuid,
  p_start_date date,
  p_end_date date
)
returns table (
  total_meal_billed numeric,
  total_customer_payments numeric,
  total_market_cost numeric,
  total_canteen_expenses numeric,
  total_salary_outflow numeric,
  net_cash_flow numeric,
  net_profit_loss numeric
) as $$
begin
  return query
  with wallet_summary as (
    select 
      coalesce(sum(case when type = 'meal_charge' then amount else 0 end), 0) as meal_billed,
      coalesce(sum(case when type = 'payment' then amount else 0 end), 0) as payments
    from public.wallet_entries
    where tenant_id = p_tenant_id
      and created_at::date between p_start_date and p_end_date
  ),
  day_summary as (
    select 
      coalesce(sum(case when category = 'market_cost' then amount else 0 end), 0) as market_cost,
      coalesce(sum(case when category = 'canteen_expense' then amount else 0 end), 0) as canteen_expenses,
      coalesce(sum(case when category = 'salary_outflow' then amount else 0 end), 0) as salary_outflow,
      coalesce(sum(case when category = 'misc_earn' then amount else 0 end), 0) as misc_earn
    from public.day_entries
    where tenant_id = p_tenant_id
      and created_at::date between p_start_date and p_end_date
  )
  select 
    ws.meal_billed,
    ws.payments,
    ds.market_cost,
    ds.canteen_expenses,
    ds.salary_outflow,
    -- Net Cash Flow: Cash Received (Payments + Misc Earn) - Cash Spent
    (ws.payments + ds.misc_earn) - (ds.market_cost + ds.canteen_expenses + ds.salary_outflow) as net_cash_flow,
    -- Net Profit/Loss: Billed Revenue + Misc Earn - Expenses
    (ws.meal_billed + ds.misc_earn) - (ds.market_cost + ds.canteen_expenses + ds.salary_outflow) as net_profit_loss
  from wallet_summary ws, day_summary ds;
end;
$$ language plpgsql stable security definer;
