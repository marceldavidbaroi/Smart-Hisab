-- ==============================================================================
-- MODULE 4: CASHBOOK & CANTEEN WALLETS (SCHEMA)
-- Purpose: Canteen financial accounts (Cash Drawer, bKash, Bank),
--          day entries (Income/Expenses), wallet transactions, and void audit logs.
-- ==============================================================================

-- 1. Canteen Accounts & Wallets
CREATE TABLE IF NOT EXISTS public.canteen_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    account_type TEXT NOT NULL CHECK (account_type IN ('cash_drawer', 'bkash', 'nagad', 'bank', 'other')),
    account_number TEXT,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    current_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Day Entries (Operational Cashbook Register)
CREATE TABLE IF NOT EXISTS public.day_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE CASCADE,
    canteen_account_id UUID REFERENCES public.canteen_accounts(id) ON DELETE SET NULL,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('income', 'expense')),
    category TEXT NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    notes TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    is_voided BOOLEAN DEFAULT false,
    voided_at TIMESTAMPTZ,
    voided_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    void_reason TEXT
);

-- 3. Wallet Entries (Master Double-Entry Journal)
CREATE TABLE IF NOT EXISTS public.wallet_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES public.staff_members(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
    canteen_account_id UUID REFERENCES public.canteen_accounts(id) ON DELETE SET NULL,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('debit', 'credit')),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    category TEXT NOT NULL,
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
CREATE INDEX IF NOT EXISTS idx_canteen_accounts_tenant ON public.canteen_accounts(tenant_id, is_active);
CREATE INDEX IF NOT EXISTS idx_day_entries_day_type ON public.day_entries(business_day_id, entry_type, is_voided);
CREATE INDEX IF NOT EXISTS idx_day_entries_tenant_date ON public.day_entries(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_entries_tenant_date ON public.wallet_entries(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_entries_customer ON public.wallet_entries(customer_id, is_voided);
CREATE INDEX IF NOT EXISTS idx_wallet_entries_account ON public.wallet_entries(canteen_account_id, is_voided);

-- ------------------------------------------------------------------------------
-- Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.canteen_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant members can view canteen accounts" ON public.canteen_accounts
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant managers can manage canteen accounts" ON public.canteen_accounts
    FOR ALL USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can view day entries" ON public.day_entries
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can insert day entries" ON public.day_entries
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can view wallet entries" ON public.wallet_entries
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Tenant members can insert wallet entries" ON public.wallet_entries
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));
