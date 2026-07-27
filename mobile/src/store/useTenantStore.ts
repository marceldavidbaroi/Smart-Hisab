import { create } from 'zustand';
import { supabase } from '@/lib/supabase';

export interface Tenant {
  id: string;
  name: string;
  slug: string;
  parent_id?: string | null;
  status: string;
  created_at?: string;
  updated_at?: string;
}

export interface TenantMembership {
  id: string;
  status: string;
  joined_at: string;
  tenant_id: string;
  user_id: string;
  tenants: Tenant | null;
  tenant_roles?: {
    id: string;
    name: string;
    permissions: any;
  } | null;
}

interface TenantState {
  myTenants: TenantMembership[];
  activeTenant: Tenant | null;
  isLoading: boolean;
  isInitialized: boolean;
  fetchTenants: (userId: string) => Promise<TenantMembership[]>;
  createTenant: (name: string, slug: string, userId: string) => Promise<Tenant>;
  setActiveTenant: (tenant: Tenant | null) => void;
  resetTenantStore: () => void;
}

export const useTenantStore = create<TenantState>((set, get) => ({
  myTenants: [],
  activeTenant: null,
  isLoading: false,
  isInitialized: false,

  fetchTenants: async (userId: string) => {
    // Validate if userId is a valid UUID to prevent Postgres syntax error (e.g., mock terminal user IDs)
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);
    if (!isUuid) {
      set({ myTenants: [], isLoading: false, isInitialized: true });
      return [];
    }

    set({ isLoading: true });
    try {
      // Claim pending email invitations first
      try {
        await supabase.rpc('claim_pending_invitations');
      } catch (err: any) {
        console.warn('Failed to claim pending invitations:', err?.message || err);
      }

      const { data, error } = await supabase
        .from('tenant_members')
        .select(`
          id,
          status,
          joined_at,
          tenant_id,
          user_id,
          tenants (
            id,
            name,
            slug,
            parent_id,
            status
          ),
          tenant_roles (
            id,
            name,
            permissions
          )
        `)
        .eq('user_id', userId)
        .eq('status', 'active');

      if (error) throw error;

      const memberships: TenantMembership[] = (data || []).map((m: any) => {
        const raw = m.tenants;
        const tenantObj = Array.isArray(raw) ? raw[0] : raw;
        return {
          ...m,
          tenants: tenantObj || null,
        };
      }).filter((m) => m.tenants !== null);

      let currentActive = get().activeTenant;
      // If no active tenant or active tenant not in list, default to first active tenant
      if (!currentActive || !memberships.some((m) => m.tenants?.id === currentActive?.id)) {
        currentActive = memberships.length > 0 ? memberships[0].tenants : null;
      }

      set({
        myTenants: memberships,
        activeTenant: currentActive,
        isLoading: false,
        isInitialized: true,
      });

      return memberships;
    } catch (err) {
      console.error('Failed to fetch user tenants:', err);
      set({ isLoading: false, isInitialized: true });
      return [];
    }
  },

  createTenant: async (name: string, slug: string, userId: string) => {
    set({ isLoading: true });
    try {
      // Call create_tenant RPC stored procedure
      const { data: tenantId, error } = await supabase.rpc('create_tenant', {
        p_name: name,
        p_slug: slug,
      });

      if (error) throw error;

      // Ensure default operational shifts are seeded for this tenant
      if (tenantId) {
        try {
          const { data: existingShifts } = await supabase
            .from('shifts')
            .select('id')
            .eq('tenant_id', tenantId);

          if (!existingShifts || existingShifts.length === 0) {
            await supabase.from('shifts').insert([
              { tenant_id: tenantId, name: 'Morning Slot', start_time: '06:30', end_time: '11:00', is_active: true },
              { tenant_id: tenantId, name: 'Afternoon Slot', start_time: '11:00', end_time: '15:30', is_active: true },
              { tenant_id: tenantId, name: 'Evening Slot', start_time: '15:30', end_time: '19:30', is_active: true },
              { tenant_id: tenantId, name: 'Night Slot', start_time: '19:30', end_time: '23:30', is_active: true },
            ]);
          }
        } catch (seedErr) {
          console.warn('Shift auto-seeding notice:', seedErr);
        }
      }

      // Re-fetch tenants for the user to get updated memberships
      const refreshed = await get().fetchTenants(userId);
      
      // Find created tenant
      let newTenant = refreshed.find((m) => m.tenant_id === tenantId || m.tenants?.id === tenantId)?.tenants || null;
      
      // Fallback: query tenants directly if needed
      if (!newTenant && tenantId) {
        const { data: tData } = await supabase
          .from('tenants')
          .select('*')
          .eq('id', tenantId)
          .single();
        if (tData) {
          newTenant = tData as Tenant;
        }
      }

      if (newTenant) {
        set({ activeTenant: newTenant });
      }

      return newTenant || { id: tenantId, name, slug, status: 'active' };
    } catch (err: any) {
      set({ isLoading: false });
      throw err;
    }
  },

  setActiveTenant: (tenant: Tenant | null) => {
    set({ activeTenant: tenant });
  },

  resetTenantStore: () => {
    set({
      myTenants: [],
      activeTenant: null,
      isLoading: false,
      isInitialized: false,
    });
  },
}));
