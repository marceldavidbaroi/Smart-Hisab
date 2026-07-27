import React, { useRef } from 'react';
import {
  View,
  Text,
  PanResponder,
  TouchableOpacity,
  LayoutChangeEvent,
  StyleSheet,
} from 'react-native';
import { Sun, Moon, Clock } from 'phosphor-react-native';

interface TimeRangeSliderProps {
  startHour: number; // 0 - 24 (e.g., 8 for 8:00 AM)
  endHour: number;   // 0 - 24 (e.g., 16 for 4:00 PM)
  onChange: (startHour: number, endHour: number) => void;
  isDark?: boolean;
  accentColor?: string;
}

export function TimeRangeSlider({
  startHour,
  endHour,
  onChange,
  isDark = false,
  accentColor = '#56778a',
}: TimeRangeSliderProps) {
  const trackWidthRef = useRef<number>(0);
  const startHourRef = useRef<number>(startHour);
  const endHourRef = useRef<number>(endHour);

  startHourRef.current = startHour;
  endHourRef.current = endHour;

  const snapToHalfHour = (hourVal: number): number => {
    // Snap to 0.5 step (30 minute increments)
    const snapped = Math.round(hourVal * 2) / 2;
    return Math.max(0, Math.min(24, snapped));
  };

  const handleStartPan = PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderMove: (evt, gestureState) => {
      if (trackWidthRef.current <= 0) return;
      // Calculate delta hours from movement
      const deltaRatio = gestureState.dx / trackWidthRef.current;
      const deltaHours = deltaRatio * 24;
      let newStart = snapToHalfHour(startHourRef.current + deltaHours);
      if (newStart >= endHourRef.current - 0.5) {
        newStart = Math.max(0, endHourRef.current - 0.5);
      }
      onChange(newStart, endHourRef.current);
    },
  });

  const handleEndPan = PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderMove: (evt, gestureState) => {
      if (trackWidthRef.current <= 0) return;
      const deltaRatio = gestureState.dx / trackWidthRef.current;
      const deltaHours = deltaRatio * 24;
      let newEnd = snapToHalfHour(endHourRef.current + deltaHours);
      if (newEnd <= startHourRef.current + 0.5) {
        newEnd = Math.min(24, startHourRef.current + 0.5);
      }
      onChange(startHourRef.current, newEnd);
    },
  });

  const formatHourTo12h = (h: number): string => {
    const hoursInt = Math.floor(h);
    const mins = h % 1 !== 0 ? '30' : '00';
    const ampm = hoursInt >= 12 && hoursInt < 24 ? 'PM' : 'AM';
    let displayHour = hoursInt % 12;
    if (displayHour === 0) displayHour = 12;
    return `${String(displayHour).padStart(2, '0')}:${mins} ${ampm}`;
  };

  const calculateDuration = (s: number, e: number): string => {
    const diff = e - s;
    if (diff <= 0) return '0 hrs';
    const hrs = Math.floor(diff);
    const mins = (diff % 1) * 60;
    if (mins === 0) return `${hrs} hrs`;
    return `${hrs} hrs ${mins} mins`;
  };

  const onTrackLayout = (e: LayoutChangeEvent) => {
    trackWidthRef.current = e.nativeEvent.layout.width;
  };

  const startPercent = (startHour / 24) * 100;
  const endPercent = (endHour / 24) * 100;
  const activeWidthPercent = Math.max(0, endPercent - startPercent);

  // Quick Presets
  const presets = [
    { label: 'Morning (8 AM - 4 PM)', start: 8, end: 16 },
    { label: 'Evening (4 PM - 12 AM)', start: 16, end: 24 },
    { label: 'Full Day (9 AM - 6 PM)', start: 9, end: 18 },
    { label: 'Night (10 PM - 6 AM)', start: 22, end: 24 },
  ];

  return (
    <View className="gap-4 my-2">
      {/* Header Info Banner */}
      <View
        className={`p-4 rounded-2xl border flex-row items-center justify-between ${
          isDark ? 'bg-secondary/30 border-border' : 'bg-primary/5 border-primary/15'
        }`}
      >
        <View className="flex-row items-center gap-2.5">
          <View className="h-10 w-10 rounded-xl bg-primary/15 items-center justify-center">
            <Clock size={20} color={accentColor} weight="bold" />
          </View>
          <View>
            <Text className={`text-xs font-semibold uppercase tracking-wider ${isDark ? 'text-slate-400' : 'text-slate-500'}`}>
              Selected Shift Window
            </Text>
            <Text className="text-base font-bold text-foreground">
              {formatHourTo12h(startHour)} – {formatHourTo12h(endHour)}
            </Text>
          </View>
        </View>

        <View className="bg-primary/15 px-3 py-1.5 rounded-full border border-primary/20">
          <Text className="text-xs font-bold text-primary">
            {calculateDuration(startHour, endHour)}
          </Text>
        </View>
      </View>

      {/* Range Slider Track Container */}
      <View className="px-2 pt-2 pb-4">
        {/* Track Label Indicators */}
        <View className="flex-row justify-between mb-2">
          <View className="flex-row items-center gap-1">
            <Moon size={12} color={isDark ? '#94a3b8' : '#64748b'} />
            <Text className="text-[11px] font-semibold text-muted-foreground">12 AM</Text>
          </View>
          <View className="flex-row items-center gap-1">
            <Sun size={12} color={isDark ? '#eab308' : '#d97706'} />
            <Text className="text-[11px] font-semibold text-muted-foreground">12 PM</Text>
          </View>
          <View className="flex-row items-center gap-1">
            <Moon size={12} color={isDark ? '#94a3b8' : '#64748b'} />
            <Text className="text-[11px] font-semibold text-muted-foreground">12 AM</Text>
          </View>
        </View>

        {/* Range Slider Bar */}
        <View
          onLayout={onTrackLayout}
          className={`h-4 rounded-full relative justify-center ${
            isDark ? 'bg-slate-800' : 'bg-slate-200'
          }`}
        >
          {/* Active Highlight Range */}
          <View
            style={{
              left: `${startPercent}%`,
              width: `${activeWidthPercent}%`,
              backgroundColor: accentColor,
            }}
            className="h-4 rounded-full absolute"
          />

          {/* Start Thumb Handle */}
          <View
            {...handleStartPan.panHandlers}
            style={{ left: `${startPercent}%`, transform: [{ translateX: -14 }] }}
            className="absolute z-20 h-7 w-7 rounded-full bg-white shadow-md border-2 border-primary items-center justify-center"
          >
            <View className="h-2 w-2 rounded-full bg-primary" />
          </View>

          {/* End Thumb Handle */}
          <View
            {...handleEndPan.panHandlers}
            style={{ left: `${endPercent}%`, transform: [{ translateX: -14 }] }}
            className="absolute z-20 h-7 w-7 rounded-full bg-white shadow-md border-2 border-primary items-center justify-center"
          >
            <View className="h-2 w-2 rounded-full bg-primary" />
          </View>
        </View>

        {/* Time Marker Ticks */}
        <View className="flex-row justify-between mt-2 px-1">
          <Text className="text-[10px] text-muted-foreground">06:00 AM</Text>
          <Text className="text-[10px] text-muted-foreground">12:00 PM</Text>
          <Text className="text-[10px] text-muted-foreground">06:00 PM</Text>
        </View>
      </View>

      {/* Preset Quick Select Chips */}
      <View className="gap-1.5">
        <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
          Quick Preset Shift Windows
        </Text>
        <View className="flex-row flex-wrap gap-2 pt-0.5">
          {presets.map((p) => {
            const isMatch = startHour === p.start && endHour === p.end;
            return (
              <TouchableOpacity
                key={p.label}
                onPress={() => onChange(p.start, p.end)}
                activeOpacity={0.7}
                className={`px-3 py-1.5 rounded-xl border ${
                  isMatch
                    ? 'bg-primary/15 border-primary'
                    : isDark
                    ? 'bg-secondary/40 border-border'
                    : 'bg-slate-100 border-slate-200'
                }`}
              >
                <Text
                  className={`text-xs font-semibold ${
                    isMatch ? 'text-primary font-bold' : 'text-foreground'
                  }`}
                >
                  {p.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </View>
  );
}
