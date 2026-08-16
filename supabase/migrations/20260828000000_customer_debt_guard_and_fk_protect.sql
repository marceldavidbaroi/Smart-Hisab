-- Migration: Customer Debt Guard & Soft-Delete Protection
-- Description: Adds check_customer_debt_before_deactivation trigger to prevent
--              soft-deactivating customers who have an outstanding wallet balance.

CREATE OR REPLACE FUNCTION public.check_customer_debt_before_deactivation()
RETURNS TRIGGER AS $$
DECLARE
  v_balance NUMERIC(12,2);
BEGIN
  IF NEW.is_active = false AND OLD.is_active = true THEN
    SELECT current_balance INTO v_balance FROM public.customer_wallets WHERE customer_id = NEW.id;
    IF v_balance > 0 THEN
      RAISE EXCEPTION 'Cannot deactivate customer with outstanding debt balance of ৳%. Settle balance first.', v_balance;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_customer_debt_guard ON public.customers;
CREATE TRIGGER trg_customer_debt_guard
  BEFORE UPDATE OF is_active ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.check_customer_debt_before_deactivation();
