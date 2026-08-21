-- ==============================================================================
-- DOMAIN 03: CUSTOMERS & MEAL ATTENDANCE / AR — TABLES & STRUCTURES
-- ==============================================================================

-- 1. Customers Directory
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    opening_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    subscribed_shifts UUID[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Unique phone per tenant (when phone provided)
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_tenant_phone_unique 
    ON public.customers(tenant_id, phone) 
    WHERE phone IS NOT NULL AND phone != '';

-- 2. Customer Wallets (Aggregated Balance & Cache)
CREATE TABLE IF NOT EXISTS public.customer_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE UNIQUE,
    current_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_debit NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_credit NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    last_transaction_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Meal Configurations (Meal Types & Rates)
CREATE TABLE IF NOT EXISTS public.meal_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    meal_name TEXT NOT NULL,
    default_rate NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    auto_punch_enabled BOOLEAN DEFAULT false,
    auto_punch_time TIME,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Meal Attendance (Daily Meal Punches)
CREATE TABLE IF NOT EXISTS public.meal_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE SET NULL,
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    meal_config_id UUID REFERENCES public.meal_configs(id) ON DELETE SET NULL,
    meal_date DATE NOT NULL DEFAULT CURRENT_DATE,
    rate NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    is_manual BOOLEAN DEFAULT false,
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
CREATE INDEX IF NOT EXISTS idx_customers_tenant_active ON public.customers(tenant_id, is_active);
CREATE INDEX IF NOT EXISTS idx_customer_wallets_balance ON public.customer_wallets(tenant_id, current_balance);
CREATE INDEX IF NOT EXISTS idx_meal_configs_tenant ON public.meal_configs(tenant_id, is_active);
CREATE INDEX IF NOT EXISTS idx_meal_attendance_tenant_date ON public.meal_attendance(tenant_id, meal_date DESC);
CREATE INDEX IF NOT EXISTS idx_meal_attendance_customer ON public.meal_attendance(customer_id, is_voided);
