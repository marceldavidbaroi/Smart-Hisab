import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Key } from 'phosphor-react-native';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';

interface PinRevealModalProps {
  visible: boolean;
  onClose: () => void;
  tempPin: string;
  targetStaffName: string;
  isDark: boolean;
  insets: any;
}

export default function PinRevealModal({
  visible,
  onClose,
  tempPin,
  targetStaffName,
  isDark,
}: PinRevealModalProps) {
  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark} snapPoints={['40%']} className="items-center">
      <View className="w-12 h-12 rounded-full bg-amber-500/15 items-center justify-center border border-amber-500/20 mb-3 -mt-2">
        <Key size={24} color="#f59e0b" weight="bold" />
      </View>

      <Text className="text-base font-bold text-foreground text-center">
        Temporary Terminal PIN
      </Text>
      <Text className="text-xs text-muted-foreground text-center mt-1 mb-4">
        Generated for <Text className="font-bold text-foreground">{targetStaffName}</Text>
      </Text>

      <View className="bg-muted border border-border px-6 py-3 rounded-2xl mb-4 w-full items-center">
        <Text className="text-3xl font-mono font-bold text-primary tracking-widest">
          {tempPin}
        </Text>
      </View>

      <Text className="text-[11px] text-amber-600 dark:text-amber-400 font-semibold text-center mb-6">
        Write this down. This PIN code will not be shown again.
      </Text>

      <TouchableOpacity
        onPress={onClose}
        activeOpacity={0.8}
        className="bg-primary w-full py-3 rounded-xl items-center"
      >
        <Text className="text-xs font-bold text-primary-foreground">Got It</Text>
      </TouchableOpacity>
    </BottomSlideModal>
  );
}
