-- Migration: Remove customer category constraint and make category optional with default 'walk_in_baki'
-- Allows customers to be created without specifying a category (each customer can have baki or contract details directly)

-- 1. Drop check constraint on category and check_contract_worker_rate if present
alter table public.customers drop constraint if exists customers_category_check;
alter table public.customers drop constraint if exists check_contract_worker_rate;

-- 2. Make category column optional (nullable with default 'walk_in_baki')
alter table public.customers alter column category drop not null;
alter table public.customers alter column category set default 'walk_in_baki';

-- 3. Update upsert_customer function to accept nullable p_category with default 'walk_in_baki'
create or replace function public.upsert_customer(
  p_tenant_id uuid,
  p_full_name text,
  p_category text default 'walk_in_baki',
  p_phone text default null,
  p_contract_daily_rate numeric default null,
  p_contract_shifts text[] default null,
  p_factory_unit text default null,
  p_is_active boolean default true,
  p_id uuid default null,
  p_device_token text default null,
  p_staff_id uuid default null
)
returns public.customers
security definer
set search_path = public
language plpgsql
as $$
declare
  v_customer public.customers;
  v_cat text;
begin
  v_cat := coalesce(p_category, 'walk_in_baki');

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

    if not public.has_staff_permission(p_staff_id, 'meal_management', 'customer_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    if not public.has_module_permission(p_tenant_id, 'meal_management', 'customer_write') then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  if p_id is not null then
    update public.customers
    set
      full_name = p_full_name,
      category = v_cat,
      phone = p_phone,
      contract_daily_rate = p_contract_daily_rate,
      contract_shifts = p_contract_shifts,
      factory_unit = p_factory_unit,
      is_active = p_is_active,
      updated_at = now()
    where id = p_id and tenant_id = p_tenant_id
    returning * into v_customer;

    if not found then
      raise exception 'Customer not found.' using errcode = 'P0002';
    end if;
  else
    insert into public.customers (
      tenant_id,
      full_name,
      category,
      phone,
      contract_daily_rate,
      contract_shifts,
      factory_unit,
      is_active
    ) values (
      p_tenant_id,
      p_full_name,
      v_cat,
      p_phone,
      p_contract_daily_rate,
      p_contract_shifts,
      p_factory_unit,
      p_is_active
    )
    returning * into v_customer;
  end if;

  return v_customer;
end;
$$;
