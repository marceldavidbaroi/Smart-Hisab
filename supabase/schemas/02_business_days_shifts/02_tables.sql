-- ==============================================================================
-- DOMAIN 02: BUSINESS DAYS & SHIFTS — TABLES & STRUCTURES
-- ==============================================================================

-- 1. Business Days Register
CREATE TABLE IF NOT EXISTS public.business_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    opened_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    closed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    opening_balance NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    actual_closing_cash NUMERIC(12,2),
    expected_closing_cash NUMERIC(12,2),
    cash_difference NUMERIC(12,2),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Operating Shifts
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Day Notes (Daily operational notes / reminders)
CREATE TABLE IF NOT EXISTS public.day_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    business_day_id UUID REFERENCES public.business_days(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------------------------------------------------------------------
-- Indexes for Performance
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_business_days_tenant_status ON public.business_days(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_business_days_opened_at ON public.business_days(opened_at DESC);
CREATE INDEX IF NOT EXISTS idx_shifts_tenant_active ON public.shifts(tenant_id, is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_day_notes_day ON public.day_notes(business_day_id);
