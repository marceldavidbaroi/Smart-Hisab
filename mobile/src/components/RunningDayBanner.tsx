import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Clock, CurrencyCircleDollar, StopCircle, Calendar, Play, Warning } from 'phosphor-react-native';
import { useBusinessDayStore } from '@/store/useBusinessDayStore';
import { useAppStore } from '@/store/useAppStore';

interface RunningDayBannerProps {
  onPressDayControl: () => void;
}

export function RunningDayBanner({ onPressDayControl }: RunningDayBannerProps) {
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';
  const { activeDay } = useBusinessDayStore();

  const [currentTime, setCurrentTime] = useState<string>('');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true }));
    };

    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  if (!activeDay) {
    return (
      <TouchableOpacity
        activeOpacity={0.85}
        onPress={onPressDayControl}
        className={`border rounded-2xl p-4 mb-4 shadow-sm flex-row items-center justify-between ${
          isDark ? 'bg-amber-950/40 border-amber-500/30' : 'bg-amber-500/10 border-amber-500/30'
        }`}
      >
        <View className="flex-row items-center gap-3.5 flex-1">
          <View className="w-11 h-11 rounded-2xl bg-amber-500/20 border border-amber-500/40 items-center justify-center">
            <Warning size={24} color="#f59e0b" weight="bold" />
          </View>

          <View className="flex-1">
            <Text className="text-[11px] font-semibold uppercase tracking-wider text-amber-700 dark:text-amber-400">
              Operational Status
            </Text>
            <Text className="text-sm font-extrabold text-foreground mt-0.5">
              No Business Day Running
            </Text>
            <Text className="text-xs text-muted-foreground mt-0.5">
              Tap to enter opening float & start day
            </Text>
          </View>
        </View>

        <View className="bg-amber-600 dark:bg-amber-500 px-3.5 py-2.5 rounded-xl flex-row items-center gap-1.5 shadow-xs">
          <Play size={16} color="#ffffff" weight="bold" />
          <Text className="text-xs font-bold text-white">Start Day</Text>
        </View>
      </TouchableOpacity>
    );
  }

  return (
    <TouchableOpacity
      activeOpacity={0.85}
      onPress={onPressDayControl}
      className={`border rounded-2xl p-4 mb-4 shadow-sm flex-row items-center justify-between ${
        isDark ? 'bg-emerald-950/40 border-emerald-500/30' : 'bg-emerald-500/10 border-emerald-500/30'
      }`}
    >
      <View className="flex-row items-center gap-3.5 flex-1">
        <View className="w-11 h-11 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 items-center justify-center">
          <Clock size={24} color="#10b981" weight="bold" />
        </View>

        <View className="flex-1">
          <View className="flex-row items-center gap-2">
            <View className="flex-row items-center gap-1">
              <Calendar size={12} color="#10b981" weight="bold" />
              <Text className="text-[11px] font-semibold text-emerald-700 dark:text-emerald-400">
                {activeDay.business_date}
              </Text>
            </View>
            <Text className="text-[11px] text-muted-foreground">•</Text>
            <Text className="text-[11px] font-bold text-emerald-600 dark:text-emerald-300">
              {currentTime}
            </Text>
          </View>

          <Text className="text-sm font-extrabold text-foreground mt-0.5">
            Day Running (Float: ৳ {Number(activeDay.opening_cash || 0).toFixed(2)})
          </Text>
        </View>
      </View>

      <View className="bg-emerald-600 dark:bg-emerald-500 px-3.5 py-2.5 rounded-xl flex-row items-center gap-1.5 shadow-xs">
        <StopCircle size={16} color="#ffffff" weight="bold" />
        <Text className="text-xs font-bold text-white">End Day</Text>
      </View>
    </TouchableOpacity>
  );
}
