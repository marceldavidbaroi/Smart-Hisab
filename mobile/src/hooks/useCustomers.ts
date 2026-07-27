import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useTenantStore } from '@/store/useTenantStore';
import { useAuthStore } from '@/store/useAuthStore';
import {
  getCustomers,
  createCustomer,
  toggleContractAttendance,
  recordBakiTransaction,
  getCustomerStatement,
  getCustomerAttendanceList,
  Customer,
  FetchCustomersFilters,
  CreateCustomerInput,
} from '@/services/customer';

export function useToggleAttendance() {
  const queryClient = useQueryClient();
  const { activeTenant, myTenants } = useTenantStore();
  const { user, deviceToken, activeStaff } = useAuthStore();

  return useMutation({
    mutationFn: async ({
      customerId,
      shiftName = 'lunch',
      dailyRate,
    }: {
      customerId: string;
      shiftName?: string;
      dailyRate?: number | null;
    }) => {
      const tenantId = activeTenant?.id || user?.tenantId || myTenants[0]?.tenant_id || myTenants[0]?.tenants?.id;
      if (!tenantId) throw new Error('No active tenant selected');

      return toggleContractAttendance({
        tenantId,
        customerId,
        shiftName,
        dailyRate,
        deviceToken: deviceToken || 'demo_device_token',
        staffId: activeStaff?.id,
      });
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['customers'] });
      queryClient.invalidateQueries({ queryKey: ['customerStatement', variables.customerId] });
      queryClient.invalidateQueries({ queryKey: ['customerAttendance', variables.customerId] });
    },
  });
}

export function useUpdateCustomerDailyRate() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ customerId, dailyRate }: { customerId: string; dailyRate: number }) => {
      const { updateCustomerDailyRate } = await import('@/services/customer');
      return updateCustomerDailyRate(customerId, dailyRate);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['customers'] });
    },
  });
}

export function useCustomerAttendance(customerId: string | null) {
  const { activeTenant, myTenants } = useTenantStore();
  const { user } = useAuthStore();
  const tenantId = activeTenant?.id || user?.tenantId || myTenants[0]?.tenant_id || myTenants[0]?.tenants?.id;

  return useQuery({
    queryKey: ['customerAttendance', customerId, tenantId],
    queryFn: async () => {
      if (!tenantId || !customerId) return [];
      return getCustomerAttendanceList(tenantId, customerId);
    },
    enabled: Boolean(tenantId && customerId),
  });
}



export function useCustomers(filters: FetchCustomersFilters = {}) {
  const { activeTenant, myTenants } = useTenantStore();
  const { user, deviceToken, activeStaff } = useAuthStore();
  const tenantId = activeTenant?.id || user?.tenantId || myTenants[0]?.tenant_id || myTenants[0]?.tenants?.id;

  const combinedFilters: FetchCustomersFilters = {
    ...filters,
    deviceToken: filters.deviceToken || deviceToken || 'demo_device_token',
    staffId: filters.staffId || activeStaff?.id,
  };

  return useQuery<Customer[], Error>({
    queryKey: ['customers', tenantId, combinedFilters],
    queryFn: async () => {
      console.log('[useCustomers] Executing API query with tenantId:', tenantId, 'staffId:', combinedFilters.staffId);
      if (!tenantId) {
        console.warn('[useCustomers] No tenantId available, returning empty list');
        return [];
      }
      const result = await getCustomers(tenantId, combinedFilters);
      console.log('[useCustomers] Fetched customers count:', result?.length || 0, result);
      return result;
    },
    enabled: Boolean(tenantId),
    staleTime: 1000 * 30, // 30 seconds
  });
}

export function useCreateCustomer() {
  const queryClient = useQueryClient();
  const { activeTenant, myTenants } = useTenantStore();
  const { user } = useAuthStore();

  return useMutation<Customer, Error, Omit<CreateCustomerInput, 'tenant_id'>>({
    mutationFn: async (customerData) => {
      const tenantId = activeTenant?.id || user?.tenantId || myTenants[0]?.tenant_id || myTenants[0]?.tenants?.id;
      if (!tenantId) {
        throw new Error('No active tenant selected');
      }
      return createCustomer({
        ...customerData,
        tenant_id: tenantId,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['customers'] });
    },
  });
}



export function useRecordBaki() {
  const queryClient = useQueryClient();
  const { activeTenant, myTenants } = useTenantStore();
  const { user, deviceToken, activeStaff } = useAuthStore();

  return useMutation({
    mutationFn: async ({
      customerId,
      itemsDescription,
      amount,
    }: {
      customerId: string;
      itemsDescription: string;
      amount: number;
    }) => {
      const tenantId = activeTenant?.id || user?.tenantId || myTenants[0]?.tenant_id || myTenants[0]?.tenants?.id;
      if (!tenantId) throw new Error('No active tenant selected');

      return recordBakiTransaction({
        tenantId,
        customerId,
        itemsDescription,
        amount,
        deviceToken: deviceToken || 'demo_device_token',
        staffId: activeStaff?.id,
      });
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['customers'] });
      queryClient.invalidateQueries({ queryKey: ['customerStatement', variables.customerId] });
    },
  });
}

export function useCustomerStatement(customerId: string | null, daysCount: number = 30) {
  const { activeTenant, myTenants } = useTenantStore();
  const { user, deviceToken, activeStaff } = useAuthStore();
  const tenantId = activeTenant?.id || user?.tenantId || myTenants[0]?.tenant_id || myTenants[0]?.tenants?.id;

  return useQuery({
    queryKey: ['customerStatement', customerId, tenantId, daysCount],
    queryFn: async () => {
      if (!tenantId || !customerId) return [];
      return getCustomerStatement({
        tenantId,
        customerId,
        daysCount,
        deviceToken: deviceToken || 'demo_device_token',
        staffId: activeStaff?.id,
      });
    },
    enabled: Boolean(tenantId && customerId),
  });
}


