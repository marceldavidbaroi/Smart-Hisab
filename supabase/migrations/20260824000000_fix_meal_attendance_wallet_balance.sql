-- Migration: Fix Meal Attendance Untoggle Balance Bug
-- Description: Updates sync_customer_wallet_balance to support both INSERT and DELETE
--              on wallet_entries, ensuring debt balance is reduced when meal attendance is removed.

CREATE OR REPLACE FUNCTION public.sync_customer_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.type = 'meal_charge' THEN
      UPDATE public.customer_wallets SET current_balance = current_balance + NEW.amount WHERE id = NEW.wallet_id;
    ELSIF NEW.type = 'payment' THEN
      UPDATE public.customer_wallets SET current_balance = current_balance - NEW.amount WHERE id = NEW.wallet_id;
    ELSIF NEW.type = 'adjustment' THEN
      UPDATE public.customer_wallets SET current_balance = current_balance + NEW.amount WHERE id = NEW.wallet_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.type = 'meal_charge' THEN
      UPDATE public.customer_wallets SET current_balance = current_balance - OLD.amount WHERE id = OLD.wallet_id;
    ELSIF OLD.type = 'payment' THEN
      UPDATE public.customer_wallets SET current_balance = current_balance + OLD.amount WHERE id = OLD.wallet_id;
    ELSIF OLD.type = 'adjustment' THEN
      UPDATE public.customer_wallets SET current_balance = current_balance - OLD.amount WHERE id = OLD.wallet_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_wallet_balance ON public.wallet_entries;
CREATE TRIGGER update_wallet_balance
  AFTER INSERT OR DELETE ON public.wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.sync_customer_wallet_balance();

-- Re-declare record_meal_attendance to re-fetch and return the updated balance accurately
CREATE OR REPLACE FUNCTION public.record_meal_attendance(
  p_tenant_id UUID,
  p_customer_id UUID,
  p_staff_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_day_id UUID;
  v_shift_id UUID;
  v_rate NUMERIC(10,2) := NULL;
  v_wallet_id UUID;
  v_att_id UUID;
  v_new_bal NUMERIC(12,2);
BEGIN
  v_day_id := public.start_business_day(p_tenant_id, p_staff_id, 0);
  v_shift_id := public.get_current_shift(p_tenant_id);

  -- 1. Try to get meal rate for specific shift if shift_id is active
  IF v_shift_id IS NOT NULL THEN
    SELECT rate INTO v_rate FROM public.meal_configs
    WHERE tenant_id = p_tenant_id AND shift_id = v_shift_id
    ORDER BY effective_from DESC LIMIT 1;
  END IF;

  -- 2. Fallback: Get latest configured meal rate for tenant
  IF v_rate IS NULL THEN
    SELECT rate INTO v_rate FROM public.meal_configs
    WHERE tenant_id = p_tenant_id
    ORDER BY effective_from DESC LIMIT 1;
  END IF;

  -- 3. Default fallback if no meal config exists yet
  IF v_rate IS NULL THEN v_rate := 0; END IF;

  SELECT id INTO v_wallet_id FROM public.customer_wallets
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id;

  -- Check if already marked for this shift & day (toggle off)
  SELECT id INTO v_att_id FROM public.meal_attendance
  WHERE tenant_id = p_tenant_id AND customer_id = p_customer_id
    AND business_day_id = v_day_id AND shift_id = v_shift_id;

  IF v_att_id IS NOT NULL THEN
    DELETE FROM public.meal_attendance WHERE id = v_att_id;
    DELETE FROM public.wallet_entries WHERE reference_id = v_att_id AND reference_type = 'meal_attendance';

    SELECT current_balance INTO v_new_bal FROM public.customer_wallets WHERE id = v_wallet_id;
    RETURN jsonb_build_object('action', 'removed', 'new_balance', v_new_bal);
  ELSE
    INSERT INTO public.meal_attendance (
      tenant_id, customer_id, business_day_id, shift_id, charge_amount, recorded_by_staff_id
    ) VALUES (
      p_tenant_id, p_customer_id, v_day_id, v_shift_id, v_rate, p_staff_id
    ) RETURNING id INTO v_att_id;

    INSERT INTO public.wallet_entries (
      tenant_id, wallet_id, business_day_id, shift_id, type, amount, reference_type, reference_id, recorded_by_staff_id
    ) VALUES (
      p_tenant_id, v_wallet_id, v_day_id, v_shift_id, 'meal_charge', v_rate, 'meal_attendance', v_att_id, p_staff_id
    );

    SELECT current_balance INTO v_new_bal FROM public.customer_wallets WHERE id = v_wallet_id;
    RETURN jsonb_build_object('action', 'added', 'new_balance', v_new_bal);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
