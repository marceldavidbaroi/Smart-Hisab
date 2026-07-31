import React from 'react';
import { View, Text, TouchableOpacity, Alert } from 'react-native';
import { CheckCircle, X } from 'phosphor-react-native';
import { Input } from '@/components/ui/input';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { Customer } from '@/services/customer';

interface CustomerRateModalProps {
  visible: boolean;
  onClose: () => void;
  customer: Customer | null;
  inputDailyRate: string;
  setInputDailyRate: (val: string) => void;
  onSaveRate: (rateNum: number) => void;
  isDark: boolean;
}

export default function CustomerRateModal({
  visible,
  onClose,
  customer,
  inputDailyRate,
  setInputDailyRate,
  onSaveRate,
  isDark,
}: CustomerRateModalProps) {
  if (!customer) return null;

  const handleSave = () => {
    const rateNum = parseFloat(inputDailyRate);
    if (isNaN(rateNum) || rateNum <= 0) {
      Alert.alert('Validation Error', 'Please enter a valid rate greater than zero.');
      return;
    }
    onSaveRate(rateNum);
  };

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="flex-row items-center justify-between mb-4">
        <Text className="text-base font-bold text-foreground">
          Set Daily Attendance Rate ({customer.full_name})
        </Text>
        <TouchableOpacity
          onPress={onClose}
          className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
        >
          <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
        </TouchableOpacity>
      </View>

      <View className="gap-3.5 mb-6">
        <Text className="text-xs text-muted-foreground">
          This customer does not have a contract daily rate configured yet. Enter the daily rate to register attendance for this customer.
        </Text>
        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Daily Rate (৳) *</Text>
          <Input
            value={inputDailyRate}
            onChangeText={setInputDailyRate}
            keyboardType="numeric"
            placeholder="e.g. 100.00"
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>
      </View>

      <TouchableOpacity
        activeOpacity={0.8}
        onPress={handleSave}
        className="bg-emerald-600 dark:bg-emerald-500 h-12 rounded-xl items-center justify-center flex-row gap-2 shadow-sm"
      >
        <CheckCircle size={18} color="#ffffff" weight="bold" />
        <Text className="text-sm font-bold text-white">Save Rate</Text>
      </TouchableOpacity>
    </BottomSlideModal>
  );
}
