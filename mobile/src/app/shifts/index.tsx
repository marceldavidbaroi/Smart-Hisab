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
import { Input } from '@/components/ui/input';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { SwipeableRow } from '@/components/ui/SwipeableRow';

export default function ShiftsScreen() {
  const router = useRouter();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const { shifts, fetchShifts, isLoading, createShift, updateShift, deleteShift, toggleShiftStatus } = useShiftStore();
  
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';
  const [refreshing, setRefreshing] = useState(false);

  // Bottom Slide Sheet Modal
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [editingShift, setEditingShift] = useState<Shift | null>(null);
  const [newShiftName, setNewShiftName] = useState('');
  const [newStartTime, setNewStartTime] = useState('08:00 AM');
  const [newEndTime, setNewEndTime] = useState('04:00 PM');
  const [modalError, setModalError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const TIME12H_RE = /^(0[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$/i;

  const to24h = (time12: string): string => {
    if (!time12) return '';
    const match = time12.trim().match(TIME12H_RE);
    if (!match) {
      const parts = time12.split(':');
      if (parts.length >= 2) {
        return `${parts[0].padStart(2, '0')}:${parts[1].slice(0, 2).padStart(2, '0')}`;
      }
      return '';
    }
    let hours = parseInt(match[1], 10);
    const minutes = match[2];
    const ampm = match[3].toUpperCase();
    if (ampm === 'AM') {
      hours = hours === 12 ? 0 : hours;
    } else {
      hours = hours === 12 ? 12 : hours + 12;
    }
    return `${String(hours).padStart(2, '0')}:${minutes}`;
  };

  const timeToMinutes = (time24Str: string): number => {
    const [h = '0', m = '0'] = time24Str.split(':');
    return parseInt(h, 10) * 60 + parseInt(m, 10);
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

  const openCreateModal = () => {
    setEditingShift(null);
    setNewShiftName('');
    setNewStartTime('08:00 AM');
    setNewEndTime('04:00 PM');
    setModalError(null);
    setIsModalVisible(true);
  };

  const openEditModal = (shift: Shift) => {
    setEditingShift(shift);
    setNewShiftName(shift.name);
    setNewStartTime(format24To12h(shift.start_time));
    setNewEndTime(format24To12h(shift.end_time));
    setModalError(null);
    setIsModalVisible(true);
  };

  const handleSaveShift = async () => {
    if (!newShiftName.trim()) {
      setModalError('Please enter a shift name.');
      return;
    }
    if (!TIME12H_RE.test(newStartTime.trim())) {
      setModalError('Invalid start time (e.g. 08:00 AM).');
      return;
    }
    if (!TIME12H_RE.test(newEndTime.trim())) {
      setModalError('Invalid end time (e.g. 04:00 PM).');
      return;
    }
    if (!activeTenant?.id) return;

    const start24 = to24h(newStartTime);
    const end24 = to24h(newEndTime);
    const newStartMin = timeToMinutes(start24);
    let newEndMin = timeToMinutes(end24);
    if (newEndMin <= newStartMin) newEndMin += 24 * 60;

    // Check overlap with existing shifts (ignoring current shift if editing)
    const conflict = shifts.find((s) => {
      if (editingShift && s.id === editingShift.id) return false;
      const sStart = timeToMinutes(s.start_time);
      let sEnd = timeToMinutes(s.end_time);
      if (sEnd <= sStart) sEnd += 24 * 60;
      return Math.max(newStartMin, sStart) < Math.min(newEndMin, sEnd);
    });

    if (conflict) {
      setModalError(`Time overlaps with shift "${conflict.name}".`);
      return;
    }

    try {
      setIsSubmitting(true);
      setModalError(null);
      if (editingShift && editingShift.id) {
        await updateShift(editingShift.id, {
          name: newShiftName.trim(),
          start_time: start24,
          end_time: end24,
        });
      } else {
        await createShift(activeTenant.id, {
          name: newShiftName.trim(),
          start_time: start24,
          end_time: end24,
          is_active: true,
        });
      }
      setIsModalVisible(false);
    } catch (err: any) {
      setModalError(err?.message || 'Failed to save shift.');
    } finally {
      setIsSubmitting(false);
    }
  };

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
          onPress={openCreateModal}
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
              onPress={openCreateModal}
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
            <SwipeableRow
              key={shift.id || idx.toString()}
              onEdit={() => openEditModal(shift)}
              onDelete={() => handleDelete(shift)}
              accentColor={accentColor}
              shouldPeek={idx === 0}
            >
              <Card className="bg-card border-border rounded-2xl p-4 mb-3.5 shadow-xs overflow-hidden">
                <View className="flex-row items-center justify-between">
                  {/* Title and Time Badge */}
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
            </SwipeableRow>
          );
        })}
      </ScrollView>

      {/* Add Shift Bottom Slide Sheet Modal */}
      <BottomSlideModal
        visible={isModalVisible}
        onClose={() => setIsModalVisible(false)}
        isDark={isDark}
      >
        <View className="gap-4">
          <View className="flex-row items-center justify-between pb-2 border-b border-border">
            <Text className="text-lg font-bold text-foreground">Add New Shift</Text>
          </View>

          <View className="gap-1.5">
            <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              Shift Name *
            </Text>
            <Input
              value={newShiftName}
              onChangeText={(text) => {
                setNewShiftName(text);
                setModalError(null);
              }}
              placeholder="e.g. Breakfast, Lunch, Dinner"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
              className="h-12 text-sm font-medium"
            />
          </View>

          <View className="flex-row gap-3">
            <View className="flex-1 gap-1.5">
              <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Start Time *
              </Text>
              <Input
                value={newStartTime}
                onChangeText={(text) => {
                  setNewStartTime(text);
                  setModalError(null);
                }}
                placeholder="08:00 AM"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="h-12 text-sm font-medium text-center"
              />
            </View>
            <View className="flex-1 gap-1.5">
              <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                End Time *
              </Text>
              <Input
                value={newEndTime}
                onChangeText={(text) => {
                  setNewEndTime(text);
                  setModalError(null);
                }}
                placeholder="04:00 PM"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="h-12 text-sm font-medium text-center"
              />
            </View>
          </View>

          {modalError && (
            <View className="bg-destructive/10 border border-destructive/20 p-3 rounded-xl">
              <Text className="text-xs font-semibold text-destructive">{modalError}</Text>
            </View>
          )}

          <Button
            onPress={handleSaveShift}
            disabled={isSubmitting || !newShiftName.trim()}
            className="w-full h-12 rounded-xl mt-2"
          >
            {isSubmitting ? (
              <ActivityIndicator color="#ffffff" size="small" />
            ) : (
              <Text className="font-bold text-primary-foreground text-sm">Save Shift</Text>
            )}
          </Button>
        </View>
      </BottomSlideModal>
    </SafeAreaView>
  );
}
