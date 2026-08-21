-- ==============================================================================
-- DOMAIN 05: VENDORS & ACCOUNTS PAYABLE — TYPES & ENUMS
-- ==============================================================================

DO $$ BEGIN
    CREATE TYPE public.vendor_entry_type AS ENUM ('debit', 'credit');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.vendor_entry_category AS ENUM ('supplies', 'payment', 'adjustment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
