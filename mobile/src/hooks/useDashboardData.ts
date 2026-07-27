import { useQuery } from '@tanstack/react-query';

export interface DashboardMetrics {
  totalSalesToday: number;
  ordersCountToday: number;
  lowStockItemsCount: number;
  monthlyRevenue: number;
  systemStatus: 'Optimal' | 'Degraded' | 'Offline';
  lastUpdated: string;
}

export function useDashboardData() {
  return useQuery<DashboardMetrics>({
    queryKey: ['mobile-dashboard-metrics'],
    queryFn: async () => {
      // Simulate network latency
      await new Promise((resolve) => setTimeout(resolve, 800));

      return {
        totalSalesToday: 14850.50,
        ordersCountToday: 34,
        lowStockItemsCount: 3,
        monthlyRevenue: 284500.00,
        systemStatus: 'Optimal',
        lastUpdated: new Date().toLocaleTimeString(),
      };
    },
    staleTime: 1000 * 30, // 30 seconds
  });
}
