-- Migration: Remove auto-seed default shifts on tenant creation
DROP TRIGGER IF EXISTS auto_seed_default_shifts ON public.tenants;
DROP FUNCTION IF EXISTS public.handle_new_tenant();
