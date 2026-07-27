import React, { useEffect, useRef } from 'react';
import {
  Modal,
  View,
  PanResponder,
  Animated,
  Dimensions,
  TouchableWithoutFeedback,
} from 'react-native';

const SCREEN_HEIGHT = Dimensions.get('window').height;

interface SwipeableModalProps {
  visible: boolean;
  onClose: () => void;
  children: React.ReactNode;
  isDark?: boolean;
  className?: string;
  maxHeight?: string;
}

export const SwipeableModal: React.FC<SwipeableModalProps> = ({
  visible,
  onClose,
  children,
  isDark = false,
  className = '',
}) => {
  const translateY = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      translateY.setValue(0);
    }
  }, [visible]);

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: (_, gestureState) => {
        return gestureState.dy > 5;
      },
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dy > 0) {
          translateY.setValue(gestureState.dy);
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dy > 100 || gestureState.vy > 0.5) {
          Animated.timing(translateY, {
            toValue: SCREEN_HEIGHT,
            duration: 180,
            useNativeDriver: true,
          }).start(() => {
            translateY.setValue(0);
            onClose();
          });
        } else {
          Animated.spring(translateY, {
            toValue: 0,
            bounciness: 4,
            useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <View className="flex-1 justify-end bg-black/60">
        <TouchableWithoutFeedback onPress={onClose}>
          <View className="flex-1" />
        </TouchableWithoutFeedback>

        <Animated.View
          style={{
            transform: [{ translateY }],
          }}
          className={`bg-card border-t border-border rounded-t-3xl px-6 pb-6 pt-2 ${isDark ? 'dark' : ''} ${className}`}
        >
          {/* Drag Handle Bar for Swiping Down */}
          <View {...panResponder.panHandlers} className="w-full items-center py-2 -mt-1 cursor-pointer">
            <View className="w-12 h-1.5 rounded-full bg-slate-300 dark:bg-slate-700" />
          </View>

          {children}
        </Animated.View>
      </View>
    </Modal>
  );
};
