-- Enable pgcrypto for password hashing
create extension if not exists "pgcrypto";

-- Create seeder user as superadmin if not exists
do $$
declare
  v_user_id uuid := '00000000-0000-0000-0000-000000000100';
  v_email text := 'admin@example.com';
  v_password text := 'Superadmin123!';
begin
  if not exists (select 1 from auth.users where email = v_email) then
    -- 1. Insert user
    insert into auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) values (
      v_user_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      v_email,
      crypt(v_password, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"System Superadmin"}'::jsonb,
      now(),
      now()
    );

    -- 2. Insert identity
    insert into auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    ) values (
      v_user_id,
      v_user_id,
      format('{"sub": "%s", "email": "%s"}', v_user_id::text, v_email)::jsonb,
      'email',
      v_user_id::text,
      now(),
      now(),
      now()
    );
  end if;
end $$;

-- Seed system staff roles for canteens
insert into public.staff_roles (id, tenant_id, name, description, permissions, is_system_role)
values 
  (
    '00000000-0000-0000-0000-000000000001',
    null,
    'Manager',
    'System manager role with permission to open/close sessions, manage financial entries, and oversee canteen operations',
    '{"modules": {"kiosk": {"log_pos": true, "log_expense": true, "log_advance": true, "view_active_session": true}, "operational_shifts": {"sessions_open": true, "sessions_close": true, "sessions_reopen": true}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    null,
    'Cashier',
    'System cashier role for counter meal attendance, POS logging, and customer debt collection',
    '{"modules": {"kiosk": {"log_pos": true, "log_expense": true, "log_advance": false, "view_active_session": true}, "operational_shifts": {"sessions_open": false, "sessions_close": false, "sessions_reopen": false}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    null,
    'Staff',
    'General staff role with permission to view operational status and clock attendance',
    '{"modules": {"kiosk": {"log_pos": false, "log_expense": false, "log_advance": false, "view_active_session": true}, "operational_shifts": {"sessions_open": false, "sessions_close": false, "sessions_reopen": false}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    null,
    'Kitchen Staff / Cook',
    'Kitchen staff role with access to view shift meal prep counts and log market item lists',
    '{"modules": {"kiosk": {"log_pos": false, "log_expense": false, "log_advance": false, "view_active_session": true}, "kitchen": {"view_meal_counts": true, "manage_market_notes": true}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000005',
    null,
    'Security Guard',
    'Gatekeeper staff role for dining hall entry scanning and customer meal punching',
    '{"modules": {"kiosk": {"log_pos": true, "log_expense": false, "log_advance": false, "view_active_session": true}, "gate": {"verify_customer": true}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000006',
    null,
    'Bazaar Purchaser',
    'Procurement staff role for logging market shopping costs and bazaar notes',
    '{"modules": {"kiosk": {"log_pos": false, "log_expense": true, "log_advance": false, "view_active_session": true}, "inventory": {"log_market_expense": true}}}'::jsonb,
    true
  )
on conflict (id) do update set 
  name = excluded.name,
  description = excluded.description,
  permissions = excluded.permissions,
  is_system_role = excluded.is_system_role;

