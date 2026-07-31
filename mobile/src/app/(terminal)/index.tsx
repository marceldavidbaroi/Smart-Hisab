import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { 
  Storefront, 
  ShoppingCart, 
  CurrencyCircleDollar, 
  Lightning, 
  Barcode, 
  Receipt,
  CheckCircle,
  ArrowsClockwise
} from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useBusinessDayStore } from '@/store/useBusinessDayStore';
import { BusinessDayGateGuard } from '@/components/BusinessDayGateGuard';
import { RunningDayBanner } from '@/components/RunningDayBanner';
import { DayControlModal } from '@/components/ui/DayControlModal';

export default function TerminalHomeScreen() {
  const { user, activeStaff } = useAuthStore();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const { activeDay } = useBusinessDayStore();
  const [dayModalVisible, setDayModalVisible] = useState(false);
  const accentColor = isDark ? '#f59e0b' : '#d97706';

  return (
    <BusinessDayGateGuard>
      <ScrollView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5`}>
        {/* Live Running / Start Day Banner */}
        <RunningDayBanner onPressDayControl={() => setDayModalVisible(true)} />

        {/* Header Store Banner */}
        <View className="bg-card border border-amber-500/30 rounded-2xl p-5 mb-4 shadow-xs">
          <View className="flex-row items-center gap-3">
            <View className="w-10 h-10 rounded-xl bg-amber-500/15 items-center justify-center border border-amber-500/30">
              <Storefront size={22} color={accentColor} weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                {activeStaff ? `Cashier: ${activeStaff.fullName}` : 'Terminal POS Store'}
              </Text>
              <Text className="text-lg font-bold text-foreground mt-0.5">
                {user?.storeName || activeTenant?.name || 'Smart Hisab Store'}
              </Text>
            </View>
          </View>
        </View>

        {/* Sales Quick Stats */}
        <View className="flex-row gap-3 mb-4">
          <View className="flex-1 bg-card border border-border rounded-2xl p-4 shadow-xs">
            <View className="flex-row items-center justify-between mb-2">
              <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
                Today's Cash
              </Text>
              <CurrencyCircleDollar size={18} color="#10b981" weight="bold" />
            </View>
            <Text className="text-xl font-bold text-foreground">৳ 0.00</Text>
            <Text className="text-xs text-muted-foreground mt-1">0 completed sales</Text>
          </View>

          <View className="flex-1 bg-card border border-border rounded-2xl p-4 shadow-xs justify-between">
            <View className="flex-row items-center justify-between mb-1">
              <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
                Opening Float
              </Text>
            </View>
            <Text className="text-xl font-bold text-emerald-600 dark:text-emerald-400">
              ৳ {Number(activeDay?.opening_cash || 0).toFixed(2)}
            </Text>
            <TouchableOpacity
              activeOpacity={0.7}
              onPress={() => setDayModalVisible(true)}
              className="mt-2"
            >
              <Text className="text-xs font-bold text-amber-600 dark:text-amber-400">
                End Business Day
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Counter POS Actions */}
        <View className="mb-5 gap-3">
          <TouchableOpacity
            activeOpacity={0.7}
            className="bg-amber-600 dark:bg-amber-500 p-4 rounded-2xl flex-row items-center justify-between shadow-xs min-h-[56px]"
          >
            <View className="flex-row items-center gap-3">
              <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center">
                <ShoppingCart size={22} color="#ffffff" weight="bold" />
              </View>
              <View>
                <Text className="text-base font-bold text-white">Open Counter POS</Text>
                <Text className="text-xs text-white/80">Start fast checkout & bill order</Text>
              </View>
            </View>
            <Lightning size={20} color="#ffffff" weight="fill" />
          </TouchableOpacity>

          <View className="flex-row gap-3">
            <TouchableOpacity
              activeOpacity={0.7}
              className="flex-1 bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-2.5 shadow-xs min-h-[48px]"
            >
              <View className="w-8 h-8 rounded-lg bg-indigo-500/10 items-center justify-center">
                <Barcode size={18} color="#6366f1" weight="bold" />
              </View>
              <Text className="text-xs font-bold text-foreground">Scan Barcode</Text>
            </TouchableOpacity>

            <TouchableOpacity
              activeOpacity={0.7}
              className="flex-1 bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-2.5 shadow-xs min-h-[48px]"
            >
              <View className="w-8 h-8 rounded-lg bg-emerald-500/10 items-center justify-center">
                <Receipt size={18} color="#10b981" weight="bold" />
              </View>
              <Text className="text-xs font-bold text-foreground">Last Receipt</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Recent Cashier Orders */}
        <View className="mb-6">
          <View className="flex-row items-center justify-between mb-2.5 px-0.5">
            <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              Recent Cashier Orders
            </Text>
            <TouchableOpacity activeOpacity={0.7} className="flex-row items-center gap-1">
              <ArrowsClockwise size={12} color={accentColor} />
              <Text className="text-xs font-semibold text-amber-600 dark:text-amber-400">Refresh</Text>
            </TouchableOpacity>
          </View>

          <View className="bg-card border border-border rounded-2xl overflow-hidden divide-y divide-border/60">
            <View className="p-3.5 flex-row items-center justify-between">
              <View className="flex-row items-center gap-3">
                <View className="w-8 h-8 rounded-lg bg-green-500/10 items-center justify-center">
                  <CheckCircle size={18} color="#22c55e" weight="bold" />
                </View>
                <View>
                  <Text className="text-xs font-bold text-foreground">No recent transactions</Text>
                  <Text className="text-[11px] text-muted-foreground">Ready for new POS checkout</Text>
                </View>
              </View>
              <Text className="text-xs font-bold text-foreground">৳ 0.00</Text>
            </View>
          </View>
        </View>

        {/* Day Control Modal */}
        <DayControlModal
          visible={dayModalVisible}
          onClose={() => setDayModalVisible(false)}
        />
      </ScrollView>
    </BusinessDayGateGuard>
  );
}
