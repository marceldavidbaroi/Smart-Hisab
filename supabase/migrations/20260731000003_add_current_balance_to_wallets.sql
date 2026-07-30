-- 1. Add current_balance column to customer_wallets and staff_wallets
alter table public.customer_wallets 
  add column if not exists current_balance numeric(12, 2) not null default 0.00;

alter table public.staff_wallets 
  add column if not exists current_balance numeric(12, 2) not null default 0.00;

-- 2. Trigger function to update customer_wallets.current_balance on wallet_entries changes
create or replace function public.sync_customer_wallet_balance()
returns trigger as $$
declare
  target_wallet_id uuid;
begin
  if (TG_OP = 'DELETE') then
    target_wallet_id := old.wallet_id;
  else
    target_wallet_id := new.wallet_id;
  end if;

  update public.customer_wallets
  set current_balance = (
    select coalesce(
      sum(
        case 
          when type = 'meal_charge' then amount
          when type = 'payment' then -amount
          when type = 'adjustment' then amount
          else 0
        end
      ), 0.00
    )
    from public.wallet_entries
    where wallet_id = target_wallet_id
  )
  where id = target_wallet_id;

  return null;
end;
$$ language plpgsql security definer;

-- Trigger on wallet_entries
drop trigger if exists on_wallet_entries_sync_balance on public.wallet_entries;

create trigger on_wallet_entries_sync_balance
  after insert or update or delete on public.wallet_entries
  for each row
  execute function public.sync_customer_wallet_balance();


-- 3. Trigger function to update staff_wallets.current_balance on salary_payouts changes
create or replace function public.sync_staff_wallet_balance()
returns trigger as $$
declare
  target_staff_id uuid;
begin
  if (TG_OP = 'DELETE') then
    target_staff_id := old.staff_id;
  else
    target_staff_id := new.staff_id;
  end if;

  update public.staff_wallets
  set current_balance = (
    select coalesce(sum(amount), 0.00)
    from public.salary_payouts
    where staff_id = target_staff_id
  )
  where staff_id = target_staff_id;

  return null;
end;
$$ language plpgsql security definer;

-- Trigger on salary_payouts
drop trigger if exists on_salary_payouts_sync_staff_balance on public.salary_payouts;

create trigger on_salary_payouts_sync_staff_balance
  after insert or update or delete on public.salary_payouts
  for each row
  execute function public.sync_staff_wallet_balance();
