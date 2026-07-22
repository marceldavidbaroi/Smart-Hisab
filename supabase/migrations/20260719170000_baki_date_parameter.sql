-- Drop the old record_baki_transaction function signature
drop function if exists public.record_baki_transaction(uuid, uuid, uuid, text, numeric, text, uuid);

-- Recreate record_baki_transaction with p_business_date parameter
create or replace function public.record_baki_transaction(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,
  p_items_description text,
  p_amount numeric,
  p_device_token text default null,
  p_staff_id uuid default null,
  p_business_date date default null
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
    p_tenant_id, p_customer_id, p_session_id, coalesce(p_business_date, v_business_date),
    trim(p_items_description), p_amount, p_staff_id, auth.uid()
  );

  select outstanding_balance into v_updated_balance
  from public.customers where id = p_customer_id;

  return v_updated_balance;
end;
$$;

-- Grant execution permissions
grant execute on function public.record_baki_transaction(uuid, uuid, uuid, text, numeric, text, uuid, date) to anon, authenticated;
