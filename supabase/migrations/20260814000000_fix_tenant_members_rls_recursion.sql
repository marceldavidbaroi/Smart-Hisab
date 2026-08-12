-- Migration: Fix infinite recursion (Error 42P17) in tenant_members & tenants RLS policies
-- SECURITY DEFINER function breaks RLS recursion when querying tenant_members.

CREATE OR REPLACE FUNCTION public.get_my_tenant_ids()
RETURNS SETOF UUID AS $$
BEGIN
  RETURN QUERY
  SELECT tenant_id
  FROM public.tenant_members
  WHERE user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Re-create tenants_select policy using SECURITY DEFINER helper function
DROP POLICY IF EXISTS tenants_select ON public.tenants;
CREATE POLICY tenants_select ON public.tenants FOR SELECT USING (
  public.is_tenant_member(id) OR public.is_superadmin()
);

-- Re-create tenant_members_select policy using SECURITY DEFINER function to eliminate RLS recursion
DROP POLICY IF EXISTS tenant_members_select ON public.tenant_members;
CREATE POLICY tenant_members_select ON public.tenant_members FOR SELECT USING (
  user_id = auth.uid() OR tenant_id IN (SELECT public.get_my_tenant_ids())
);
