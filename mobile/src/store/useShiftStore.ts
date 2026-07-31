import { create } from 'zustand';
import { supabase } from '@/lib/supabase';

export interface Shift {
  id?: string;
  tenant_id?: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
  days?: string[];
  created_at?: string;
  updated_at?: string;
}

interface ShiftState {
  shifts: Shift[];
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
  fetchShifts: (tenantId: string) => Promise<Shift[]>;
  createShift: (tenantId: string, shiftData: Omit<Shift, 'id' | 'tenant_id'>) => Promise<Shift>;
  updateShift: (shiftId: string, shiftData: Partial<Shift>) => Promise<Shift>;
  toggleShiftStatus: (shiftId: string, isActive: boolean) => Promise<void>;
  deleteShift: (shiftId: string) => Promise<void>;
  resetShiftStore: () => void;
}

export const useShiftStore = create<ShiftState>((set, get) => ({
  shifts: [],
  isLoading: false,
  isInitialized: false,
  error: null,

  fetchShifts: async (tenantId: string) => {
    if (!tenantId) {
      set({ shifts: [], isLoading: false, isInitialized: true, error: null });
      return [];
    }

    set({ isLoading: true, error: null });
    try {
      const { data, error } = await supabase
        .from('shifts')
        .select('*')
        .eq('tenant_id', tenantId)
        .order('created_at', { ascending: true });

      if (error) throw error;

      const shiftsList: Shift[] = data || [];
      set({
        shifts: shiftsList,
        isLoading: false,
        isInitialized: true,
        error: null,
      });

      return shiftsList;
    } catch (err: any) {
      console.error('Failed to fetch shifts:', err);
      set({
        shifts: [],
        isLoading: false,
        isInitialized: true,
        error: err.message || 'Failed to fetch shifts.',
      });
      return [];
    }
  },

  createShift: async (tenantId: string, shiftData: Omit<Shift, 'id' | 'tenant_id'>) => {
    set({ isLoading: true, error: null });
    try {
      const payload = {
        tenant_id: tenantId,
        name: shiftData.name,
        start_time: shiftData.start_time,
        end_time: shiftData.end_time,
        is_active: shiftData.is_active ?? true,
      };

      const { data, error } = await supabase
        .from('shifts')
        .insert(payload)
        .select('*')
        .single();

      if (error) throw error;

      const newShift: Shift = data;
      set((state) => ({
        shifts: [...state.shifts, newShift],
        isLoading: false,
        error: null,
      }));

      return newShift;
    } catch (err: any) {
      console.error('Failed to create shift:', err);
      set({ isLoading: false, error: err.message || 'Failed to create shift.' });
      throw err;
    }
  },

  updateShift: async (shiftId: string, shiftData: Partial<Shift>) => {
    try {
      const { data, error } = await supabase
        .from('shifts')
        .update({
          ...shiftData,
          updated_at: new Date().toISOString(),
        })
        .eq('id', shiftId)
        .select('*')
        .single();

      if (error) throw error;

      const updated: Shift = data;
      set((state) => ({
        shifts: state.shifts.map((s) => (s.id === shiftId ? updated : s)),
      }));

      return updated;
    } catch (err: any) {
      console.error('Failed to update shift:', err);
      throw err;
    }
  },

  toggleShiftStatus: async (shiftId: string, isActive: boolean) => {
    try {
      const { error } = await supabase
        .from('shifts')
        .update({ is_active: isActive, updated_at: new Date().toISOString() })
        .eq('id', shiftId);

      if (error) throw error;

      set((state) => ({
        shifts: state.shifts.map((s) => (s.id === shiftId ? { ...s, is_active: isActive } : s)),
      }));
    } catch (err: any) {
      console.error('Failed to toggle shift status:', err);
      throw err;
    }
  },

  deleteShift: async (shiftId: string) => {
    try {
      const { error } = await supabase.from('shifts').delete().eq('id', shiftId);
      if (error) throw error;

      set((state) => ({
        shifts: state.shifts.filter((s) => s.id !== shiftId),
      }));
    } catch (err: any) {
      console.error('Failed to delete shift:', err);
      throw err;
    }
  },

  resetShiftStore: () => {
    set({
      shifts: [],
      isLoading: false,
      isInitialized: false,
      error: null,
    });
  },
}));
