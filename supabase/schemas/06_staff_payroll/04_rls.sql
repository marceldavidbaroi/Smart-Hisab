-- ==============================================================================
-- DOMAIN 06: STAFF & PAYROLL — ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Enable RLS on all domain tables
ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_payouts ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. Staff Members Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view staff" ON public.staff_members;
CREATE POLICY "Tenant members can view staff" ON public.staff_members
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant managers can manage staff" ON public.staff_members;
CREATE POLICY "Tenant managers can manage staff" ON public.staff_members
    FOR ALL USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 3. Staff Wallets Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view staff wallets" ON public.staff_wallets;
CREATE POLICY "Tenant members can view staff wallets" ON public.staff_wallets
    FOR SELECT USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 4. Staff Attendance Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view staff attendance" ON public.staff_attendance;
CREATE POLICY "Tenant members can view staff attendance" ON public.staff_attendance
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert staff attendance" ON public.staff_attendance;
CREATE POLICY "Tenant members can insert staff attendance" ON public.staff_attendance
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 5. Salary Payouts Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view salary payouts" ON public.salary_payouts;
CREATE POLICY "Tenant members can view salary payouts" ON public.salary_payouts
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant managers can insert salary payouts" ON public.salary_payouts;
CREATE POLICY "Tenant managers can insert salary payouts" ON public.salary_payouts
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant managers can update salary payouts" ON public.salary_payouts;
CREATE POLICY "Tenant managers can update salary payouts" ON public.salary_payouts
    FOR UPDATE USING (public.is_tenant_member(tenant_id));
