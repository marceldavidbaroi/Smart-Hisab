import React from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { User, CalendarCheck, Receipt, Coins, FileText, CreditCard, Wallet } from 'phosphor-react-native';
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

      {/* Action Buttons */}
      <View className="gap-3 mb-2">
        {/* 1. Add Meal */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => {
            onClose();
            onToggleAttendance();
          }}
          disabled={isAttendancePending}
          className="w-full bg-emerald-600 dark:bg-emerald-500 rounded-2xl flex-row items-center p-4 min-h-[56px]"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mr-3">
            <CalendarCheck size={22} color="#ffffff" weight="bold" />
          </View>
          <View className="flex-1">
            <Text className="text-base font-bold text-white">Add Meal</Text>
            <Text className="text-xs text-white/80">Log daily attendance/meal charge</Text>
          </View>
          {isAttendancePending && <ActivityIndicator color="#ffffff" size="small" />}
        </TouchableOpacity>

        {/* 2. New Transaction (Baki / Payment) */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => {
            onClose();
            onOpenBakiModal();
          }}
          className="w-full bg-amber-600 dark:bg-amber-500 rounded-2xl flex-row items-center p-4 min-h-[56px]"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mr-3">
            <Receipt size={22} color="#ffffff" weight="bold" />
          </View>
          <View className="flex-1">
            <Text className="text-base font-bold text-white">New Transaction</Text>
            <Text className="text-xs text-white/80">Record credit (baki) or payment entry</Text>
          </View>
        </TouchableOpacity>

        {/* 3. Customer Wallet */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => {
            onClose();
            Alert.alert('Customer Wallet', `View and manage wallet account for ${customer.full_name}`);
          }}
          className="w-full bg-indigo-600 dark:bg-indigo-500 rounded-2xl flex-row items-center p-4 min-h-[56px]"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mr-3">
            <Wallet size={22} color="#ffffff" weight="bold" />
          </View>
          <View className="flex-1">
            <Text className="text-base font-bold text-white">Wallet Account</Text>
            <Text className="text-xs text-white/80">Manage customer prepaid balance & top-ups</Text>
          </View>
        </TouchableOpacity>

        {/* 4. Customer Report */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => {
            onClose();
            onOpenReport();
          }}
          className="w-full bg-slate-800 dark:bg-slate-700 rounded-2xl flex-row items-center p-4 min-h-[56px]"
        >
          <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mr-3">
            <FileText size={22} color="#ffffff" weight="bold" />
          </View>
          <View className="flex-1">
            <Text className="text-base font-bold text-white">Customer Report</Text>
            <Text className="text-xs text-white/80">View statement & transaction history</Text>
          </View>
        </TouchableOpacity>
      </View>
    </BottomSlideModal>
  );
}
