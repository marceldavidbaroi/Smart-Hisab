-- ==============================================================================
-- DOMAIN 03: CUSTOMERS & MEAL ATTENDANCE / AR — ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Enable RLS on all domain tables
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_attendance ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. Customers Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view customers" ON public.customers;
CREATE POLICY "Tenant members can view customers" ON public.customers
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can manage customers" ON public.customers;
CREATE POLICY "Tenant members can manage customers" ON public.customers
    FOR ALL USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 3. Customer Wallets Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view customer wallets" ON public.customer_wallets;
CREATE POLICY "Tenant members can view customer wallets" ON public.customer_wallets
    FOR SELECT USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 4. Meal Configurations Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view meal configs" ON public.meal_configs;
CREATE POLICY "Tenant members can view meal configs" ON public.meal_configs
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant managers can manage meal configs" ON public.meal_configs;
CREATE POLICY "Tenant managers can manage meal configs" ON public.meal_configs
    FOR ALL USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 5. Meal Attendance Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view meal attendance" ON public.meal_attendance;
CREATE POLICY "Tenant members can view meal attendance" ON public.meal_attendance
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert meal attendance" ON public.meal_attendance;
CREATE POLICY "Tenant members can insert meal attendance" ON public.meal_attendance
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));
