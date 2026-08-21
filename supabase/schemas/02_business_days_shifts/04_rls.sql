-- ==============================================================================
-- DOMAIN 02: BUSINESS DAYS & SHIFTS — ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Enable RLS on all domain tables
ALTER TABLE public.business_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_notes ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. Business Days Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view business days" ON public.business_days;
CREATE POLICY "Tenant members can view business days" ON public.business_days
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert business days" ON public.business_days;
CREATE POLICY "Tenant members can insert business days" ON public.business_days
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can update business days" ON public.business_days;
CREATE POLICY "Tenant members can update business days" ON public.business_days
    FOR UPDATE USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 3. Shifts Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view shifts" ON public.shifts;
CREATE POLICY "Tenant members can view shifts" ON public.shifts
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant managers can manage shifts" ON public.shifts;
CREATE POLICY "Tenant managers can manage shifts" ON public.shifts
    FOR ALL USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 4. Day Notes Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view day notes" ON public.day_notes;
CREATE POLICY "Tenant members can view day notes" ON public.day_notes
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert day notes" ON public.day_notes;
CREATE POLICY "Tenant members can insert day notes" ON public.day_notes
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));
