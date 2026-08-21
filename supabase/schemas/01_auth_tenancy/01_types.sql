-- ==============================================================================
-- DOMAIN 01: AUTH & MULTI-TENANCY — TYPES & ENUMS
-- ==============================================================================

DO $$ BEGIN
    CREATE TYPE public.canteen_role AS ENUM ('owner', 'manager', 'staff');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.invite_status AS ENUM ('active', 'expired', 'exhausted', 'revoked');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
