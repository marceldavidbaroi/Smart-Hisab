-- Kiosk-safe read for baki transactions (extra items / add-ons) in a session
-- Root cause: workspace RLS (has_module_permission) blocks paired-device anon clients.

create or replace function public.list_session_baki_transactions(
  p_tenant_id uuid,
  p_device_token text,
  p_staff_id uuid,
  p_session_id uuid
)
returns table (
  id uuid,
  customer_id uuid,
  customer_name text,
  items_description text,
  amount numeric,
  created_at timestamptz,
  staff_name text
)
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  perform public.assert_kiosk_staff(p_tenant_id, p_device_token, p_staff_id);

  if not public.has_staff_permission(p_staff_id, 'meal_management', 'baki_read') then
    raise exception 'Permission denied: baki_read.' using errcode = '42501';
  end if;

  return query
  select 
    b.id,
    b.customer_id,
    c.full_name as customer_name,
    b.items_description,
    b.amount,
    b.created_at,
    s.full_name as staff_name
  from public.baki_transactions b
  join public.customers c on c.id = b.customer_id
  left join public.staff_members s on s.id = b.created_by_staff_id
  where b.tenant_id = p_tenant_id
    and b.session_id = p_session_id
  order by b.created_at desc;
end;
$$;

grant execute on function public.list_session_baki_transactions(uuid, text, uuid, uuid) to anon, authenticated;
