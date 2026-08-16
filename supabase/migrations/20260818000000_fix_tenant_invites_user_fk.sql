-- Fix foreign key constraints on public.tenant_invites for user deletion
-- 1. Make created_by nullable so ON DELETE SET NULL works
ALTER TABLE public.tenant_invites
  ALTER COLUMN created_by DROP NOT NULL;

-- 2. Update created_by foreign key constraint to ON DELETE SET NULL
ALTER TABLE public.tenant_invites
  DROP CONSTRAINT IF EXISTS tenant_invites_created_by_fkey,
  ADD CONSTRAINT tenant_invites_created_by_fkey
    FOREIGN KEY (created_by)
    REFERENCES auth.users(id)
    ON DELETE SET NULL;

-- 3. Also update used_by foreign key constraint to ON DELETE SET NULL for consistency
ALTER TABLE public.tenant_invites
  DROP CONSTRAINT IF EXISTS tenant_invites_used_by_fkey,
  ADD CONSTRAINT tenant_invites_used_by_fkey
    FOREIGN KEY (used_by)
    REFERENCES auth.users(id)
    ON DELETE SET NULL;
