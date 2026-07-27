import React, { useState } from 'react';
import {
  View,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Clock, CalendarCheck, Sparkle, WarningCircle, Check } from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useShiftStore } from '@/store/useShiftStore';
import { Text } from '@/components/ui/text';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';
import { TimeRangeSlider } from '@/components/ui/TimeRangeSlider';

const DAYS_OF_WEEK = [
  { key: 'Mon', label: 'Mon' },
  { key: 'Tue', label: 'Tue' },
  { key: 'Wed', label: 'Wed' },
  { key: 'Thu', label: 'Thu' },
  { key: 'Fri', label: 'Fri' },
  { key: 'Sat', label: 'Sat' },
  { key: 'Sun', label: 'Sun' },
];

export default function AddShiftScreen() {
  const router = useRouter();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const { createShift, isLoading } = useShiftStore();
  const isDark = colorScheme === 'dark';

  const [name, setName] = useState('General Shift');
  const [startHourNum, setStartHourNum] = useState<number>(8); // 8:00 AM
  const [endHourNum, setEndHourNum] = useState<number>(16);   // 4:00 PM
  const [startTime, setStartTime] = useState('08:00 AM');
  const [endTime, setEndTime] = useState('04:00 PM');
  const [selectedDays, setSelectedDays] = useState<string[]>(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
  const [error, setError] = useState<string | null>(null);

  const accentColor = isDark ? '#d4984e' : '#56778a';

  const formatHourTo12hString = (h: number): string => {
    const hoursInt = Math.floor(h);
    const mins = h % 1 !== 0 ? '30' : '00';
    const ampm = hoursInt >= 12 && hoursInt < 24 ? 'PM' : 'AM';
    let displayHour = hoursInt % 12;
    if (displayHour === 0) displayHour = 12;
    return `${String(displayHour).padStart(2, '0')}:${mins} ${ampm}`;
  };

  const handleSliderChange = (sHour: number, eHour: number) => {
    setStartHourNum(sHour);
    setEndHourNum(eHour);
    setStartTime(formatHourTo12hString(sHour));
    setEndTime(formatHourTo12hString(eHour));
    setError(null);
  };

  const toggleDay = (dayKey: string) => {
    setError(null);
    if (selectedDays.includes(dayKey)) {
      if (selectedDays.length === 1) {
        setError('At least one working day must be selected.');
        return;
      }
      setSelectedDays(selectedDays.filter((d) => d !== dayKey));
    } else {
      setSelectedDays([...selectedDays, dayKey]);
    }
  };

  const to24h = (time12: string): string => {
    if (!time12) return '08:00';
    const match = time12.trim().match(/^(0[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$/i);
    if (!match) {
      const parts = time12.split(':');
      if (parts.length >= 2) {
        const h = parts[0].padStart(2, '0');
        const m = parts[1].slice(0, 2).padStart(2, '0');
        return `${h}:${m}`;
      }
      return '08:00';
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

  const validateTimeFormat = (timeStr: string) => {
    return /^(0[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$/i.test(timeStr.trim());
  };

  const handleSaveShift = async () => {
    if (!name.trim()) {
      setError('Please enter a shift name.');
      return;
    }

    if (!validateTimeFormat(startTime)) {
      setError('Invalid Start Time format. Use format hh:mm AM/PM (e.g. 08:00 AM).');
      return;
    }

    if (!validateTimeFormat(endTime)) {
      setError('Invalid End Time format. Use format hh:mm AM/PM (e.g. 04:00 PM).');
      return;
    }

    if (selectedDays.length === 0) {
      setError('Please select at least one working day.');
      return;
    }

    if (!activeTenant?.id) {
      setError('Active workspace tenant not found. Please log in again.');
      return;
    }

    try {
      setError(null);
      const start24 = to24h(startTime);
      const end24 = to24h(endTime);

      await createShift(activeTenant.id, {
        name: name.trim(),
        start_time: start24,
        end_time: end24,
        is_active: true,
        days: selectedDays,
      });

      router.replace('/(main)');
    } catch (err: any) {
      console.error('Failed to create initial shift:', err);
      setError(err?.message || 'Failed to save initial shift.');
    }
  };

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1"
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', paddingHorizontal: 20, paddingVertical: 24 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Header Branding */}
          <View className="items-center mb-6">
            <View className="h-16 w-16 rounded-2xl bg-primary/15 items-center justify-center mb-3 border border-primary/20 shadow-xs">
              <Clock size={36} color={accentColor} weight="bold" />
            </View>
            <Text className="text-2xl font-bold text-foreground text-center tracking-tight">
              Initial Shift Setup
            </Text>
            <Text className="text-xs font-semibold text-muted-foreground text-center mt-1 uppercase tracking-wider">
              Configure working hours & days for {activeTenant?.name || 'your workspace'}
            </Text>
          </View>

          {/* Form Card */}
          <Card className="bg-card border-border shadow-sm rounded-2xl overflow-hidden">
            <CardHeader className="p-5 pb-2">
              <CardTitle className="text-lg font-bold text-foreground">
                Shift Configuration
              </CardTitle>
              <CardDescription className="text-xs text-muted-foreground leading-relaxed">
                Define the default daily working shift for operations, POS logging, and staff sessions.
              </CardDescription>
            </CardHeader>

            <CardContent className="p-5 pt-2 gap-4">
              {/* Shift Name Input */}
              <View className="gap-1.5">
                <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                  Shift Name
                </Text>
                <View className="relative flex-row items-center">
                  <View className="absolute left-3.5 z-10">
                    <Sparkle size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                  </View>
                  <Input
                    value={name}
                    onChangeText={(val) => {
                      setName(val);
                      setError(null);
                    }}
                    placeholder="e.g. Morning Shift / General Shift"
                    placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                    className="pl-11 h-12 text-sm font-medium w-full"
                  />
                </View>
              </View>

              {/* Time Range Slider Component */}
              <TimeRangeSlider
                startHour={startHourNum}
                endHour={endHourNum}
                onChange={handleSliderChange}
                isDark={isDark}
                accentColor={accentColor}
              />

              {/* Editable Time Input Fallbacks */}
              <View className="flex-row gap-3">
                <View className="flex-1 gap-1.5">
                  <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                    Start Time
                  </Text>
                  <Input
                    value={startTime}
                    onChangeText={(val) => {
                      setStartTime(val);
                      setError(null);
                    }}
                    placeholder="08:00 AM"
                    placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                    className="h-12 text-sm font-medium text-center"
                  />
                </View>

                <View className="flex-1 gap-1.5">
                  <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                    End Time
                  </Text>
                  <Input
                    value={endTime}
                    onChangeText={(val) => {
                      setEndTime(val);
                      setError(null);
                    }}
                    placeholder="04:00 PM"
                    placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                    className="h-12 text-sm font-medium text-center"
                  />
                </View>
              </View>

              {/* Day Mapper Component */}
              <View className="gap-2 mt-1">
                <View className="flex-row items-center justify-between">
                  <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                    Working Days (Day Mapper)
                  </Text>
                  <View className="flex-row items-center gap-1">
                    <CalendarCheck size={14} color={accentColor} />
                    <Text className="text-xs font-medium text-primary">
                      {selectedDays.length} Days Active
                    </Text>
                  </View>
                </View>

                <View className="flex-row flex-wrap gap-2 pt-1">
                  {DAYS_OF_WEEK.map((day) => {
                    const isSelected = selectedDays.includes(day.key);
                    return (
                      <TouchableOpacity
                        key={day.key}
                        onPress={() => toggleDay(day.key)}
                        activeOpacity={0.7}
                        style={{ minWidth: 44 }}
                        className={`h-11 px-3.5 rounded-xl border flex-row items-center justify-center gap-1.5 ${
                          isSelected
                            ? 'bg-primary border-primary'
                            : isDark
                            ? 'bg-secondary/40 border-border'
                            : 'bg-slate-100 border-slate-200'
                        }`}
                      >
                        {isSelected && <Check size={14} color="#ffffff" weight="bold" />}
                        <Text
                          className={`text-xs font-bold ${
                            isSelected ? 'text-primary-foreground' : 'text-foreground'
                          }`}
                        >
                          {day.label}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>

              {/* Error Banner */}
              {error && (
                <View className="flex-row items-center gap-2 bg-destructive/10 border border-destructive/20 p-3 rounded-xl">
                  <WarningCircle size={16} color="#ef4444" />
                  <Text className="flex-1 text-xs text-destructive font-semibold">
                    {error}
                  </Text>
                </View>
              )}

              {/* Save Action Button */}
              <Button
                variant="default"
                onPress={handleSaveShift}
                disabled={isLoading || !name.trim()}
                className="w-full h-12 rounded-xl mt-3 shadow-xs"
              >
                {isLoading ? (
                  <ActivityIndicator size="small" color="#ffffff" />
                ) : (
                  <Text className="font-bold text-primary-foreground text-sm">
                    Save Shift & Continue to Dashboard
                  </Text>
                )}
              </Button>
            </CardContent>
          </Card>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
