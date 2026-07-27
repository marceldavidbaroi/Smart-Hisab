import React from 'react';
import { LoginScreen } from '@/components/LoginScreen';
import { useRouter } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';

export default function RegisterScreen() {
  const router = useRouter();
  const { isTerminalDevice, user } = useAuthStore();

  return (
    <LoginScreen
      initialMode="signup_mode"
      onNavigateToLogin={() => router.replace('/(auth)/login')}
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
