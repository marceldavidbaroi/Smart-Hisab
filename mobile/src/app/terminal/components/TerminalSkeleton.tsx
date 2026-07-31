import React, { useEffect, useRef } from 'react';
import { View, Animated } from 'react-native';

export default function TerminalSkeleton() {
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
      {[1, 2, 3].map((i) => (
        <Animated.View
          key={i}
          style={{ opacity }}
          className="bg-card border border-border rounded-2xl p-4 shadow-xs gap-3"
        >
          <View className="flex-row items-center justify-between">
            <View className="flex-row items-center gap-3">
              <View className="w-10 h-10 rounded-xl bg-muted border border-border" />
              <View className="gap-1.5">
                <View className="h-4 w-28 bg-muted rounded" />
                <View className="h-3 w-20 bg-muted rounded" />
              </View>
            </View>
            <View className="h-6 w-16 bg-muted rounded-full" />
          </View>

          <View className="bg-muted/40 border border-border/50 rounded-xl p-3 flex-row items-center justify-between">
            <View className="gap-1">
              <View className="h-3 w-24 bg-muted rounded" />
              <View className="h-5 w-20 bg-muted rounded" />
            </View>
            <View className="h-8 w-24 bg-muted rounded-lg" />
          </View>
        </Animated.View>
      ))}
    </View>
  );
}
