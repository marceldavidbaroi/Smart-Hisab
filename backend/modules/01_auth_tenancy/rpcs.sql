-- ==============================================================================
-- MODULE 1: AUTH & MULTI-TENANCY (RPCS & FUNCTIONS)
-- Purpose: Authentication triggers, tenant lifecycle, invite code redemption,
--          member management, and account deletion.
-- ==============================================================================

-- 1. Helper: Check if current user is member of tenant
CREATE OR REPLACE FUNCTION public.is_tenant_member(p_tenant_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.tenant_members
        WHERE tenant_id = p_tenant_id
        AND user_id = auth.uid()
        AND is_active = true
    );
$$;

-- 2. Helper: Check if current user is owner of tenant
CREATE OR REPLACE FUNCTION public.is_tenant_owner(p_tenant_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.tenant_members
        WHERE tenant_id = p_tenant_id
        AND user_id = auth.uid()
        AND role = 'owner'
        AND is_active = true
    );
$$;

-- 3. Helper: Check if user is superadmin
CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
    SELECT COALESCE(
        (SELECT is_superadmin FROM public.user_profiles WHERE id = auth.uid()),
        false
    );
$$;

-- 4. Helper: Get all tenant IDs user belongs to (RLS non-recursive)
CREATE OR REPLACE FUNCTION public.get_my_tenant_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
    SELECT tenant_id FROM public.tenant_members
    WHERE user_id = auth.uid()
    AND is_active = true;
$$;

-- 5. Trigger: Auto-create user_profile on auth.users sign-up
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url, phone)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone', '')
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = CASE WHEN public.user_profiles.full_name = '' THEN EXCLUDED.full_name ELSE public.user_profiles.full_name END,
        phone = CASE WHEN public.user_profiles.phone IS NULL OR public.user_profiles.phone = '' THEN EXCLUDED.phone ELSE public.user_profiles.phone END,
        updated_at = now();
    RETURN NEW;
END;
$$;

-- 6. RPC: Create a new tenant & assign current user as Owner
CREATE OR REPLACE FUNCTION public.create_tenant(p_name TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_tenant_id UUID;
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Create tenant
    INSERT INTO public.tenants (name)
    VALUES (p_name)
    RETURNING id INTO v_tenant_id;

    -- Add current user as owner
    INSERT INTO public.tenant_members (tenant_id, user_id, role)
    VALUES (v_tenant_id, v_user_id, 'owner');

    -- Seed default shifts (Breakfast, Lunch, Dinner)
    INSERT INTO public.shifts (tenant_id, name, start_time, end_time, sort_order)
    VALUES
        (v_tenant_id, 'Breakfast', '06:00:00', '11:00:00', 1),
        (v_tenant_id, 'Lunch',     '11:00:00', '16:00:00', 2),
        (v_tenant_id, 'Dinner',    '16:00:00', '23:59:59', 3);

    RETURN jsonb_build_object(
        'success', true,
        'tenant_id', v_tenant_id,
        'name', p_name,
        'role', 'owner'
    );
END;
$$;

-- 7. RPC: Generate a 6-digit invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code(
    p_tenant_id UUID,
    p_role TEXT DEFAULT 'manager'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_code TEXT;
    v_expires_at TIMESTAMPTZ := now() + INTERVAL '7 days';
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized: Not a member of this tenant';
    END IF;

    -- Generate random 6-digit alphanumeric code
    v_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 6));

    INSERT INTO public.tenant_invites (tenant_id, invite_code, role, created_by, expires_at, max_uses)
    VALUES (p_tenant_id, v_code, p_role, auth.uid(), v_expires_at, 5);

    RETURN jsonb_build_object(
        'success', true,
        'invite_code', v_code,
        'expires_at', v_expires_at,
        'role', p_role
    );
END;
$$;

-- 8. RPC: Join tenant by invite code
CREATE OR REPLACE FUNCTION public.join_tenant_by_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_invite RECORD;
    v_user_id UUID := auth.uid();
    v_tenant_name TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_invite
    FROM public.tenant_invites
    WHERE upper(invite_code) = upper(p_code)
      AND is_active = true
      AND expires_at > now()
      AND uses_count < max_uses;

    IF v_invite IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired invite code';
    END IF;

    -- Check if already member
    IF EXISTS (
        SELECT 1 FROM public.tenant_members
        WHERE tenant_id = v_invite.tenant_id
          AND user_id = v_user_id
          AND is_active = true
    ) THEN
        SELECT name INTO v_tenant_name FROM public.tenants WHERE id = v_invite.tenant_id;
        RETURN jsonb_build_object(
            'success', true,
            'tenant_id', v_invite.tenant_id,
            'tenant_name', v_tenant_name,
            'role', v_invite.role,
            'message', 'Already a member of this canteen'
        );
    END IF;

    -- Add membership
    INSERT INTO public.tenant_members (tenant_id, user_id, role)
    VALUES (v_invite.tenant_id, v_user_id, v_invite.role)
    ON CONFLICT (tenant_id, user_id)
    DO UPDATE SET is_active = true, role = EXCLUDED.role, updated_at = now();

    -- Increment usage
    UPDATE public.tenant_invites
    SET uses_count = uses_count + 1
    WHERE id = v_invite.id;

    SELECT name INTO v_tenant_name FROM public.tenants WHERE id = v_invite.tenant_id;

    RETURN jsonb_build_object(
        'success', true,
        'tenant_id', v_invite.tenant_id,
        'tenant_name', v_tenant_name,
        'role', v_invite.role
    );
END;
$$;

-- 9. RPC: Leave a canteen
CREATE OR REPLACE FUNCTION public.leave_canteen(p_tenant_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_role TEXT;
    v_other_owners INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT role INTO v_role
    FROM public.tenant_members
    WHERE tenant_id = p_tenant_id AND user_id = v_user_id AND is_active = true;

    IF v_role IS NULL THEN
        RAISE EXCEPTION 'Not a member of this canteen';
    END IF;

    IF v_role = 'owner' THEN
        SELECT count(*) INTO v_other_owners
        FROM public.tenant_members
        WHERE tenant_id = p_tenant_id AND role = 'owner' AND user_id != v_user_id AND is_active = true;

        IF v_other_owners = 0 THEN
            RAISE EXCEPTION 'Sole owner cannot leave canteen. Transfer ownership or delete canteen instead.';
        END IF;
    END IF;

    DELETE FROM public.tenant_members
    WHERE tenant_id = p_tenant_id AND user_id = v_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 10. RPC: Delete canteen (Owner only)
CREATE OR REPLACE FUNCTION public.delete_canteen(p_tenant_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF NOT public.is_tenant_owner(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized: Only canteen owner can delete the canteen';
    END IF;

    DELETE FROM public.tenants WHERE id = p_tenant_id;
    RETURN jsonb_build_object('success', true);
END;
$$;

-- 11. RPC: Delete user account
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM auth.users WHERE id = v_user_id;
    RETURN jsonb_build_object('success', true);
END;
$$;
