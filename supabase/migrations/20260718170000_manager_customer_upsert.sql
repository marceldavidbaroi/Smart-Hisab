-- Manager gets customer_write; Cashier stays false
update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "customer_write": true, "attendance_read": true, "attendance_write": true, "baki_read": true, "baki_write": true, "collections_read": true, "collections_write": true}'::jsonb
)
where name = 'Manager';

update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "customer_write": false, "attendance_read": true, "attendance_write": true, "baki_read": true, "baki_write": true, "collections_read": true, "collections_write": true}'::jsonb
)
where name = 'Cashier';

create or replace function public.upsert_customer(
  p_tenant_id uuid,
  p_full_name text,
  p_category text,
  p_phone text,
  p_contract_daily_rate numeric,
  p_contract_shifts text[],
  p_factory_unit text,
  p_is_active boolean,
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
begin
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
      category = p_category,
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
      p_category,
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

grant execute on function public.upsert_customer(uuid, text, text, text, numeric, text[], text, boolean, uuid, text, uuid) to authenticated;
