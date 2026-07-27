import React from 'react';
import { View, Text } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ArrowsLeftRight, TrendUp, ArrowsClockwise } from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';

export default function OperationScreen() {
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';

  return (
    <SafeAreaView edges={['top', 'left', 'right']} className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'} p-6`}>
      <View className="mb-6 pb-4 border-b border-border">
        <Text className="text-muted-foreground text-xs font-semibold uppercase tracking-wider">
          Daily Operations
        </Text>
        <Text className="text-2xl font-bold text-foreground mt-1">
          Operations
        </Text>
      </View>

      <View className="gap-4">
        <View className="bg-card border border-border rounded-2xl p-5 shadow-xs flex-row items-center gap-4">
          <View className="h-12 w-12 rounded-xl bg-primary/10 items-center justify-center">
            <ArrowsLeftRight size={24} color={isDark ? '#d4984e' : '#56778a'} />
          </View>
          <View className="flex-1">
            <Text className="text-foreground font-bold text-base">Transactions & Sales</Text>
            <Text className="text-muted-foreground text-xs mt-0.5">Manage daily register transactions and logs</Text>
          </View>
        </View>

        <View className="bg-card border border-border rounded-2xl p-5 shadow-xs flex-row items-center gap-4">
          <View className="h-12 w-12 rounded-xl bg-primary/10 items-center justify-center">
            <TrendUp size={24} color={isDark ? '#d4984e' : '#56778a'} />
          </View>
          <View className="flex-1">
            <Text className="text-foreground font-bold text-base">Stock Adjustments</Text>
            <Text className="text-muted-foreground text-xs mt-0.5">Inventory count, restock and level updates</Text>
          </View>
        </View>

        <View className="bg-card border border-border rounded-2xl p-5 shadow-xs flex-row items-center gap-4">
          <View className="h-12 w-12 rounded-xl bg-primary/10 items-center justify-center">
            <ArrowsClockwise size={24} color={isDark ? '#d4984e' : '#56778a'} />
          </View>
          <View className="flex-1">
            <Text className="text-foreground font-bold text-base">Sync & Offline Logs</Text>
            <Text className="text-muted-foreground text-xs mt-0.5">Check offline queue and backend sync status</Text>
          </View>
        </View>
      </View>
    </SafeAreaView>
  );
}
