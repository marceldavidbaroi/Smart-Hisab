-- Smart-Hisab RPC: Delete Canteen (Owner) & Leave Canteen (Manager)

-- 1. Delete Canteen RPC (Owner only)
CREATE OR REPLACE FUNCTION public.delete_canteen(p_tenant_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID;
  v_role TEXT;
BEGIN
  -- 1. Identify calling user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', 'Unauthenticated request.')
    );
  END IF;

  -- 2. Verify caller is an owner of the target tenant
  SELECT role INTO v_role
  FROM public.tenant_members
  WHERE tenant_id = p_tenant_id AND user_id = v_user_id;

  IF v_role IS NULL OR v_role != 'owner' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', 'Only canteen owners can delete a canteen.')
    );
  END IF;

  -- 3. Delete tenant (Triggers ON DELETE CASCADE across all child tables)
  DELETE FROM public.tenants WHERE id = p_tenant_id;

  RETURN jsonb_build_object('success', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', SQLERRM)
    );
END;
$$;

-- 2. Leave Canteen RPC (Managers/Non-owners)
CREATE OR REPLACE FUNCTION public.leave_canteen(p_tenant_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID;
  v_role TEXT;
BEGIN
  -- 1. Identify calling user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', 'Unauthenticated request.')
    );
  END IF;

  -- 2. Verify membership & role
  SELECT role INTO v_role
  FROM public.tenant_members
  WHERE tenant_id = p_tenant_id AND user_id = v_user_id;

  IF v_role IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', 'You are not a member of this canteen.')
    );
  END IF;

  IF v_role = 'owner' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', 'Canteen owners cannot leave. You must delete the canteen or transfer ownership.')
    );
  END IF;

  -- 3. Remove tenant membership
  DELETE FROM public.tenant_members
  WHERE tenant_id = p_tenant_id AND user_id = v_user_id;

  RETURN jsonb_build_object('success', true);
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object('message', SQLERRM)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_canteen(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_canteen(UUID) TO authenticated;
