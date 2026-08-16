-- Migration: Add salary_type and monthly_salary to staff_members
-- Description: Adds salary_type ('monthly' or 'daily') and monthly_salary (salary/wage amount) columns to staff_members table.

ALTER TABLE public.staff_members
ADD COLUMN IF NOT EXISTS salary_type TEXT NOT NULL DEFAULT 'monthly' CHECK (salary_type IN ('monthly', 'daily')),
ADD COLUMN IF NOT EXISTS monthly_salary NUMERIC(12,2) NOT NULL DEFAULT 0;

-- Optional: index on salary_type if filtering by payout cycle in future
CREATE INDEX IF NOT EXISTS idx_staff_members_salary_type ON public.staff_members(tenant_id, salary_type);
