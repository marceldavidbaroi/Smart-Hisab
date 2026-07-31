import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Check, CurrencyCircleDollar, Calendar, FileText } from 'phosphor-react-native';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { createMealConfig, updateMealConfig, MealConfig } from '@/services/mealConfig';

interface MealConfigAddEditModalProps {
  visible: boolean;
  onClose: () => void;
  editingConfig: MealConfig | null;
  activeTenantId: string | undefined;
  onSuccess: (savedConfig: MealConfig, isEdit: boolean) => void;
  isDark: boolean;
  accentColor: string;
}

export default function MealConfigAddEditModal({
  visible,
  onClose,
  editingConfig,
  activeTenantId,
  onSuccess,
  isDark,
  accentColor,
}: MealConfigAddEditModalProps) {
  const [rateStr, setRateStr] = useState('');
  const [effectiveFrom, setEffectiveFrom] = useState('');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (visible) {
      if (editingConfig) {
        setRateStr(String(editingConfig.rate));
        setEffectiveFrom(editingConfig.effective_from);
        setNote(editingConfig.note || '');
      } else {
        setRateStr('');
        setEffectiveFrom(new Date().toISOString().substring(0, 10));
        setNote('');
      }
    }
  }, [visible, editingConfig]);

  const handleSubmit = async () => {
    if (!activeTenantId) return;

    const parsedRate = parseFloat(rateStr);
    if (isNaN(parsedRate) || parsedRate < 0) {
      Alert.alert('Validation Error', 'Please enter a valid meal rate (>= 0)');
      return;
    }

    if (!effectiveFrom.trim()) {
      Alert.alert('Validation Error', 'Please enter effective date (YYYY-MM-DD)');
      return;
    }

    setSubmitting(true);
    try {
      if (editingConfig) {
        const updated = await updateMealConfig(editingConfig.id, {
          rate: parsedRate,
          effective_from: effectiveFrom.trim(),
          note: note.trim() || null,
        });
        onSuccess(updated, true);
      } else {
        const created = await createMealConfig({
          tenant_id: activeTenantId,
          rate: parsedRate,
          effective_from: effectiveFrom.trim(),
          note: note.trim() || null,
        });
        onSuccess(created, false);
      }
      onClose();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to save meal configuration');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="gap-4">
        {/* Header */}
        <View className="flex-row items-center justify-between pb-2 border-b border-border">
          <View>
            <Text className="text-base font-bold text-foreground">
              {editingConfig ? 'Edit Meal Config' : 'Add Meal Config'}
            </Text>
            <Text className="text-xs text-muted-foreground mt-0.5">
              Set meal rate pricing and details
            </Text>
          </View>
        </View>

        {/* Rate Input */}
        <View className="gap-1.5">
          <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Meal Rate (৳) *
          </Text>
          <View className="flex-row items-center bg-card border border-border rounded-xl px-3.5 h-12">
            <CurrencyCircleDollar size={20} color={accentColor} weight="bold" />
            <TextInput
              value={rateStr}
              onChangeText={setRateStr}
              placeholder="0.00"
              keyboardType="decimal-pad"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
              className="flex-1 text-base font-bold text-foreground ml-2.5"
            />
          </View>
        </View>

        {/* Effective Date Input */}
        <View className="gap-1.5">
          <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Effective From (YYYY-MM-DD) *
          </Text>
          <View className="flex-row items-center bg-card border border-border rounded-xl px-3.5 h-12">
            <Calendar size={20} color={accentColor} weight="bold" />
            <TextInput
              value={effectiveFrom}
              onChangeText={setEffectiveFrom}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
              className="flex-1 text-sm font-semibold text-foreground ml-2.5"
            />
          </View>
        </View>

        {/* Note / Details Input */}
        <View className="gap-1.5">
          <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Meal Details / Note
          </Text>
          <View className="flex-row items-start bg-card border border-border rounded-xl px-3.5 py-2.5 min-h-[80px]">
            <FileText size={20} color={accentColor} weight="bold" style={{ marginTop: 2 }} />
            <TextInput
              value={note}
              onChangeText={setNote}
              placeholder="e.g. Lunch & Dinner standard rate"
              multiline
              numberOfLines={3}
              textAlignVertical="top"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
              className="flex-1 text-sm text-foreground ml-2.5"
            />
          </View>
        </View>

        {/* Save Button */}
        <TouchableOpacity
          onPress={handleSubmit}
          disabled={submitting}
          activeOpacity={0.8}
          className="w-full h-12 bg-primary rounded-xl flex-row items-center justify-center gap-2 mt-2 shadow-xs min-h-[48px]"
        >
          {submitting ? (
            <ActivityIndicator size="small" color="#ffffff" />
          ) : (
            <>
              <Check size={20} color="#ffffff" weight="bold" />
              <Text className="text-sm font-bold text-primary-foreground">
                {editingConfig ? 'Update Config' : 'Save Config'}
              </Text>
            </>
          )}
        </TouchableOpacity>
      </View>
    </BottomSlideModal>
  );
}
