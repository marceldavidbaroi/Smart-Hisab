-- ==============================================================================
-- DOMAIN 03: CUSTOMERS & MEAL ATTENDANCE / AR — TYPES & ENUMS
-- ==============================================================================

DO $$ BEGIN
    CREATE TYPE public.wallet_entry_type AS ENUM ('debit', 'credit');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.customer_wallet_category AS ENUM ('meal', 'baki_payment', 'manual_debit', 'adjustment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
