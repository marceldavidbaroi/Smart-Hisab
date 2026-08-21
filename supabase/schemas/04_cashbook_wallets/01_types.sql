-- ==============================================================================
-- DOMAIN 04: CASHBOOK & CANTEEN WALLETS — TYPES & ENUMS
-- ==============================================================================

DO $$ BEGIN
    CREATE TYPE public.canteen_account_type AS ENUM ('cash_drawer', 'bkash', 'nagad', 'bank', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.day_entry_type AS ENUM ('income', 'expense');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
