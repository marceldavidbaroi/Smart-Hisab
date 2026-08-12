-- Enable pgcrypto for password hashing
create extension if not exists "pgcrypto";

-- 1. Create Owner Account: owner@gmail.com / 123456
do $$
declare
  v_owner_id uuid := '11111111-1111-1111-1111-111111111111';
  v_owner_email text := 'owner@gmail.com';
  v_password text := '123456';
begin
  if not exists (select 1 from auth.users where email = v_owner_email) then
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) values (
      v_owner_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      v_owner_email, crypt(v_password, gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Owner Account"}'::jsonb, now(), now()
    );

    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
    ) values (
      v_owner_id, v_owner_id, format('{"sub": "%s", "email": "%s"}', v_owner_id::text, v_owner_email)::jsonb,
      'email', v_owner_id::text, now(), now(), now()
    );
  end if;
end $$;

-- 2. Create Manager Account: manager@gmail.com / 123456
do $$
declare
  v_manager_id uuid := '22222222-2222-2222-2222-222222222222';
  v_manager_email text := 'manager@gmail.com';
  v_password text := '123456';
begin
  if not exists (select 1 from auth.users where email = v_manager_email) then
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) values (
      v_manager_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      v_manager_email, crypt(v_password, gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"full_name":"Manager Account"}'::jsonb, now(), now()
    );

    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
    ) values (
      v_manager_id, v_manager_id, format('{"sub": "%s", "email": "%s"}', v_manager_id::text, v_manager_email)::jsonb,
      'email', v_manager_id::text, now(), now(), now()
    );
  end if;
end $$;
