-- Migration: Update create_tenant to auto-seed standard Bangladeshi canteen shifts
-- (Breakfast, Lunch, Evening Snack, Dinner) upon new canteen creation.

CREATE OR REPLACE FUNCTION public.create_tenant(p_name TEXT)
RETURNS UUID AS $$
DECLARE
  v_tenant_id UUID;
  v_breakfast_id UUID;
  v_lunch_id UUID;
  v_snack_id UUID;
  v_dinner_id UUID;
BEGIN
  -- 1. Create tenant
  INSERT INTO public.tenants (name) VALUES (p_name) RETURNING id INTO v_tenant_id;

  -- 2. Add creator as owner
  INSERT INTO public.tenant_members (tenant_id, user_id, role)
  VALUES (v_tenant_id, auth.uid(), 'owner');

  -- 3. Auto-seed standard Bangladeshi canteen shifts (Customer can edit/adjust later)
  INSERT INTO public.shifts (tenant_id, name, start_time, end_time, is_active)
  VALUES (v_tenant_id, 'Morning Breakfast (সকালের নাস্তা)', '07:00:00', '11:00:00', true)
  RETURNING id INTO v_breakfast_id;

  INSERT INTO public.shifts (tenant_id, name, start_time, end_time, is_active)
  VALUES (v_tenant_id, 'Lunch (দুপুরের খাবার)', '12:30:00', '16:00:00', true)
  RETURNING id INTO v_lunch_id;

  INSERT INTO public.shifts (tenant_id, name, start_time, end_time, is_active)
  VALUES (v_tenant_id, 'Evening Snack (বিকালের নাস্তা)', '16:30:00', '19:00:00', true)
  RETURNING id INTO v_snack_id;

  INSERT INTO public.shifts (tenant_id, name, start_time, end_time, is_active)
  VALUES (v_tenant_id, 'Dinner (রাতের খাবার)', '19:30:00', '23:00:00', true)
  RETURNING id INTO v_dinner_id;

  -- 4. Auto-seed starter standard meal rates
  INSERT INTO public.meal_configs (tenant_id, shift_id, rate, effective_from, note)
  VALUES 
    (v_tenant_id, v_breakfast_id, 50.00, current_date, 'Standard Breakfast Rate'),
    (v_tenant_id, v_lunch_id, 80.00, current_date, 'Standard Lunch Rate'),
    (v_tenant_id, v_snack_id, 40.00, current_date, 'Standard Evening Snack Rate'),
    (v_tenant_id, v_dinner_id, 70.00, current_date, 'Standard Dinner Rate');

  RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
