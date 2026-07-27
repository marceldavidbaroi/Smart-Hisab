import React, { useRef, useState } from 'react';
import {
  View,
  SafeAreaView,
  ScrollView,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  Pressable,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { LogIn, QrCode, ArrowLeft, ShieldCheck, CheckCircle2, KeyRound } from 'lucide-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useAuthStore } from '@/store/useAuthStore';
import { Text } from '@/components/ui/text';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';

export type AuthMode = 'login_home' | 'pin_pairing';

interface LoginScreenProps {
  onLoginSuccess?: () => void;
}

export function LoginScreen({ onLoginSuccess }: LoginScreenProps) {
  const { colorScheme } = useAppStore();
  const { loginWithGoogle, pairWithPin, isLoading } = useAuthStore();
  const isDark = colorScheme === 'dark';

  const [mode, setMode] = useState<AuthMode>('login_home');
  const [pin, setPin] = useState<string[]>(['', '', '', '', '', '']);
  const [pinError, setPinError] = useState<string | null>(null);
  const [pairingSuccess, setPairingSuccess] = useState(false);

  const inputRefs = useRef<Array<TextInput | null>>([]);

  const handleGoogleLogin = async () => {
    try {
      await loginWithGoogle();
      if (onLoginSuccess) {
        onLoginSuccess();
      }
    } catch (e) {
      console.error(e);
    }
  };

  const handlePinChange = (text: string, index: number) => {
    // Only allow numbers
    const cleanedText = text.replace(/[^0-9]/g, '');
    setPinError(null);

    const newPin = [...pin];
    if (cleanedText.length > 1) {
      // Paste handling
      const digits = cleanedText.slice(0, 6).split('');
      for (let i = 0; i < 6; i++) {
        newPin[i] = digits[i] || '';
      }
      setPin(newPin);
      if (digits.length === 6) {
        inputRefs.current[5]?.blur();
        submitPin(newPin.join(''));
      } else {
        inputRefs.current[Math.min(digits.length, 5)]?.focus();
      }
      return;
    }

    newPin[index] = cleanedText;
    setPin(newPin);

    if (cleanedText !== '' && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }

    const fullPin = newPin.join('');
    if (fullPin.length === 6) {
      submitPin(fullPin);
    }
  };

  const handleKeyPress = (e: any, index: number) => {
    if (e.nativeEvent.key === 'Backspace' && pin[index] === '' && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const submitPin = async (pinValue: string) => {
    if (pinValue.length !== 6) {
      setPinError('Please enter a valid 6-digit PIN');
      return;
    }

    try {
      setPinError(null);
      await pairWithPin(pinValue);
      setPairingSuccess(true);
      setTimeout(() => {
        if (onLoginSuccess) {
          onLoginSuccess();
        }
      }, 1000);
    } catch (err: any) {
      setPinError(err.message || 'Pairing failed. Invalid PIN code.');
    }
  };

  const resetPinForm = () => {
    setPin(['', '', '', '', '', '']);
    setPinError(null);
    setPairingSuccess(false);
  };

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'}`}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1"
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24 }}
          keyboardShouldPersistTaps="handled"
        >
          {/* Logo & Header Title */}
          <View className="items-center mb-8">
            <View className="h-16 w-16 rounded-2xl bg-primary/10 border border-primary/20 items-center justify-center mb-4">
              <ShieldCheck size={36} color={isDark ? '#dbad6a' : '#628395'} />
            </View>
            <Text className="text-3xl font-black tracking-tight text-foreground text-center">
              Smart Hisab
            </Text>
            <Text className="text-sm text-muted-foreground text-center mt-1">
              Store Management & POS Synchronization
            </Text>
          </View>

          {/* Main Auth Container */}
          <Card className="bg-card border-border shadow-sm">
            {mode === 'login_home' ? (
              <CardContent className="pt-6 space-y-5">
                <View className="mb-2">
                  <Text className="text-xl font-bold text-foreground text-center">
                    Welcome Back
                  </Text>
                  <Text className="text-xs text-muted-foreground text-center mt-1">
                    Sign in to manage your inventory and store orders
                  </Text>
                </View>

                {/* Google Login Button */}
                <TouchableOpacity
                  onPress={handleGoogleLogin}
                  disabled={isLoading}
                  activeOpacity={0.8}
                  className="flex-row items-center justify-center space-x-3 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl py-3.5 px-4 active:bg-slate-100 dark:active:bg-slate-800"
                >
                  {isLoading ? (
                    <ActivityIndicator size="small" color={isDark ? '#dbad6a' : '#628395'} />
                  ) : (
                    <>
                      {/* Custom SVG/styled representation for Google Icon */}
                      <View className="h-5 w-5 items-center justify-center rounded-full bg-slate-100 border border-slate-200">
                        <Text className="text-xs font-black text-red-500">G</Text>
                      </View>
                      <Text className="text-sm font-semibold text-slate-800 dark:text-slate-100">
                        Continue with Google
                      </Text>
                    </>
                  )}
                </TouchableOpacity>

                {/* Separator Divider */}
                <View className="flex-row items-center my-2">
                  <Separator className="flex-1" />
                  <Text className="text-xs text-muted-foreground px-3 uppercase tracking-wider font-semibold">
                    OR
                  </Text>
                  <Separator className="flex-1" />
                </View>

                {/* PIN Device Pairing Button */}
                <Button
                  variant="outline"
                  onPress={() => {
                    resetPinForm();
                    setMode('pin_pairing');
                  }}
                  className="w-full flex-row items-center justify-center space-x-2 py-3 border-border"
                >
                  <KeyRound size={18} color={isDark ? '#dbad6a' : '#628395'} />
                  <Text className="font-semibold text-foreground">
                    Pair Device with 6-Digit PIN
                  </Text>
                </Button>

                <View className="pt-2">
                  <Badge variant="outline" className="justify-center py-1 bg-muted/40 border-border">
                    <Text className="text-[11px] text-muted-foreground text-center">
                      🔐 Encrypted POS & Multi-tenant Store Access
                    </Text>
                  </Badge>
                </View>
              </CardContent>
            ) : (
              /* PIN Pairing View */
              <CardContent className="pt-6 space-y-5">
                <TouchableOpacity
                  onPress={() => setMode('login_home')}
                  className="flex-row items-center space-x-1 mb-1"
                >
                  <ArrowLeft size={16} color={isDark ? '#dbad6a' : '#628395'} />
                  <Text className="text-xs font-semibold text-air-force-blue dark:text-sunlit-clay">
                    Back to Login Options
                  </Text>
                </TouchableOpacity>

                <View className="items-center mb-1">
                  <View className="h-10 w-10 rounded-full bg-air-force-blue/10 dark:bg-sunlit-clay/20 items-center justify-center mb-2">
                    <QrCode size={20} color={isDark ? '#dbad6a' : '#628395'} />
                  </View>
                  <Text className="text-lg font-bold text-foreground text-center">
                    Device Pairing PIN
                  </Text>
                  <Text className="text-xs text-muted-foreground text-center mt-1 px-4">
                    Enter the 6-digit code generated from your Smart Hisab Web Dashboard to connect this terminal.
                  </Text>
                </View>

                {/* PIN Inputs (6 Boxes) */}
                <View className="flex-row justify-between space-x-2 my-2 px-1">
                  {pin.map((digit, index) => (
                    <TextInput
                      key={index}
                      ref={(ref) => (inputRefs.current[index] = ref)}
                      value={digit}
                      onChangeText={(text) => handlePinChange(text, index)}
                      onKeyPress={(e) => handleKeyPress(e, index)}
                      keyboardType="number-pad"
                      maxLength={1}
                      selectTextOnFocus
                      className={`h-12 w-11 rounded-lg text-center text-xl font-bold border ${
                        pinError
                          ? 'border-destructive bg-destructive/5 text-destructive'
                          : digit
                          ? 'border-primary bg-primary/10 text-primary'
                          : 'border-border bg-background text-foreground'
                      }`}
                    />
                  ))}
                </View>

                {/* Error Banner */}
                {pinError && (
                  <Text className="text-xs text-destructive text-center font-medium">
                    ⚠️ {pinError}
                  </Text>
                )}

                {/* Success Banner */}
                {pairingSuccess && (
                  <View className="flex-row items-center justify-center space-x-2 bg-green-500/10 border border-green-500/30 p-2.5 rounded-lg">
                    <CheckCircle2 size={18} color="#22c55e" />
                    <Text className="text-xs font-bold text-green-600 dark:text-green-400">
                      Device Paired Successfully! Redirecting...
                    </Text>
                  </View>
                )}

                {/* Manual Submit Button */}
                <Button
                  variant="default"
                  onPress={() => submitPin(pin.join(''))}
                  disabled={isLoading || pin.join('').length !== 6 || pairingSuccess}
                  className="w-full bg-primary mt-2"
                >
                  {isLoading ? (
                    <ActivityIndicator size="small" color="#ffffff" />
                  ) : (
                    <Text className="font-bold text-primary-foreground">
                      Verify & Pair Terminal
                    </Text>
                  )}
                </Button>
              </CardContent>
            )}
          </Card>

          {/* Footer Information */}
          <Text className="text-[11px] text-muted-foreground text-center mt-8">
            Smart Hisab Mobile v1.0 • Multi-tenant POS System
          </Text>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
