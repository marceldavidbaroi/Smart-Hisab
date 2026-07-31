import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import {
  ArrowLeft,
  CalendarCheck,
  Calendar,
  CaretLeft,
  CaretRight,
  ForkKnife,
  Users,
  CurrencyCircleDollar,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import {
  getMealAttendanceByDate,
  DayAttendanceSummary,
} from '@/services/mealAttendance';
import MealAttendanceSkeleton from './components/MealAttendanceSkeleton';

export default function MealAttendanceScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedDate, setSelectedDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split('T')[0];
  });
  const [summary, setSummary] = useState<DayAttendanceSummary>({
    date: selectedDate,
    total_count: 0,
    total_charge: 0,
    items: [],
  });

  useEffect(() => {
    if (activeTenant?.id) {
      fetchAttendance();
    }
  }, [activeTenant?.id, selectedDate]);

  const fetchAttendance = async (isRefresh = false) => {
    if (!activeTenant?.id) return;

    if (isRefresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }

    try {
      const data = await getMealAttendanceByDate(activeTenant.id, selectedDate);
      setSummary(data);
    } catch (err: any) {
      console.error('Error fetching meal attendance:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleDateShift = (days: number) => {
    const current = new Date(selectedDate);
    current.setDate(current.getDate() + days);
    setSelectedDate(current.toISOString().split('T')[0]);
  };

  const isToday = selectedDate === new Date().toISOString().split('T')[0];

  return (
    <View
      className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}
      style={{ paddingTop: insets.top }}
    >
      {/* Header Toolbar */}
      <View className="flex-row items-center justify-between px-5 py-3 border-b border-border bg-card">
        <TouchableOpacity
          onPress={() => router.back()}
          activeOpacity={0.7}
          className="w-10 h-10 rounded-xl items-center justify-center bg-muted/50 border border-border min-h-[48px] min-w-[48px]"
        >
          <ArrowLeft size={20} color={isDark ? '#f8fafc' : '#0f172a'} />
        </TouchableOpacity>

        <View className="items-center flex-1 mx-2">
          <Text className="text-base font-bold text-foreground">
            Meal Attendance
          </Text>
          <Text className="text-[11px] text-muted-foreground">
            Daily Attendance Summary
          </Text>
        </View>

        <View className="w-10" />
      </View>

      {/* Date Selector Navigation Bar */}
      <View className="px-5 pt-4">
        <View className="bg-card border border-border rounded-2xl p-2.5 flex-row items-center justify-between shadow-xs">
          <TouchableOpacity
            onPress={() => handleDateShift(-1)}
            activeOpacity={0.7}
            className="w-10 h-10 rounded-xl bg-muted/40 items-center justify-center border border-border min-h-[48px] min-w-[48px]"
          >
            <CaretLeft size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>

          <View className="flex-row items-center gap-2">
            <Calendar size={18} color={accentColor} weight="bold" />
            <Text className="text-sm font-bold text-foreground">
              {selectedDate} {isToday ? '(Today)' : ''}
            </Text>
          </View>

          <TouchableOpacity
            onPress={() => handleDateShift(1)}
            activeOpacity={0.7}
            className="w-10 h-10 rounded-xl bg-muted/40 items-center justify-center border border-border min-h-[48px] min-w-[48px]"
          >
            <CaretRight size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>
      </View>

      {loading && !refreshing ? (
        <MealAttendanceSkeleton />
      ) : (
        <ScrollView
          className="flex-1 px-5 pt-4"
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => fetchAttendance(true)}
              tintColor={accentColor}
            />
          }
        >
          {/* Day Basis Summary KPI Cards */}
          <View className="bg-card border border-border rounded-2xl p-4 mb-4 shadow-xs">
            <Text className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              Day Summary ({selectedDate})
            </Text>
            <View className="flex-row gap-3">
              <View className="flex-1 bg-orange-500/10 border border-orange-500/20 rounded-xl p-3.5 items-center justify-center">
                <View className="flex-row items-center gap-1.5 mb-1">
                  <Users size={16} color="#f97316" weight="bold" />
                  <Text className="text-xs font-semibold text-orange-600 dark:text-orange-400">
                    Total Meals
                  </Text>
                </View>
                <Text className="text-2xl font-bold text-foreground">
                  {summary.total_count}
                </Text>
              </View>

              <View className="flex-1 bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-3.5 items-center justify-center">
                <View className="flex-row items-center gap-1.5 mb-1">
                  <CurrencyCircleDollar size={16} color="#10b981" weight="bold" />
                  <Text className="text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                    Total Charge
                  </Text>
                </View>
                <Text className="text-2xl font-bold text-foreground">
                  ৳ {summary.total_charge.toFixed(2)}
                </Text>
              </View>
            </View>
          </View>

          {/* Detailed Attendance List */}
          <View className="mb-6">
            <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2.5 px-0.5">
              Attendance Records ({summary.items.length})
            </Text>

            {summary.items.length === 0 ? (
              <View className="bg-card border border-border rounded-2xl p-8 items-center justify-center shadow-xs">
                <View className="w-12 h-12 rounded-2xl bg-muted/50 items-center justify-center mb-3 border border-border">
                  <ForkKnife size={24} color={isDark ? '#94a3b8' : '#64748b'} />
                </View>
                <Text className="text-base font-bold text-foreground mb-1 text-center">
                  No Attendance Recorded
                </Text>
                <Text className="text-xs text-muted-foreground text-center">
                  No meal attendance records found for {selectedDate}.
                </Text>
              </View>
            ) : (
              summary.items.map((item) => (
                <View
                  key={item.id}
                  className="bg-card border border-border rounded-xl p-3.5 mb-2.5 flex-row items-center justify-between shadow-xs"
                >
                  <View className="flex-row items-center gap-3 flex-1">
                    <View className="w-10 h-10 rounded-xl bg-primary/10 border border-primary/20 items-center justify-center">
                      <CalendarCheck size={20} color={accentColor} weight="bold" />
                    </View>
                    <View className="flex-1">
                      <Text className="text-base font-bold text-foreground" numberOfLines={1}>
                        {item.customer?.full_name || 'Unnamed Customer'}
                      </Text>
                      <Text className="text-xs text-muted-foreground mt-0.5">
                        {item.shift?.name ? `Shift: ${item.shift.name}` : 'General Shift'}
                        {item.customer?.phone ? ` • ${item.customer.phone}` : ''}
                      </Text>
                    </View>
                  </View>

                  <View className="bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-1 rounded-lg">
                    <Text className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                      ৳ {Number(item.charge_amount).toFixed(2)}
                    </Text>
                  </View>
                </View>
              ))
            )}
          </View>
        </ScrollView>
      )}
    </View>
  );
}
