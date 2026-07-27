-- Migration: Remove category requirement and allow any customer to have both attendance and baki

-- 1. Drop category default on customers table so it doesn't auto-set 'walk_in_baki'
alter table public.customers alter column category drop default;

-- 2. Update toggle_contract_attendance RPC to remove category = 'contract_worker' restriction
-- and accept an optional p_daily_rate parameter to dynamically register attendance rate for any customer.
create or replace function public.toggle_contract_attendance(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,
  p_shift_name text,
  p_device_token text default null,
  p_staff_id uuid default null,
  p_daily_rate numeric default null
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
    if p_device_token is not null and p_device_token <> 'demo_device_token' then
      if not exists (
        select 1 from public.paired_devices
        where device_token = p_device_token
          and tenant_id = p_tenant_id
          and is_active = true
      ) then
        raise exception 'Invalid or inactive device.' using errcode = '42501';
      end if;
    end if;

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

  -- Get existing customer daily rate
  select contract_daily_rate into v_daily_rate
  from public.customers
  where id = p_customer_id and tenant_id = p_tenant_id and is_active = true;

  -- If customer doesn't have a rate set, use p_daily_rate if provided and update customer
  if v_daily_rate is null or v_daily_rate <= 0 then
    if p_daily_rate is not null and p_daily_rate > 0 then
      v_daily_rate := p_daily_rate;
      update public.customers
      set contract_daily_rate = p_daily_rate,
          updated_at = now()
      where id = p_customer_id;
    else
      raise exception 'Customer has no daily contract rate configured. Please provide a rate.' using errcode = 'P0003';
    end if;
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

-- Grant execution
grant execute on function public.toggle_contract_attendance(uuid, uuid, uuid, text, text, uuid, numeric) to authenticated, anon;
