import React from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator } from 'react-native';
import { UserPlus, X } from 'phosphor-react-native';
import { Input } from '@/components/ui/input';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';

interface CustomerAddModalProps {
  visible: boolean;
  onClose: () => void;
  fullName: string;
  setFullName: (val: string) => void;
  phone: string;
  setPhone: (val: string) => void;
  dailyRate: string;
  setDailyRate: (val: string) => void;
  factoryUnit: string;
  setFactoryUnit: (val: string) => void;
  onSubmit: () => void;
  isPending: boolean;
  isDark: boolean;
}

export default function CustomerAddModal({
  visible,
  onClose,
  fullName,
  setFullName,
  phone,
  setPhone,
  dailyRate,
  setDailyRate,
  factoryUnit,
  setFactoryUnit,
  onSubmit,
  isPending,
  isDark,
}: CustomerAddModalProps) {
  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="flex-row items-center justify-between mb-5">
        <Text className="text-lg font-bold text-foreground">Add New Customer</Text>
        <TouchableOpacity
          onPress={onClose}
          className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
        >
          <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
        </TouchableOpacity>
      </View>

      <View className="gap-3.5 mb-6">
        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Full Name *</Text>
          <Input
            value={fullName}
            onChangeText={setFullName}
            placeholder="Enter full name"
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>

        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Phone Number</Text>
          <Input
            value={phone}
            onChangeText={setPhone}
            keyboardType="phone-pad"
            placeholder="+880 1..."
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>

        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Daily Contract Rate (৳, Optional)</Text>
          <Input
            value={dailyRate}
            onChangeText={setDailyRate}
            keyboardType="numeric"
            placeholder="0.00"
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>

        <View>
          <Text className="text-xs font-semibold text-muted-foreground mb-1">Factory Unit (Optional)</Text>
          <Input
            value={factoryUnit}
            onChangeText={setFactoryUnit}
            placeholder="e.g. Unit 1"
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          />
        </View>
      </View>

      <TouchableOpacity
        activeOpacity={0.8}
        onPress={onSubmit}
        disabled={isPending}
        className="bg-primary h-12 rounded-xl items-center justify-center flex-row gap-2 shadow-sm"
      >
        {isPending ? (
          <ActivityIndicator color="#ffffff" size="small" />
        ) : (
          <>
            <UserPlus size={18} color="#ffffff" weight="bold" />
            <Text className="text-sm font-bold text-primary-foreground">Save Customer</Text>
          </>
        )}
      </TouchableOpacity>
    </BottomSlideModal>
  );
}
