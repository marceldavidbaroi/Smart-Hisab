-- Migration: Prevent duplicate membership & owner role downgrade when joining canteen by code
CREATE OR REPLACE FUNCTION public.join_tenant_by_code(p_code TEXT)
RETURNS JSON AS $$
DECLARE
  v_invite public.tenant_invites%ROWTYPE;
  v_tenant public.tenants%ROWTYPE;
  v_existing_role TEXT;
BEGIN
  -- 1. Locate valid invite code
  SELECT * INTO v_invite FROM public.tenant_invites
  WHERE code = p_code AND used_at IS NULL AND expires_at > now();

  IF v_invite.id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite code';
  END IF;

  -- 2. Prevent user from re-joining a canteen they are already part of
  SELECT role INTO v_existing_role
  FROM public.tenant_members
  WHERE tenant_id = v_invite.tenant_id AND user_id = auth.uid();

  IF v_existing_role IS NOT NULL THEN
    IF v_existing_role = 'owner' THEN
      RAISE EXCEPTION 'You are already the owner of this canteen.';
    ELSE
      RAISE EXCEPTION 'You are already a member of this canteen.';
    END IF;
  END IF;

  -- 3. Add new membership
  INSERT INTO public.tenant_members (tenant_id, user_id, role)
  VALUES (v_invite.tenant_id, auth.uid(), v_invite.role);

  -- 4. Mark invite code as used
  UPDATE public.tenant_invites
  SET used_by = auth.uid(), used_at = now()
  WHERE id = v_invite.id;

  -- 5. Fetch tenant details
  SELECT * INTO v_tenant FROM public.tenants WHERE id = v_invite.tenant_id;

  RETURN json_build_object(
    'tenant_id', v_tenant.id,
    'name', v_tenant.name,
    'role', v_invite.role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.join_tenant_by_code(TEXT) TO authenticated;
