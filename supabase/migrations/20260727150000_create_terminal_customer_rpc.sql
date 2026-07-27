-- Migration: Add Security Definer RPC for Terminal Customer Creation
-- Created: 2026-07-27
-- Purpose: Bypasses table-level RLS on customers for POS terminal pairing devices while keeping search path safe and strict parameters.

CREATE OR REPLACE FUNCTION public.create_terminal_customer(
  p_tenant_id UUID,
  p_full_name TEXT,
  p_phone TEXT DEFAULT NULL,
  p_factory_unit TEXT DEFAULT NULL,
  p_contract_daily_rate NUMERIC DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
  v_new_customer customers%ROWTYPE;
BEGIN
  -- Input validation
  IF p_tenant_id IS NULL OR TRIM(p_full_name) = '' THEN
    RAISE EXCEPTION 'Tenant ID and Customer full name are required.';
  END IF;

  INSERT INTO public.customers (
    tenant_id,
    full_name,
    phone,
    factory_unit,
    contract_daily_rate,
    is_active
  ) VALUES (
    p_tenant_id,
    TRIM(p_full_name),
    NULLIF(TRIM(p_phone), ''),
    NULLIF(TRIM(p_factory_unit), ''),
    p_contract_daily_rate,
    TRUE
  )
  RETURNING * INTO v_new_customer;

  RETURN row_to_json(v_new_customer);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Grant execution to anon and authenticated roles for terminal device calls
GRANT EXECUTE ON FUNCTION public.create_terminal_customer(UUID, TEXT, TEXT, TEXT, NUMERIC) TO anon, authenticated, service_role;

-- Migration: Add Security Definer RPC for Terminal Customer Fetching
CREATE OR REPLACE FUNCTION public.get_terminal_customers(
  p_tenant_id UUID
) RETURNS SETOF customers AS $$
BEGIN
  IF p_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Tenant ID is required.';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.customers
  WHERE tenant_id = p_tenant_id
    AND is_active = TRUE
  ORDER BY full_name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

GRANT EXECUTE ON FUNCTION public.get_terminal_customers(UUID) TO anon, authenticated, service_role;

