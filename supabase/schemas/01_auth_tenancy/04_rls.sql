-- ==============================================================================
-- DOMAIN 01: AUTH & MULTI-TENANCY — ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- 1. Enable RLS on all domain tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_invites ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. User Profiles Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- ------------------------------------------------------------------------------
-- 3. Tenants Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Tenant members can view their tenant" ON public.tenants;
CREATE POLICY "Tenant members can view their tenant" ON public.tenants
    FOR SELECT USING (public.is_tenant_member(id));

DROP POLICY IF EXISTS "Owners can update their tenant" ON public.tenants;
CREATE POLICY "Owners can update their tenant" ON public.tenants
    FOR UPDATE USING (public.is_tenant_owner(id));

-- ------------------------------------------------------------------------------
-- 4. Tenant Members Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Members can view membership in their tenants" ON public.tenant_members;
CREATE POLICY "Members can view membership in their tenants" ON public.tenant_members
    FOR SELECT USING (tenant_id IN (SELECT public.get_my_tenant_ids()));

DROP POLICY IF EXISTS "Owners can manage memberships" ON public.tenant_members;
CREATE POLICY "Owners can manage memberships" ON public.tenant_members
    FOR ALL USING (public.is_tenant_owner(tenant_id));

-- ------------------------------------------------------------------------------
-- 5. Tenant Invites Policies
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Managers and owners can view invites" ON public.tenant_invites;
CREATE POLICY "Managers and owners can view invites" ON public.tenant_invites
    FOR SELECT USING (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Owners and managers can create invites" ON public.tenant_invites;
CREATE POLICY "Owners and managers can create invites" ON public.tenant_invites
    FOR INSERT WITH CHECK (public.is_tenant_member(tenant_id));

DROP POLICY IF EXISTS "Anyone authenticated can lookup active invite by code" ON public.tenant_invites;
CREATE POLICY "Anyone authenticated can lookup active invite by code" ON public.tenant_invites
    FOR SELECT TO authenticated USING (is_active = true AND expires_at > now());
