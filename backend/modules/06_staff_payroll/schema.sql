-- ==============================================================================
-- MODULE 6: STAFF & PAYROLL (SCHEMA)
-- Purpose: Staff directory, wage contracts (daily vs monthly), salary advances,
--          attendance, and payroll vouchers.
-- ==============================================================================

-- 1. Staff Members Directory
CREATE TABLE IF NOT EXISTS public.staff_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'staff',
    salary_type TEXT NOT NULL DEFAULT 'monthly' CHECK (salary_type IN ('daily', 'monthly')),
    monthly_salary NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    daily_rate NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    pin_code TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Staff Wallets (Advance & Payroll Tracker Cache)
CREATE TABLE IF NOT EXISTS public.staff_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE UNIQUE,
    current_advance_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_salary_paid NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    last_payout_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Staff Attendance
CREATE TABLE IF NOT EXISTS public.staff_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'present' CHECK (status IN ('present', 'absent', 'half_day', 'leave')),
    check_in_time TIME,
    check_out_time TIME,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Salary Payouts & Advance Vouchers
CREATE TABLE IF NOT EXISTS public.salary_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES public.staff_members(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
    canteen_account_id UUID REFERENCES public.canteen_accounts(id) ON DELETE SET NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    payout_type TEXT NOT NULL DEFAULT 'salary' CHECK (payout_type IN ('advance', 'salary')),
    payout_month DATE,
    notes TEXT,
    paid_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    is_voided BOOLEAN DEFAULT false,
    voided_at TIMESTAMPTZ,
    voided_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    void_reason TEXT
);

-- ------------------------------------------------------------------------------
-- Indexes for Performance
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_staff_members_tenant_active ON public.staff_members(tenant_id, is_active);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_tenant_date ON public.staff_attendance(tenant_id, attendance_date DESC);
CREATE INDEX IF NOT EXISTS idx_salary_payouts_staff ON public.salary_payouts(staff_id, payout_month);
CREATE INDEX IF NOT EXISTS idx_salary_payouts_tenant ON public.salary_payouts(tenant_id, created_at DESC);

-- ------------------------------------------------------------------------------
-- Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_payouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant members can view staff" ON public.staff_members
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant managers can manage staff" ON public.staff_members
    FOR ALL USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can view staff wallets" ON public.staff_wallets
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can view staff attendance" ON public.staff_attendance
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can view salary payouts" ON public.salary_payouts
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant managers can insert salary payouts" ON public.salary_payouts
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));
