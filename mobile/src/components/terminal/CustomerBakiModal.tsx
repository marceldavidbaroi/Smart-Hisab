import React from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator } from 'react-native';
import { Receipt, X } from 'phosphor-react-native';
import { Input } from '@/components/ui/input';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { Customer } from '@/services/customer';

interface CustomerBakiModalProps {
  visible: boolean;
  onClose: () => void;
  customer: Customer | null;
  bakiAmount: string;
  setBakiAmount: (val: string) => void;
  bakiDescription: string;
  setBakiDescription: (val: string) => void;
  onSubmit: () => void;
  isPending: boolean;
  isDark: boolean;
}

export default function CustomerBakiModal({
  visible,
  onClose,
  customer,
  bakiAmount,
  setBakiAmount,
  bakiDescription,
  setBakiDescription,
  onSubmit,
  isPending,
  isDark,
}: CustomerBakiModalProps) {
  if (!customer) return null;

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="flex-row items-center justify-between mb-4">
        <Text className="text-base font-bold text-foreground">
          Add Baki Entry for {customer.full_name}
        </Text>
        <TouchableOpacity
          onPress={onClose}
          className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
        >
          <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
        </TouchableOpacity>
      </View>

      <View className="gap-3.5 mb-6">
        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Amount (৳) *</Text>
          <Input
            value={bakiAmount}
            onChangeText={setBakiAmount}
            keyboardType="numeric"
            placeholder="0.00"
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>

        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Items Description *</Text>
          <Input
            value={bakiDescription}
            onChangeText={setBakiDescription}
            placeholder="e.g. Lunch Rice + Fish Curry"
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>
      </View>

      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onSubmit}
        disabled={isPending}
        className="bg-amber-600 dark:bg-amber-500 h-12 rounded-xl items-center justify-center flex-row gap-2"
      >
        {isPending ? (
          <ActivityIndicator color="#ffffff" size="small" />
        ) : (
          <>
            <Receipt size={18} color="#ffffff" weight="bold" />
            <Text className="text-sm font-bold text-white">Save Baki Entry</Text>
          </>
        )}
      </TouchableOpacity>
    </BottomSlideModal>
  );
}
