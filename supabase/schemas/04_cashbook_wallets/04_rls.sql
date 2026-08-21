-- ==============================================================================
-- DOMAIN 04: CASHBOOK & CANTEEN WALLETS — ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Enable RLS on all domain tables
ALTER TABLE public.canteen_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_entries ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. Canteen Accounts Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view canteen accounts" ON public.canteen_accounts;
CREATE POLICY "Tenant members can view canteen accounts" ON public.canteen_accounts
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant managers can manage canteen accounts" ON public.canteen_accounts;
CREATE POLICY "Tenant managers can manage canteen accounts" ON public.canteen_accounts
    FOR ALL USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 3. Day Entries Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view day entries" ON public.day_entries;
CREATE POLICY "Tenant members can view day entries" ON public.day_entries
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert day entries" ON public.day_entries;
CREATE POLICY "Tenant members can insert day entries" ON public.day_entries
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can update day entries" ON public.day_entries;
CREATE POLICY "Tenant members can update day entries" ON public.day_entries
    FOR UPDATE USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 4. Wallet Entries Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view wallet entries" ON public.wallet_entries;
CREATE POLICY "Tenant members can view wallet entries" ON public.wallet_entries
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert wallet entries" ON public.wallet_entries;
CREATE POLICY "Tenant members can insert wallet entries" ON public.wallet_entries
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can update wallet entries" ON public.wallet_entries;
CREATE POLICY "Tenant members can update wallet entries" ON public.wallet_entries
    FOR UPDATE USING (public.is_tenant_member(tenant_id));
