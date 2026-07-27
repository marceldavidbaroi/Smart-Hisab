import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { 
  Storefront, 
  ShoppingCart, 
  Clock, 
  CurrencyCircleDollar, 
  Lightning, 
  Barcode, 
  Receipt,
  CheckCircle,
  ArrowsClockwise
} from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { Modal, TextInput as RNTextInput } from 'react-native';

export default function TerminalHomeScreen() {
  const { user, activeStaff } = useAuthStore();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const [dayStatus, setDayStatus] = useState<'open' | 'closed'>('closed');
  const [modalType, setModalType] = useState<'start' | 'end' | null>(null);
  const [cashAmount, setCashAmount] = useState('');
  
  const accentColor = isDark ? '#f59e0b' : '#d97706';

  const handleStartDay = () => {
    // In a real app, call API here
    setDayStatus('open');
    setModalType(null);
    setCashAmount('');
  };

  const handleEndDay = () => {
    // In a real app, call API here
    setDayStatus('closed');
    setModalType(null);
    setCashAmount('');
  };

  return (
    <ScrollView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5`}>
      {/* Header Store Banner */}
      <View className="bg-card border border-amber-500/30 rounded-2xl p-5 mb-4 shadow-xs">
        <View className="flex-row items-center gap-3">
          <View className="w-10 h-10 rounded-xl bg-amber-500/15 items-center justify-center border border-amber-500/30">
            <Storefront size={22} color={accentColor} weight="bold" />
          </View>
          <View className="flex-1">
            <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              {activeStaff ? `Cashier: ${activeStaff.fullName}` : 'Terminal POS Store'}
            </Text>
            <Text className="text-lg font-bold text-foreground mt-0.5">
              {user?.storeName || activeTenant?.name || 'Smart Hisab Store'}
            </Text>
          </View>
        </View>
      </View>

      {/* Shift & Sales Quick Stats */}
      <View className="flex-row gap-3 mb-4">
        <View className="flex-1 bg-card border border-border rounded-2xl p-4 shadow-xs">
          <View className="flex-row items-center justify-between mb-2">
            <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
              Today's Cash
            </Text>
            <CurrencyCircleDollar size={18} color="#10b981" weight="bold" />
          </View>
          <Text className="text-xl font-bold text-foreground">৳ 12,450.00</Text>
          <Text className="text-[10px] text-muted-foreground mt-1">14 completed sales</Text>
        </View>

        <View className="flex-1 bg-card border border-border rounded-2xl p-4 shadow-xs">
          <View className="flex-row items-center justify-between mb-2">
            <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
              Business Day
            </Text>
            <Clock size={18} color={dayStatus === 'open' ? "#22c55e" : "#f59e0b"} weight="bold" />
          </View>
          <Text className={`text-sm font-bold ${dayStatus === 'open' ? 'text-green-600 dark:text-green-400' : 'text-amber-600'}`}>
            {dayStatus === 'open' ? 'OPEN' : 'CLOSED'}
          </Text>
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={() => setModalType(dayStatus === 'open' ? 'end' : 'start')}
            className="mt-2"
          >
            <Text className="text-[11px] font-bold text-amber-600 dark:text-amber-400">
              {dayStatus === 'open' ? 'End Day' : 'Start Day'}
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Counter POS Actions */}
      <View className="mb-5 gap-3">
        <TouchableOpacity
          activeOpacity={0.7}
          className="bg-amber-600 dark:bg-amber-500 p-4 rounded-2xl flex-row items-center justify-between shadow-xs min-h-[56px]"
        >
          <View className="flex-row items-center gap-3">
            <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center">
              <ShoppingCart size={22} color="#ffffff" weight="bold" />
            </View>
            <View>
              <Text className="text-base font-bold text-white">Open Counter POS</Text>
              <Text className="text-xs text-white/80">Start fast checkout & bill order</Text>
            </View>
          </View>
          <Lightning size={20} color="#ffffff" weight="fill" />
        </TouchableOpacity>

        <View className="flex-row gap-3">
          <TouchableOpacity
            activeOpacity={0.7}
            className="flex-1 bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-2.5 shadow-xs min-h-[48px]"
          >
            <View className="w-8 h-8 rounded-lg bg-indigo-500/10 items-center justify-center">
              <Barcode size={18} color="#6366f1" weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground">Scan Barcode</Text>
          </TouchableOpacity>

          <TouchableOpacity
            activeOpacity={0.7}
            className="flex-1 bg-card border border-border rounded-xl p-3.5 flex-row items-center gap-2.5 shadow-xs min-h-[48px]"
          >
            <View className="w-8 h-8 rounded-lg bg-emerald-500/10 items-center justify-center">
              <Receipt size={18} color="#10b981" weight="bold" />
            </View>
            <Text className="text-xs font-bold text-foreground">Last Receipt</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Recent Cashier Orders */}
      <View className="mb-6">
        <View className="flex-row items-center justify-between mb-2.5 px-0.5">
          <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Recent Cashier Orders
          </Text>
          <TouchableOpacity activeOpacity={0.7} className="flex-row items-center gap-1">
            <ArrowsClockwise size={12} color={accentColor} />
            <Text className="text-xs font-semibold text-amber-600 dark:text-amber-400">Refresh</Text>
          </TouchableOpacity>
        </View>

        <View className="bg-card border border-border rounded-2xl overflow-hidden divide-y divide-border/60">
          <View className="p-3.5 flex-row items-center justify-between">
            <View className="flex-row items-center gap-3">
              <View className="w-8 h-8 rounded-lg bg-green-500/10 items-center justify-center">
                <CheckCircle size={18} color="#22c55e" weight="bold" />
              </View>
              <View>
                <Text className="text-xs font-bold text-foreground">INV-#9042</Text>
                <Text className="text-[10px] text-muted-foreground">Cash • 2 items • 12:44 PM</Text>
              </View>
            </View>
            <Text className="text-xs font-bold text-foreground">৳ 450.00</Text>
          </View>

          <View className="p-3.5 flex-row items-center justify-between">
            <View className="flex-row items-center gap-3">
              <View className="w-8 h-8 rounded-lg bg-green-500/10 items-center justify-center">
                <CheckCircle size={18} color="#22c55e" weight="bold" />
              </View>
              <View>
                <Text className="text-xs font-bold text-foreground">INV-#9041</Text>
                <Text className="text-[10px] text-muted-foreground">bKash QR • 5 items • 12:15 PM</Text>
              </View>
            </View>
            <Text className="text-xs font-bold text-foreground">৳ 1,820.00</Text>
          </View>
        </View>
      </View>

      {/* Start/End Day Modal */}
      <Modal visible={modalType !== null} transparent animationType="fade">
        <View className="flex-1 bg-black/60 items-center justify-center p-5">
          <View className="bg-card border border-border w-full max-w-sm rounded-2xl p-5 shadow-lg">
            <Text className="text-lg font-bold text-foreground mb-2">
              {modalType === 'start' ? 'Start Business Day' : 'End Business Day'}
            </Text>
            <Text className="text-xs text-muted-foreground mb-4">
              {modalType === 'start' 
                ? 'Enter the opening drawer cash amount.'
                : 'Enter the closing drawer cash amount for reconciliation.'}
            </Text>

            <View className="mb-5">
              <Text className="text-[11px] font-semibold text-muted-foreground uppercase mb-1.5">
                {modalType === 'start' ? 'Opening Cash (৳)' : 'Closing Cash (৳)'}
              </Text>
              <RNTextInput
                value={cashAmount}
                onChangeText={setCashAmount}
                keyboardType="numeric"
                placeholder="0.00"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="bg-background border border-input rounded-xl px-4 h-12 text-foreground font-semibold text-base"
              />
            </View>

            <View className="flex-row gap-3">
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => setModalType(null)}
                className="flex-1 h-11 border border-border rounded-xl items-center justify-center"
              >
                <Text className="text-xs font-bold text-foreground">Cancel</Text>
              </TouchableOpacity>
              
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={modalType === 'start' ? handleStartDay : handleEndDay}
                className="flex-1 h-11 bg-amber-600 dark:bg-amber-500 rounded-xl items-center justify-center"
              >
                <Text className="text-xs font-bold text-white">
                  {modalType === 'start' ? 'Start Day' : 'End Day'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

    </ScrollView>
  );
}
