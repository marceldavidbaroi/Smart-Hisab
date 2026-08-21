-- ==============================================================================
-- DOMAIN 06: STAFF & PAYROLL — RPCS, FUNCTIONS & TRIGGERS
-- ==============================================================================

-- 1. Trigger: Auto-create staff wallet on new staff registration
CREATE OR REPLACE FUNCTION public.handle_new_staff()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    INSERT INTO public.staff_wallets (tenant_id, staff_id)
    VALUES (NEW.tenant_id, NEW.id)
    ON CONFLICT (staff_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_staff_created ON public.staff_members;
CREATE TRIGGER on_staff_created
    AFTER INSERT ON public.staff_members
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_staff();

-- 2. RPC: Record Staff Salary or Advance Payout
CREATE OR REPLACE FUNCTION public.record_salary_payout_v2(
    p_tenant_id UUID,
    p_staff_id UUID,
    p_canteen_account_id UUID,
    p_amount NUMERIC,
    p_payout_type TEXT DEFAULT 'salary',
    p_payout_month DATE DEFAULT NULL,
    p_business_day_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_account RECORD;
    v_staff RECORD;
    v_payout_id UUID;
    v_category TEXT;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Payout amount must be greater than zero';
    END IF;

    IF p_payout_type NOT IN ('advance', 'salary') THEN
        RAISE EXCEPTION 'Invalid payout_type: must be advance or salary';
    END IF;

    SELECT * INTO v_account FROM public.canteen_accounts WHERE id = p_canteen_account_id AND tenant_id = p_tenant_id;
    IF v_account IS NULL THEN
        RAISE EXCEPTION 'Payment account not found';
    END IF;

    SELECT * INTO v_staff FROM public.staff_members WHERE id = p_staff_id AND tenant_id = p_tenant_id;
    IF v_staff IS NULL THEN
        RAISE EXCEPTION 'Staff member not found';
    END IF;

    v_category := CASE WHEN p_payout_type = 'advance' THEN 'salary_advance' ELSE 'salary_payout' END;

    -- 1. Insert salary payout voucher
    INSERT INTO public.salary_payouts (
        tenant_id, staff_id, business_day_id, canteen_account_id,
        amount, payout_type, payout_month, notes, paid_by
    ) VALUES (
        p_tenant_id, p_staff_id, p_business_day_id, p_canteen_account_id,
        p_amount, p_payout_type, COALESCE(p_payout_month, CURRENT_DATE),
        p_notes, v_user_id
    ) RETURNING id INTO v_payout_id;

    -- 2. Insert expense into day_entries (Cash outflow from canteen account)
    IF p_business_day_id IS NOT NULL THEN
        INSERT INTO public.day_entries (
            tenant_id, business_day_id, canteen_account_id, entry_type,
            category, amount, notes, created_by
        ) VALUES (
            p_tenant_id, p_business_day_id, p_canteen_account_id, 'expense',
            v_category, p_amount,
            COALESCE(p_notes, (CASE WHEN p_payout_type = 'advance' THEN 'Salary Advance: ' ELSE 'Salary Payout: ' END) || v_staff.name),
            v_user_id
        );
    END IF;

    -- 3. Update staff wallet cache
    IF p_payout_type = 'advance' THEN
        UPDATE public.staff_wallets SET
            current_advance_balance = current_advance_balance + p_amount,
            last_payout_at = now(),
            updated_at = now()
        WHERE staff_id = p_staff_id;
    ELSE
        UPDATE public.staff_wallets SET
            total_salary_paid = total_salary_paid + p_amount,
            current_advance_balance = 0.00,
            last_payout_at = now(),
            updated_at = now()
        WHERE staff_id = p_staff_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'salary_payout_id', v_payout_id,
        'staff_id', p_staff_id,
        'payout_type', p_payout_type,
        'canteen_account_id', p_canteen_account_id,
        'amount', p_amount
    );
END;
$$;

-- 3. RPC: Verify staff PIN code for POS authorization
CREATE OR REPLACE FUNCTION public.verify_staff_pin(
    p_tenant_id UUID,
    p_pin TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
    v_staff RECORD;
BEGIN
    SELECT id, name, role, is_active INTO v_staff
    FROM public.staff_members
    WHERE tenant_id = p_tenant_id
      AND pin_code = p_pin
      AND is_active = true
    LIMIT 1;

    IF v_staff IS NULL THEN
        RETURN jsonb_build_object('valid', false);
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'staff_id', v_staff.id,
        'name', v_staff.name,
        'role', v_staff.role
    );
END;
$$;

-- 4. RPC: Set staff PIN code
CREATE OR REPLACE FUNCTION public.set_staff_pin(
    p_staff_id UUID,
    p_pin TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_staff RECORD;
BEGIN
    SELECT * INTO v_staff FROM public.staff_members WHERE id = p_staff_id;
    IF v_staff IS NULL THEN
        RAISE EXCEPTION 'Staff member not found';
    END IF;

    IF NOT public.is_tenant_member(v_staff.tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF length(p_pin) != 4 OR p_pin !~ '^\d{4}$' THEN
        RAISE EXCEPTION 'PIN must be exactly 4 digits';
    END IF;

    UPDATE public.staff_members SET
        pin_code = p_pin,
        updated_at = now()
    WHERE id = p_staff_id;

    RETURN jsonb_build_object('success', true, 'staff_id', p_staff_id);
END;
$$;

-- 5. RPC: Reset staff PIN code
CREATE OR REPLACE FUNCTION public.reset_staff_pin(p_staff_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_staff RECORD;
BEGIN
    SELECT * INTO v_staff FROM public.staff_members WHERE id = p_staff_id;
    IF v_staff IS NULL THEN
        RAISE EXCEPTION 'Staff member not found';
    END IF;

    IF NOT public.is_tenant_member(v_staff.tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    UPDATE public.staff_members SET
        pin_code = NULL,
        updated_at = now()
    WHERE id = p_staff_id;

    RETURN jsonb_build_object('success', true, 'staff_id', p_staff_id, 'pin_reset', true);
END;
$$;
