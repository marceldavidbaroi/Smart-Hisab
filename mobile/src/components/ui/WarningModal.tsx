import React from 'react';
import { View, Text, TouchableOpacity, TextInput } from 'react-native';
import { Warning, WarningCircle, Trash, Info, CheckCircle } from 'phosphor-react-native';
import { BottomSlideModal } from './BottomSlideModal';

export type WarningVariant = 'warning' | 'danger' | 'info' | 'success';

export interface WarningModalProps {
  visible: boolean;
  onClose: () => void;
  onConfirm: () => void | Promise<void>;
  title: string;
  description: string;
  variant?: WarningVariant;
  confirmText?: string;
  cancelText?: string;
  isLoading?: boolean;
  isDark?: boolean;
  /** Optional verification input (e.g. "DELETE PROFILE") for high-level destructive actions */
  requiredConfirmText?: string;
  confirmInputPlaceholder?: string;
}

export function WarningModal({
  visible,
  onClose,
  onConfirm,
  title,
  description,
  variant = 'warning',
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  isLoading = false,
  isDark = false,
  requiredConfirmText,
  confirmInputPlaceholder,
}: WarningModalProps) {
  const [inputText, setInputText] = React.useState('');

  React.useEffect(() => {
    if (visible) {
      setInputText('');
    }
  }, [visible]);

  const isConfirmDisabled =
    isLoading || (Boolean(requiredConfirmText) && inputText.trim() !== requiredConfirmText);

  const getVariantStyles = () => {
    switch (variant) {
      case 'danger':
        return {
          iconBg: 'bg-rose-500/10 border-rose-500/30',
          iconColor: '#ef4444',
          IconComponent: Trash,
          badgeBg: 'bg-rose-500/10',
          badgeText: 'text-rose-600 dark:text-rose-400',
          buttonBg: 'bg-rose-600 active:bg-rose-700',
          buttonText: 'text-white',
        };
      case 'info':
        return {
          iconBg: 'bg-sky-500/10 border-sky-500/30',
          iconColor: '#0284c7',
          IconComponent: Info,
          badgeBg: 'bg-sky-500/10',
          badgeText: 'text-sky-600 dark:text-sky-400',
          buttonBg: 'bg-sky-600 active:bg-sky-700',
          buttonText: 'text-white',
        };
      case 'success':
        return {
          iconBg: 'bg-emerald-500/10 border-emerald-500/30',
          iconColor: '#10b981',
          IconComponent: CheckCircle,
          badgeBg: 'bg-emerald-500/10',
          badgeText: 'text-emerald-600 dark:text-emerald-400',
          buttonBg: 'bg-emerald-600 active:bg-emerald-700',
          buttonText: 'text-white',
        };
      case 'warning':
      default:
        return {
          iconBg: 'bg-amber-500/10 border-amber-500/30',
          iconColor: '#f59e0b',
          IconComponent: Warning,
          badgeBg: 'bg-amber-500/10',
          badgeText: 'text-amber-600 dark:text-amber-400',
          buttonBg: 'bg-amber-500 active:bg-amber-600',
          buttonText: 'text-slate-950 font-bold',
        };
    }
  };

  const style = getVariantStyles();
  const IconComponent = style.IconComponent;

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="items-center gap-4 py-2">
        {/* Decorative Badge Icon Header */}
        <View
          className={`w-16 h-16 rounded-3xl border items-center justify-center shadow-xs ${style.iconBg}`}
        >
          <IconComponent size={32} color={style.iconColor} weight="bold" />
        </View>

        {/* Header Text */}
        <View className="items-center gap-1">
          <Text className="text-xl font-bold text-foreground text-center">{title}</Text>
          <Text className="text-xs text-muted-foreground text-center leading-5 px-3">
            {description}
          </Text>
        </View>

        {/* Required Confirmation Text Challenge */}
        {requiredConfirmText ? (
          <View className="w-full gap-2 mt-1">
            <View className="bg-destructive/10 p-3 rounded-2xl border border-destructive/20 items-center">
              <Text className="text-xs text-muted-foreground mb-1">To confirm, type exactly:</Text>
              <Text className="text-sm font-mono font-bold text-destructive select-all">
                {requiredConfirmText}
              </Text>
            </View>
            <TextInput
              value={inputText}
              onChangeText={setInputText}
              placeholder={confirmInputPlaceholder || `Type '${requiredConfirmText}'`}
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
              autoCapitalize="characters"
              className="w-full bg-background border border-input rounded-2xl px-4 h-12 text-foreground font-mono text-sm text-center"
            />
          </View>
        ) : null}

        {/* Actions Footer */}
        <View className="w-full flex-row gap-3 pt-3">
          <TouchableOpacity
            onPress={onClose}
            disabled={isLoading}
            activeOpacity={0.7}
            className="flex-1 h-12 rounded-2xl border border-border bg-muted/40 items-center justify-center min-h-[48px] cursor-pointer"
          >
            <Text className="text-sm font-semibold text-foreground">{cancelText}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={onConfirm}
            disabled={isConfirmDisabled}
            activeOpacity={0.8}
            className={`flex-1 h-12 rounded-2xl items-center justify-center min-h-[48px] cursor-pointer ${
              style.buttonBg
            } ${isConfirmDisabled ? 'opacity-50' : ''}`}
          >
            <Text className={`text-sm font-bold ${style.buttonText}`}>
              {isLoading ? 'Processing...' : confirmText}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </BottomSlideModal>
  );
}
