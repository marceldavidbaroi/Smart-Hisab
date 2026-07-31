import React from 'react';
import { View, Text, TouchableOpacity, Modal, TouchableWithoutFeedback } from 'react-native';
import { XCircle, ArrowClockwise, ShieldWarning } from 'phosphor-react-native';

export interface ErrorModalProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  message: string | null | undefined;
  errorDetails?: string;
  onRetry?: () => void;
  isDark?: boolean;
}

export function ErrorModal({
  visible,
  onClose,
  title = 'Operation Error',
  message,
  errorDetails,
  onRetry,
  isDark = false,
}: ErrorModalProps) {
  if (!message && !visible) return null;

  // Format permission or RLS errors into user-friendly message
  const rawMsg = message || 'An unexpected error occurred. Please try again.';
  const isPermissionError =
    rawMsg.toLowerCase().includes('permission denied') ||
    rawMsg.toLowerCase().includes('row-level security') ||
    rawMsg.toLowerCase().includes('sessions_open');

  const displayTitle = isPermissionError ? 'Access Denied' : title;
  const displayMessage = isPermissionError
    ? 'You do not have permission to perform this action. Please verify staff role permissions or contact your store manager.'
    : rawMsg;

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <View className="flex-1 bg-black/70 justify-center items-center p-5">
        {/* Backdrop Tap */}
        <TouchableWithoutFeedback onPress={onClose}>
          <View className="absolute inset-0" />
        </TouchableWithoutFeedback>

        {/* Center Dialog Card */}
        <View
          className={`w-full max-w-sm ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
          } border rounded-3xl p-6 shadow-2xl items-center gap-4 z-10`}
        >
          {/* Red Warning/Error Icon Badge */}
          <View className="w-16 h-16 rounded-3xl bg-rose-500/10 border border-rose-500/30 items-center justify-center shadow-xs">
            {isPermissionError ? (
              <ShieldWarning size={34} color="#ef4444" weight="bold" />
            ) : (
              <XCircle size={34} color="#ef4444" weight="bold" />
            )}
          </View>

          {/* Title & Message */}
          <View className="items-center gap-1.5 px-1">
            <Text className="text-xl font-bold text-foreground text-center">{displayTitle}</Text>
            <Text className="text-sm text-muted-foreground text-center leading-5">
              {displayMessage}
            </Text>
          </View>

          {/* Technical Error Code Pill */}
          {isPermissionError && (
            <View className="w-full bg-rose-500/10 border border-rose-500/20 p-2.5 rounded-xl">
              <Text className="text-[11px] font-mono text-rose-600 dark:text-rose-400 text-center">
                Code: {rawMsg}
              </Text>
            </View>
          )}

          {errorDetails && (
            <View className="w-full bg-muted/60 border border-border p-2.5 rounded-xl">
              <Text className="text-xs font-mono text-muted-foreground">{errorDetails}</Text>
            </View>
          )}

          {/* Footer Action Buttons */}
          <View className="w-full flex-row gap-3 pt-2">
            {onRetry && (
              <TouchableOpacity
                onPress={() => {
                  onClose();
                  onRetry();
                }}
                activeOpacity={0.8}
                className="flex-1 h-12 rounded-2xl border border-border bg-muted/40 flex-row items-center justify-center gap-2 min-h-[48px]"
              >
                <ArrowClockwise size={18} color={isDark ? '#e2e8f0' : '#1e293b'} weight="bold" />
                <Text className="text-sm font-semibold text-foreground">Retry</Text>
              </TouchableOpacity>
            )}

            <TouchableOpacity
              onPress={onClose}
              activeOpacity={0.8}
              className="flex-1 h-12 rounded-2xl bg-rose-600 active:bg-rose-700 items-center justify-center min-h-[48px]"
            >
              <Text className="text-sm font-bold text-white">Dismiss</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}
