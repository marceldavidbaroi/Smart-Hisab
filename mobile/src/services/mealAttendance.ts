import { supabase } from '@/lib/supabase';

export interface MealAttendance {
  id: string;
  tenant_id: string;
  customer_id: string;
  date: string;
  shift_id: string | null;
  charge_amount: number;
  recorded_by_staff_id: string | null;
  created_at: string;
  customer?: {
    id: string;
    full_name: string;
    phone: string | null;
  };
  shift?: {
    id: string;
    name: string;
  };
}

export interface DayAttendanceSummary {
  date: string;
  total_count: number;
  total_charge: number;
  items: MealAttendance[];
}

export async function getMealAttendanceByDate(
  tenantId: string,
  targetDate: string // YYYY-MM-DD format
): Promise<DayAttendanceSummary> {
  const { data, error } = await supabase
    .from('meal_attendance')
    .select(`
      id,
      tenant_id,
      customer_id,
      date,
      shift_id,
      charge_amount,
      recorded_by_staff_id,
      created_at,
      customer:customers(id, full_name, phone),
      shift:shifts(id, name)
    `)
    .eq('tenant_id', tenantId)
    .eq('date', targetDate)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching meal attendance by date:', error);
    throw error;
  }

  const items = (data || []) as unknown as MealAttendance[];
  const total_count = items.length;
  const total_charge = items.reduce((acc, curr) => acc + (Number(curr.charge_amount) || 0), 0);

  return {
    date: targetDate,
    total_count,
    total_charge,
    items,
  };
}
