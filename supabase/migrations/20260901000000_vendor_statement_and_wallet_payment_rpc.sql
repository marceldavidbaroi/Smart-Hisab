-- Migration: Vendor Statement Khata & record_vendor_payment_v2 RPC
-- Description: Implements get_vendor_statement for paginated vendor transaction ledger
--              and record_vendor_payment_v2 with Canteen Account (Cash Drawer, bKash, Bank) routing.

--------------------------------------------------------------------------------
-- 1. RPC: record_vendor_payment_v2
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_vendor_payment_v2(
  p_tenant_id UUID,
  p_vendor_id UUID,
  p_amount NUMERIC,
  p_account_id UUID DEFAULT NULL,
  p_staff_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
  v_day_id UUID;
  v_vendor_wallet_id UUID;
  v_v_entry_id UUID;
  v_day_entry_id UUID;
  v_target_account_id UUID;
  v_new_bal NUMERIC(12,2);
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Payment amount must be greater than zero';
  END IF;

  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);

  -- 1. Find or verify vendor wallet
  SELECT id INTO v_vendor_wallet_id FROM public.vendor_wallets
  WHERE tenant_id = p_tenant_id AND vendor_id = p_vendor_id;

  IF v_vendor_wallet_id IS NULL THEN
    INSERT INTO public.vendor_wallets (tenant_id, vendor_id, current_balance)
    VALUES (p_tenant_id, p_vendor_id, 0.00)
    RETURNING id INTO v_vendor_wallet_id;
  END IF;

  -- 2. Determine target Canteen Account (Cash Drawer, bKash, Bank, etc.)
  IF p_account_id IS NOT NULL THEN
    SELECT id INTO v_target_account_id FROM public.canteen_accounts
    WHERE id = p_account_id AND tenant_id = p_tenant_id;
  ELSE
    v_target_account_id := public.get_default_cash_drawer_account(p_tenant_id);
  END IF;

  -- 3. Insert vendor_wallet_entries ('payment' reduces vendor baki debt)
  INSERT INTO public.vendor_wallet_entries (
    tenant_id, vendor_wallet_id, business_day_id, type, amount, reference_type, recorded_by_staff_id, recorded_by_user_id, notes
  ) VALUES (
    p_tenant_id, v_vendor_wallet_id, v_day_id, 'payment', p_amount, 'cash_payment', p_staff_id, auth.uid(), p_notes
  ) RETURNING id INTO v_v_entry_id;

  -- 4. Insert day_entries (outflow from today's business day)
  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_staff_id, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', 'vendor_payment', p_amount, 'vendor_wallet_entry', v_v_entry_id, p_notes, p_staff_id, auth.uid()
  ) RETURNING id INTO v_day_entry_id;

  -- 5. Insert canteen_account_entries (outflow from selected physical wallet/account)
  IF v_target_account_id IS NOT NULL THEN
    INSERT INTO public.canteen_account_entries (
      tenant_id, account_id, business_day_id, entry_type, amount, category, reference_type, reference_id, recorded_by_staff_id, recorded_by_user_id, notes
    ) VALUES (
      p_tenant_id, v_target_account_id, v_day_id, 'outflow', p_amount, 'vendor_payment', 'day_entry', v_day_entry_id, p_staff_id, auth.uid(), p_notes
    );
  END IF;

  SELECT current_balance INTO v_new_bal FROM public.vendor_wallets WHERE id = v_vendor_wallet_id;
  RETURN v_new_bal;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------------------------
-- 2. RPC: get_vendor_statement
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_vendor_statement(
  p_tenant_id UUID,
  p_vendor_id UUID,
  p_start DATE DEFAULT NULL,
  p_end DATE DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_vendor_wallet_id UUID;
  v_entries JSONB;
  v_total_count BIGINT;
  v_opening_balance NUMERIC(12,2) := 0;
BEGIN
  SELECT id INTO v_vendor_wallet_id FROM public.vendor_wallets
  WHERE tenant_id = p_tenant_id AND vendor_id = p_vendor_id;

  IF v_vendor_wallet_id IS NULL THEN
    RETURN jsonb_build_object('entries', '[]'::jsonb, 'total_count', 0, 'opening_balance', 0);
  END IF;

  -- Calculate opening balance if start date is provided
  IF p_start IS NOT NULL THEN
    SELECT COALESCE(
      SUM(CASE 
        WHEN type = 'purchase' THEN amount
        WHEN type = 'payment' THEN -amount
        WHEN type = 'adjustment' THEN amount
        ELSE 0 
      END), 0
    ) INTO v_opening_balance
    FROM public.vendor_wallet_entries
    WHERE tenant_id = p_tenant_id AND vendor_wallet_id = v_vendor_wallet_id AND created_at < p_start::timestamptz;
  END IF;

  -- Total count
  SELECT COUNT(*) INTO v_total_count
  FROM public.vendor_wallet_entries
  WHERE tenant_id = p_tenant_id AND vendor_wallet_id = v_vendor_wallet_id
    AND (p_start IS NULL OR created_at >= p_start::timestamptz)
    AND (p_end IS NULL OR created_at <= (p_end + 1)::timestamptz);

  -- Paginated entries
  SELECT jsonb_agg(e) INTO v_entries FROM (
    SELECT 
      vwe.id,
      vwe.type,
      vwe.amount,
      vwe.reference_type,
      vwe.reference_id,
      vwe.notes,
      vwe.created_at,
      sm.full_name AS recorded_by_staff_name
    FROM public.vendor_wallet_entries vwe
    LEFT JOIN public.staff_members sm ON sm.id = vwe.recorded_by_staff_id
    WHERE vwe.tenant_id = p_tenant_id AND vwe.vendor_wallet_id = v_vendor_wallet_id
      AND (p_start IS NULL OR vwe.created_at >= p_start::timestamptz)
      AND (p_end IS NULL OR vwe.created_at <= (p_end + 1)::timestamptz)
    ORDER BY vwe.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) e;

  RETURN jsonb_build_object(
    'entries', COALESCE(v_entries, '[]'::jsonb),
    'total_count', v_total_count,
    'opening_balance', v_opening_balance
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.record_vendor_payment_v2(UUID, UUID, NUMERIC, UUID, UUID, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_vendor_statement(UUID, UUID, DATE, DATE, INT, INT) TO authenticated, anon;
