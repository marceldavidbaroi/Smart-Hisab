import { supabase } from '@/lib/supabase';

export interface MealConfig {
  id: string;
  tenant_id: string;
  rate: number;
  effective_from: string;
  note: string | null;
  created_at?: string;
}

export async function getMealConfigs(tenantId: string): Promise<MealConfig[]> {
  const { data, error } = await supabase
    .from('meal_configs')
    .select('*')
    .eq('tenant_id', tenantId)
    .order('effective_from', { ascending: false });

  if (error) {
    console.error('Error fetching meal configs:', error);
    throw error;
  }

  return (data || []) as MealConfig[];
}

export async function createMealConfig(payload: {
  tenant_id: string;
  rate: number;
  effective_from: string;
  note?: string | null;
}): Promise<MealConfig> {
  const { data, error } = await supabase
    .from('meal_configs')
    .insert({
      tenant_id: payload.tenant_id,
      rate: payload.rate,
      effective_from: payload.effective_from,
      note: payload.note || null,
    })
    .select()
    .single();

  if (error) {
    console.error('Error creating meal config:', error);
    throw error;
  }

  return data as MealConfig;
}

export async function updateMealConfig(
  id: string,
  payload: {
    rate: number;
    effective_from: string;
    note?: string | null;
  }
): Promise<MealConfig> {
  const { data, error } = await supabase
    .from('meal_configs')
    .update({
      rate: payload.rate,
      effective_from: payload.effective_from,
      note: payload.note || null,
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    console.error('Error updating meal config:', error);
    throw error;
  }

  return data as MealConfig;
}

export async function deleteMealConfig(id: string): Promise<void> {
  const { error } = await supabase
    .from('meal_configs')
    .delete()
    .eq('id', id);

  if (error) {
    console.error('Error deleting meal config:', error);
    throw error;
  }
}
