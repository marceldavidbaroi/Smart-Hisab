-- Migration: Add self-service delete policy to public.tenants
-- Enable tenant owners and superadmins to delete their tenants

create policy "Tenant owners can delete their tenants" on public.tenants
  for delete using (
    public.is_tenant_owner(id)
  );
