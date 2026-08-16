-- Migration: Staff Advance Payments & Salary Payout Type Support
-- Description: Adds payout_type ('regular_salary', 'advance') and account_id to salary_payouts table.
--              Updates record_salary_payout_v2 RPC to handle advance payments and account deductions.

--------------------------------------------------------------------------------
-- 1. ALTER SALARY PAYOUTS TABLE
--------------------------------------------------------------------------------

ALTER TABLE public.salary_payouts
ADD COLUMN IF NOT EXISTS payout_type TEXT NOT NULL DEFAULT 'regular_salary' CHECK (payout_type IN ('regular_salary', 'advance')),
ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES public.canteen_accounts(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS payout_month TEXT DEFAULT to_char(now(), 'YYYY-MM');

CREATE INDEX IF NOT EXISTS idx_salary_payouts_type_month 
ON public.salary_payouts(tenant_id, staff_id, payout_type, payout_month);

--------------------------------------------------------------------------------
-- 2. UPDATED RPC: record_salary_payout_v2
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.record_salary_payout_v2(
  p_tenant_id UUID,
  p_staff_id UUID,
  p_amount NUMERIC,
  p_account_id UUID DEFAULT NULL,
  p_payment_mode TEXT DEFAULT 'cash',
  p_payout_type TEXT DEFAULT 'regular_salary',
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
  v_payout_id UUID;
  v_target_account_id UUID;
  v_category TEXT;
  v_current_month TEXT := to_char(CURRENT_DATE, 'YYYY-MM');
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Payout amount must be greater than zero';
  END IF;

  v_day_id := public.start_business_day(p_tenant_id, NULL, 0);

  -- Resolve Canteen Account
  IF p_account_id IS NOT NULL THEN
    SELECT id INTO v_target_account_id FROM public.canteen_accounts
    WHERE id = p_account_id AND tenant_id = p_tenant_id;
  ELSE
    IF lower(p_payment_mode) = 'bank' THEN
      SELECT id INTO v_target_account_id FROM public.canteen_accounts 
      WHERE tenant_id = p_tenant_id AND account_type = 'bank' LIMIT 1;
    ELSIF lower(p_payment_mode) IN ('mobile_money', 'bkash', 'nagad') THEN
      SELECT id INTO v_target_account_id FROM public.canteen_accounts 
      WHERE tenant_id = p_tenant_id AND account_type = 'mobile_money' LIMIT 1;
    ELSE
      v_target_account_id := public.get_default_cash_drawer_account(p_tenant_id);
    END IF;
  END IF;

  -- 1. Insert salary payout record with payout_type
  INSERT INTO public.salary_payouts (
    tenant_id, staff_id, business_day_id, amount, payment_mode, payout_type, account_id, payout_month, notes
  ) VALUES (
    p_tenant_id, p_staff_id, v_day_id, p_amount, p_payment_mode, p_payout_type, v_target_account_id, v_current_month, p_notes
  ) RETURNING id INTO v_payout_id;

  -- 2. Insert day_entries (General journal outflow)
  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', 'salary_outflow', p_amount, 'salary_payout', v_payout_id, p_notes, auth.uid()
  );

  -- 3. Insert canteen account ledger entry
  IF v_target_account_id IS NOT NULL THEN
    INSERT INTO public.canteen_account_entries (
      tenant_id, account_id, business_day_id, entry_type, amount, category, reference_type, reference_id, recorded_by_user_id, notes
    ) VALUES (
      p_tenant_id, v_target_account_id, v_day_id, 'outflow', p_amount, 'salary_outflow', 'salary_payout', v_payout_id, auth.uid(), p_notes
    );
  END IF;

  RETURN v_payout_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.record_salary_payout_v2(UUID, UUID, NUMERIC, UUID, TEXT, TEXT, TEXT) TO authenticated, anon;
