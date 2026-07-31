import React from 'react';
import { View } from 'react-native';

export default function MealAttendanceSkeleton() {
  return (
    <View className="p-5 gap-4">
      {/* Date & Summary Skeleton Card */}
      <View className="bg-card border border-border rounded-2xl p-4 gap-3 animate-pulse">
        <View className="w-32 h-4 bg-muted/60 rounded" />
        <View className="flex-row gap-3">
          <View className="flex-1 bg-muted/40 h-16 rounded-xl" />
          <View className="flex-1 bg-muted/40 h-16 rounded-xl" />
        </View>
      </View>

      {/* Items list skeleton */}
      {[1, 2, 3].map((i) => (
        <View key={i} className="bg-card border border-border rounded-xl p-4 flex-row justify-between items-center animate-pulse">
          <View className="gap-2 flex-1">
            <View className="w-36 h-4 bg-muted/60 rounded" />
            <View className="w-24 h-3 bg-muted/40 rounded" />
          </View>
          <View className="w-16 h-6 bg-muted/50 rounded-lg" />
        </View>
      ))}
    </View>
  );
}
