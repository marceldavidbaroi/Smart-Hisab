-- Migration: Add Metadata Column and Transaction Voiding RPCs
-- Description: Adds metadata JSONB column to wallet_entries, vendor_wallet_entries, and day_entries.
--              Provides void_wallet_entry and void_day_entry RPCs for reversing transaction mistakes with reason.

-- 1. Add missing columns to ledger tables if missing
ALTER TABLE public.wallet_entries 
ADD COLUMN IF NOT EXISTS recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL;

ALTER TABLE public.wallet_entries 
ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.vendor_wallet_entries 
ADD COLUMN IF NOT EXISTS recorded_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL;

ALTER TABLE public.vendor_wallet_entries 
ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.day_entries 
ADD COLUMN IF NOT EXISTS created_by_staff_id UUID REFERENCES public.staff_members(id) ON DELETE SET NULL;

ALTER TABLE public.day_entries 
ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;


-- 2. Add indexes for status filtering in metadata
CREATE INDEX IF NOT EXISTS idx_wallet_entries_metadata_status 
ON public.wallet_entries ((metadata->>'status'));

CREATE INDEX IF NOT EXISTS idx_vendor_wallet_entries_metadata_status 
ON public.vendor_wallet_entries ((metadata->>'status'));

CREATE INDEX IF NOT EXISTS idx_day_entries_metadata_status 
ON public.day_entries ((metadata->>'status'));


-- 3. RPC: void_wallet_entry
-- Allows staff/owners to void/reverse a mistaken customer Baki charge or payment entry.
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
  -- Validate mandatory reason
  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RAISE EXCEPTION 'A cancellation reason is required to void a transaction.';
  END IF;

  -- Fetch original entry
  SELECT * INTO v_entry
  FROM public.wallet_entries
  WHERE id = p_entry_id AND tenant_id = p_tenant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet entry not found.';
  END IF;

  -- Check if already voided
  IF (v_entry.metadata->>'status') = 'voided' THEN
    RAISE EXCEPTION 'This transaction has already been voided.';
  END IF;

  -- Verify active business day is still OPEN
  IF v_entry.business_day_id IS NOT NULL THEN
    SELECT * INTO v_bday
    FROM public.business_days
    WHERE id = v_entry.business_day_id;

    IF FOUND AND v_bday.status = 'closed' THEN
      RAISE EXCEPTION 'Cannot void a transaction from a closed business day.';
    END IF;
  END IF;

  -- Build void info JSON
  v_void_info := jsonb_build_object(
    'reason', p_reason,
    'voided_at', now(),
    'voided_by_staff_id', p_staff_id,
    'reversal_entry_id', v_reversal_id
  );

  -- Update original entry metadata to voided
  UPDATE public.wallet_entries
  SET metadata = jsonb_set(
        COALESCE(metadata, '{}'::jsonb),
        '{status}', '"voided"'
      ) || jsonb_build_object('void_info', v_void_info)
  WHERE id = p_entry_id;

  -- Compute balancing reversal adjustment amount
  -- If original was payment (which reduced debt), adjustment = +amount (increases debt back)
  -- If original was meal_charge (which increased debt), adjustment = -amount (reduces debt back)
  IF v_entry.type = 'payment' THEN
    v_adj_amount := v_entry.amount;
  ELSE
    v_adj_amount := -v_entry.amount;
  END IF;

  -- Insert opposing reversal wallet entry
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

  -- If original entry was a cash payment, balance the cashbook (day_entries) by creating a cash outflow entry
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


-- 4. RPC: void_day_entry
-- Allows staff/owners to void/reverse an erroneous cashbook entry (e.g. market expense, income).
CREATE OR REPLACE FUNCTION public.void_day_entry(
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
  v_rev_entry_type TEXT;
  v_void_info JSONB;
  v_result JSONB;
BEGIN
  -- Validate mandatory reason
  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RAISE EXCEPTION 'A cancellation reason is required to void a cashbook entry.';
  END IF;

  -- Fetch original entry
  SELECT * INTO v_entry
  FROM public.day_entries
  WHERE id = p_entry_id AND tenant_id = p_tenant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cashbook entry not found.';
  END IF;

  -- Check if already voided
  IF (v_entry.metadata->>'status') = 'voided' THEN
    RAISE EXCEPTION 'This entry has already been voided.';
  END IF;

  -- Verify active business day is still OPEN
  IF v_entry.business_day_id IS NOT NULL THEN
    SELECT * INTO v_bday
    FROM public.business_days
    WHERE id = v_entry.business_day_id;

    IF FOUND AND v_bday.status = 'closed' THEN
      RAISE EXCEPTION 'Cannot void a transaction from a closed business day.';
    END IF;
  END IF;

  -- Build void info JSON
  v_void_info := jsonb_build_object(
    'reason', p_reason,
    'voided_at', now(),
    'voided_by_staff_id', p_staff_id,
    'reversal_entry_id', v_reversal_id
  );

  -- Update original entry metadata to voided
  UPDATE public.day_entries
  SET metadata = jsonb_set(
        COALESCE(metadata, '{}'::jsonb),
        '{status}', '"voided"'
      ) || jsonb_build_object('void_info', v_void_info)
  WHERE id = p_entry_id;

  -- Opposite entry type: inflow -> outflow, outflow -> inflow
  IF v_entry.entry_type = 'inflow' THEN
    v_rev_entry_type := 'outflow';
  ELSE
    v_rev_entry_type := 'inflow';
  END IF;

  -- Insert balancing reversal day entry
  INSERT INTO public.day_entries (
    id,
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
    created_by_user_id,
    metadata
  ) VALUES (
    v_reversal_id,
    v_entry.tenant_id,
    v_entry.business_day_id,
    v_entry.shift_id,
    v_rev_entry_type,
    v_entry.category,
    v_entry.amount,
    'direct_expense',
    p_entry_id,
    'Reversal: ' || p_reason,
    p_staff_id,
    auth.uid(),
    jsonb_build_object(
      'status', 'reversal',
      'original_entry_id', p_entry_id,
      'reason', p_reason
    )
  );

  v_result := jsonb_build_object(
    'success', true,
    'voided_entry_id', p_entry_id,
    'reversal_entry_id', v_reversal_id
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5. Grant permissions to authenticated & anon roles
GRANT EXECUTE ON FUNCTION public.void_wallet_entry(UUID, UUID, TEXT, UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.void_day_entry(UUID, UUID, TEXT, UUID) TO authenticated, anon;
