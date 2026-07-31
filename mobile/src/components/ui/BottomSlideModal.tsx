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

const SCREEN_HEIGHT = Dimensions.get('window').height;

export interface BottomSlideModalProps {
  visible: boolean;
  onClose: () => void;
  children: React.ReactNode;
  isDark?: boolean;
  className?: string;
  snapPoints?: (string | number)[];
}

export function BottomSlideModal({
  visible,
  onClose,
  children,
  isDark = false,
  className = '',
}: BottomSlideModalProps) {
  const insets = useSafeAreaInsets();
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
        duration: 200,
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
        {/* Dark Dim Backdrop */}
        <TouchableWithoutFeedback onPress={onClose}>
          <View className="absolute inset-0 bg-black/60" />
        </TouchableWithoutFeedback>

        <Animated.View
          style={{
            transform: [{ translateY }],
            backgroundColor: isDark ? '#0f172a' : '#ffffff',
            maxHeight: SCREEN_HEIGHT * 0.85,
            paddingBottom: keyboardHeight > 0 ? keyboardHeight : Math.max(insets.bottom, 16) + 12,
          }}
          className="w-full border-t border-border rounded-t-3xl shadow-2xl overflow-hidden"
        >
          {/* Pull / Close Handle Bar */}
          <TouchableOpacity
            onPress={onClose}
            activeOpacity={0.7}
            className="w-full items-center pt-3.5 pb-2 cursor-pointer"
          >
            <View className="w-12 h-1.5 rounded-full bg-slate-300 dark:bg-slate-700" />
          </TouchableOpacity>

          {/* Modal Content ScrollView */}
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
}



