import React, { useState } from 'react';
import { ScrollView } from 'react-native';
import { useAppStore } from '@/store/useAppStore';
import { RunningDayBanner } from '@/components/RunningDayBanner';
import { DayControlModal } from '@/components/ui/DayControlModal';

export default function TerminalHomeScreen() {
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';
  const [dayModalVisible, setDayModalVisible] = useState(false);

  return (
    <ScrollView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5`}>
      {/* Simple Button for the Day */}
      <RunningDayBanner onPressDayControl={() => setDayModalVisible(true)} />

      {/* Day Control Modal */}
      <DayControlModal
        visible={dayModalVisible}
        onClose={() => setDayModalVisible(false)}
      />
    </ScrollView>
  );
}
