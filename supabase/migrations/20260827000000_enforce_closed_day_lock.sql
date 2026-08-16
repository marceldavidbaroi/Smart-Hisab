-- Migration: Enforce Closed Business Day Lock Trigger
-- Description: Adds check_closed_day_lock trigger function and applies it to
--              wallet_entries, day_entries, meal_attendance, and vendor_wallet_entries
--              to prevent modifications on closed business days.

CREATE OR REPLACE FUNCTION public.check_closed_day_lock()
RETURNS TRIGGER AS $$
DECLARE
  v_day_id UUID;
  v_day_status TEXT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_day_id := OLD.business_day_id;
  ELSE
    v_day_id := NEW.business_day_id;
  END IF;

  IF v_day_id IS NOT NULL THEN
    SELECT status INTO v_day_status FROM public.business_days WHERE id = v_day_id;
    IF v_day_status = 'closed' THEN
      RAISE EXCEPTION 'Cannot modify records tied to a closed business day.';
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply to ledger tables
DROP TRIGGER IF EXISTS enforce_closed_day_lock ON public.wallet_entries;
CREATE TRIGGER enforce_closed_day_lock
  BEFORE INSERT OR UPDATE OR DELETE ON public.wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.check_closed_day_lock();

DROP TRIGGER IF EXISTS enforce_closed_day_lock ON public.day_entries;
CREATE TRIGGER enforce_closed_day_lock
  BEFORE INSERT OR UPDATE OR DELETE ON public.day_entries
  FOR EACH ROW EXECUTE FUNCTION public.check_closed_day_lock();

DROP TRIGGER IF EXISTS enforce_closed_day_lock ON public.meal_attendance;
CREATE TRIGGER enforce_closed_day_lock
  BEFORE INSERT OR UPDATE OR DELETE ON public.meal_attendance
  FOR EACH ROW EXECUTE FUNCTION public.check_closed_day_lock();

DROP TRIGGER IF EXISTS enforce_closed_day_lock ON public.vendor_wallet_entries;
CREATE TRIGGER enforce_closed_day_lock
  BEFORE INSERT OR UPDATE OR DELETE ON public.vendor_wallet_entries
  FOR EACH ROW EXECUTE FUNCTION public.check_closed_day_lock();
