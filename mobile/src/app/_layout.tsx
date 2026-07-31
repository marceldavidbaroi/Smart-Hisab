import React, { useEffect } from 'react';
import { Stack } from 'expo-router';
import { QueryClientProvider } from '@tanstack/react-query';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { BottomSheetModalProvider } from '@gorhom/bottom-sheet';
import { queryClient } from '@/api/queryClient';
import { useAuthStore } from '@/store/useAuthStore';
import '../../global.css';

export default function RootLayout() {
  const initialize = useAuthStore((state) => state.initialize);

  useEffect(() => {
    initialize();

    // Catch unhandled keep-awake promise rejections gracefully on Web/Expo Go
    if (typeof window !== 'undefined' && window.addEventListener) {
      const handleUnhandledRejection = (event: any) => {
        if (event?.reason?.message?.toLowerCase().includes('keep awake')) {
          event.preventDefault();
          console.warn('[KeepAwake] Suppressed unhandled rejection:', event.reason?.message);
        }
      };
      window.addEventListener('unhandledrejection', handleUnhandledRejection);
      return () => window.removeEventListener('unhandledrejection', handleUnhandledRejection);
    }
  }, [initialize]);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <BottomSheetModalProvider>
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="index" />
              <Stack.Screen name="create-tenant" />
              <Stack.Screen name="terminal/index" />
              <Stack.Screen name="staff/index" />
              <Stack.Screen name="(auth)" />
              <Stack.Screen name="(main)" />
              <Stack.Screen name="(terminal)" />
            </Stack>
            <StatusBar style="auto" />
          </BottomSheetModalProvider>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}


