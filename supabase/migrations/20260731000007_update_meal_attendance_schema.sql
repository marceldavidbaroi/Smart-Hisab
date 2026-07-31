-- Migration to update meal_attendance schema: replace business_day_id with date column
ALTER TABLE public.meal_attendance DROP COLUMN IF EXISTS business_day_id;
ALTER TABLE public.meal_attendance ADD COLUMN IF NOT EXISTS date date NOT NULL DEFAULT CURRENT_DATE;

CREATE INDEX IF NOT EXISTS idx_meal_attendance_date ON public.meal_attendance(date);

