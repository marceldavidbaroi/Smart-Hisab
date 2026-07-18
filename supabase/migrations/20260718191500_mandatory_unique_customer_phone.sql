-- Migration: Make customer phone unique per tenant and mandatory
-- Update existing null/empty phone numbers to prevent failures
UPDATE public.customers 
SET phone = 'N/A-' || substring(id::text, 1, 8) 
WHERE phone IS NULL OR trim(phone) = '';

-- Alter column to NOT NULL
ALTER TABLE public.customers ALTER COLUMN phone SET NOT NULL;

-- Enforce check constraint for non-empty string
ALTER TABLE public.customers ADD CONSTRAINT check_phone_not_empty CHECK (length(trim(phone)) > 0);

-- Enforce unique constraint per tenant
ALTER TABLE public.customers ADD CONSTRAINT customers_tenant_phone_key UNIQUE (tenant_id, phone);
