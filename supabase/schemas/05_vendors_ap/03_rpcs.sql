-- ==============================================================================
-- DOMAIN 05: VENDORS & ACCOUNTS PAYABLE — RPCS, FUNCTIONS & TRIGGERS
-- ==============================================================================

-- 1. Trigger: Auto-create vendor wallet on new vendor
CREATE OR REPLACE FUNCTION public.handle_new_vendor()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    INSERT INTO public.vendor_wallets (
        tenant_id, vendor_id, current_balance, total_debit, total_credit
    ) VALUES (
        NEW.tenant_id, NEW.id, NEW.opening_balance,
        CASE WHEN NEW.opening_balance > 0 THEN NEW.opening_balance ELSE 0 END,
        0.00
    ) ON CONFLICT (vendor_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_vendor_created ON public.vendors;
CREATE TRIGGER on_vendor_created
    AFTER INSERT ON public.vendors
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_vendor();

-- 2. Trigger Function: Sync vendor wallet balance from entries
CREATE OR REPLACE FUNCTION public.sync_vendor_wallet_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_vendor_id UUID;
    v_opening_balance NUMERIC(12,2) := 0.00;
    v_total_debit NUMERIC(12,2) := 0.00;
    v_total_credit NUMERIC(12,2) := 0.00;
    v_current_balance NUMERIC(12,2) := 0.00;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_vendor_id := OLD.vendor_id;
    ELSE
        v_vendor_id := NEW.vendor_id;
    END IF;

    IF v_vendor_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT opening_balance INTO v_opening_balance
    FROM public.vendors WHERE id = v_vendor_id;

    -- Total Debit (Credit purchases from supplier / Baki)
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_debit
    FROM public.vendor_wallet_entries
    WHERE vendor_id = v_vendor_id AND entry_type = 'debit' AND is_voided = false;

    -- Total Credit (Settlement payments made to supplier)
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total_credit
    FROM public.vendor_wallet_entries
    WHERE vendor_id = v_vendor_id AND entry_type = 'credit' AND is_voided = false;

    v_current_balance := v_opening_balance + v_total_debit - v_total_credit;

    UPDATE public.vendor_wallets SET
        current_balance = v_current_balance,
        total_debit = v_total_debit,
        total_credit = v_total_credit,
        last_transaction_at = now(),
        updated_at = now()
    WHERE vendor_id = v_vendor_id;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_vendor_entry_changed ON public.vendor_wallet_entries;
CREATE TRIGGER on_vendor_entry_changed
    AFTER INSERT OR UPDATE OR DELETE ON public.vendor_wallet_entries
    FOR EACH ROW EXECUTE FUNCTION public.sync_vendor_wallet_balance();

-- 3. RPC: Record Vendor Settlement Payment (Settles AP and draws from Canteen Account)
CREATE OR REPLACE FUNCTION public.record_vendor_payment_v2(
    p_tenant_id UUID,
    p_vendor_id UUID,
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
    v_vendor RECORD;
    v_vendor_entry_id UUID;
BEGIN
    IF NOT public.is_tenant_member(p_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be greater than zero';
    END IF;

    SELECT * INTO v_account FROM public.canteen_accounts WHERE id = p_canteen_account_id AND tenant_id = p_tenant_id;
    IF v_account IS NULL THEN
        RAISE EXCEPTION 'Canteen account / wallet not found';
    END IF;

    SELECT * INTO v_vendor FROM public.vendors WHERE id = p_vendor_id AND tenant_id = p_tenant_id;
    IF v_vendor IS NULL THEN
        RAISE EXCEPTION 'Vendor not found';
    END IF;

    -- 1. Insert vendor credit entry (reduces payable debt)
    INSERT INTO public.vendor_wallet_entries (
        tenant_id, vendor_id, business_day_id, canteen_account_id,
        entry_type, amount, category, notes, created_by
    ) VALUES (
        p_tenant_id, p_vendor_id, p_business_day_id, p_canteen_account_id,
        'credit', p_amount, 'payment',
        COALESCE(p_notes, 'Payment to vendor: ' || v_vendor.name || ' via ' || v_account.name),
        v_user_id
    ) RETURNING id INTO v_vendor_entry_id;

    -- 2. Insert expense into day_entries (Cash outflow from canteen account)
    IF p_business_day_id IS NOT NULL THEN
        INSERT INTO public.day_entries (
            tenant_id, business_day_id, canteen_account_id, entry_type,
            category, amount, notes, created_by
        ) VALUES (
            p_tenant_id, p_business_day_id, p_canteen_account_id, 'expense',
            'vendor_payment', p_amount,
            COALESCE(p_notes, 'Vendor payment: ' || v_vendor.name),
            v_user_id
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'vendor_entry_id', v_vendor_entry_id,
        'vendor_id', p_vendor_id,
        'canteen_account_id', p_canteen_account_id,
        'amount', p_amount
    );
END;
$$;

-- 4. RPC: Get Vendor Statement (Chronological Ledger)
CREATE OR REPLACE FUNCTION public.get_vendor_statement(
    p_vendor_id UUID,
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
    SELECT tenant_id INTO v_tenant_id FROM public.vendors WHERE id = p_vendor_id;
    IF NOT public.is_tenant_member(v_tenant_id) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    RETURN QUERY
    SELECT 
        ve.id,
        ve.entry_type,
        ve.category,
        ve.amount,
        ve.notes,
        ve.created_at,
        ve.is_voided,
        ca.name AS account_name
    FROM public.vendor_wallet_entries ve
    LEFT JOIN public.canteen_accounts ca ON ca.id = ve.canteen_account_id
    WHERE ve.vendor_id = p_vendor_id
      AND (p_start_date IS NULL OR ve.created_at >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR ve.created_at <= (p_end_date::TEXT || ' 23:59:59')::TIMESTAMPTZ)
    ORDER BY ve.created_at DESC;
END;
$$;
