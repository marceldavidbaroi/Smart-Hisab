-- Migration: Add subscribed_shifts to customers table
-- Description: Adds subscribed_shifts array column to allow customers to have active meal subscriptions (e.g. Lunch, Dinner).

ALTER TABLE public.customers
ADD COLUMN IF NOT EXISTS subscribed_shifts TEXT[] DEFAULT '{}';

-- Update create_or_reactivate_customer RPC to return subscribed_shifts
CREATE OR REPLACE FUNCTION public.create_or_reactivate_customer(
  p_tenant_id UUID,
  p_name TEXT,
  p_phone TEXT,
  p_address TEXT DEFAULT NULL,
  p_institution TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_existing RECORD;
  v_customer_id UUID;
  v_wallet_id UUID;
  v_balance NUMERIC(12,2) := 0;
  v_is_reactivated BOOLEAN := false;
  v_subscribed_shifts TEXT[] := '{}';
BEGIN
  -- 1. Check for existing active customer
  SELECT * INTO v_existing FROM public.customers
  WHERE tenant_id = p_tenant_id AND phone = p_phone AND is_active = true;

  IF FOUND THEN
    RAISE EXCEPTION 'An active customer with phone % already exists.', p_phone;
  END IF;

  -- 2. Check for inactive customer to reactivate
  SELECT * INTO v_existing FROM public.customers
  WHERE tenant_id = p_tenant_id AND phone = p_phone AND is_active = false
  ORDER BY created_at DESC LIMIT 1;

  IF FOUND THEN
    UPDATE public.customers
    SET is_active = true,
        name = p_name,
        address = COALESCE(p_address, address),
        institution = COALESCE(p_institution, institution)
    WHERE id = v_existing.id
    RETURNING id, COALESCE(subscribed_shifts, '{}') INTO v_customer_id, v_subscribed_shifts;

    v_is_reactivated := true;
  ELSE
    -- 3. Create brand new customer
    INSERT INTO public.customers (
      tenant_id, name, phone, address, institution, is_active, subscribed_shifts
    ) VALUES (
      p_tenant_id, p_name, p_phone, p_address, p_institution, true, '{}'
    ) RETURNING id, subscribed_shifts INTO v_customer_id, v_subscribed_shifts;
  END IF;

  -- Fetch or ensure wallet exists
  SELECT id, current_balance INTO v_wallet_id, v_balance
  FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = v_customer_id;

  RETURN jsonb_build_object(
    'success', true,
    'is_reactivated', v_is_reactivated,
    'customer', jsonb_build_object(
      'id', v_customer_id,
      'tenant_id', p_tenant_id,
      'name', p_name,
      'phone', p_phone,
      'address', p_address,
      'institution', p_institution,
      'is_active', true,
      'subscribed_shifts', v_subscribed_shifts,
      'current_balance', COALESCE(v_balance, 0)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_or_reactivate_customer(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated, anon;
