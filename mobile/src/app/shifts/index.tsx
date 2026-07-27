import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
  Alert,
  Switch,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import {
  Clock,
  ArrowLeft,
  Plus,
  Storefront,
  Trash,
  CheckCircle,
  XCircle,
  CalendarCheck,
  Sparkle,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useShiftStore, Shift } from '@/store/useShiftStore';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

export default function ShiftsScreen() {
  const router = useRouter();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const { shifts, fetchShifts, isLoading, toggleShiftStatus, deleteShift } = useShiftStore();
  
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    if (activeTenant?.id) {
      await fetchShifts(activeTenant.id);
    }
  }, [activeTenant?.id, fetchShifts]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const handleToggle = async (shift: Shift) => {
    if (!shift.id) return;
    try {
      await toggleShiftStatus(shift.id, !shift.is_active);
    } catch (err: any) {
      Alert.alert('Error', err?.message || 'Failed to update shift status.');
    }
  };

  const handleDelete = (shift: Shift) => {
    if (!shift.id) return;
    Alert.alert(
      'Delete Shift',
      `Are you sure you want to delete "${shift.name}"? This action cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteShift(shift.id!);
            } catch (err: any) {
              Alert.alert('Error', err?.message || 'Failed to delete shift.');
            }
          },
        },
      ]
    );
  };

  const format24To12h = (time24?: string): string => {
    if (!time24) return '--:--';
    const parts = time24.split(':');
    if (parts.length < 2) return time24;
    let hour = parseInt(parts[0], 10);
    const minute = parts[1].substring(0, 2);
    if (isNaN(hour)) return time24;
    const ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 || 12;
    return `${String(hour).padStart(2, '0')}:${minute} ${ampm}`;
  };

  const activeShiftsCount = shifts.filter((s) => s.is_active).length;

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      {/* Header Bar */}
      <View className="px-5 py-3 flex-row items-center justify-between border-b border-border bg-card">
        <View className="flex-row items-center gap-3">
          <TouchableOpacity
            onPress={() => router.back()}
            activeOpacity={0.7}
            className="w-10 h-10 rounded-xl bg-muted/60 items-center justify-center border border-border min-h-[48px] min-w-[48px]"
          >
            <ArrowLeft size={20} color={isDark ? '#e2e8f0' : '#1e293b'} weight="bold" />
          </TouchableOpacity>
          <View>
            <Text className="text-lg font-bold text-foreground tracking-tight">
              Shift Management
            </Text>
            <Text className="text-xs text-muted-foreground">
              {activeTenant?.name || 'Workspace Shifts'}
            </Text>
          </View>
        </View>

        <TouchableOpacity
          onPress={() => router.push('/add-shift')}
          activeOpacity={0.7}
          className="bg-primary px-3.5 h-10 rounded-xl flex-row items-center gap-1.5 min-h-[48px]"
        >
          <Plus size={16} color="#ffffff" weight="bold" />
          <Text className="text-xs font-bold text-primary-foreground">Add Shift</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        contentContainerStyle={{ padding: 20, paddingBottom: 40 }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={[accentColor]} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Workspace Summary Header */}
        <View className="bg-card border border-border rounded-2xl p-4 mb-4 shadow-xs flex-row items-center justify-between">
          <View className="flex-row items-center gap-3">
            <View className="w-10 h-10 rounded-xl bg-primary/15 items-center justify-center border border-primary/20">
              <Clock size={22} color={accentColor} weight="bold" />
            </View>
            <View>
              <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Active Operational Shifts
              </Text>
              <Text className="text-base font-bold text-foreground">
                {shifts.length} {shifts.length === 1 ? 'Shift Configured' : 'Shifts Configured'}
              </Text>
            </View>
          </View>
          <View className="bg-emerald-500/10 border border-emerald-500/20 px-3 py-1 rounded-full">
            <Text className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
              {activeShiftsCount} Active
            </Text>
          </View>
        </View>

        {/* Loading Indicator */}
        {isLoading && !refreshing && shifts.length === 0 && (
          <View className="py-12 items-center justify-center">
            <ActivityIndicator size="large" color={accentColor} />
            <Text className="text-xs font-semibold text-muted-foreground mt-3">
              Loading workspace shifts...
            </Text>
          </View>
        )}

        {/* Empty State */}
        {!isLoading && shifts.length === 0 && (
          <Card className="bg-card border-border rounded-2xl p-8 items-center justify-center shadow-xs my-4">
            <View className="w-16 h-16 rounded-2xl bg-muted/60 border border-border items-center justify-center mb-3">
              <Clock size={36} color={isDark ? '#64748b' : '#94a3b8'} weight="light" />
            </View>
            <Text className="text-lg font-bold text-foreground text-center">
              No Shifts Created Yet
            </Text>
            <Text className="text-xs text-muted-foreground text-center mt-1 mb-5 leading-relaxed max-w-[260px]">
              Set up working shifts to manage store operational hours, cashier turns, and daily ledger reports.
            </Text>
            <Button
              onPress={() => router.push('/add-shift')}
              className="px-6 h-11 rounded-xl flex-row items-center gap-2"
            >
              <Plus size={16} color="#ffffff" weight="bold" />
              <Text className="text-xs font-bold text-primary-foreground">Create First Shift</Text>
            </Button>
          </Card>
        )}

        {/* Shifts List */}
        {shifts.map((shift, idx) => {
          const formattedStart = format24To12h(shift.start_time);
          const formattedEnd = format24To12h(shift.end_time);

          return (
            <Card
              key={shift.id || idx.toString()}
              className="bg-card border-border rounded-2xl p-4 mb-3.5 shadow-xs overflow-hidden"
            >
              <View className="flex-row items-start justify-between">
                {/* Title and Badge */}
                <View className="flex-1 mr-3">
                  <View className="flex-row items-center gap-2 mb-1">
                    <View className="w-8 h-8 rounded-lg bg-primary/10 items-center justify-center border border-primary/20">
                      <Sparkle size={16} color={accentColor} weight="bold" />
                    </View>
                    <Text className="text-base font-bold text-foreground flex-1" numberOfLines={1}>
                      {shift.name}
                    </Text>
                  </View>

                  {/* Time Badge */}
                  <View className="flex-row items-center gap-2 mt-2">
                    <View className="bg-muted/80 border border-border px-3 py-1.5 rounded-xl flex-row items-center gap-1.5">
                      <Clock size={14} color={isDark ? '#94a3b8' : '#64748b'} />
                      <Text className="text-xs font-semibold text-foreground">
                        {formattedStart} — {formattedEnd}
                      </Text>
                    </View>
                  </View>
                </View>

                {/* Status Toggle & Delete */}
                <View className="items-end gap-2">
                  <View className="flex-row items-center gap-2">
                    <Text className={`text-[11px] font-bold ${shift.is_active ? 'text-emerald-600 dark:text-emerald-400' : 'text-muted-foreground'}`}>
                      {shift.is_active ? 'Active' : 'Disabled'}
                    </Text>
                    <Switch
                      value={shift.is_active}
                      onValueChange={() => handleToggle(shift)}
                      trackColor={{ false: '#94a3b8', true: '#10b981' }}
                      thumbColor="#ffffff"
                      style={{ transform: [{ scaleX: 0.8 }, { scaleY: 0.8 }] }}
                    />
                  </View>

                  <TouchableOpacity
                    onPress={() => handleDelete(shift)}
                    activeOpacity={0.7}
                    className="p-2 rounded-lg bg-destructive/10 border border-destructive/20 min-h-[36px] min-w-[36px] items-center justify-center"
                  >
                    <Trash size={15} color="#ef4444" weight="bold" />
                  </TouchableOpacity>
                </View>
              </View>

              {/* Working Days Chips */}
              {shift.days && shift.days.length > 0 && (
                <View className="mt-3 pt-3 border-t border-border/60 flex-row items-center flex-wrap gap-1.5">
                  <CalendarCheck size={14} color={isDark ? '#94a3b8' : '#64748b'} />
                  {shift.days.map((day) => (
                    <View
                      key={day}
                      className="bg-primary/10 border border-primary/20 px-2.5 py-0.5 rounded-md"
                    >
                      <Text className="text-[10px] font-bold text-primary">{day}</Text>
                    </View>
                  ))}
                </View>
              )}
            </Card>
          );
        })}
      </ScrollView>
    </SafeAreaView>
  );
}
