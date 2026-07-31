-- Smart-Hisab Database Schema v2 (Consolidated Fresh Start)
-- Specification: docs/new/database_schema_v2.md

CREATE EXTENSION IF NOT EXISTS pgcrypto;

--------------------------------------------------------------------------------
-- 1. IDENTITY & ACCESS
--------------------------------------------------------------------------------

-- User Profiles (1-to-1 with auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  is_superadmin BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tenants (Canteen / Business)
CREATE TABLE IF NOT EXISTS public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
  subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'business')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tenant Members (Maps users to tenants with flat role: owner or manager)
CREATE TABLE IF NOT EXISTS public.tenant_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'manager')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT tenant_members_tenant_user_unique UNIQUE (tenant_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_tenant_members_tenant_id ON public.tenant_members(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_members_user_id ON public.tenant_members(user_id);

-- Tenant Invites (6-digit join codes for managers)
CREATE TABLE IF NOT EXISTS public.tenant_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'manager' CHECK (role IN ('manager')),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  expires_at TIMESTAMPTZ NOT NULL,
  used_by UUID REFERENCES auth.users(id),
  used_at TIMESTAMPTZ
);

--------------------------------------------------------------------------------
-- 2. STAFF & PAYROLL
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.staff_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL,
  phone TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  allow_terminal_login BOOLEAN NOT NULL DEFAULT false,
  hashed_pin TEXT,
  temp_pin TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT staff_members_tenant_phone_unique UNIQUE (tenant_id, phone)
);
CREATE INDEX IF NOT EXISTS idx_staff_members_tenant_id ON public.staff_members(tenant_id);

CREATE TABLE IF NOT EXISTS public.staff_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL UNIQUE REFERENCES public.staff_members(id) ON DELETE CASCADE,
  current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

--------------------------------------------------------------------------------
-- 3. SHIFTS & MEALS
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_shifts_tenant_id ON public.shifts(tenant_id);

CREATE TABLE IF NOT EXISTS public.meal_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  rate NUMERIC(10,2) NOT NULL CHECK (rate >= 0),
  effective_from DATE NOT NULL DEFAULT current_date,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_meal_configs_tenant_shift ON public.meal_configs(tenant_id, shift_id);

--------------------------------------------------------------------------------
-- 4. CUSTOMERS & WALLETS
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT,
  institution TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON public.customers(tenant_id);

CREATE TABLE IF NOT EXISTS public.customer_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL UNIQUE REFERENCES public.customers(id) ON DELETE CASCADE,
  current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_customer_wallets_tenant ON public.customer_wallets(tenant_id);

--------------------------------------------------------------------------------
-- 5. VENDORS & SUPPLIER LEDGER
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_vendors_tenant_id ON public.vendors(tenant_id);

CREATE TABLE IF NOT EXISTS public.vendor_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  vendor_id UUID NOT NULL UNIQUE REFERENCES public.vendors(id) ON DELETE CASCADE,
  current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_vendor_wallets_tenant ON public.vendor_wallets(tenant_id);

--------------------------------------------------------------------------------
-- 6. BUSINESS DAY & CASHBOOK
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.business_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  business_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('open', 'closed')),
  opening_cash NUMERIC(12,2) NOT NULL DEFAULT 0,
  closing_cash NUMERIC(12,2),
  expected_cash NUMERIC(12,2),
  variance NUMERIC(12,2),
  opened_by_staff_id UUID REFERENCES public.staff_members(id),
  opened_by_user_id UUID REFERENCES auth.users(id),
  closed_by_staff_id UUID REFERENCES public.staff_members(id),
  closed_by_user_id UUID REFERENCES auth.users(id),
  opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_open_business_day ON public.business_days (tenant_id) WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_business_days_tenant_date ON public.business_days(tenant_id, business_date);

CREATE TABLE IF NOT EXISTS public.staff_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'half_day')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_lookup ON public.staff_attendance(tenant_id, staff_id, business_day_id);

CREATE TABLE IF NOT EXISTS public.salary_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  payment_mode TEXT NOT NULL DEFAULT 'cash' CHECK (payment_mode IN ('cash', 'bank', 'mobile_money')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_salary_payouts_lookup ON public.salary_payouts(tenant_id, staff_id, business_day_id);

CREATE TABLE IF NOT EXISTS public.meal_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  charge_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_meal_attendance_lookup ON public.meal_attendance(tenant_id, customer_id, business_day_id);

CREATE TABLE IF NOT EXISTS public.wallet_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES public.customer_wallets(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('meal_charge', 'payment', 'adjustment')),
  amount NUMERIC(12,2) NOT NULL,
  reference_type TEXT CHECK (reference_type IN ('meal_attendance', 'cash_collection', 'manual_adjustment')),
  reference_id UUID,
  recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wallet_entries_lookup ON public.wallet_entries(tenant_id, wallet_id, business_day_id);

CREATE TABLE IF NOT EXISTS public.vendor_wallet_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  vendor_wallet_id UUID NOT NULL REFERENCES public.vendor_wallets(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('purchase', 'payment', 'adjustment')),
  amount NUMERIC(12,2) NOT NULL,
  reference_type TEXT CHECK (reference_type IN ('market_expense', 'cash_payment', 'manual_adjustment')),
  reference_id UUID,
  recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL,
  recorded_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_vendor_wallet_entries_lookup ON public.vendor_wallet_entries(tenant_id, vendor_wallet_id, business_day_id);

CREATE TABLE IF NOT EXISTS public.day_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  entry_type TEXT NOT NULL CHECK (entry_type IN ('inflow', 'outflow')),
  category TEXT NOT NULL CHECK (category IN ('customer_payment', 'market_cost', 'canteen_expense', 'salary_outflow', 'vendor_payment', 'misc_earn')),
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  reference_type TEXT CHECK (reference_type IN ('wallet_entry', 'salary_payout', 'vendor_wallet_entry', 'direct_expense', 'direct_income')),
  reference_id UUID,
  notes TEXT,
  created_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL,
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_day_entries_lookup ON public.day_entries(tenant_id, business_day_id, category);

CREATE TABLE IF NOT EXISTS public.day_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
  note_type TEXT NOT NULL CHECK (note_type IN ('market_list', 'general_note', 'issue')),
  content TEXT NOT NULL,
  created_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL,
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_day_notes_lookup ON public.day_notes(tenant_id, business_day_id);

--------------------------------------------------------------------------------
-- 7. HELPER FUNCTIONS & RLS SECURITY
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_tenant_member(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.tenant_members
    WHERE tenant_id = p_tenant_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_tenant_owner(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.tenant_members
    WHERE tenant_id = p_tenant_id AND user_id = auth.uid() AND role = 'owner'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND is_superadmin = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_wallet_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_notes ENABLE ROW LEVEL SECURITY;

-- Standard tenant RLS policies
DO $$
DECLARE
  tbl TEXT;
  tbls TEXT[] := ARRAY[
    'staff_members', 'staff_wallets', 'staff_attendance', 'salary_payouts',
    'customers', 'customer_wallets', 'wallet_entries',
    'vendors', 'vendor_wallets', 'vendor_wallet_entries',
    'shifts', 'meal_configs', 'meal_attendance',
    'business_days', 'day_entries', 'day_notes'
  ];
BEGIN
  FOREACH tbl IN ARRAY tbls LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I_member_select ON public.%I', tbl, tbl);
    EXECUTE format('CREATE POLICY %I_member_select ON public.%I FOR SELECT USING (public.is_tenant_member(tenant_id))', tbl, tbl);

    EXECUTE format('DROP POLICY IF EXISTS %I_member_all ON public.%I', tbl, tbl);
    EXECUTE format('CREATE POLICY %I_member_all ON public.%I FOR ALL USING (public.is_tenant_member(tenant_id))', tbl, tbl);
  END LOOP;
END $$;

-- Specialized RLS for Identity tables
CREATE POLICY user_profiles_select ON public.user_profiles FOR SELECT USING (true);
CREATE POLICY user_profiles_update ON public.user_profiles FOR UPDATE USING (id = auth.uid());

CREATE POLICY tenants_select ON public.tenants FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.tenant_members WHERE tenant_id = id AND user_id = auth.uid()) OR public.is_superadmin()
);

CREATE POLICY tenant_members_select ON public.tenant_members FOR SELECT USING (
  tenant_id IN (SELECT tenant_id FROM public.tenant_members WHERE user_id = auth.uid())
);

--------------------------------------------------------------------------------
-- 8. AUTOMATED TRIGGERS
--------------------------------------------------------------------------------

-- Trigger 1: Auth signup -> user_profiles
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'User'),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    avatar_url = EXCLUDED.avatar_url,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Trigger 2: Auto-create customer wallet
CREATE OR REPLACE FUNCTION public.handle_new_customer()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.customer_wallets (tenant_id, customer_id, current_balance)
  VALUES (NEW.tenant_id, NEW.id, 0)
  ON CONFLICT (customer_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_create_customer_wallet ON public.customers;
CREATE TRIGGER auto_create_customer_wallet
  AFTER INSERT ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_customer();

-- Trigger 3: Auto-create staff wallet
CREATE OR REPLACE FUNCTION public.handle_new_staff()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.staff_wallets (tenant_id, staff_id, current_balance)
  VALUES (NEW.tenant_id, NEW.id, 0)
  ON CONFLICT (staff_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_create_staff_wallet ON public.staff_members;
CREATE TRIGGER auto_create_staff_wallet
  AFTER INSERT ON public.staff_members
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_staff();

-- Trigger 4: Auto-create vendor wallet
CREATE OR REPLACE FUNCTION public.handle_new_vendor()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.vendor_wallets (tenant_id, vendor_id, current_balance)
  VALUES (NEW.tenant_id, NEW.id, 0)
  ON CONFLICT (vendor_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_create_vendor_wallet ON public.vendors;
CREATE TRIGGER auto_create_vendor_wallet
  AFTER INSERT ON public.vendors
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_vendor();

-- Trigger 5: Auto-seed default shifts on tenant creation
CREATE OR REPLACE FUNCTION public.handle_new_tenant()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.shifts (tenant_id, name, start_time, end_time)
  VALUES
    (NEW.id, 'Breakfast', '06:00:00', '09:00:00'),
    (NEW.id, 'Lunch', '12:00:00', '15:00:00'),
    (NEW.id, 'Dinner', '19:00:00', '22:00:00');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_seed_default_shifts ON public.tenants;
CREATE TRIGGER auto_seed_default_shifts
  AFTER INSERT ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_tenant();

-- Trigger 6: Update customer wallet balance on wallet_entries insert
CREATE OR REPLACE FUNCTION public.sync_customer_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'meal_charge' THEN
    UPDATE public.customer_wallets
    SET current_balance = current_balance + NEW.amount
    WHERE id = NEW.wallet_id;
  ELSIF NEW.type = 'payment' THEN
    UPDATE public.customer_wallets
    SET current_balance = current_balance - NEW.amount
    WHERE id = NEW.wallet_id;
  ELSIF NEW.type = 'adjustment' THEN
    UPDATE public.customer_wallets
    SET current_balance = current_balance + NEW.amount
    WHERE id = NEW.wallet_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_wallet_balance ON public.wallet_entries;
CREATE TRIGGER update_wallet_balance
  AFTER INSERT ON public.wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.sync_customer_wallet_balance();

-- Trigger 7: Update vendor wallet balance on vendor_wallet_entries insert
CREATE OR REPLACE FUNCTION public.sync_vendor_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'purchase' THEN
    UPDATE public.vendor_wallets
    SET current_balance = current_balance + NEW.amount
    WHERE id = NEW.vendor_wallet_id;
  ELSIF NEW.type = 'payment' THEN
    UPDATE public.vendor_wallets
    SET current_balance = current_balance - NEW.amount
    WHERE id = NEW.vendor_wallet_id;
  ELSIF NEW.type = 'adjustment' THEN
    UPDATE public.vendor_wallets
    SET current_balance = current_balance + NEW.amount
    WHERE id = NEW.vendor_wallet_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_vendor_wallet_balance ON public.vendor_wallet_entries;
CREATE TRIGGER update_vendor_wallet_balance
  AFTER INSERT ON public.vendor_wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.sync_vendor_wallet_balance();

--------------------------------------------------------------------------------
-- 9. RPC FUNCTIONS
--------------------------------------------------------------------------------

-- Create Canteen (Onboarding)
CREATE OR REPLACE FUNCTION public.create_tenant(p_name TEXT)
RETURNS UUID AS $$
DECLARE
  v_tenant_id UUID;
BEGIN
  INSERT INTO public.tenants (name) VALUES (p_name) RETURNING id INTO v_tenant_id;
  INSERT INTO public.tenant_members (tenant_id, user_id, role)
  VALUES (v_tenant_id, auth.uid(), 'owner');
  RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate Invite Code for Manager
CREATE OR REPLACE FUNCTION public.generate_invite_code(p_tenant_id UUID, p_role TEXT DEFAULT 'manager')
RETURNS TEXT AS $$
DECLARE
  v_code TEXT;
BEGIN
  IF NOT public.is_tenant_owner(p_tenant_id) THEN
    RAISE EXCEPTION 'Only canteen owners can generate invite codes';
  END IF;

  v_code := lpad(floor(random() * 900000 + 100000)::text, 6, '0');

  INSERT INTO public.tenant_invites (tenant_id, code, role, created_by, expires_at)
  VALUES (p_tenant_id, v_code, p_role, auth.uid(), now() + interval '24 hours');

  RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Join Canteen via Invite Code
CREATE OR REPLACE FUNCTION public.join_tenant_by_code(p_code TEXT)
RETURNS JSON AS $$
DECLARE
  v_invite public.tenant_invites%ROWTYPE;
  v_tenant public.tenants%ROWTYPE;
BEGIN
  SELECT * INTO v_invite FROM public.tenant_invites
  WHERE code = p_code AND used_at IS NULL AND expires_at > now();

  IF v_invite.id IS NULL THEN
    RAISE EXCEPTION 'Invalid or expired invite code';
  END IF;

  INSERT INTO public.tenant_members (tenant_id, user_id, role)
  VALUES (v_invite.tenant_id, auth.uid(), v_invite.role)
  ON CONFLICT (tenant_id, user_id) DO UPDATE SET role = EXCLUDED.role;

  UPDATE public.tenant_invites
  SET used_by = auth.uid(), used_at = now()
  WHERE id = v_invite.id;

  SELECT * INTO v_tenant FROM public.tenants WHERE id = v_invite.tenant_id;

  RETURN json_build_object(
    'tenant_id', v_tenant.id,
    'name', v_tenant.name,
    'role', v_invite.role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Business Day Management
CREATE OR REPLACE FUNCTION public.get_active_business_day(p_tenant_id UUID)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
BEGIN
  SELECT id INTO v_day_id FROM public.business_days
  WHERE tenant_id = p_tenant_id AND status = 'open'
  LIMIT 1;
  RETURN v_day_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.start_business_day(
  p_tenant_id UUID,
  p_staff_id UUID DEFAULT NULL,
  p_opening_cash NUMERIC DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
BEGIN
  IF NOT public.is_tenant_member(p_tenant_id) THEN
    RAISE EXCEPTION 'Not a member of this canteen';
  END IF;

  v_day_id := public.get_active_business_day(p_tenant_id);
  IF v_day_id IS NOT NULL THEN
    RETURN v_day_id;
  END IF;

  INSERT INTO public.business_days (
    tenant_id, business_date, status, opening_cash, opened_by_staff_id, opened_by_user_id
  ) VALUES (
    p_tenant_id, CURRENT_DATE, 'open', p_opening_cash, p_staff_id, auth.uid()
  ) RETURNING id INTO v_day_id;

  RETURN v_day_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.calculate_expected_cash(p_day_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  v_opening NUMERIC(12,2) := 0;
  v_inflows NUMERIC(12,2) := 0;
  v_outflows NUMERIC(12,2) := 0;
BEGIN
  SELECT opening_cash INTO v_opening FROM public.business_days WHERE id = p_day_id;

  SELECT COALESCE(SUM(amount), 0) INTO v_inflows FROM public.day_entries
  WHERE business_day_id = p_day_id AND entry_type = 'inflow';

  SELECT COALESCE(SUM(amount), 0) INTO v_outflows FROM public.day_entries
  WHERE business_day_id = p_day_id AND entry_type = 'outflow';

  RETURN (COALESCE(v_opening, 0) + v_inflows - v_outflows);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.end_business_day(
  p_tenant_id UUID,
  p_day_id UUID,
  p_staff_id UUID DEFAULT NULL,
  p_closing_cash NUMERIC DEFAULT 0,
  p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (expected NUMERIC, variance NUMERIC, status TEXT) AS $$
DECLARE
  v_expected NUMERIC(12,2);
  v_variance NUMERIC(12,2);
BEGIN
  v_expected := public.calculate_expected_cash(p_day_id);
  v_variance := p_closing_cash - v_expected;

  UPDATE public.business_days SET
    status = 'closed',
    closing_cash = p_closing_cash,
    expected_cash = v_expected,
    variance = v_variance,
    closed_by_staff_id = p_staff_id,
    closed_by_user_id = auth.uid(),
    closed_at = now(),
    notes = p_notes,
    updated_at = now()
  WHERE id = p_day_id AND tenant_id = p_tenant_id;

  RETURN QUERY SELECT v_expected, v_variance, 'closed'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Shift Resolver
CREATE OR REPLACE FUNCTION public.get_current_shift(p_tenant_id UUID)
RETURNS UUID AS $$
DECLARE
  v_shift_id UUID;
  v_curr_time TIME := CURRENT_TIME;
BEGIN
  SELECT id INTO v_shift_id FROM public.shifts
  WHERE tenant_id = p_tenant_id AND is_active = true
    AND v_curr_time >= start_time AND v_curr_time <= end_time
  ORDER BY start_time ASC LIMIT 1;

  IF v_shift_id IS NULL THEN
    SELECT id INTO v_shift_id FROM public.shifts
    WHERE tenant_id = p_tenant_id AND is_active = true
    ORDER BY start_time ASC LIMIT 1;
  END IF;

  RETURN v_shift_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record Meal Attendance
CREATE OR REPLACE FUNCTION public.record_meal_attendance(
  p_tenant_id UUID,
  p_customer_id UUID,
  p_staff_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_day_id UUID;
  v_shift_id UUID;
  v_rate NUMERIC(10,2) := 0;
  v_wallet_id UUID;
  v_att_id UUID;
  v_new_bal NUMERIC(12,2);
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);
  v_shift_id := public.get_current_shift(p_tenant_id);

  SELECT rate INTO v_rate FROM public.meal_configs
  WHERE tenant_id = p_tenant_id AND shift_id = v_shift_id
  ORDER BY effective_from DESC LIMIT 1;
  IF v_rate IS NULL THEN v_rate := 50; END IF;

  SELECT id INTO v_wallet_id FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id;

  -- Check if already marked for this shift & day (toggle off)
  SELECT id INTO v_att_id FROM public.meal_attendance
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id
    AND business_day_id = v_day_id AND shift_id = v_shift_id;

  IF v_att_id IS NOT NULL THEN
    DELETE FROM public.meal_attendance WHERE id = v_att_id;
    DELETE FROM public.wallet_entries WHERE reference_id = v_att_id AND reference_type = 'meal_attendance';

    SELECT current_balance INTO v_new_bal FROM public.customer_wallets WHERE id = v_wallet_id;
    RETURN jsonb_build_object('action', 'removed', 'new_balance', v_new_bal);
  ELSE
    INSERT INTO public.meal_attendance (
      tenant_id, customer_id, business_day_id, shift_id, charge_amount, recorded_by_staff_id
    ) VALUES (
      p_tenant_id, p_customer_id, v_day_id, v_shift_id, v_rate, p_staff_id
    ) RETURNING id INTO v_att_id;

    INSERT INTO public.wallet_entries (
      tenant_id, wallet_id, business_day_id, shift_id, type, amount, reference_type, reference_id, recorded_by_staff_id
    ) VALUES (
      p_tenant_id, v_wallet_id, v_day_id, v_shift_id, 'meal_charge', v_rate, 'meal_attendance', v_att_id, p_staff_id
    );

    SELECT current_balance INTO v_new_bal FROM public.customer_wallets WHERE id = v_wallet_id;
    RETURN jsonb_build_object('action', 'added', 'new_balance', v_new_bal);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record Baki Cash Payment
CREATE OR REPLACE FUNCTION public.record_baki_payment(
  p_tenant_id UUID,
  p_customer_id UUID,
  p_amount NUMERIC,
  p_staff_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
  v_day_id UUID;
  v_wallet_id UUID;
  v_w_entry_id UUID;
  v_new_bal NUMERIC(12,2);
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);

  SELECT id INTO v_wallet_id FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id;

  INSERT INTO public.wallet_entries (
    tenant_id, wallet_id, business_day_id, type, amount, reference_type, recorded_by_staff_id, notes
  ) VALUES (
    p_tenant_id, v_wallet_id, v_day_id, 'payment', p_amount, 'cash_collection', p_staff_id, p_notes
  ) RETURNING id INTO v_w_entry_id;

  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_staff_id, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'inflow', 'customer_payment', p_amount, 'wallet_entry', v_w_entry_id, p_notes, p_staff_id, auth.uid()
  );

  SELECT current_balance INTO v_new_bal FROM public.customer_wallets WHERE id = v_wallet_id;
  RETURN v_new_bal;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record Expense
CREATE OR REPLACE FUNCTION public.record_expense(
  p_tenant_id UUID,
  p_category TEXT,
  p_amount NUMERIC,
  p_vendor_id UUID DEFAULT NULL,
  p_staff_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
  v_entry_id UUID;
  v_vendor_wallet_id UUID;
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);

  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, notes, created_by_staff_id, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', p_category, p_amount, 'direct_expense', p_notes, p_staff_id, auth.uid()
  ) RETURNING id INTO v_entry_id;

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

-- Record Vendor Payment
CREATE OR REPLACE FUNCTION public.record_vendor_payment(
  p_tenant_id UUID,
  p_vendor_id UUID,
  p_amount NUMERIC,
  p_staff_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
  v_day_id UUID;
  v_vendor_wallet_id UUID;
  v_v_entry_id UUID;
  v_new_bal NUMERIC(12,2);
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);

  SELECT id INTO v_vendor_wallet_id FROM public.vendor_wallets
  WHERE tenant_id = p_tenant_id AND vendor_id = p_vendor_id;

  INSERT INTO public.vendor_wallet_entries (
    tenant_id, vendor_wallet_id, business_day_id, type, amount, reference_type, recorded_by_staff_id, recorded_by_user_id, notes
  ) VALUES (
    p_tenant_id, v_vendor_wallet_id, v_day_id, 'payment', p_amount, 'cash_payment', p_staff_id, auth.uid(), p_notes
  ) RETURNING id INTO v_v_entry_id;

  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_staff_id, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', 'vendor_payment', p_amount, 'vendor_wallet_entry', v_v_entry_id, p_notes, p_staff_id, auth.uid()
  );

  SELECT current_balance INTO v_new_bal FROM public.vendor_wallets WHERE id = v_vendor_wallet_id;
  RETURN v_new_bal;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record Salary Payout
CREATE OR REPLACE FUNCTION public.record_salary_payout(
  p_tenant_id UUID,
  p_staff_id UUID,
  p_amount NUMERIC,
  p_payment_mode TEXT DEFAULT 'cash',
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_day_id UUID;
  v_payout_id UUID;
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, NULL, 0);

  INSERT INTO public.salary_payouts (
    tenant_id, staff_id, business_day_id, amount, payment_mode, notes
  ) VALUES (
    p_tenant_id, p_staff_id, v_day_id, p_amount, p_payment_mode, p_notes
  ) RETURNING id INTO v_payout_id;

  INSERT INTO public.day_entries (
    tenant_id, business_day_id, entry_type, category, amount, reference_type, reference_id, notes, created_by_user_id
  ) VALUES (
    p_tenant_id, v_day_id, 'outflow', 'salary_outflow', p_amount, 'salary_payout', v_payout_id, p_notes, auth.uid()
  );

  RETURN v_payout_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify Staff PIN
CREATE OR REPLACE FUNCTION public.verify_staff_pin(p_tenant_id UUID, p_pin TEXT)
RETURNS JSONB AS $$
DECLARE
  v_staff RECORD;
BEGIN
  FOR v_staff IN
    SELECT id, full_name, role, phone, hashed_pin, temp_pin
    FROM public.staff_members
    WHERE tenant_id = p_tenant_id AND is_active = true AND allow_terminal_login = true
  LOOP
    IF (v_staff.temp_pin IS NOT NULL AND v_staff.temp_pin = p_pin) OR
       (v_staff.hashed_pin IS NOT NULL AND v_staff.hashed_pin = crypt(p_pin, v_staff.hashed_pin)) THEN
      RETURN jsonb_build_object(
        'success', true,
        'staff', jsonb_build_object(
          'id', v_staff.id,
          'name', v_staff.full_name,
          'role', v_staff.role
        )
      );
    END IF;
  END LOOP;

  RETURN jsonb_build_object('success', false, 'message', 'Invalid PIN');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
