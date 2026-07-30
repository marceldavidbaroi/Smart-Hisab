-- Function to automatically create a customer wallet when a new customer is created
create or replace function public.handle_new_customer_wallet()
returns trigger as $$
begin
  insert into public.customer_wallets (tenant_id, customer_id)
  values (new.tenant_id, new.id)
  on conflict (customer_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger on customers insert
drop trigger if exists on_customer_created_create_wallet on public.customers;

create trigger on_customer_created_create_wallet
  after insert on public.customers
  for each row
  execute function public.handle_new_customer_wallet();
