-- Migration: Drop Legacy Tables (Sessions, Baki Transactions, Collections, Old Attendance, Old Ledger)
-- Replaced by Master Architecture: customer_wallets, wallet_entries, day_entries, meal_attendance

-- 1. Drop Deprecated RPC Functions referencing legacy tables
DROP FUNCTION IF EXISTS public.open_session(uuid, uuid, text, numeric, text) CASCADE;
DROP FUNCTION IF EXISTS public.close_session(uuid, uuid, text, numeric, text) CASCADE;
DROP FUNCTION IF EXISTS public.reopen_session(uuid, uuid, text, text) CASCADE;

-- 2. Drop Legacy Tables
DROP TABLE IF EXISTS public.sessions CASCADE;
DROP TABLE IF EXISTS public.customer_daily_attendance CASCADE;
DROP TABLE IF EXISTS public.baki_transactions CASCADE;
DROP TABLE IF EXISTS public.customer_collections CASCADE;
DROP TABLE IF EXISTS public.transaction_ledger CASCADE;
