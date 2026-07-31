import React from 'react';
import { View } from 'react-native';

export default function MealConfigSkeleton() {
  return (
    <View className="gap-3">
      {[1, 2, 3].map((key) => (
        <View
          key={key}
          className="bg-card border border-border rounded-2xl p-4 gap-3 animate-pulse"
        >
          <View className="flex-row items-center justify-between">
            <View className="w-24 h-6 bg-slate-200 dark:bg-slate-700 rounded-lg" />
            <View className="w-20 h-5 bg-slate-200 dark:bg-slate-700 rounded-full" />
          </View>
          <View className="w-full h-4 bg-slate-200 dark:bg-slate-700 rounded" />
        </View>
      ))}
    </View>
  );
}
