-- Migration: Fix get_customer_statement_kiosk permissions and default parameters

create or replace function public.get_customer_statement_kiosk(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_days_count integer default 30,
  p_device_token text default null,
  p_staff_id uuid default null
)
returns table (
  unique_id text,
  event_date text,
  event_type text,
  description text,
  amount numeric,
  method text,
  notes text,
  session_id uuid
)
security definer
set search_path = public
language plpgsql
as $$
begin
  -- Validate permissions for staff vs standard authenticated user
  if p_staff_id is not null then
    -- Validate device token if provided (skip if demo token)
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

    -- Validate staff exists and is active in tenant
    if not exists (
      select 1 from public.staff_members
      where id = p_staff_id
        and tenant_id = p_tenant_id
        and is_active = true
    ) then
      raise exception 'Invalid staff member for tenant.' using errcode = '42501';
    end if;

    -- Check staff read permissions (accept customer_read, statement_read, attendance_read, or baki_read)
    if not (
      public.has_staff_permission(p_staff_id, 'meal_management', 'customer_read') or
      public.has_staff_permission(p_staff_id, 'meal_management', 'statement_read') or
      public.has_staff_permission(p_staff_id, 'meal_management', 'attendance_read') or
      public.has_staff_permission(p_staff_id, 'meal_management', 'baki_read')
    ) then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  else
    -- Fallback for standard logged-in user session
    if not (
      public.has_module_permission(p_tenant_id, 'meal_management', 'customer_read') or
      public.has_module_permission(p_tenant_id, 'meal_management', 'statement_read')
    ) then
      raise exception 'Permission denied.' using errcode = '42501';
    end if;
  end if;

  return query
  -- Attendance
  select 
    'att-' || a.id::text as unique_id,
    a.business_date::text as event_date,
    'attendance'::text as event_type,
    'Daily contract charge'::text as description,
    a.rate_applied as amount,
    null::text as method,
    null::text as notes,
    a.session_id
  from public.customer_daily_attendance a
  where a.tenant_id = p_tenant_id
    and a.customer_id = p_customer_id
    and a.business_date >= (current_date - p_days_count)

  union all

  -- Baki Charges
  select 
    'baki-' || b.id::text as unique_id,
    b.business_date::text as event_date,
    'baki'::text as event_type,
    b.items_description as description,
    b.amount,
    null::text as method,
    null::text as notes,
    b.session_id
  from public.baki_transactions b
  where b.tenant_id = p_tenant_id
    and b.customer_id = p_customer_id
    and b.business_date >= (current_date - p_days_count)

  union all

  -- Collections
  select 
    'col-' || c.id::text as unique_id,
    c.collected_at::text as event_date,
    'collection'::text as event_type,
    'Collection'::text as description,
    c.amount,
    c.payment_method as method,
    c.notes,
    c.session_id
  from public.customer_collections c
  where c.tenant_id = p_tenant_id
    and c.customer_id = p_customer_id
    and c.collected_at >= (now() - (p_days_count || ' days')::interval)

  order by event_date desc;
end;
$$;

grant execute on function public.get_customer_statement_kiosk(uuid, uuid, integer, text, uuid) to anon, authenticated;
