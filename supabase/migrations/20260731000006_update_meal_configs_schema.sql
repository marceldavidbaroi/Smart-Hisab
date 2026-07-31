drop index if exists public.idx_meal_configs_shift;
alter table public.meal_configs drop column if exists shift_id cascade;
alter table public.meal_configs add column if not exists note text;



