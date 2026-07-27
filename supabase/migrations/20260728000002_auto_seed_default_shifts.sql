-- Migration: Auto Seed Default Operational Shifts on Tenant Creation

create or replace function public.create_tenant(
  p_name text,
  p_slug text
)
returns uuid
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id uuid;
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'You must be logged in to create a workspace.';
  end if;

  -- 1. Create tenant
  insert into public.tenants (name, slug)
  values (p_name, p_slug)
  returning id into v_tenant_id;

  -- 2. Create tenant settings with default active modules
  insert into public.tenant_settings (tenant_id, enabled_features)
  values (v_tenant_id, '{"shift-sessions": true, "financial-ledger": true, "meal-management": true, "procurement": true, "staff-payroll": true}'::jsonb);

  -- 3. Create tenant billing record (default free tier)
  insert into public.tenant_billing (tenant_id, subscription_tier, status)
  values (v_tenant_id, 'free', 'active');

  -- 4. Create owner member mapping
  insert into public.tenant_members (tenant_id, user_id, role_id, status)
  values (v_tenant_id, v_user_id, '00000000-0000-0000-0000-000000000001', 'active');

  -- 5. Auto seed default operational shifts
  insert into public.shifts (tenant_id, name, start_time, end_time, is_active)
  values 
    (v_tenant_id, 'Morning Slot', '06:30'::time, '11:00'::time, true),
    (v_tenant_id, 'Afternoon Slot', '11:00'::time, '15:30'::time, true),
    (v_tenant_id, 'Evening Slot', '15:30'::time, '19:30'::time, true),
    (v_tenant_id, 'Night Slot', '19:30'::time, '23:30'::time, true);

  return v_tenant_id;
end;
$$;

-- Seed default shifts for any existing tenants that do not have shifts configured
insert into public.shifts (tenant_id, name, start_time, end_time, is_active)
select t.id, s.name, s.start_time, s.end_time, true
from public.tenants t
cross join (
  values 
    ('Morning Slot', '06:30'::time, '11:00'::time),
    ('Afternoon Slot', '11:00'::time, '15:30'::time),
    ('Evening Slot', '15:30'::time, '19:30'::time),
    ('Night Slot', '19:30'::time, '23:30'::time)
) as s(name, start_time, end_time)
where not exists (
  select 1 from public.shifts existing where existing.tenant_id = t.id
);
