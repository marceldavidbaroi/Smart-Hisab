-- ==============================================================================
-- MODULE 1: AUTH & MULTI-TENANCY (SCHEMA)
-- Purpose: User profiles, tenant organizations, membership roles, and invites.
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

-- ------------------------------------------------------------------------------
-- Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_invites ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Users can read own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Tenants Policies
CREATE POLICY "Tenant members can view their tenant" ON public.tenants
    FOR SELECT USING (public.is_tenant_member(id));

CREATE POLICY "Owners can update their tenant" ON public.tenants
    FOR UPDATE USING (public.is_tenant_owner(id));

-- Tenant Members Policies
CREATE POLICY "Members can view membership in their tenants" ON public.tenant_members
    FOR SELECT USING (tenant_id IN (SELECT public.get_my_tenant_ids()));

CREATE POLICY "Owners can manage memberships" ON public.tenant_members
    FOR ALL USING (public.is_tenant_owner(tenant_id));

-- Tenant Invites Policies
CREATE POLICY "Managers and owners can view invites" ON public.tenant_invites
    FOR SELECT USING (public.is_tenant_member(tenant_id));

CREATE POLICY "Owners and managers can create invites" ON public.tenant_invites
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

CREATE POLICY "Anyone authenticated can lookup active invite by code" ON public.tenant_invites
    FOR SELECT TO authenticated USING (is_active = true AND expires_at > now());
