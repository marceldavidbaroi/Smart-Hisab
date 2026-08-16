-- Migration: Enforce unique phone number per tenant for active customers
-- Filename: 20260823000000_unique_customer_phone_per_tenant.sql

-- 1. Create unique partial index to enforce unique phone per tenant among active customers
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_customer_phone_per_tenant
ON public.customers (tenant_id, phone)
WHERE (is_active = true);
