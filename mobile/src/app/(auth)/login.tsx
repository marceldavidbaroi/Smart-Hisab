import React from 'react';
import { LoginScreen } from '@/components/LoginScreen';
import { useRouter } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';

export default function AuthLoginScreen() {
  const router = useRouter();
  const { isTerminalDevice, user } = useAuthStore();

  return (
    <LoginScreen
      initialMode="login_home"
      onNavigateToRegister={() => router.replace('/(auth)/register')}
      onLoginSuccess={() => {
        const isTerminal = isTerminalDevice || user?.isTerminalDevice;
        if (isTerminal) {
          router.replace('/(terminal)');
        } else {
          router.replace('/(main)');
        }
      }}
    />
  );
}
