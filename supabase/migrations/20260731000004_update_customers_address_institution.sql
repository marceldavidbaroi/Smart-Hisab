-- Migration: Update customers schema (replace room_no with address and institution)

-- 1. Drop room_no column if it exists
alter table public.customers drop column if exists room_no;

-- 2. Add address and institution columns (optional / nullable text)
alter table public.customers add column if not exists address text;
alter table public.customers add column if not exists institution text;
