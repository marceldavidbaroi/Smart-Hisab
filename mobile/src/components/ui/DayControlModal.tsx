import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { Play, StopCircle, CurrencyCircleDollar, CheckCircle, Warning, Clock } from 'phosphor-react-native';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { ErrorModal } from '@/components/ui/ErrorModal';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { useBusinessDayStore, BusinessDay } from '@/store/useBusinessDayStore';
import { useAuthStore } from '@/store/useAuthStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useAppStore } from '@/store/useAppStore';

interface DayControlModalProps {
  visible: boolean;
  onClose: () => void;
  enforceMode?: boolean;
}

export function DayControlModal({ visible, onClose, enforceMode = false }: DayControlModalProps) {
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const { activeTenant } = useTenantStore();
  const { deviceToken, activeStaff } = useAuthStore();
  const { activeDay, startDay, endDay, isLoading } = useBusinessDayStore();

  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [cashInput, setCashInput] = useState('');
  const [notesInput, setNotesInput] = useState('');
  const [summaryResult, setSummaryResult] = useState<{ expected_cash: number; variance: number } | null>(null);

  const handleStartDay = async () => {
    const amount = parseFloat(cashInput);
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
      });
      setCashInput('');
      onClose();
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to start business day.');
    }
  };

  const handleEndDay = async () => {
    const amount = parseFloat(cashInput);
    if (isNaN(amount) || amount < 0) {
      Alert.alert('Validation Error', 'Please enter a valid non-negative closing cash amount.');
      return;
    }

    if (!activeTenant?.id || !activeDay?.id) {
      Alert.alert('Error', 'No active business day to close.');
      return;
    }

    try {
      const result = await endDay({
        tenantId: activeTenant.id,
        deviceToken: deviceToken || undefined,
        staffId: activeStaff?.id || undefined,
        dayId: activeDay.id,
        closingCash: amount,
        notes: notesInput || undefined,
      });

      setSummaryResult({
        expected_cash: Number(result.expected_cash || 0),
        variance: Number(result.variance || 0),
      });
      setCashInput('');
      setNotesInput('');
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to end business day.');
    }
  };

  const isDayRunning = !!activeDay && activeDay.status === 'open';

  return (
    <BottomSlideModal
      visible={visible}
      isDark={isDark}
      onClose={() => {
        if (enforceMode && !isDayRunning) {
          Alert.alert('Day Required', 'You must start a business day before proceeding.');
          return;
        }
        setSummaryResult(null);
        onClose();
      }}
    >
      <View className="gap-4">
        {/* Header */}
        <View className="flex-row items-center justify-between border-b border-border pb-3">
          <View className="flex-row items-center gap-2.5">
            <View className={`w-10 h-10 rounded-xl items-center justify-center border ${
              isDayRunning ? 'bg-emerald-500/10 border-emerald-500/20' : 'bg-amber-500/10 border-amber-500/20'
            }`}>
              {isDayRunning ? (
                <StopCircle size={22} color="#10b981" weight="bold" />
              ) : (
                <Play size={22} color="#f59e0b" weight="bold" />
              )}
            </View>
            <View>
              <Text className="text-base font-bold text-foreground">
                {summaryResult ? 'Day Closure Summary' : isDayRunning ? 'End Business Day' : 'Start Business Day'}
              </Text>
              <Text className="text-xs text-muted-foreground">
                {isDayRunning
                  ? `Active Day Opened: ${new Date(activeDay.opened_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
                  : 'Specify initial counter cash to open day'}
              </Text>
            </View>
          </View>
        </View>

        {summaryResult ? (
          /* Summary Screen after End Day */
          <View className="gap-3 py-2">
            <View className="bg-emerald-500/10 border border-emerald-500/30 p-4 rounded-2xl items-center gap-1">
              <CheckCircle size={32} color="#10b981" weight="bold" />
              <Text className="text-sm font-bold text-emerald-600 dark:text-emerald-400">
                Business Day Closed Successfully!
              </Text>
            </View>

            <View className="bg-card border border-border p-4 rounded-2xl gap-2">
              <View className="flex-row justify-between">
                <Text className="text-xs text-muted-foreground">Expected Cash:</Text>
                <Text className="text-xs font-bold text-foreground">৳ {summaryResult.expected_cash.toFixed(2)}</Text>
              </View>
              <View className="flex-row justify-between">
                <Text className="text-xs text-muted-foreground">Variance:</Text>
                <Text className={`text-xs font-bold ${
                  summaryResult.variance < 0 ? 'text-destructive' : 'text-emerald-500'
                }`}>
                  ৳ {summaryResult.variance.toFixed(2)}
                </Text>
              </View>
            </View>

            <Button
              variant="default"
              onPress={() => {
                setSummaryResult(null);
                onClose();
              }}
              className="h-12 rounded-xl mt-2"
            >
              <Text className="text-sm font-bold text-primary-foreground">Done</Text>
            </Button>
          </View>
        ) : !isDayRunning ? (
          /* Start Day Form */
          <View className="gap-3.5">
            <View className="bg-amber-500/10 border border-amber-500/20 p-3 rounded-xl flex-row items-center gap-2">
              <Warning size={18} color="#f59e0b" weight="bold" />
              <Text className="text-xs font-semibold text-amber-700 dark:text-amber-400 flex-1">
                No active business day. Enter counter opening cash to begin operations.
              </Text>
            </View>

            <View className="gap-1.5">
              <Text className="text-xs font-semibold text-muted-foreground uppercase">
                Opening Counter Cash (৳) *
              </Text>
              <Input
                value={cashInput}
                onChangeText={setCashInput}
                keyboardType="numeric"
                placeholder="0.00"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="h-12 text-base font-bold"
              />
            </View>

            <Button
              variant="default"
              onPress={handleStartDay}
              disabled={isLoading}
              className="h-12 rounded-xl flex-row items-center justify-center gap-2 mt-1"
            >
              {isLoading ? (
                <ActivityIndicator size="small" color="#ffffff" />
              ) : (
                <>
                  <Play size={18} color="#ffffff" weight="bold" />
                  <Text className="text-sm font-bold text-primary-foreground">Start Business Day</Text>
                </>
              )}
            </Button>
          </View>
        ) : (
          /* End Day Form */
          <View className="gap-3.5">
            <View className="bg-card border border-border p-3.5 rounded-xl flex-row items-center justify-between">
              <View>
                <Text className="text-xs font-semibold text-muted-foreground uppercase">Opening Cash</Text>
                <Text className="text-sm font-bold text-foreground">৳ {Number(activeDay?.opening_cash || 0).toFixed(2)}</Text>
              </View>
              <View className="bg-emerald-500/10 border border-emerald-500/20 px-3 py-1 rounded-full">
                <Text className="text-xs font-bold text-emerald-600 dark:text-emerald-400">Day Running</Text>
              </View>
            </View>

            <View className="gap-1.5">
              <Text className="text-xs font-semibold text-muted-foreground uppercase">
                Closing Counter Cash (৳) *
              </Text>
              <Input
                value={cashInput}
                onChangeText={setCashInput}
                keyboardType="numeric"
                placeholder="0.00"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="h-12 text-base font-bold"
              />
            </View>

            <View className="gap-1.5">
              <Text className="text-xs font-semibold text-muted-foreground uppercase">
                Closing Notes (Optional)
              </Text>
              <Input
                value={notesInput}
                onChangeText={setNotesInput}
                placeholder="e.g. Counter cash matched expected total"
                placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                className="h-11 text-xs"
              />
            </View>

            <Button
              variant="destructive"
              onPress={handleEndDay}
              disabled={isLoading}
              className="h-12 rounded-xl flex-row items-center justify-center gap-2 mt-1"
            >
              {isLoading ? (
                <ActivityIndicator size="small" color="#ffffff" />
              ) : (
                <>
                  <StopCircle size={18} color="#ffffff" weight="bold" />
                  <Text className="text-sm font-bold text-destructive-foreground">End Business Day</Text>
                </>
              )}
            </Button>
          </View>
        )}
      </View>

      {/* Error Slide Sheet */}
      <ErrorModal
        visible={Boolean(errorMessage)}
        onClose={() => setErrorMessage(null)}
        message={errorMessage}
        isDark={isDark}
      />
    </BottomSlideModal>
  );
}
