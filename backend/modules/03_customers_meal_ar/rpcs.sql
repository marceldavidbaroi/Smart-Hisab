-- ==============================================================================
-- MODULE 3: CUSTOMERS & MEAL ATTENDANCE / AR (RPCS & FUNCTIONS)
-- Purpose: Customer creation/reactivation, meal punching, baki collection,
--          balance sync, statement generation, and debt safety guards.
-- ==============================================================================

-- 1. Trigger: Auto-create customer wallet on new customer
CREATE OR REPLACE FUNCTION public.handle_new_customer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    INSERT INTO public.customer_wallets (
        tenant_id, customer_id, current_balance, total_debit, total_credit
    ) VALUES (
        NEW.tenant_id, NEW.id, NEW.opening_balance, 
        CASE WHEN NEW.opening_balance > 0 THEN NEW.opening_balance ELSE 0 END,
        CASE WHEN NEW.opening_balance < 0 THEN ABS(NEW.opening_balance) ELSE 0 END
    );
    RETURN NEW;
END;
$$;

-- 2. Trigger Function: Sync customer wallet balance from entries & attendance
CREATE OR REPLACE FUNCTION public.sync_customer_wallet_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_customer_id UUID;
    v_tenant_id UUID;
    v_opening_balance NUMERIC(12,2) := 0.00;
    v_total_debit NUMERIC(12,2) := 0.00;
    v_total_credit NUMERIC(12,2) := 0.00;
    v_current_balance NUMERIC(12,2) := 0.00;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_customer_id := OLD.customer_id;
    ELSE
        v_customer_id := NEW.customer_id;
    END IF;

    IF v_customer_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT opening_balance, tenant_id INTO v_opening_balance, v_tenant_id
    FROM public.customers WHERE id = v_customer_id;

    -- Total Debit (Charges, Meals & Manual Baki)
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_debit
    FROM public.wallet_entries
    WHERE customer_id = v_customer_id AND entry_type = 'debit' AND is_voided = false;

    -- Total Credit (Payments & Repayments)
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_credit
    FROM public.wallet_entries
    WHERE customer_id = v_customer_id AND entry_type = 'credit' AND is_voided = false;

    v_current_balance := v_opening_balance + v_total_debit - v_total_credit;

    UPDATE public.customer_wallets SET
        current_balance = v_current_balance,
        total_debit = v_total_debit,
        total_credit = v_total_credit,
        last_transaction_at = now(),
        updated_at = now()
    WHERE customer_id = v_customer_id;

    RETURN NULL;
END;
$$;

-- 3. Trigger Guard: Prevent deactivating customer with unpaid debt
CREATE OR REPLACE FUNCTION public.check_customer_debt_before_deactivation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC(12,2);
BEGIN
    IF OLD.is_active = true AND NEW.is_active = false THEN
        SELECT current_balance INTO v_balance
        FROM public.customer_wallets
        WHERE customer_id = NEW.id;

        IF v_balance > 0 THEN
            RAISE EXCEPTION 'Cannot deactivate customer "%" because they have an outstanding debt of BDT %', NEW.name, v_balance;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- 4. RPC: Create or reactivate customer (Idempotent by phone)
CREATE OR REPLACE FUNCTION public.create_or_reactivate_customer(
    p_tenant_id UUID,
    p_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_opening_balance NUMERIC DEFAULT 0.00,
    p_subscribed_shifts UUID[] DEFAULT '{}'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_existing RECORD;
    v_customer_id UUID;
    v_clean_phone TEXT;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    v_clean_phone := NULLIF(trim(p_phone), '');

    IF v_clean_phone IS NOT NULL THEN
        SELECT * INTO v_existing
        FROM public.customers
        WHERE tenant_id = p_tenant_id AND phone = v_clean_phone;

        IF v_existing IS NOT NULL THEN
            IF v_existing.is_active = false THEN
                UPDATE public.customers SET
                    name = p_name,
                    email = COALESCE(p_email, email),
                    address = COALESCE(p_address, address),
                    subscribed_shifts = COALESCE(p_subscribed_shifts, subscribed_shifts),
                    is_active = true,
                    updated_at = now()
                WHERE id = v_existing.id
                RETURNING id INTO v_customer_id;

                RETURN jsonb_build_object(
                    'success', true,
                    'customer_id', v_customer_id,
                    'name', p_name,
                    'reactivated', true
                );
            ELSE
                RAISE EXCEPTION 'Customer with phone % already exists', v_clean_phone;
            END IF;
        END IF;
    END IF;

    INSERT INTO public.customers (
        tenant_id, name, phone, email, address, opening_balance, subscribed_shifts, is_active
    ) VALUES (
        p_tenant_id, p_name, v_clean_phone, p_email, p_address, p_opening_balance, COALESCE(p_subscribed_shifts, '{}'), true
    ) RETURNING id INTO v_customer_id;

    RETURN jsonb_build_object(
        'success', true,
        'customer_id', v_customer_id,
        'name', p_name,
        'reactivated', false
    );
END;
$$;

-- 5. RPC: Record Meal Attendance Punch (Creates meal attendance + wallet debit)
CREATE OR REPLACE FUNCTION public.record_meal_attendance(
    p_tenant_id UUID,
    p_customer_id UUID,
    p_shift_id UUID DEFAULT NULL,
    p_meal_config_id UUID DEFAULT NULL,
    p_rate NUMERIC DEFAULT NULL,
    p_business_day_id UUID DEFAULT NULL,
    p_is_manual BOOLEAN DEFAULT false,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_rate NUMERIC(10,2);
    v_resolved_shift_id UUID := p_shift_id;
    v_resolved_config_id UUID := p_meal_config_id;
    v_meal_name TEXT := 'Meal';
    v_attendance_id UUID;
    v_user_id UUID := auth.uid();
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- Resolve meal config and rate if not explicitly supplied
    IF v_resolved_config_id IS NULL AND v_resolved_shift_id IS NOT NULL THEN
        SELECT id, default_rate, meal_name INTO v_resolved_config_id, v_rate, v_meal_name
        FROM public.meal_configs
        WHERE tenant_id = p_tenant_id AND shift_id = v_resolved_shift_id AND is_active = true
        LIMIT 1;
    ELSIF v_resolved_config_id IS NOT NULL THEN
        SELECT default_rate, shift_id, meal_name INTO v_rate, v_resolved_shift_id, v_meal_name
        FROM public.meal_configs
        WHERE id = v_resolved_config_id;
    END IF;

    v_rate := COALESCE(p_rate, v_rate, 0.00);

    -- 1. Insert meal attendance record
    INSERT INTO public.meal_attendance (
        tenant_id, customer_id, business_day_id, shift_id, meal_config_id,
        meal_date, rate, is_manual, notes, created_by
    ) VALUES (
        p_tenant_id, p_customer_id, p_business_day_id, v_resolved_shift_id, v_resolved_config_id,
        CURRENT_DATE, v_rate, p_is_manual, p_notes, v_user_id
    ) RETURNING id INTO v_attendance_id;

    -- 2. Insert wallet debit entry (charges customer)
    INSERT INTO public.wallet_entries (
        tenant_id, customer_id, business_day_id, entry_type, amount,
        category, notes, created_by
    ) VALUES (
        p_tenant_id, p_customer_id, p_business_day_id, 'debit', v_rate,
        'meal', COALESCE(p_notes, v_meal_name || ' meal charge'), v_user_id
    );

    RETURN jsonb_build_object(
        'success', true,
        'attendance_id', v_attendance_id,
        'customer_id', p_customer_id,
        'rate', v_rate,
        'meal_date', CURRENT_DATE
    );
END;
$$;

-- 6. RPC: Record Baki (Customer Debt) Payment into Canteen Wallet
CREATE OR REPLACE FUNCTION public.record_baki_payment_v2(
    p_tenant_id UUID,
    p_customer_id UUID,
    p_canteen_account_id UUID,
    p_amount NUMERIC,
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
    v_customer RECORD;
    v_entry_id UUID;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be greater than zero';
    END IF;

    SELECT * INTO v_account FROM public.canteen_accounts WHERE id = p_canteen_account_id AND tenant_id = p_tenant_id;
    IF v_account IS NULL THEN
        RAISE EXCEPTION 'Payment account / wallet not found';
    END IF;

    SELECT * INTO v_customer FROM public.customers WHERE id = p_customer_id AND tenant_id = p_tenant_id;
    IF v_customer IS NULL THEN
        RAISE EXCEPTION 'Customer not found';
    END IF;

    -- 1. Insert customer wallet credit (reduces customer debt)
    INSERT INTO public.wallet_entries (
        tenant_id, customer_id, business_day_id, canteen_account_id,
        entry_type, amount, category, notes, created_by
    ) VALUES (
        p_tenant_id, p_customer_id, p_business_day_id, p_canteen_account_id,
        'credit', p_amount, 'baki_payment',
        COALESCE(p_notes, 'Baki payment from ' || v_customer.name || ' via ' || v_account.name),
        v_user_id
    ) RETURNING id INTO v_entry_id;

    -- 2. Insert day entry income into cashbook
    IF p_business_day_id IS NOT NULL THEN
        INSERT INTO public.day_entries (
            tenant_id, business_day_id, canteen_account_id, entry_type,
            category, amount, notes, created_by
        ) VALUES (
            p_tenant_id, p_business_day_id, p_canteen_account_id, 'income',
            'baki_collection', p_amount,
            COALESCE(p_notes, 'Baki collection: ' || v_customer.name),
            v_user_id
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'wallet_entry_id', v_entry_id,
        'customer_id', p_customer_id,
        'canteen_account_id', p_canteen_account_id,
        'amount', p_amount
    );
END;
$$;

-- 7. RPC: Get Customer Balance
CREATE OR REPLACE FUNCTION public.get_customer_balance(p_customer_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
    v_wallet RECORD;
    v_customer RECORD;
BEGIN
    SELECT * INTO v_customer FROM public.customers WHERE id = p_customer_id;
    IF v_customer IS NULL THEN
        RAISE EXCEPTION 'Customer not found';
    END IF;

    IF NOT public.is_tenant_member(v_customer.tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    SELECT * INTO v_wallet FROM public.customer_wallets WHERE customer_id = p_customer_id;

    RETURN jsonb_build_object(
        'customer_id', p_customer_id,
        'customer_name', v_customer.name,
        'current_balance', COALESCE(v_wallet.current_balance, 0.00),
        'total_debit', COALESCE(v_wallet.total_debit, 0.00),
        'total_credit', COALESCE(v_wallet.total_credit, 0.00),
        'last_transaction_at', v_wallet.last_transaction_at
    );
END;
$$;

-- 8. RPC: Get Customer Statement (Chronological Ledger)
CREATE OR REPLACE FUNCTION public.get_customer_statement(
    p_customer_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    entry_type TEXT,
    category TEXT,
    amount NUMERIC,
    notes TEXT,
    created_at TIMESTAMPTZ,
    is_voided BOOLEAN,
    account_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    SELECT tenant_id INTO v_tenant_id FROM public.customers WHERE id = p_customer_id;
    IF NOT public.is_tenant_member(v_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    RETURN QUERY
    SELECT 
        w.id,
        w.entry_type,
        w.category,
        w.amount,
        w.notes,
        w.created_at,
        w.is_voided,
        ca.name AS account_name
    FROM public.wallet_entries w
    LEFT JOIN public.canteen_accounts ca ON ca.id = w.canteen_account_id
    WHERE w.customer_id = p_customer_id
      AND (p_start_date IS NULL OR w.created_at >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR w.created_at <= (p_end_date::TEXT || ' 23:59:59')::TIMESTAMPTZ)
    ORDER BY w.created_at DESC;
END;
$$;
