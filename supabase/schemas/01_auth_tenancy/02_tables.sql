-- ==============================================================================
-- DOMAIN 01: AUTH & MULTI-TENANCY — TABLES & STRUCTURES
-- ==============================================================================

-- 1. User Profiles (Extends auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    is_superadmin BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Tenants (Canteen Organizations)
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    currency TEXT DEFAULT 'BDT',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Tenant Memberships & Roles
CREATE TABLE IF NOT EXISTS public.tenant_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'staff')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, user_id)
);

-- 4. Tenant Invites (6-Digit Join Codes)
CREATE TABLE IF NOT EXISTS public.tenant_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    invite_code TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'manager' CHECK (role IN ('owner', 'manager', 'staff')),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    max_uses INT DEFAULT 1,
    uses_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ------------------------------------------------------------------------------
-- Indexes for Performance
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_tenant_members_tenant ON public.tenant_members(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_members_user ON public.tenant_members(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_invites_code ON public.tenant_invites(invite_code);
CREATE INDEX IF NOT EXISTS idx_tenant_invites_tenant ON public.tenant_invites(tenant_id);
