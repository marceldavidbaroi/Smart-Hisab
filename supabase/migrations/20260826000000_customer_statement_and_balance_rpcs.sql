-- Migration: Customer Statement & Computed Balance RPCs
-- Description: Implements get_customer_balance for computed ledger balance verification
--              and get_customer_statement for paginated customer transaction history.

CREATE OR REPLACE FUNCTION public.get_customer_balance(
  p_tenant_id UUID,
  p_customer_id UUID
)
RETURNS NUMERIC AS $$
DECLARE
  v_wallet_id UUID;
  v_balance NUMERIC(12,2) := 0;
BEGIN
  SELECT id INTO v_wallet_id FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id;

  IF v_wallet_id IS NULL THEN RETURN 0; END IF;

  SELECT COALESCE(
    SUM(CASE 
      WHEN type = 'meal_charge' THEN amount
      WHEN type = 'payment' THEN -amount
      WHEN type = 'adjustment' THEN amount
      ELSE 0 
    END), 0
  ) INTO v_balance
  FROM public.wallet_entries
  WHERE tenant_id = p_tenant_id AND wallet_id = v_wallet_id;

  RETURN v_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_customer_statement(
  p_tenant_id UUID,
  p_customer_id UUID,
  p_start DATE DEFAULT NULL,
  p_end DATE DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_wallet_id UUID;
  v_entries JSONB;
  v_total_count BIGINT;
  v_opening_balance NUMERIC(12,2) := 0;
BEGIN
  SELECT id INTO v_wallet_id FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id;

  IF v_wallet_id IS NULL THEN
    RETURN jsonb_build_object('entries', '[]'::jsonb, 'total_count', 0, 'opening_balance', 0);
  END IF;

  -- Calculate opening balance if start date is provided
  IF p_start IS NOT NULL THEN
    SELECT COALESCE(
      SUM(CASE 
        WHEN type = 'meal_charge' THEN amount
        WHEN type = 'payment' THEN -amount
        WHEN type = 'adjustment' THEN amount
        ELSE 0 
      END), 0
    ) INTO v_opening_balance
    FROM public.wallet_entries
    WHERE tenant_id = p_tenant_id AND wallet_id = v_wallet_id AND created_at < p_start::timestamptz;
  END IF;

  -- Total count
  SELECT COUNT(*) INTO v_total_count
  FROM public.wallet_entries
  WHERE tenant_id = p_tenant_id AND wallet_id = v_wallet_id
    AND (p_start IS NULL OR created_at >= p_start::timestamptz)
    AND (p_end IS NULL OR created_at <= (p_end + 1)::timestamptz);

  -- Paginated entries
  SELECT jsonb_agg(e) INTO v_entries FROM (
    SELECT 
      w.id,
      w.type,
      w.amount,
      w.reference_type,
      w.reference_id,
      w.notes,
      w.metadata,
      w.created_at,
      s.name AS shift_name,
      sm.full_name AS recorded_by_staff_name
    FROM public.wallet_entries w
    LEFT JOIN public.shifts s ON s.id = w.shift_id
    LEFT JOIN public.staff_members sm ON sm.id = w.recorded_by_staff_id
    WHERE w.tenant_id = p_tenant_id AND w.wallet_id = v_wallet_id
      AND (p_start IS NULL OR w.created_at >= p_start::timestamptz)
      AND (p_end IS NULL OR w.created_at <= (p_end + 1)::timestamptz)
    ORDER BY w.created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) e;

  RETURN jsonb_build_object(
    'entries', COALESCE(v_entries, '[]'::jsonb),
    'total_count', v_total_count,
    'opening_balance', v_opening_balance
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_customer_balance(UUID, UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_customer_statement(UUID, UUID, DATE, DATE, INT, INT) TO authenticated, anon;
