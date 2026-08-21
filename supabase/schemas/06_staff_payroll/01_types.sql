-- ==============================================================================
-- DOMAIN 06: STAFF & PAYROLL — TYPES & ENUMS
-- ==============================================================================

DO $$ BEGIN
    CREATE TYPE public.staff_salary_type AS ENUM ('daily', 'monthly');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.salary_payout_type AS ENUM ('advance', 'salary');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.staff_attendance_status AS ENUM ('present', 'absent', 'half_day', 'leave');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
