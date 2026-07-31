import React from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { User, CalendarCheck, Receipt, Coins, FileText } from 'phosphor-react-native';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { Customer } from '@/services/customer';

interface CustomerActionModalProps {
  visible: boolean;
  onClose: () => void;
  customer: Customer | null;
  onToggleAttendance: () => void;
  onOpenBakiModal: () => void;
  onOpenReport: () => void;
  isAttendancePending: boolean;
  isDark: boolean;
}

export default function CustomerActionModal({
  visible,
  onClose,
  customer,
  onToggleAttendance,
  onOpenBakiModal,
  onOpenReport,
  isAttendancePending,
  isDark,
}: CustomerActionModalProps) {
  if (!customer) return null;

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="flex-row items-center gap-3 mb-5">
        <View className="w-10 h-10 rounded-full bg-amber-500/10 items-center justify-center">
          <User size={22} color={isDark ? '#d4984e' : '#56778a'} weight="bold" />
        </View>
        <View>
          <Text className="text-base font-bold text-foreground">{customer.full_name}</Text>
          <Text className="text-xs text-muted-foreground">{customer.phone || 'No phone'}</Text>
        </View>
      </View>

      {/* 2x2 Action Grid */}
      <View className="flex-row flex-wrap justify-between gap-3 mb-2">
        {/* 1. Meal Attendance */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={onToggleAttendance}
          disabled={isAttendancePending}
          className="w-[48%] aspect-square bg-emerald-600 dark:bg-emerald-500 rounded-2xl items-center justify-center p-3"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
            <CalendarCheck size={22} color="#ffffff" weight="bold" />
          </View>
          <Text className="text-sm font-bold text-white text-center">Meal</Text>
          {isAttendancePending && <ActivityIndicator color="#ffffff" size="small" className="mt-1" />}
        </TouchableOpacity>

        {/* 2. Baki Entry */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={onOpenBakiModal}
          className="w-[48%] aspect-square bg-amber-600 dark:bg-amber-500 rounded-2xl items-center justify-center p-3"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
            <Receipt size={22} color="#ffffff" weight="bold" />
          </View>
          <Text className="text-sm font-bold text-white text-center">Baki</Text>
        </TouchableOpacity>

        {/* 3. Direct Payment */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => {
            Alert.alert('Payment Collection', `Collect payment from ${customer.full_name}`);
          }}
          className="w-[48%] aspect-square bg-blue-600 dark:bg-blue-500 rounded-2xl items-center justify-center p-3"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
            <Coins size={22} color="#ffffff" weight="bold" />
          </View>
          <Text className="text-sm font-bold text-white text-center">Payment</Text>
        </TouchableOpacity>

        {/* 4. Ledger Report */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={onOpenReport}
          className="w-[48%] aspect-square bg-slate-800 dark:bg-slate-700 rounded-2xl items-center justify-center p-3"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
            <FileText size={22} color="#ffffff" weight="bold" />
          </View>
          <Text className="text-sm font-bold text-white text-center">Report</Text>
        </TouchableOpacity>
      </View>
    </BottomSlideModal>
  );
}
