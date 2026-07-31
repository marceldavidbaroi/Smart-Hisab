import React from 'react';
import { View } from 'react-native';

export default function CustomerSkeleton() {
  return (
    <View className="gap-3 mb-8">
      {[1, 2, 3, 4, 5].map((i) => (
        <View
          key={i}
          className="bg-card border border-border rounded-2xl p-4 shadow-xs flex-row items-center justify-between min-h-[64px]"
        >
          <View className="flex-row items-center gap-3 flex-1">
            <View className="w-12 h-12 rounded-2xl bg-muted animate-pulse" />
            <View className="flex-1 gap-2">
              <View className="w-32 h-4 rounded bg-muted animate-pulse" />
              <View className="flex-row gap-2">
                <View className="w-16 h-3 rounded bg-muted animate-pulse" />
                <View className="w-24 h-3 rounded bg-muted animate-pulse" />
              </View>
            </View>
          </View>
          <View className="w-20 h-10 rounded-xl bg-muted animate-pulse" />
        </View>
      ))}
    </View>
  );
}
