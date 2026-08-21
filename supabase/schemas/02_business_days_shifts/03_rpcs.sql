-- ==============================================================================
-- DOMAIN 02: BUSINESS DAYS & SHIFTS — RPCS, FUNCTIONS & TRIGGERS
-- ==============================================================================

-- 1. RPC: Get the currently active business day for tenant
CREATE OR REPLACE FUNCTION public.get_active_business_day(p_tenant_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
    v_day RECORD;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    SELECT * INTO v_day
    FROM public.business_days
    WHERE tenant_id = p_tenant_id AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF v_day IS NULL THEN
        RETURN jsonb_build_object('active', false);
    END IF;

    RETURN jsonb_build_object(
        'active', true,
        'id', v_day.id,
        'tenant_id', v_day.tenant_id,
        'opening_balance', v_day.opening_balance,
        'opened_at', v_day.opened_at,
        'status', v_day.status,
        'notes', v_day.notes
    );
END;
$$;

-- 2. RPC: Start/Open a new business day
CREATE OR REPLACE FUNCTION public.start_business_day(
    p_tenant_id UUID,
    p_opening_balance NUMERIC DEFAULT 0.00,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_active_day RECORD;
    v_new_id UUID;
    v_user_id UUID := auth.uid();
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Check if day is already open
    SELECT * INTO v_active_day
    FROM public.business_days
    WHERE tenant_id = p_tenant_id AND status = 'open';

    IF v_active_day IS NOT NULL THEN
        RAISE EXCEPTION 'A business day is already open. Close it before opening a new one.';
    END IF;

    INSERT INTO public.business_days (
        tenant_id, opened_by, opening_balance, status, opened_at, notes
    ) VALUES (
        p_tenant_id, v_user_id, p_opening_balance, 'open', now(), p_notes
    ) RETURNING id INTO v_new_id;

    RETURN jsonb_build_object(
        'success', true,
        'business_day_id', v_new_id,
        'opening_balance', p_opening_balance,
        'opened_at', now()
    );
END;
$$;

-- 3. RPC: Calculate expected physical cash drawer balance for open day
CREATE OR REPLACE FUNCTION public.calculate_expected_cash(p_day_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
    v_day RECORD;
    v_drawer_account_id UUID;
    v_cash_in NUMERIC(12,2) := 0.00;
    v_cash_out NUMERIC(12,2) := 0.00;
    v_expected NUMERIC(12,2) := 0.00;
BEGIN
    SELECT * INTO v_day FROM public.business_days WHERE id = p_day_id;
    IF v_day IS NULL THEN
        RAISE EXCEPTION 'Business day not found';
    END IF;

    -- Get cash drawer account
    SELECT id INTO v_drawer_account_id
    FROM public.canteen_accounts
    WHERE tenant_id = v_day.tenant_id AND account_type = 'cash_drawer'
    LIMIT 1;

    -- Calculate cash in from direct income & customer baki repayments
    SELECT COALESCE(SUM(amount), 0.00) INTO v_cash_in
    FROM public.day_entries
    WHERE business_day_id = p_day_id
      AND entry_type = 'income'
      AND is_voided = false
      AND (canteen_account_id = v_drawer_account_id OR (canteen_account_id IS NULL AND v_drawer_account_id IS NULL));

    -- Calculate cash out from drawer (expenses, vendor settlements, salary advances)
    SELECT COALESCE(SUM(amount), 0.00) INTO v_cash_out
    FROM public.day_entries
    WHERE business_day_id = p_day_id
      AND entry_type = 'expense'
      AND is_voided = false
      AND (canteen_account_id = v_drawer_account_id OR (canteen_account_id IS NULL AND v_drawer_account_id IS NULL));

    v_expected := v_day.opening_balance + v_cash_in - v_cash_out;

    RETURN jsonb_build_object(
        'business_day_id', p_day_id,
        'opening_balance', v_day.opening_balance,
        'cash_in', v_cash_in,
        'cash_out', v_cash_out,
        'expected_closing_cash', v_expected
    );
END;
$$;

-- 4. RPC: End/Close the active business day with reconciliation
CREATE OR REPLACE FUNCTION public.end_business_day(
    p_day_id UUID,
    p_actual_closing_cash NUMERIC,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_day RECORD;
    v_calc JSONB;
    v_expected NUMERIC(12,2);
    v_diff NUMERIC(12,2);
    v_user_id UUID := auth.uid();
BEGIN
    SELECT * INTO v_day FROM public.business_days WHERE id = p_day_id;
    IF v_day IS NULL THEN
        RAISE EXCEPTION 'Business day not found';
    END IF;

    IF v_day.status = 'closed' THEN
        RAISE EXCEPTION 'Business day is already closed';
    END IF;

    IF NOT public.is_tenant_member(v_day.tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    v_calc := public.calculate_expected_cash(p_day_id);
    v_expected := (v_calc->>'expected_closing_cash')::NUMERIC;
    v_diff := p_actual_closing_cash - v_expected;

    UPDATE public.business_days SET
        status = 'closed',
        closed_by = v_user_id,
        closed_at = now(),
        actual_closing_cash = p_actual_closing_cash,
        expected_closing_cash = v_expected,
        cash_difference = v_diff,
        notes = COALESCE(p_notes, notes),
        updated_at = now()
    WHERE id = p_day_id;

    RETURN jsonb_build_object(
        'success', true,
        'business_day_id', p_day_id,
        'opening_balance', v_day.opening_balance,
        'actual_closing_cash', p_actual_closing_cash,
        'expected_closing_cash', v_expected,
        'cash_difference', v_diff,
        'closed_at', now()
    );
END;
$$;

-- 5. RPC: Get currently active shift based on current time
CREATE OR REPLACE FUNCTION public.get_current_shift(p_tenant_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
    v_current_time TIME := CURRENT_TIME;
    v_shift RECORD;
BEGIN
    SELECT * INTO v_shift
    FROM public.shifts
    WHERE tenant_id = p_tenant_id
      AND is_active = true
      AND v_current_time >= start_time
      AND v_current_time <= end_time
    ORDER BY sort_order ASC
    LIMIT 1;

    IF v_shift IS NULL THEN
        SELECT * INTO v_shift
        FROM public.shifts
        WHERE tenant_id = p_tenant_id AND is_active = true
        ORDER BY sort_order ASC
        LIMIT 1;
    END IF;

    IF v_shift IS NULL THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'id', v_shift.id,
        'name', v_shift.name,
        'start_time', v_shift.start_time,
        'end_time', v_shift.end_time
    );
END;
$$;

-- 6. Trigger Helper: Closed Day Data Lock Guard
CREATE OR REPLACE FUNCTION public.check_closed_day_lock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_day_id UUID;
    v_status TEXT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_day_id := OLD.business_day_id;
    ELSE
        v_day_id := NEW.business_day_id;
    END IF;

    IF v_day_id IS NOT NULL THEN
        SELECT status INTO v_status FROM public.business_days WHERE id = v_day_id;
        IF v_status = 'closed' THEN
            RAISE EXCEPTION 'Cannot modify financial records attached to a closed business day (Day ID: %).', v_day_id;
        END IF;
    END IF;

    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
