import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  TouchableOpacity,
  TouchableWithoutFeedback,
  ScrollView,
  Platform,
  Animated,
  Dimensions,
  Modal,
  Keyboard,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAppStore } from '@/store/useAppStore';

const SCREEN_HEIGHT = Dimensions.get('window').height;

export interface SwipeableModalProps {
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
  isDark: isDarkProp,
  className = '',
}) => {
  const insets = useSafeAreaInsets();
  const { colorScheme } = useAppStore();
  const isDark = isDarkProp ?? (colorScheme === 'dark');

  const translateY = useRef(new Animated.Value(SCREEN_HEIGHT)).current;
  const [keyboardHeight, setKeyboardHeight] = useState(0);

  useEffect(() => {
    if (visible) {
      Animated.spring(translateY, {
        toValue: 0,
        useNativeDriver: true,
        bounciness: 4,
        speed: 14,
      }).start();
    } else {
      Animated.timing(translateY, {
        toValue: SCREEN_HEIGHT,
        duration: 180,
        useNativeDriver: true,
      }).start();
    }
  }, [visible]);

  useEffect(() => {
    const showEvent = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
    const hideEvent = Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide';

    const showSubscription = Keyboard.addListener(showEvent, (e) => {
      setKeyboardHeight(e.endCoordinates.height);
    });

    const hideSubscription = Keyboard.addListener(hideEvent, () => {
      setKeyboardHeight(0);
    });

    return () => {
      showSubscription.remove();
      hideSubscription.remove();
    };
  }, []);

  return (
    <Modal
      visible={visible}
      transparent
      animationType="none"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <View className="flex-1 justify-end relative">
        {/* Dark Backdrop Overlay */}
        <TouchableWithoutFeedback onPress={onClose}>
          <View className="absolute inset-0 bg-black/60" />
        </TouchableWithoutFeedback>

        <Animated.View
          style={{
            transform: [{ translateY }],
            backgroundColor: isDark ? '#1b262c' : '#ffffff',
            maxHeight: SCREEN_HEIGHT * 0.85,
            paddingBottom: keyboardHeight > 0 ? keyboardHeight : Math.max(insets.bottom, 16) + 12,
          }}
          className="w-full border-t border-border rounded-t-[32px] shadow-2xl overflow-hidden"
        >
          {/* Top Drag / Pull Handle */}
          <TouchableOpacity
            onPress={onClose}
            activeOpacity={0.7}
            className="w-full items-center pt-3.5 pb-2 cursor-pointer"
          >
            <View className="w-12 h-1.5 rounded-full bg-slate-300 dark:bg-slate-700" />
          </TouchableOpacity>

          {/* Scrollable Modal Content */}
          <ScrollView
            contentContainerStyle={{
              paddingHorizontal: 20,
              paddingTop: 8,
              paddingBottom: 24,
            }}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            <View className={className}>{children}</View>
          </ScrollView>
        </Animated.View>
      </View>
    </Modal>
  );
};
