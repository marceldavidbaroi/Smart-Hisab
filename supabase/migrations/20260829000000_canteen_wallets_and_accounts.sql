-- Migration: Canteen Wallets & Multi-Channel Business Money Accounts
-- Description: Adds canteen_accounts and canteen_account_entries tables.
--              Enables tracking business funds across Cash Drawer, bKash / Mobile Money, Bank, and Safe.
--              Includes auto-seeding default accounts upon tenant creation and updated RPCs.

--------------------------------------------------------------------------------
-- 1. CANTEEN ACCOUNTS & ENTRIES TABLES
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.canteen_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  account_type TEXT NOT NULL CHECK (account_type IN ('cash_drawer', 'mobile_money', 'bank', 'safe')),
  account_number TEXT,
  current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_canteen_accounts_tenant ON public.canteen_accounts(tenant_id, account_type);

CREATE TABLE IF NOT EXISTS public.canteen_account_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES public.canteen_accounts(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  entry_type TEXT NOT NULL CHECK (entry_type IN ('inflow', 'outflow')),
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  category TEXT NOT NULL CHECK (category IN (
    'customer_collection', 'market_cost', 'canteen_expense',
    'salary_outflow', 'vendor_payment', 'misc_income', 'transfer', 'adjustment'
  )),
  reference_type TEXT CHECK (reference_type IN (
    'wallet_entry', 'salary_payout', 'vendor_wallet_entry',
    'day_entry', 'account_transfer', 'manual_adjustment'
  )),
  reference_id UUID,
  recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL,
  recorded_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  notes TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_canteen_account_entries_lookup 
ON public.canteen_account_entries(tenant_id, account_id, business_day_id);

--------------------------------------------------------------------------------
-- 2. RLS & LOCK POLICIES
--------------------------------------------------------------------------------

ALTER TABLE public.canteen_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteen_account_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS canteen_accounts_member_select ON public.canteen_accounts;
CREATE POLICY canteen_accounts_member_select ON public.canteen_accounts 
FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS canteen_accounts_member_all ON public.canteen_accounts;
CREATE POLICY canteen_accounts_member_all ON public.canteen_accounts 
FOR ALL USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS canteen_account_entries_member_select ON public.canteen_account_entries;
CREATE POLICY canteen_account_entries_member_select ON public.canteen_account_entries 
FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS canteen_account_entries_member_all ON public.canteen_account_entries;
CREATE POLICY canteen_account_entries_member_all ON public.canteen_account_entries 
FOR ALL USING (public.is_tenant_member(tenant_id));

-- Trigger: Closed Business Day Lock
DROP TRIGGER IF EXISTS enforce_closed_day_lock ON public.canteen_account_entries;
CREATE TRIGGER enforce_closed_day_lock
  BEFORE INSERT OR UPDATE OR DELETE ON public.canteen_account_entries
  FOR EACH ROW EXECUTE FUNCTION public.check_closed_day_lock();

--------------------------------------------------------------------------------
-- 3. BALANCE SYNC TRIGGER
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sync_canteen_account_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.entry_type = 'inflow' THEN
    UPDATE public.canteen_accounts
    SET current_balance = current_balance + NEW.amount,
        updated_at = now()
    WHERE id = NEW.account_id;
  ELSIF NEW.entry_type = 'outflow' THEN
    UPDATE public.canteen_accounts
    SET current_balance = current_balance - NEW.amount,
        updated_at = now()
    WHERE id = NEW.account_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_canteen_account_balance ON public.canteen_account_entries;
CREATE TRIGGER trg_sync_canteen_account_balance
  AFTER INSERT ON public.canteen_account_entries
  FOR EACH ROW EXECUTE FUNCTION public.sync_canteen_account_balance();

--------------------------------------------------------------------------------
-- 4. AUTO-SEED DEFAULT CANTEEN WALLETS FOR TENANTS
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.seed_default_canteen_accounts(p_tenant_id UUID)
RETURNS VOID AS $$
BEGIN
  -- 1. Cash Drawer (Primary / Default)
  IF NOT EXISTS (SELECT 1 FROM public.canteen_accounts WHERE tenant_id = p_tenant_id AND account_type = 'cash_drawer') THEN
    INSERT INTO public.canteen_accounts (tenant_id, name, account_type, is_default)
    VALUES (p_tenant_id, 'Cash Drawer (Counter)', 'cash_drawer', true);
  END IF;

  -- 2. bKash / Mobile Money
  IF NOT EXISTS (SELECT 1 FROM public.canteen_accounts WHERE tenant_id = p_tenant_id AND account_type = 'mobile_money') THEN
    INSERT INTO public.canteen_accounts (tenant_id, name, account_type, is_default)
    VALUES (p_tenant_id, 'bKash / Mobile Money', 'mobile_money', false);
  END IF;

  -- 3. Bank Account
  IF NOT EXISTS (SELECT 1 FROM public.canteen_accounts WHERE tenant_id = p_tenant_id AND account_type = 'bank') THEN
    INSERT INTO public.canteen_accounts (tenant_id, name, account_type, is_default)
    VALUES (p_tenant_id, 'Bank Account', 'bank', false);
  END IF;

  -- 4. Safe / Vault
  IF NOT EXISTS (SELECT 1 FROM public.canteen_accounts WHERE tenant_id = p_tenant_id AND account_type = 'safe') THEN
    INSERT INTO public.canteen_accounts (tenant_id, name, account_type, is_default)
    VALUES (p_tenant_id, 'Safe (Tijori)', 'safe', false);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on new tenant creation
CREATE OR REPLACE FUNCTION public.handle_new_tenant_accounts()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.seed_default_canteen_accounts(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_create_canteen_accounts ON public.tenants;
CREATE TRIGGER auto_create_canteen_accounts
  AFTER INSERT ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_tenant_accounts();

-- Seed all existing tenants right now
DO $$
DECLARE
  t RECORD;
BEGIN
  FOR t IN SELECT id FROM public.tenants LOOP
    PERFORM public.seed_default_canteen_accounts(t.id);
  END LOOP;
END $$;

--------------------------------------------------------------------------------
-- 5. UPDATED HELPER & CORE RPCS WITH ACCOUNT INTEGRATION
--------------------------------------------------------------------------------

-- Helper: Get or create cash drawer account id for tenant
CREATE OR REPLACE FUNCTION public.get_default_cash_drawer_account(p_tenant_id UUID)
RETURNS UUID AS $$
DECLARE
  v_acc_id UUID;
BEGIN
  SELECT id INTO v_acc_id FROM public.canteen_accounts
  WHERE tenant_id = p_tenant_id AND account_type = 'cash_drawer'
  LIMIT 1;

  IF v_acc_id IS NULL THEN
    PERFORM public.seed_default_canteen_accounts(p_tenant_id);
    SELECT id INTO v_acc_id FROM public.canteen_accounts
    WHERE tenant_id = p_tenant_id AND account_type = 'cash_drawer'
    LIMIT 1;
  END IF;

  RETURN v_acc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate expected cash only counts physical cash drawer transactions
CREATE OR REPLACE FUNCTION public.calculate_expected_cash(p_day_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  v_opening NUMERIC(12,2) := 0;
  v_inflows NUMERIC(12,2) := 0;
  v_outflows NUMERIC(12,2) := 0;
  v_cash_drawer_id UUID;
  v_tenant_id UUID;
BEGIN
  SELECT tenant_id, opening_cash INTO v_tenant_id, v_opening 
  FROM public.business_days WHERE id = p_day_id;

  IF v_tenant_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT id INTO v_cash_drawer_id 
  FROM public.canteen_accounts 
  WHERE tenant_id = v_tenant_id AND account_type = 'cash_drawer' 
  LIMIT 1;

  -- If canteen account entries exist for cash drawer, use those for precise reconciliation
  IF v_cash_drawer_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.canteen_account_entries 
    WHERE business_day_id = p_day_id AND account_id = v_cash_drawer_id
  ) THEN
    SELECT COALESCE(SUM(amount), 0) INTO v_inflows 
    FROM public.canteen_account_entries
    WHERE business_day_id = p_day_id AND account_id = v_cash_drawer_id AND entry_type = 'inflow';

    SELECT COALESCE(SUM(amount), 0) INTO v_outflows 
    FROM public.canteen_account_entries
    WHERE business_day_id = p_day_id AND account_id = v_cash_drawer_id AND entry_type = 'outflow';
  ELSE
    -- Backward-compatible fallback to day_entries
    SELECT COALESCE(SUM(amount), 0) INTO v_inflows FROM public.day_entries
    WHERE business_day_id = p_day_id AND entry_type = 'inflow';

    SELECT COALESCE(SUM(amount), 0) INTO v_outflows FROM public.day_entries
    WHERE business_day_id = p_day_id AND entry_type = 'outflow';
  END IF;

  RETURN (COALESCE(v_opening, 0) + v_inflows - v_outflows);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced Record Expense RPC
CREATE OR REPLACE FUNCTION public.record_expense_v2(
  p_tenant_id UUID,
  p_category TEXT,
  p_amount NUMERIC,
  p_account_id UUID DEFAULT NULL,
  p_vendor_id UUID DEFAULT NULL,
  p_staff_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
  v_entry_id UUID;
  v_vendor_wallet_id UUID;
  v_target_account_id UUID;
  v_account_type TEXT;
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);

  IF p_account_id IS NOT NULL THEN
    SELECT id, account_type INTO v_target_account_id, v_account_type 
    FROM public.canteen_accounts
    WHERE id = p_account_id AND tenant_id = p_tenant_id;
  ELSE
    v_target_account_id := public.get_default_cash_drawer_account(p_tenant_id);
    SELECT account_type INTO v_account_type FROM public.canteen_accounts WHERE id = v_target_account_id;
  END IF;

  -- 1. Insert into day_entries (General journal)
  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, notes, created_by_staff_id, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', p_category, p_amount, 'direct_expense', p_notes, p_staff_id, auth.uid()
  ) RETURNING id INTO v_entry_id;

  -- 2. Insert into canteen account ledger
  IF v_target_account_id IS NOT NULL THEN
    INSERT INTO public.canteen_account_entries (
      tenant_id, account_id, business_day_id, entry_type, amount, category, reference_type, reference_id, recorded_by_staff_id, recorded_by_user_id, notes
    ) VALUES (
      p_tenant_id, v_target_account_id, v_day_id, 'outflow', p_amount, 'market_cost', 'day_entry', v_entry_id, p_staff_id, auth.uid(), p_notes
    );
  END IF;

  -- 3. If vendor linked, record in vendor ledger
  IF p_vendor_id IS NOT NULL THEN
    SELECT id INTO v_vendor_wallet_id FROM public.vendor_wallets
    WHERE tenant_id = p_tenant_id AND vendor_id = p_vendor_id;

    IF v_vendor_wallet_id IS NOT NULL THEN
      INSERT INTO public.vendor_wallet_entries (
        tenant_id, vendor_wallet_id, business_day_id, type, amount, reference_type, reference_id, recorded_by_staff_id, recorded_by_user_id, notes
      ) VALUES (
        p_tenant_id, v_vendor_wallet_id, v_day_id, 'purchase', p_amount, 'market_expense', v_entry_id, p_staff_id, auth.uid(), p_notes
      );
    END IF;
  END IF;

  RETURN v_entry_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced Record Baki / Customer Payment RPC
CREATE OR REPLACE FUNCTION public.record_baki_payment_v2(
  p_tenant_id UUID,
  p_customer_id UUID,
  p_amount NUMERIC,
  p_account_id UUID DEFAULT NULL,
  p_staff_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
  v_day_id UUID;
  v_wallet_id UUID;
  v_w_entry_id UUID;
  v_target_account_id UUID;
  v_new_bal NUMERIC(12,2);
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);

  SELECT id INTO v_wallet_id FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id;

  IF v_wallet_id IS NULL THEN
    RAISE EXCEPTION 'Customer wallet not found';
  END IF;

  IF p_account_id IS NOT NULL THEN
    SELECT id INTO v_target_account_id FROM public.canteen_accounts
    WHERE id = p_account_id AND tenant_id = p_tenant_id;
  ELSE
    v_target_account_id := public.get_default_cash_drawer_account(p_tenant_id);
  END IF;

  -- 1. Insert customer wallet credit
  INSERT INTO public.wallet_entries (
    tenant_id, wallet_id, business_day_id, type, amount, reference_type, recorded_by_staff_id, notes
  ) VALUES (
    p_tenant_id, v_wallet_id, v_day_id, 'payment', p_amount, 'cash_collection', p_staff_id, p_notes
  ) RETURNING id INTO v_w_entry_id;

  -- 2. Insert day_entries
  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_staff_id, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'inflow', 'customer_payment', p_amount, 'wallet_entry', v_w_entry_id, p_notes, p_staff_id, auth.uid()
  );

  -- 3. Insert into canteen account ledger
  IF v_target_account_id IS NOT NULL THEN
    INSERT INTO public.canteen_account_entries (
      tenant_id, account_id, business_day_id, entry_type, amount, category, reference_type, reference_id, recorded_by_staff_id, recorded_by_user_id, notes
    ) VALUES (
      p_tenant_id, v_target_account_id, v_day_id, 'inflow', p_amount, 'customer_collection', 'wallet_entry', v_w_entry_id, p_staff_id, auth.uid(), p_notes
    );
  END IF;

  SELECT current_balance INTO v_new_bal FROM public.customer_wallets WHERE id = v_wallet_id;
  RETURN v_new_bal;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced Record Salary Payout RPC
CREATE OR REPLACE FUNCTION public.record_salary_payout_v2(
  p_tenant_id UUID,
  p_staff_id UUID,
  p_amount NUMERIC,
  p_account_id UUID DEFAULT NULL,
  p_payment_mode TEXT DEFAULT 'cash',
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
  v_payout_id UUID;
  v_target_account_id UUID;
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, NULL, 0);

  IF p_account_id IS NOT NULL THEN
    SELECT id INTO v_target_account_id FROM public.canteen_accounts
    WHERE id = p_account_id AND tenant_id = p_tenant_id;
  ELSE
    IF p_payment_mode = 'bank' THEN
      SELECT id INTO v_target_account_id FROM public.canteen_accounts WHERE tenant_id = p_tenant_id AND account_type = 'bank' LIMIT 1;
    ELSIF p_payment_mode = 'mobile_money' THEN
      SELECT id INTO v_target_account_id FROM public.canteen_accounts WHERE tenant_id = p_tenant_id AND account_type = 'mobile_money' LIMIT 1;
    ELSE
      v_target_account_id := public.get_default_cash_drawer_account(p_tenant_id);
    END IF;
  END IF;

  -- 1. Insert salary payout record
  INSERT INTO public.salary_payouts (
    tenant_id, staff_id, business_day_id, amount, payment_mode, notes
  ) VALUES (
    p_tenant_id, p_staff_id, v_day_id, p_amount, p_payment_mode, p_notes
  ) RETURNING id INTO v_payout_id;

  -- 2. Insert day_entries
  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', 'salary_outflow', p_amount, 'salary_payout', v_payout_id, p_notes, auth.uid()
  );

  -- 3. Insert canteen account entry
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

-- Internal Canteen Funds Transfer RPC (e.g. Move Cash Drawer cash to Safe or Deposit into Bank)
CREATE OR REPLACE FUNCTION public.transfer_canteen_funds(
  p_tenant_id UUID,
  p_from_account_id UUID,
  p_to_account_id UUID,
  p_amount NUMERIC,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_day_id UUID;
  v_from_bal NUMERIC(12,2);
  v_to_bal NUMERIC(12,2);
  v_xfer_id UUID := gen_random_uuid();
BEGIN
  IF p_from_account_id = p_to_account_id THEN
    RAISE EXCEPTION 'Source and destination accounts must be different';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Transfer amount must be greater than zero';
  END IF;

  v_day_id := public.get_active_business_day(p_tenant_id);

  -- Debit from Source Account
  INSERT INTO public.canteen_account_entries (
    tenant_id, account_id, business_day_id, entry_type, amount, category, reference_type, reference_id, recorded_by_user_id, notes
  ) VALUES (
    p_tenant_id, p_from_account_id, v_day_id, 'outflow', p_amount, 'transfer', 'account_transfer', v_xfer_id, auth.uid(), p_notes
  );

  -- Credit into Destination Account
  INSERT INTO public.canteen_account_entries (
    tenant_id, account_id, business_day_id, entry_type, amount, category, reference_type, reference_id, recorded_by_user_id, notes
  ) VALUES (
    p_tenant_id, p_to_account_id, v_day_id, 'inflow', p_amount, 'transfer', 'account_transfer', v_xfer_id, auth.uid(), p_notes
  );

  SELECT current_balance INTO v_from_bal FROM public.canteen_accounts WHERE id = p_from_account_id;
  SELECT current_balance INTO v_to_bal FROM public.canteen_accounts WHERE id = p_to_account_id;

  RETURN jsonb_build_object(
    'success', true,
    'transfer_id', v_xfer_id,
    'from_balance', v_from_bal,
    'to_balance', v_to_bal
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grants
GRANT EXECUTE ON FUNCTION public.seed_default_canteen_accounts(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_default_cash_drawer_account(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.record_expense_v2(UUID, TEXT, NUMERIC, UUID, UUID, UUID, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.record_baki_payment_v2(UUID, UUID, NUMERIC, UUID, UUID, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.record_salary_payout_v2(UUID, UUID, NUMERIC, UUID, TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.transfer_canteen_funds(UUID, UUID, UUID, NUMERIC, TEXT) TO authenticated, anon;
