-- Kiosk-safe read for attendance list
-- Root cause: workspace RLS (has_module_permission) blocks paired-device anon clients.

create or replace function public.list_attendance_for_date(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_business_date date
)
returns setof public.customer_daily_attendance
security definer
set search_path = public
language plpgsql
as $$
begin
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

  if not public.has_staff_permission(p_staff_id, 'meal_management', 'attendance_read') then
    raise exception 'Permission denied.' using errcode = '42501';
  end if;

  return query
  select a.*
  from public.customer_daily_attendance a
  where a.tenant_id = p_tenant_id
    and a.business_date = p_business_date;
end;
$$;

grant execute on function public.list_attendance_for_date(uuid, text, uuid, date) to anon, authenticated;
