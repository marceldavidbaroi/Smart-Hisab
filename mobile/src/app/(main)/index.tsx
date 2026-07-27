import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { 
  Storefront, 
  ShieldCheck, 
  ChartLineUp, 
  UserPlus, 
  UserCheck, 
  DeviceMobile, 
  Users, 
  ShoppingCart, 
  BookOpen, 
  Clock, 
  CurrencyCircleDollar, 
  Gear,
  Receipt,
  Barcode,
  SignOut,
  CheckCircle,
  Lightning,
  ArrowsClockwise
} from 'phosphor-react-native';
import { useRouter } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useBusinessDayStore } from '@/store/useBusinessDayStore';
import { DayControlModal } from '@/components/ui/DayControlModal';

export default function HomeScreen() {
  const router = useRouter();
  const { user, isTerminalDevice, logout } = useAuthStore();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const [shiftOpen, setShiftOpen] = useState(true);
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const { activeDay, fetchActiveDay } = useBusinessDayStore();
  const [dayModalVisible, setDayModalVisible] = useState(false);

  React.useEffect(() => {
    if (activeTenant?.id) {
      fetchActiveDay(activeTenant.id);
    }
  }, [activeTenant?.id, fetchActiveDay]);

  const isTerminal = isTerminalDevice || user?.isTerminalDevice;

  if (isTerminal) {
    return (
      <View className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5 justify-between`}>
        {/* Top Section - Tenant / Store Name Header */}
        <View className="bg-card border border-border rounded-2xl p-5 shadow-xs items-center gap-2">
          <View className="w-12 h-12 rounded-2xl bg-primary/10 border border-primary/20 items-center justify-center mb-1">
            <Storefront size={26} color={accentColor} weight="bold" />
          </View>
          <Text className="text-xs font-bold text-muted-foreground uppercase tracking-wider">
            Terminal Active Store
          </Text>
          <Text className="text-xl font-bold text-foreground text-center">
            {user?.storeName || activeTenant?.name || 'Smart Hisab Store'}
          </Text>
          <View className="bg-emerald-500/10 border border-emerald-500/20 px-3 py-1 rounded-full mt-1">
            <Text className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
              {user?.name || 'POS Terminal #1'}
            </Text>
          </View>
        </View>

        {/* Bottom Section - Clean Logout / Unpair Button */}
        <View className="gap-3 mb-4">
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={async () => {
              await logout();
              router.replace('/(auth)/login');
            }}
            className="w-full h-12 bg-destructive rounded-xl flex-row items-center justify-center gap-2 shadow-xs min-h-[48px]"
          >
            <SignOut size={18} color="#ffffff" weight="bold" />
            <Text className="text-sm font-bold text-destructive-foreground">
              Logout / Unpair Terminal
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <ScrollView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5`}>
      {/* Business Day Status Card */}
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={() => setDayModalVisible(true)}
        className={`border rounded-2xl p-4 mb-4 shadow-xs flex-row items-center justify-between ${
          activeDay
            ? 'bg-emerald-500/10 border-emerald-500/30'
            : 'bg-amber-500/10 border-amber-500/30'
        }`}
      >
        <View className="flex-row items-center gap-3">
          <View className={`w-10 h-10 rounded-xl items-center justify-center border ${
            activeDay ? 'bg-emerald-500/20 border-emerald-500/40' : 'bg-amber-500/20 border-amber-500/40'
          }`}>
            <Clock size={22} color={activeDay ? '#10b981' : '#f59e0b'} weight="bold" />
          </View>
          <View>
            <Text className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              Business Day Status
            </Text>
            <Text className="text-sm font-bold text-foreground mt-0.5">
              {activeDay ? `Day Running (Opening: ৳ ${Number(activeDay.opening_cash || 0).toFixed(2)})` : 'No Active Day Running'}
            </Text>
          </View>
        </View>

        <View className={`px-3 py-1.5 rounded-xl border ${
          activeDay ? 'bg-emerald-500/20 border-emerald-500/40' : 'bg-amber-500 border-amber-600'
        }`}>
          <Text className={`text-xs font-bold ${activeDay ? 'text-emerald-700 dark:text-emerald-400' : 'text-white'}`}>
            {activeDay ? 'End Day' : 'Start Day'}
          </Text>
        </View>
      </TouchableOpacity>

      {/* Day Control Modal */}
      <DayControlModal
        visible={dayModalVisible}
        onClose={() => setDayModalVisible(false)}
      />

      {/* Active Workspace Info Banner */}
      <View className="bg-card border border-border rounded-2xl p-5 mb-4 shadow-xs">
        <View className="flex-row items-center justify-between mb-3">
          <View className="flex-row items-center gap-2">
            <View className="w-8 h-8 rounded-lg bg-primary/15 items-center justify-center border border-primary/20">
              <Storefront size={18} color={accentColor} weight="bold" />
            </View>
            <View>
              <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Current Workspace
              </Text>
              <Text className="text-base font-bold text-foreground mt-0.5">
                {activeTenant?.name || 'Smart Hisab Store'}
              </Text>
            </View>
          </View>
          {activeTenant?.slug && (
            <View className="bg-muted px-2.5 py-1 rounded-full border border-border">
              <Text className="text-[11px] font-semibold text-primary">
                @{activeTenant.slug}
              </Text>
            </View>
          )}
        </View>

        <Text className="text-xs text-muted-foreground leading-relaxed">
          Logged in as <Text className="font-semibold text-foreground">{user?.name || user?.email}</Text>. Multi-tenant isolation active.
        </Text>
      </View>

      {/* Quick Summary Cards */}
      <View className="flex-row gap-3 mb-4">
        <View className="flex-1 bg-card border border-border rounded-2xl p-4 shadow-xs">
          <View className="flex-row items-center justify-between mb-2">
            <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
              Sales Today
            </Text>
            <ChartLineUp size={16} color={accentColor} weight="bold" />
          </View>
          <Text className="text-xl font-bold text-foreground">৳ 0.00</Text>
        </View>

        <View className="flex-1 bg-card border border-border rounded-2xl p-4 shadow-xs">
          <View className="flex-row items-center justify-between mb-2">
            <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
              Security Status
            </Text>
            <ShieldCheck size={16} color="#22c55e" weight="bold" />
          </View>
          <Text className="text-xs font-bold text-green-600 dark:text-green-400">
            Protected
          </Text>
        </View>
      </View>

      {/* Feature Action Buttons */}
      <View className="mb-4">
        <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2.5 px-0.5">
          Quick Actions
        </Text>
        <View className="flex-row flex-wrap gap-2.5">
          <TouchableOpacity 
            onPress={() => setDayModalVisible(true)}
            activeOpacity={0.7}
            className="flex-1 min-w-[45%] bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-3 shadow-xs"
          >
            <View className={`w-10 h-10 rounded-lg items-center justify-center border ${
              activeDay ? 'bg-emerald-500/10 border-emerald-500/20' : 'bg-amber-500/10 border-amber-500/20'
            }`}>
              <Clock size={20} color={activeDay ? '#10b981' : '#f59e0b'} weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-xs font-bold text-foreground">
                {activeDay ? 'End Day' : 'Start Day'}
              </Text>
              <Text className="text-[10px] text-muted-foreground">
                {activeDay ? 'Close counter cash' : 'Open counter cash'}
              </Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => router.push('/shifts')}
            activeOpacity={0.7}
            className="flex-1 min-w-[45%] bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-3 shadow-xs"
          >
            <View className="w-10 h-10 rounded-lg bg-rose-500/10 items-center justify-center border border-rose-500/20">
              <Clock size={20} color="#f43f5e" weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-xs font-bold text-foreground">Shifts Setup</Text>
              <Text className="text-[10px] text-muted-foreground">Manage work hours</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => router.push('/staff')}
            activeOpacity={0.7}
            className="flex-1 min-w-[45%] bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-3 shadow-xs"
          >
            <View className="w-10 h-10 rounded-lg bg-emerald-500/10 items-center justify-center border border-emerald-500/20">
              <UserCheck size={20} color="#10b981" weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-xs font-bold text-foreground">Add Staff</Text>
              <Text className="text-[10px] text-muted-foreground">Staff & cashier</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => router.push('/terminal')}
            activeOpacity={0.7}
            className="flex-1 min-w-[45%] bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-3 shadow-xs"
          >
            <View className="w-10 h-10 rounded-lg bg-purple-500/10 items-center justify-center border border-purple-500/20">
              <DeviceMobile size={20} color="#a855f7" weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-xs font-bold text-foreground">Add Terminal</Text>
              <Text className="text-[10px] text-muted-foreground">Register POS device</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity 
            activeOpacity={0.7}
            className="flex-1 min-w-[45%] bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-3 shadow-xs"
          >
            <View className="w-10 h-10 rounded-lg bg-amber-500/10 items-center justify-center border border-amber-500/20">
              <Users size={20} color="#f59e0b" weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-xs font-bold text-foreground">Add Customer</Text>
              <Text className="text-[10px] text-muted-foreground">Client directory</Text>
            </View>
          </TouchableOpacity>
        </View>
      </View>

      {/* Key Web Features Section */}
      <View className="mb-6">
        <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2.5 px-0.5">
          Key Web Features
        </Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} className="flex-row pb-2">
          <TouchableOpacity 
            onPress={() => router.push('/terminal')}
            activeOpacity={0.7}
            className="w-28 bg-card border border-border rounded-xl p-3 items-center justify-center gap-2 shadow-xs mr-2.5"
          >
            <View className="w-10 h-10 rounded-xl bg-primary/10 items-center justify-center border border-primary/20">
              <ShoppingCart size={20} color={accentColor} weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground text-center">Counter POS</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            activeOpacity={0.7}
            className="w-28 bg-card border border-border rounded-xl p-3 items-center justify-center gap-2 shadow-xs mr-2.5"
          >
            <View className="w-10 h-10 rounded-xl bg-indigo-500/10 items-center justify-center border border-indigo-500/20">
              <BookOpen size={20} color="#6366f1" weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground text-center">Ledger</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => router.push('/shifts')}
            activeOpacity={0.7}
            className="w-28 bg-card border border-border rounded-xl p-3 items-center justify-center gap-2 shadow-xs mr-2.5"
          >
            <View className="w-10 h-10 rounded-xl bg-rose-500/10 items-center justify-center border border-rose-500/20">
              <Clock size={20} color="#f43f5e" weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground text-center">Shifts</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            activeOpacity={0.7}
            className="w-28 bg-card border border-border rounded-xl p-3 items-center justify-center gap-2 shadow-xs mr-2.5"
          >
            <View className="w-10 h-10 rounded-xl bg-teal-500/10 items-center justify-center border border-teal-500/20">
              <CurrencyCircleDollar size={20} color="#14b8a6" weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground text-center">Finance</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            activeOpacity={0.7}
            className="w-28 bg-card border border-border rounded-xl p-3 items-center justify-center gap-2 shadow-xs mr-2.5"
          >
            <View className="w-10 h-10 rounded-xl bg-slate-500/10 items-center justify-center border border-slate-500/20">
              <Gear size={20} color="#64748b" weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground text-center">Settings</Text>
          </TouchableOpacity>
        </ScrollView>
      </View>
    </ScrollView>
  );
}
