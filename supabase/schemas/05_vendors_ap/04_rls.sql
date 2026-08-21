-- ==============================================================================
-- DOMAIN 05: VENDORS & ACCOUNTS PAYABLE — ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Enable RLS on all domain tables
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_wallet_entries ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. Vendors Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view vendors" ON public.vendors;
CREATE POLICY "Tenant members can view vendors" ON public.vendors
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can manage vendors" ON public.vendors;
CREATE POLICY "Tenant members can manage vendors" ON public.vendors
    FOR ALL USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 3. Vendor Wallets Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view vendor wallets" ON public.vendor_wallets;
CREATE POLICY "Tenant members can view vendor wallets" ON public.vendor_wallets
    FOR SELECT USING (public.is_tenant_member(tenant_id));

-- ------------------------------------------------------------------------------
-- 4. Vendor Wallet Entries Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view vendor entries" ON public.vendor_wallet_entries;
CREATE POLICY "Tenant members can view vendor entries" ON public.vendor_wallet_entries
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can insert vendor entries" ON public.vendor_wallet_entries;
CREATE POLICY "Tenant members can insert vendor entries" ON public.vendor_wallet_entries
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Tenant members can update vendor entries" ON public.vendor_wallet_entries;
CREATE POLICY "Tenant members can update vendor entries" ON public.vendor_wallet_entries
    FOR UPDATE USING (public.is_tenant_member(tenant_id));
