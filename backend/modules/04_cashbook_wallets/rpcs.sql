-- ==============================================================================
-- MODULE 4: CASHBOOK & CANTEEN WALLETS (RPCS & FUNCTIONS)
-- Purpose: Canteen account initialization, balance recalculation, expense logging,
--          inter-account transfers, and dual-layer transaction voiding.
-- ==============================================================================

-- 1. Helper: Seed default canteen accounts (Cash Drawer, bKash, Bank)
CREATE OR REPLACE FUNCTION public.seed_default_canteen_accounts(p_tenant_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    INSERT INTO public.canteen_accounts (tenant_id, name, account_type, is_default, current_balance)
    VALUES
        (p_tenant_id, 'Cash Drawer', 'cash_drawer', true, 0.00),
        (p_tenant_id, 'bKash Merchant', 'bkash', false, 0.00),
        (p_tenant_id, 'Bank Account', 'bank', false, 0.00)
    ON CONFLICT DO NOTHING;
END;
$$;

-- 2. Trigger: Auto-seed canteen accounts on new tenant
CREATE OR REPLACE FUNCTION public.handle_new_tenant_accounts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    PERFORM public.seed_default_canteen_accounts(NEW.id);
    RETURN NEW;
END;
$$;

-- 3. Helper: Get default cash drawer account for tenant
CREATE OR REPLACE FUNCTION public.get_default_cash_drawer_account(p_tenant_id UUID)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
    SELECT id FROM public.canteen_accounts
    WHERE tenant_id = p_tenant_id AND account_type = 'cash_drawer'
    LIMIT 1;
$$;

-- 4. Trigger Function: Sync canteen account current_balance from transactions
CREATE OR REPLACE FUNCTION public.sync_canteen_account_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_account_id UUID;
    v_total_income NUMERIC(12,2) := 0.00;
    v_total_expense NUMERIC(12,2) := 0.00;
    v_transfer_in NUMERIC(12,2) := 0.00;
    v_transfer_out NUMERIC(12,2) := 0.00;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_account_id := OLD.canteen_account_id;
    ELSE
        v_account_id := NEW.canteen_account_id;
    END IF;

    IF v_account_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Calculate total income in day_entries
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_income
    FROM public.day_entries
    WHERE canteen_account_id = v_account_id AND entry_type = 'income' AND is_voided = false;

    -- Calculate total expense in day_entries
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_expense
    FROM public.day_entries
    WHERE canteen_account_id = v_account_id AND entry_type = 'expense' AND is_voided = false;

    UPDATE public.canteen_accounts SET
        current_balance = (v_total_income - v_total_expense),
        updated_at = now()
    WHERE id = v_account_id;

    RETURN NULL;
END;
$$;

-- 5. RPC: Record Operational Expense into Cashbook & Account
CREATE OR REPLACE FUNCTION public.record_expense_v2(
    p_tenant_id UUID,
    p_canteen_account_id UUID,
    p_category TEXT,
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
    v_entry_id UUID;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Expense amount must be greater than zero';
    END IF;

    SELECT * INTO v_account FROM public.canteen_accounts WHERE id = p_canteen_account_id AND tenant_id = p_tenant_id;
    IF v_account IS NULL THEN
        RAISE EXCEPTION 'Canteen account not found';
    END IF;

    INSERT INTO public.day_entries (
        tenant_id, business_day_id, canteen_account_id, entry_type,
        category, amount, notes, created_by
    ) VALUES (
        p_tenant_id, p_business_day_id, p_canteen_account_id, 'expense',
        p_category, p_amount, p_notes, v_user_id
    ) RETURNING id INTO v_entry_id;

    RETURN jsonb_build_object(
        'success', true,
        'day_entry_id', v_entry_id,
        'canteen_account_id', p_canteen_account_id,
        'amount', p_amount,
        'category', p_category
    );
END;
$$;

-- 6. RPC: Transfer funds between canteen accounts
CREATE OR REPLACE FUNCTION public.transfer_canteen_funds(
    p_tenant_id UUID,
    p_from_account_id UUID,
    p_to_account_id UUID,
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
    v_from_account RECORD;
    v_to_account RECORD;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be greater than zero';
    END IF;

    IF p_from_account_id = p_to_account_id THEN
        RAISE EXCEPTION 'Cannot transfer funds to the same account';
    END IF;

    SELECT * INTO v_from_account FROM public.canteen_accounts WHERE id = p_from_account_id AND tenant_id = p_tenant_id;
    SELECT * INTO v_to_account FROM public.canteen_accounts WHERE id = p_to_account_id AND tenant_id = p_tenant_id;

    IF v_from_account IS NULL OR v_to_account IS NULL THEN
        RAISE EXCEPTION 'One or both accounts not found';
    END IF;

    -- 1. Debit outgoing account (Expense / Transfer Out)
    INSERT INTO public.day_entries (
        tenant_id, business_day_id, canteen_account_id, entry_type,
        category, amount, notes, created_by
    ) VALUES (
        p_tenant_id, p_business_day_id, p_from_account_id, 'expense',
        'transfer_out', p_amount,
        COALESCE(p_notes, 'Transfer to ' || v_to_account.name),
        v_user_id
    );

    -- 2. Credit incoming account (Income / Transfer In)
    INSERT INTO public.day_entries (
        tenant_id, business_day_id, canteen_account_id, entry_type,
        category, amount, notes, created_by
    ) VALUES (
        p_tenant_id, p_business_day_id, p_to_account_id, 'income',
        'transfer_in', p_amount,
        COALESCE(p_notes, 'Transfer from ' || v_from_account.name),
        v_user_id
    );

    RETURN jsonb_build_object(
        'success', true,
        'from_account_id', p_from_account_id,
        'to_account_id', p_to_account_id,
        'amount', p_amount
    );
END;
$$;

-- 7. RPC: Void a wallet entry (with audit log and automatic balance sync)
CREATE OR REPLACE FUNCTION public.void_wallet_entry(
    p_entry_id UUID,
    p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_entry RECORD;
    v_user_id UUID := auth.uid();
BEGIN
    SELECT * INTO v_entry FROM public.wallet_entries WHERE id = p_entry_id;
    IF v_entry IS NULL THEN
        RAISE EXCEPTION 'Wallet entry not found';
    END IF;

    IF NOT public.is_tenant_member(v_entry.tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF v_entry.is_voided THEN
        RAISE EXCEPTION 'Transaction is already voided';
    END IF;

    UPDATE public.wallet_entries SET
        is_voided = true,
        voided_at = now(),
        voided_by = v_user_id,
        void_reason = p_reason
    WHERE id = p_entry_id;

    -- Trigger balance sync
    IF v_entry.customer_id IS NOT NULL THEN
        PERFORM public.sync_customer_wallet_balance();
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'entry_id', p_entry_id,
        'voided', true
    );
END;
$$;

-- 8. RPC: Void a day entry (Cashbook expense/income)
CREATE OR REPLACE FUNCTION public.void_day_entry(
    p_entry_id UUID,
    p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_entry RECORD;
    v_user_id UUID := auth.uid();
BEGIN
    SELECT * INTO v_entry FROM public.day_entries WHERE id = p_entry_id;
    IF v_entry IS NULL THEN
        RAISE EXCEPTION 'Day entry not found';
    END IF;

    IF NOT public.is_tenant_member(v_entry.tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF v_entry.is_voided THEN
        RAISE EXCEPTION 'Transaction is already voided';
    END IF;

    UPDATE public.day_entries SET
        is_voided = true,
        voided_at = now(),
        voided_by = v_user_id,
        void_reason = p_reason
    WHERE id = p_entry_id;

    RETURN jsonb_build_object(
        'success', true,
        'entry_id', p_entry_id,
        'voided', true
    );
END;
$$;
