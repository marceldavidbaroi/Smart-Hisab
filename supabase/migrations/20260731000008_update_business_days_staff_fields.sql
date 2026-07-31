-- Migration to update business_days schema: add opened_by_staff_id and closed_by_staff_id foreign keys to staff table
ALTER TABLE public.business_days 
  ADD COLUMN IF NOT EXISTS opened_by_staff_id uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS closed_by_staff_id uuid REFERENCES public.staff(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_business_days_opened_by_staff ON public.business_days(opened_by_staff_id);
CREATE INDEX IF NOT EXISTS idx_business_days_closed_by_staff ON public.business_days(closed_by_staff_id);
