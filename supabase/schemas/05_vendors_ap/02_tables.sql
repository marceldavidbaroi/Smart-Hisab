-- ==============================================================================
-- DOMAIN 05: VENDORS & ACCOUNTS PAYABLE — TABLES & STRUCTURES
-- ==============================================================================

-- 1. Vendors Directory
CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    category TEXT DEFAULT 'general',
    opening_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Vendor Wallets (Aggregated Payable Balance Cache)
CREATE TABLE IF NOT EXISTS public.vendor_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE UNIQUE,
    current_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_debit NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_credit NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    last_transaction_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Vendor Wallet Entries (Debit = Purchase Baki, Credit = Settlement Payment)
CREATE TABLE IF NOT EXISTS public.vendor_wallet_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
    canteen_account_id UUID REFERENCES public.canteen_accounts(id) ON DELETE SET NULL,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('debit', 'credit')),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    category TEXT NOT NULL DEFAULT 'supplies',
    notes TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    is_voided BOOLEAN DEFAULT false,
    voided_at TIMESTAMPTZ,
    voided_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    void_reason TEXT
);

-- ------------------------------------------------------------------------------
-- Indexes for Performance
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_vendors_tenant_active ON public.vendors(tenant_id, is_active);
CREATE INDEX IF NOT EXISTS idx_vendor_wallets_balance ON public.vendor_wallets(tenant_id, current_balance);
CREATE INDEX IF NOT EXISTS idx_vendor_wallet_entries_vendor ON public.vendor_wallet_entries(vendor_id, is_voided);
CREATE INDEX IF NOT EXISTS idx_vendor_wallet_entries_tenant ON public.vendor_wallet_entries(tenant_id, created_at DESC);
