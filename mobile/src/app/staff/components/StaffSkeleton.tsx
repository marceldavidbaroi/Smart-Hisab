import React, { useEffect, useRef } from 'react';
import { View, Animated } from 'react-native';

export default function StaffSkeleton() {
  const opacity = useRef(new Animated.Value(0.3)).current;

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, {
          toValue: 0.7,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0.3,
          duration: 800,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [opacity]);

  return (
    <View className="gap-3 mb-8">
      {[1, 2, 3, 4].map((i) => (
        <Animated.View
          key={i}
          style={{ opacity }}
          className="bg-card border border-border rounded-xl p-4 shadow-xs flex-row items-center justify-between"
        >
          <View className="flex-1 flex-row items-center gap-3">
            <View className="w-11 h-11 rounded-full bg-muted border border-border" />
            <View className="flex-1">
              <View className="flex-row items-center gap-2">
                <View className="h-4 w-24 bg-muted rounded" />
                <View className="h-4 w-16 bg-muted rounded-full" />
              </View>
              <View className="flex-row items-center gap-2 mt-2">
                <View className="h-3 w-20 bg-muted rounded" />
                <View className="h-4 w-16 bg-muted rounded-md" />
              </View>
            </View>
          </View>
          <View className="flex-row items-center gap-2">
            <View className="w-8 h-8 rounded-lg bg-muted border border-border" />
            <View className="w-10 h-6 rounded-full bg-muted border border-border" />
          </View>
        </Animated.View>
      ))}
    </View>
  );
}
