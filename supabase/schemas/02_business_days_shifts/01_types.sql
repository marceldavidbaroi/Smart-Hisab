-- ==============================================================================
-- DOMAIN 02: BUSINESS DAYS & SHIFTS — TYPES & ENUMS
-- ==============================================================================

DO $$ BEGIN
    CREATE TYPE public.business_day_status AS ENUM ('open', 'closed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
