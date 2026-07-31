import React from 'react';
import { View, Text, TouchableOpacity, FlatList, ActivityIndicator } from 'react-native';
import { FileText, X, CalendarCheck, Receipt, Coins } from 'phosphor-react-native';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';
import { Customer, CustomerStatementItem } from '@/services/customer';

interface CustomerStatementModalProps {
  visible: boolean;
  onClose: () => void;
  customer: Customer | null;
  statementItems: CustomerStatementItem[];
  isLoading: boolean;
  isDark: boolean;
}

export default function CustomerStatementModal({
  visible,
  onClose,
  customer,
  statementItems,
  isLoading,
  isDark,
}: CustomerStatementModalProps) {
  if (!customer) return null;

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark} className="h-[80%]">
      <View className="flex-row items-center justify-between mb-4">
        <View className="flex-row items-center gap-2">
          <FileText size={20} color={isDark ? '#f59e0b' : '#d97706'} weight="bold" />
          <Text className="text-base font-bold text-foreground">
            30-Day Statement ({customer.full_name})
          </Text>
        </View>
        <TouchableOpacity
          onPress={onClose}
          className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
        >
          <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
        </TouchableOpacity>
      </View>

      {isLoading ? (
        <View className="flex-1 justify-center items-center">
          <ActivityIndicator size="large" color="#f59e0b" />
          <Text className="text-xs text-muted-foreground mt-2">Loading statement history...</Text>
        </View>
      ) : statementItems.length === 0 ? (
        <View className="flex-1 justify-center items-center py-10">
          <Text className="text-sm font-medium text-muted-foreground">No records found for the last 30 days</Text>
        </View>
      ) : (
        <FlatList
          data={statementItems}
          keyExtractor={(item) => item.unique_id}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={{ paddingBottom: 20 }}
          renderItem={({ item }) => (
            <View className="bg-card border border-border rounded-2xl p-3.5 mb-2.5 flex-row items-center justify-between shadow-xs">
              <View className="flex-row items-center gap-3">
                <View
                  className={`w-9 h-9 rounded-xl items-center justify-center ${
                    item.event_type === 'attendance'
                      ? 'bg-emerald-500/15 border border-emerald-500/30'
                      : item.event_type === 'baki'
                      ? 'bg-amber-500/15 border border-amber-500/30'
                      : 'bg-blue-500/15 border border-blue-500/30'
                  }`}
                >
                  {item.event_type === 'attendance' ? (
                    <CalendarCheck size={18} color="#10b981" weight="bold" />
                  ) : item.event_type === 'baki' ? (
                    <Receipt size={18} color="#f59e0b" weight="bold" />
                  ) : (
                    <Coins size={18} color="#3b82f6" weight="bold" />
                  )}
                </View>

                <View>
                  <Text className="text-xs font-bold text-foreground">
                    {item.description || item.event_type}
                  </Text>
                  <Text className="text-[10px] text-muted-foreground">
                    {item.event_date ? new Date(item.event_date).toLocaleDateString() : ''}
                  </Text>
                </View>
              </View>

              <View className="items-end">
                <Text
                  className={`text-xs font-bold ${
                    item.event_type === 'collection'
                      ? 'text-emerald-600 dark:text-emerald-400'
                      : 'text-destructive'
                  }`}
                >
                  {item.event_type === 'collection' ? '-' : '+'} ৳ {item.amount.toFixed(2)}
                </Text>
                <Text className="text-[10px] text-muted-foreground capitalize">
                  {item.method || item.event_type}
                </Text>
              </View>
            </View>
          )}
        />
      )}
    </BottomSlideModal>
  );
}
