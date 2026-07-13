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
