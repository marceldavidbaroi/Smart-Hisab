-- Migration: Add RPC for users to delete their own account

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();
  
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Deleting the user from auth.users will cascade to public.user_profiles
  delete from auth.users where id = v_uid;
end;
$$;

-- Grant execution to authenticated users
grant execute on function public.delete_own_account() to authenticated;
