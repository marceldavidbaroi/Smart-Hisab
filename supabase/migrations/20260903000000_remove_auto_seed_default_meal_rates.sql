-- Migration: Update create_tenant to only auto-seed shifts and remove default meal rates
-- This ensures meal_configs table starts clean for new canteens/tenants.

CREATE OR REPLACE FUNCTION public.create_tenant(p_name TEXT)
RETURNS UUID AS $$
DECLARE
  v_tenant_id UUID;
BEGIN
  -- 1. Create tenant
  INSERT INTO public.tenants (name) VALUES (p_name) RETURNING id INTO v_tenant_id;

  -- 2. Add creator as owner
  INSERT INTO public.tenant_members (tenant_id, user_id, role)
  VALUES (v_tenant_id, auth.uid(), 'owner');

  -- 3. Auto-seed standard Bangladeshi canteen operating shifts
  INSERT INTO public.shifts (tenant_id, name, start_time, end_time, is_active)
  VALUES 
    (v_tenant_id, 'Morning Breakfast (সকালের নাস্তা)', '07:00:00', '11:00:00', true),
    (v_tenant_id, 'Lunch (দুপুরের খাবার)', '12:30:00', '16:00:00', true),
    (v_tenant_id, 'Evening Snack (বিকালের নাস্তা)', '16:30:00', '19:00:00', true),
    (v_tenant_id, 'Dinner (রাতের খাবার)', '19:30:00', '23:00:00', true);

  RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
