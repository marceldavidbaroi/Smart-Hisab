-- Create staff_wallets table
create table if not exists public.staff_wallets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  staff_id uuid not null unique references public.staff_members(id) on delete cascade,
  current_balance numeric(12, 2) not null default 0.00,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_staff_wallets_tenant on public.staff_wallets(tenant_id);
create index if not exists idx_staff_wallets_staff on public.staff_wallets(staff_id);

alter table public.staff_wallets enable row level security;

create policy "Staff wallets tenant access"
  on public.staff_wallets
  for all
  using (
    tenant_id in (
      select tenant_id from public.tenant_members where user_id = auth.uid()
    )
  );

-- Function to automatically create a staff wallet when a new staff member is created
create or replace function public.handle_new_staff_wallet()
returns trigger as $$
begin
  insert into public.staff_wallets (tenant_id, staff_id)
  values (new.tenant_id, new.id)
  on conflict (staff_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger on staff_members insert
drop trigger if exists on_staff_created_create_wallet on public.staff_members;

create trigger on_staff_created_create_wallet
  after insert on public.staff_members
  for each row
  execute function public.handle_new_staff_wallet();
