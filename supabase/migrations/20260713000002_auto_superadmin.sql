-- Update the trigger function to automatically promote the first registered user to superadmin
create or replace function public.handle_new_user()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
declare
  v_is_first_user boolean;
begin
  -- Check if there are any superadmins in the user_profiles table.
  -- If not, this user will be promoted to superadmin.
  select not exists (
    select 1 from public.user_profiles where is_superadmin = true
  ) into v_is_first_user;

  insert into public.user_profiles (id, full_name, avatar_url, is_superadmin)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', null),
    v_is_first_user
  )
  on conflict (id) do update
  set is_superadmin = case 
    when v_is_first_user then true 
    else public.user_profiles.is_superadmin 
  end;
  return new;
end;
$$;

-- Retroactively promote the oldest user if no superadmin exists
update public.user_profiles
set is_superadmin = true
where id = (
  select id from public.user_profiles
  where not exists (select 1 from public.user_profiles where is_superadmin = true)
  order by created_at asc
  limit 1
);
