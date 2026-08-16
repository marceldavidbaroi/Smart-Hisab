-- Migration: Ensure recorded_by_staff_id and metadata columns exist on wallet_entries, day_entries, and vendor_wallet_entries
-- Description: Uses explicit information_schema checks to force column creation on live database tables.

DO $$ 
BEGIN
  -- 1. Ensure recorded_by_staff_id on wallet_entries
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'wallet_entries' 
      AND column_name = 'recorded_by_staff_id'
  ) THEN
    ALTER TABLE public.wallet_entries ADD COLUMN recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL;
  END IF;

  -- 2. Ensure metadata on wallet_entries
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'wallet_entries' 
      AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.wallet_entries ADD COLUMN metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
  END IF;

  -- 3. Ensure recorded_by_staff_id on vendor_wallet_entries
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'vendor_wallet_entries' 
      AND column_name = 'recorded_by_staff_id'
  ) THEN
    ALTER TABLE public.vendor_wallet_entries ADD COLUMN recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL;
  END IF;

  -- 4. Ensure metadata on vendor_wallet_entries
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'vendor_wallet_entries' 
      AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.vendor_wallet_entries ADD COLUMN metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
  END IF;

  -- 5. Ensure created_by_staff_id on day_entries
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'day_entries' 
      AND column_name = 'created_by_staff_id'
  ) THEN
    ALTER TABLE public.day_entries ADD COLUMN created_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL;
  END IF;

  -- 6. Ensure metadata on day_entries
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'day_entries' 
      AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.day_entries ADD COLUMN metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
  END IF;
END $$;


-- Re-create RPC: void_wallet_entry
CREATE OR REPLACE FUNCTION public.void_wallet_entry(
  p_tenant_id UUID,
  p_entry_id UUID,
  p_reason TEXT,
  p_staff_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_entry RECORD;
  v_bday RECORD;
  v_reversal_id UUID := gen_random_uuid();
  v_adj_amount NUMERIC(12,2);
  v_void_info JSONB;
  v_result JSONB;
BEGIN
  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RAISE EXCEPTION 'A cancellation reason is required to void a transaction.';
  END IF;

  SELECT * INTO v_entry
  FROM public.wallet_entries
  WHERE id = p_entry_id AND tenant_id = p_tenant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet entry not found.';
  END IF;

  IF (v_entry.metadata->>'status') = 'voided' THEN
    RAISE EXCEPTION 'This transaction has already been voided.';
  END IF;

  IF v_entry.business_day_id IS NOT NULL THEN
    SELECT * INTO v_bday
    FROM public.business_days
    WHERE id = v_entry.business_day_id;

    IF FOUND AND v_bday.status = 'closed' THEN
      RAISE EXCEPTION 'Cannot void a transaction from a closed business day.';
    END IF;
  END IF;

  v_void_info := jsonb_build_object(
    'reason', p_reason,
    'voided_at', now(),
    'voided_by_staff_id', p_staff_id,
    'reversal_entry_id', v_reversal_id
  );

  UPDATE public.wallet_entries
  SET metadata = jsonb_set(
        COALESCE(metadata, '{}'::jsonb),
        '{status}', '"voided"'
      ) || jsonb_build_object('void_info', v_void_info)
  WHERE id = p_entry_id;

  IF v_entry.type = 'payment' THEN
    v_adj_amount := v_entry.amount;
  ELSE
    v_adj_amount := -v_entry.amount;
  END IF;

  INSERT INTO public.wallet_entries (
    id,
    tenant_id,
    wallet_id,
    business_day_id,
    shift_id,
    type,
    amount,
    reference_type,
    reference_id,
    recorded_by_staff_id,
    notes,
    metadata
  ) VALUES (
    v_reversal_id,
    v_entry.tenant_id,
    v_entry.wallet_id,
    v_entry.business_day_id,
    v_entry.shift_id,
    'adjustment',
    v_adj_amount,
    'manual_adjustment',
    p_entry_id,
    p_staff_id,
    'Reversal: ' || p_reason,
    jsonb_build_object(
      'status', 'reversal',
      'original_entry_id', p_entry_id,
      'reason', p_reason
    )
  );

  IF v_entry.type = 'payment' THEN
    INSERT INTO public.day_entries (
      tenant_id,
      business_day_id,
      shift_id,
      entry_type,
      category,
      amount,
      reference_type,
      reference_id,
      notes,
      created_by_staff_id,
      metadata
    ) VALUES (
      v_entry.tenant_id,
      v_entry.business_day_id,
      v_entry.shift_id,
      'outflow',
      'customer_payment',
      v_entry.amount,
      'wallet_entry',
      v_reversal_id,
      'Reversal of voided cash payment: ' || p_reason,
      p_staff_id,
      jsonb_build_object(
        'status', 'reversal',
        'original_entry_id', p_entry_id,
        'reason', p_reason
      )
    );
  END IF;

  v_result := jsonb_build_object(
    'success', true,
    'voided_entry_id', p_entry_id,
    'reversal_entry_id', v_reversal_id
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.void_wallet_entry(UUID, UUID, TEXT, UUID) TO authenticated, anon;
