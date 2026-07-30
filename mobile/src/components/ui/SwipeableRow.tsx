import React, { useEffect, useRef } from 'react';
import { View, Text, Animated, TouchableOpacity } from 'react-native';
import Swipeable from 'react-native-gesture-handler/Swipeable';
import { PencilSimple, Trash } from 'phosphor-react-native';

interface SwipeableRowProps {
  children: React.ReactNode;
  onEdit: () => void;
  onDelete: () => void;
  accentColor: string;
  shouldPeek?: boolean;
}

export const SwipeableRow: React.FC<SwipeableRowProps> = ({
  children,
  onEdit,
  onDelete,
  accentColor,
  shouldPeek = false,
}) => {
  const swipeableRef = useRef<Swipeable>(null);

  useEffect(() => {
    if (shouldPeek) {
      // Trigger a smooth peek animation on entry (open right actions partially, then close)
      const timer = setTimeout(() => {
        swipeableRef.current?.openRight();
        setTimeout(() => {
          swipeableRef.current?.close();
        }, 700);
      }, 500);

      return () => clearTimeout(timer);
    }
  }, [shouldPeek]);

  const renderRightActions = (
    progress: Animated.AnimatedInterpolation<number>,
    dragX: Animated.AnimatedInterpolation<number>
  ) => {
    const scale = dragX.interpolate({
      inputRange: [-120, 0],
      outputRange: [1, 0],
      extrapolate: 'clamp',
    });

    return (
      <View className="flex-row items-center ml-2 mb-3">
        {/* Edit Swipe Action */}
        <TouchableOpacity
          onPress={() => {
            swipeableRef.current?.close();
            onEdit();
          }}
          activeOpacity={0.8}
          className="w-14 h-full bg-amber-500/20 border border-amber-500/30 rounded-2xl items-center justify-center mr-1.5"
        >
          <Animated.View style={{ transform: [{ scale }] }}>
            <PencilSimple size={20} color={accentColor} weight="bold" />
            <Text className="text-[10px] font-bold text-amber-600 dark:text-amber-400 mt-0.5">
              Edit
            </Text>
          </Animated.View>
        </TouchableOpacity>

        {/* Delete Swipe Action */}
        <TouchableOpacity
          onPress={() => {
            swipeableRef.current?.close();
            onDelete();
          }}
          activeOpacity={0.8}
          className="w-14 h-full bg-destructive/20 border border-destructive/30 rounded-2xl items-center justify-center"
        >
          <Animated.View style={{ transform: [{ scale }] }}>
            <Trash size={20} color="#ef4444" weight="bold" />
            <Text className="text-[10px] font-bold text-destructive mt-0.5">
              Delete
            </Text>
          </Animated.View>
        </TouchableOpacity>
      </View>
    );
  };

  return (
    <Swipeable
      ref={swipeableRef}
      renderRightActions={renderRightActions}
      friction={2}
      overshootRight={false}
    >
      {children}
    </Swipeable>
  );
};
