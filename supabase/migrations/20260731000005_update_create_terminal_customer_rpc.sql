-- Migration: Update create_terminal_customer RPC to support address and institution fields

CREATE OR REPLACE FUNCTION public.create_terminal_customer(
  p_tenant_id UUID,
  p_full_name TEXT,
  p_phone TEXT DEFAULT NULL,
  p_factory_unit TEXT DEFAULT NULL,
  p_contract_daily_rate NUMERIC DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_institution TEXT DEFAULT NULL
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
    address,
    institution,
    is_active
  ) VALUES (
    p_tenant_id,
    TRIM(p_full_name),
    NULLIF(TRIM(p_phone), ''),
    NULLIF(TRIM(p_factory_unit), ''),
    p_contract_daily_rate,
    NULLIF(TRIM(p_address), ''),
    NULLIF(TRIM(p_institution), ''),
    TRUE
  )
  RETURNING * INTO v_new_customer;

  RETURN row_to_json(v_new_customer);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Grant execution to anon, authenticated, and service_role
GRANT EXECUTE ON FUNCTION public.create_terminal_customer(UUID, TEXT, TEXT, TEXT, NUMERIC, TEXT, TEXT) TO anon, authenticated, service_role;
