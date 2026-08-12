-- Smart-Hisab RPC: Delete User Account and Cascade Tenant Data
-- Deletes the caller's user account, user_profiles, and any owned tenants & related data.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID;
  v_owned_tenant_ids UUID[];
  v_tenant_id UUID;
BEGIN
  -- 1. Identify calling user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', 'Unauthenticated request.')
    );
  END IF;

  -- 2. Find tenants where this user is an 'owner'
  SELECT ARRAY_AGG(tenant_id)
  INTO v_owned_tenant_ids
  FROM public.tenant_members
  WHERE user_id = v_user_id AND role = 'owner';

  -- 3. Delete owned tenants (triggers ON DELETE CASCADE across all tables)
  IF v_owned_tenant_ids IS NOT NULL AND ARRAY_LENGTH(v_owned_tenant_ids, 1) > 0 THEN
    FOREACH v_tenant_id IN ARRAY v_owned_tenant_ids LOOP
      DELETE FROM public.tenants WHERE id = v_tenant_id;
    END LOOP;
  END IF;

  -- 4. Delete remaining tenant memberships & user profile
  DELETE FROM public.tenant_members WHERE user_id = v_user_id;
  DELETE FROM public.user_profiles WHERE id = v_user_id;

  -- 5. Purge auth.users record
  DELETE FROM auth.users WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', SQLERRM)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
