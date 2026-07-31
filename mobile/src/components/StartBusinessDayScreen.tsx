import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, Alert, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Play, Calendar, Storefront, CurrencyCircleDollar, Warning, Sparkle, X } from 'phosphor-react-native';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { ErrorModal } from '@/components/ui/ErrorModal';
import { useBusinessDayStore } from '@/store/useBusinessDayStore';
import { useAuthStore } from '@/store/useAuthStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useAppStore } from '@/store/useAppStore';

interface StartBusinessDayScreenProps {
  onClose?: () => void;
}

export function StartBusinessDayScreen({ onClose }: StartBusinessDayScreenProps) {
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';

  const { activeTenant } = useTenantStore();
  const { deviceToken, activeStaff, user } = useAuthStore();
  const { startDay, lastClosedDay, isLoading } = useBusinessDayStore();

  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [dateInput, setDateInput] = useState(new Date().toISOString().split('T')[0]);
  const [openingCashInput, setOpeningCashInput] = useState(
    lastClosedDay?.closing_cash ? String(lastClosedDay.closing_cash) : ''
  );

  const suggestedFloat = lastClosedDay?.closing_cash 
    ? Number(lastClosedDay.closing_cash) 
    : lastClosedDay?.expected_cash 
    ? Number(lastClosedDay.expected_cash) 
    : 0;

  const handleStartDay = async () => {
    const amount = parseFloat(openingCashInput);
    if (isNaN(amount) || amount < 0) {
      setErrorMessage('Please enter a valid non-negative opening cash amount.');
      return;
    }

    if (!activeTenant?.id) {
      setErrorMessage('No active workspace selected.');
      return;
    }

    try {
      await startDay({
        tenantId: activeTenant.id,
        deviceToken: deviceToken || undefined,
        staffId: activeStaff?.id || undefined,
        openingCash: amount,
        businessDate: dateInput,
      });
    } catch (err: any) {
      setErrorMessage(err.message || 'Could not start business day.');
    }
  };

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'} p-5 justify-between`}>
      {/* Top Bar with Optional Close Button */}
      {onClose && (
        <View className="flex-row items-center justify-end">
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={onClose}
            className="w-10 h-10 rounded-full bg-card border border-border items-center justify-center shadow-xs"
          >
            <X size={20} color={isDark ? '#cbd5e1' : '#475569'} weight="bold" />
          </TouchableOpacity>
        </View>
      )}

      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center' }} className="py-4">
        {/* Workspace Brand Badge */}
        <View className="items-center mb-6">
          <View className="w-16 h-16 rounded-3xl bg-amber-500/15 border border-amber-500/30 items-center justify-center mb-3">
            <Storefront size={32} color="#f59e0b" weight="bold" />
          </View>
          <Text className="text-xs font-bold text-amber-600 dark:text-amber-400 uppercase tracking-widest mb-1">
            Business Day Setup
          </Text>
          <Text className="text-2xl font-extrabold text-foreground text-center">
            {activeTenant?.name || user?.storeName || 'Smart Hisab Store'}
          </Text>
        </View>

        {/* Form Card */}
        <View className="bg-card border border-border rounded-3xl p-5 mb-5 shadow-sm gap-4">
          <View className="flex-row items-center gap-3">
            <View className="w-10 h-10 rounded-2xl bg-amber-500/10 border border-amber-500/30 items-center justify-center">
              <Warning size={22} color="#f59e0b" weight="bold" />
            </View>
            <View className="flex-1">
              <Text className="text-base font-bold text-foreground">Start Business Day</Text>
              <Text className="text-xs text-muted-foreground">
                Register counter cash float before recording transactions or opening POS counter.
              </Text>
            </View>
          </View>

          {/* Date Picker / Input */}
          <View className="gap-1.5 pt-2 border-t border-border">
            <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              Business Date
            </Text>
            <View className="bg-background border border-input rounded-2xl px-4 h-12 flex-row items-center justify-between">
              <Input
                value={dateInput}
                onChangeText={setDateInput}
                placeholder="YYYY-MM-DD"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="flex-1 h-12 text-foreground font-bold text-base border-0 p-0"
              />
              <Calendar size={20} color={isDark ? '#94a3b8' : '#64748b'} weight="bold" />
            </View>
          </View>

          {/* Suggested Float Recommendation */}
          {suggestedFloat > 0 && (
            <TouchableOpacity
              activeOpacity={0.7}
              onPress={() => setOpeningCashInput(String(suggestedFloat))}
              className="bg-amber-500/10 border border-amber-500/30 rounded-2xl p-3.5 flex-row items-center justify-between"
            >
              <View className="flex-row items-center gap-2.5">
                <Sparkle size={18} color="#f59e0b" weight="fill" />
                <View>
                  <Text className="text-xs font-semibold text-amber-700 dark:text-amber-400">Previous Day Closing Cash</Text>
                  <Text className="text-sm font-bold text-foreground">৳ {suggestedFloat.toFixed(2)}</Text>
                </View>
              </View>
              <View className="bg-amber-500/20 px-3 py-1 rounded-full">
                <Text className="text-xs font-bold text-amber-700 dark:text-amber-300">Use Float</Text>
              </View>
            </TouchableOpacity>
          )}

          {/* Opening Counter Cash Input */}
          <View className="gap-1.5">
            <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
              Opening Counter Cash (৳) *
            </Text>
            <View className="bg-background border border-input rounded-2xl px-4 h-14 flex-row items-center gap-2">
              <CurrencyCircleDollar size={24} color="#10b981" weight="bold" />
              <Input
                value={openingCashInput}
                onChangeText={setOpeningCashInput}
                keyboardType="numeric"
                placeholder="0.00"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="flex-1 h-14 text-foreground font-bold text-xl border-0 p-0"
              />
            </View>
          </View>

          {/* Action Buttons */}
          <View className="gap-2.5 mt-2">
            <Button
              variant="default"
              onPress={handleStartDay}
              disabled={isLoading}
              className="h-14 bg-amber-600 dark:bg-amber-500 active:bg-amber-700 rounded-2xl flex-row items-center justify-center gap-2 shadow-sm"
            >
              {isLoading ? (
                <ActivityIndicator size="small" color="#ffffff" />
              ) : (
                <>
                  <Play size={20} color="#ffffff" weight="fill" />
                  <Text className="text-base font-bold text-white">Start Business Day</Text>
                </>
              )}
            </Button>

            {onClose && (
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={onClose}
                className="h-12 border border-border rounded-2xl items-center justify-center"
              >
                <Text className="text-xs font-bold text-muted-foreground">Skip for Now (Explore Mode)</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      </ScrollView>

      {/* Error Slide Sheet */}
      <ErrorModal
        visible={Boolean(errorMessage)}
        onClose={() => setErrorMessage(null)}
        message={errorMessage}
        onRetry={handleStartDay}
        isDark={isDark}
      />
    </SafeAreaView>
  );
}
