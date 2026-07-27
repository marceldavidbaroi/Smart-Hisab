import React, { useRef, useState } from 'react';
import {
  View,
  ScrollView,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ShieldCheck, ArrowLeft, Key, EnvelopeSimple, Lock, User, CheckCircle, WarningCircle, Eye, EyeSlash } from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useAuthStore } from '@/store/useAuthStore';
import { Text } from '@/components/ui/text';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';

export type AuthMode = 'login_home' | 'signup_mode' | 'pin_pairing' | 'forgot_password';

interface LoginScreenProps {
  onLoginSuccess?: () => void;
  initialMode?: AuthMode;
  onNavigateToLogin?: () => void;
  onNavigateToRegister?: () => void;
}

export function LoginScreen({
  onLoginSuccess,
  initialMode = 'login_home',
  onNavigateToLogin,
  onNavigateToRegister,
}: LoginScreenProps) {
  const { colorScheme } = useAppStore();
  const { login, signUp, resetPassword, pairWithPin, isLoading } = useAuthStore();
  const isDark = colorScheme === 'dark';

  const [mode, setMode] = useState<AuthMode>(initialMode);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [resetSuccessMessage, setResetSuccessMessage] = useState<string | null>(null);

  const [pin, setPin] = useState<string[]>(['', '', '', '', '', '']);
  const [pinError, setPinError] = useState<string | null>(null);
  const [pairingSuccess, setPairingSuccess] = useState(false);

  const inputRefs = useRef<Array<TextInput | null>>([]);

  const switchMode = (newMode: AuthMode) => {
    setAuthError(null);
    setResetSuccessMessage(null);
    setMode(newMode);
    if (newMode === 'login_home' && mode !== 'login_home' && onNavigateToLogin) {
      onNavigateToLogin();
    } else if (newMode === 'signup_mode' && mode !== 'signup_mode' && onNavigateToRegister) {
      onNavigateToRegister();
    }
  };

  const handleEmailLogin = async () => {
    if (!email.trim() || !password) {
      setAuthError('Please enter both email and password.');
      return;
    }
    try {
      setAuthError(null);
      await login(email.trim(), password);
      if (onLoginSuccess) {
        onLoginSuccess();
      }
    } catch (err: any) {
      setAuthError(err.message || 'Invalid email or password.');
    }
  };

  const handleSignUp = async () => {
    if (!fullName.trim()) {
      setAuthError('Please enter your full name.');
      return;
    }
    if (!email.trim()) {
      setAuthError('Please enter your email address.');
      return;
    }
    if (!password) {
      setAuthError('Please enter a password.');
      return;
    }
    if (password.length < 6) {
      setAuthError('Password must be at least 6 characters.');
      return;
    }
    if (!confirmPassword) {
      setAuthError('Please confirm your password.');
      return;
    }
    if (password !== confirmPassword) {
      setAuthError('Password and confirm password do not match.');
      return;
    }
    try {
      setAuthError(null);
      await signUp(email.trim(), password, fullName.trim() || undefined);
      // Switch to login view after successful registration
      switchMode('login_home');
    } catch (err: any) {
      setAuthError(err.message || 'Failed to create account.');
    }
  };

  const handleResetPassword = async () => {
    if (!email.trim()) {
      setAuthError('Please enter your email address.');
      return;
    }
    try {
      setAuthError(null);
      setResetSuccessMessage(null);
      await resetPassword(email.trim());
      setResetSuccessMessage('Password reset instructions sent to your email.');
    } catch (err: any) {
      setAuthError(err.message || 'Failed to send reset email.');
    }
  };

  const handlePinChange = (text: string, index: number) => {
    const cleanedText = text.replace(/[^0-9]/g, '');
    setPinError(null);

    const newPin = [...pin];
    if (cleanedText.length > 1) {
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

  const accentColor = isDark ? '#dbad6a' : '#628395';

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1"
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', paddingHorizontal: 20, paddingVertical: 20 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <View className="items-center mb-6">
            <View className="h-14 w-14 rounded-2xl bg-primary/10 items-center justify-center mb-2 border border-primary/20">
              <ShieldCheck size={32} color={accentColor} />
            </View>
            <Text className="text-2xl font-bold text-foreground text-center tracking-tight">
              Smart Hisab
            </Text>
          </View>

          {/* Card */}
          <Card className="bg-card border-border shadow-xs rounded-2xl overflow-hidden">
            {mode === 'login_home' || mode === 'signup_mode' ? (
              <CardContent className="p-5 gap-4">
                {/* Mode Selector Tabs */}
                <View className="flex-row p-1 bg-muted/50 rounded-xl">
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => switchMode('login_home')}
                    className={`flex-1 py-2 rounded-lg items-center ${
                      mode === 'login_home' ? 'bg-background shadow-xs' : ''
                    }`}
                  >
                    <Text className={`text-xs font-bold ${mode === 'login_home' ? 'text-foreground' : 'text-muted-foreground'}`}>
                      Sign In
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => switchMode('signup_mode')}
                    className={`flex-1 py-2 rounded-lg items-center ${
                      mode === 'signup_mode' ? 'bg-background shadow-xs' : ''
                    }`}
                  >
                    <Text className={`text-xs font-bold ${mode === 'signup_mode' ? 'text-foreground' : 'text-muted-foreground'}`}>
                      Create Account
                    </Text>
                  </TouchableOpacity>
                </View>

                {mode === 'signup_mode' && (
                  <View className="gap-1">
                    <Text className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                      Full Name
                    </Text>
                    <View className="relative flex-row items-center">
                      <View className="absolute left-3.5 z-10">
                        <User size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                      </View>
                      <Input
                        value={fullName}
                        onChangeText={(val) => {
                          setFullName(val);
                          setAuthError(null);
                        }}
                        placeholder="John Doe"
                        placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                        className="pl-11 h-11 text-sm font-medium w-full"
                      />
                    </View>
                  </View>
                )}

                {/* Email Input */}
                <View className="gap-1">
                  <Text className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Email Address
                  </Text>
                  <View className="relative flex-row items-center">
                    <View className="absolute left-3.5 z-10">
                      <EnvelopeSimple size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                    </View>
                    <Input
                      value={email}
                      onChangeText={(val) => {
                        setEmail(val);
                        setAuthError(null);
                      }}
                      placeholder="name@example.com"
                      placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                      keyboardType="email-address"
                      autoCapitalize="none"
                      className="pl-11 h-11 text-sm font-medium w-full"
                    />
                  </View>
                </View>

                {/* Password Input */}
                <View className="gap-1">
                  <View className="flex-row items-center justify-between">
                    <Text className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                      Password
                    </Text>
                    {mode === 'login_home' && (
                      <TouchableOpacity
                        activeOpacity={0.7}
                        onPress={() => switchMode('forgot_password')}
                      >
                        <Text className="text-xs font-semibold text-primary">
                          Forgot Password?
                        </Text>
                      </TouchableOpacity>
                    )}
                  </View>
                  <View className="relative flex-row items-center">
                    <View className="absolute left-3.5 z-10">
                      <Lock size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                    </View>
                    <Input
                      value={password}
                      onChangeText={(val) => {
                        setPassword(val);
                        setAuthError(null);
                      }}
                      placeholder={mode === 'signup_mode' ? 'At least 6 characters' : '••••••••'}
                      placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                      secureTextEntry={!showPassword}
                      className="pl-11 pr-11 h-11 text-sm font-medium w-full"
                    />
                    <TouchableOpacity
                      activeOpacity={0.7}
                      onPress={() => setShowPassword(!showPassword)}
                      className="absolute right-3.5 z-10 p-1"
                    >
                      {showPassword ? (
                        <EyeSlash size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                      ) : (
                        <Eye size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                      )}
                    </TouchableOpacity>
                  </View>
                </View>

                {/* Confirm Password Input for Registration */}
                {mode === 'signup_mode' && (
                  <View className="gap-1">
                    <Text className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                      Confirm Password
                    </Text>
                    <View className="relative flex-row items-center">
                      <View className="absolute left-3.5 z-10">
                        <Lock size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                      </View>
                      <Input
                        value={confirmPassword}
                        onChangeText={(val) => {
                          setConfirmPassword(val);
                          setAuthError(null);
                        }}
                        placeholder="Re-enter password"
                        placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                        secureTextEntry={!showConfirmPassword}
                        className="pl-11 pr-11 h-11 text-sm font-medium w-full"
                      />
                      <TouchableOpacity
                        activeOpacity={0.7}
                        onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                        className="absolute right-3.5 z-10 p-1"
                      >
                        {showConfirmPassword ? (
                          <EyeSlash size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                        ) : (
                          <Eye size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                        )}
                      </TouchableOpacity>
                    </View>
                  </View>
                )}

                {/* Error Banner */}
                {authError && (
                  <View className="flex-row items-center gap-2 bg-destructive/10 border border-destructive/20 p-2.5 rounded-xl">
                    <WarningCircle size={16} color="#ef4444" />
                    <Text className="flex-1 text-xs text-destructive font-medium">
                      {authError}
                    </Text>
                  </View>
                )}

                {/* Submit Action Button */}
                <Button
                  variant="default"
                  onPress={mode === 'login_home' ? handleEmailLogin : handleSignUp}
                  disabled={isLoading}
                  className="w-full h-11 rounded-xl mt-1 flex-row items-center justify-center min-h-[48px]"
                >
                  {isLoading ? (
                    <ActivityIndicator size="small" color="#ffffff" />
                  ) : (
                    <Text className="font-bold text-primary-foreground text-sm text-center">
                      {mode === 'login_home' ? 'Sign In' : 'Create Account'}
                    </Text>
                  )}
                </Button>

                {/* Switch view helper text */}
                <View className="flex-row items-center justify-center gap-1 mt-1">
                  <Text className="text-xs text-muted-foreground">
                    {mode === 'login_home' ? "Don't have an account?" : 'Already have an account?'}
                  </Text>
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => switchMode(mode === 'login_home' ? 'signup_mode' : 'login_home')}
                  >
                    <Text className="text-xs font-bold text-primary">
                      {mode === 'login_home' ? 'Create Account' : 'Sign In'}
                    </Text>
                  </TouchableOpacity>
                </View>

                {/* PIN Device Pairing Button */}
                <TouchableOpacity
                  activeOpacity={0.7}
                  onPress={() => {
                    resetPinForm();
                    switchMode('pin_pairing');
                  }}
                  className="flex-row items-center justify-center gap-2 py-2 mt-1"
                >
                  <Key size={15} color={accentColor} />
                  <Text className="text-xs font-semibold text-primary">
                    Pair Device with 6-Digit PIN
                  </Text>
                </TouchableOpacity>
              </CardContent>
            ) : mode === 'forgot_password' ? (
              <CardContent className="p-5 gap-4">
                <TouchableOpacity
                  activeOpacity={0.7}
                  onPress={() => switchMode('login_home')}
                  className="flex-row items-center gap-1.5 self-start"
                >
                  <ArrowLeft size={16} color={accentColor} />
                  <Text className="text-xs font-semibold text-primary">
                    Back to Sign In
                  </Text>
                </TouchableOpacity>

                <View className="items-center">
                  <Text className="text-lg font-bold text-foreground text-center">
                    Reset Password
                  </Text>
                </View>

                {/* Email Input */}
                <View className="gap-1">
                  <Text className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                    Email Address
                  </Text>
                  <View className="relative flex-row items-center">
                    <View className="absolute left-3.5 z-10">
                      <EnvelopeSimple size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                    </View>
                    <Input
                      value={email}
                      onChangeText={(val) => {
                        setEmail(val);
                        setAuthError(null);
                        setResetSuccessMessage(null);
                      }}
                      placeholder="name@example.com"
                      placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                      keyboardType="email-address"
                      autoCapitalize="none"
                      className="pl-11 h-11 text-sm font-medium w-full"
                    />
                  </View>
                </View>

                {authError && (
                  <View className="flex-row items-center gap-2 bg-destructive/10 border border-destructive/20 p-2.5 rounded-xl">
                    <WarningCircle size={16} color="#ef4444" />
                    <Text className="flex-1 text-xs text-destructive font-medium">
                      {authError}
                    </Text>
                  </View>
                )}

                {resetSuccessMessage && (
                  <View className="flex-row items-center gap-2 bg-green-500/10 border border-green-500/30 p-2.5 rounded-xl">
                    <CheckCircle size={16} color="#22c55e" />
                    <Text className="flex-1 text-xs font-bold text-green-600 dark:text-green-400">
                      {resetSuccessMessage}
                    </Text>
                  </View>
                )}

                <Button
                  variant="default"
                  onPress={handleResetPassword}
                  disabled={isLoading}
                  className="w-full h-11 rounded-xl flex-row items-center justify-center min-h-[48px]"
                >
                  {isLoading ? (
                    <ActivityIndicator size="small" color="#ffffff" />
                  ) : (
                    <Text className="font-bold text-primary-foreground text-sm text-center">
                      Send Reset Link
                    </Text>
                  )}
                </Button>
              </CardContent>
            ) : (
              <CardContent className="p-5 gap-4">
                <TouchableOpacity
                  activeOpacity={0.7}
                  onPress={() => switchMode('login_home')}
                  className="flex-row items-center gap-1.5 self-start py-1"
                >
                  <ArrowLeft size={16} color={accentColor} />
                  <Text className="text-xs font-semibold text-primary">
                    Back to Standard Sign In
                  </Text>
                </TouchableOpacity>

                <View className="items-center">
                  <View className="w-12 h-12 rounded-2xl bg-amber-500/10 border border-amber-500/20 items-center justify-center mb-2">
                    <Key size={24} color={isDark ? '#f59e0b' : '#d97706'} weight="bold" />
                  </View>
                  <Text className="text-lg font-bold text-foreground text-center">
                    Terminal Device Login
                  </Text>
                  <Text className="text-xs text-muted-foreground text-center mt-1">
                    Enter the 6-digit Device Pairing PIN generated from your Web Management Dashboard.
                  </Text>
                </View>

                {/* PIN Inputs */}
                <View className="flex-row justify-between gap-2 my-2">
                  {pin.map((digit, index) => (
                    <TextInput
                      key={index}
                      ref={(ref) => {
                        inputRefs.current[index] = ref;
                      }}
                      value={digit}
                      onChangeText={(text) => handlePinChange(text, index)}
                      onKeyPress={(e) => handleKeyPress(e, index)}
                      keyboardType="number-pad"
                      maxLength={1}
                      selectTextOnFocus
                      className={`h-12 flex-1 rounded-xl text-center text-xl font-bold border ${
                        pinError
                          ? 'border-destructive bg-destructive/5 text-destructive'
                          : digit
                          ? 'border-primary bg-primary/10 text-foreground'
                          : 'border-input bg-background text-foreground'
                      }`}
                    />
                  ))}
                </View>

                {/* Demo Quick PIN Fill Helper */}
                <View className="bg-muted/40 border border-border/60 rounded-xl p-3 flex-row items-center justify-between">
                  <View>
                    <Text className="text-[11px] font-semibold text-muted-foreground">Demo Test PIN</Text>
                    <Text className="text-xs font-mono font-bold text-foreground">123456</Text>
                  </View>
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => {
                      const demoPin = ['1', '2', '3', '4', '5', '6'];
                      setPin(demoPin);
                      setPinError(null);
                      submitPin('123456');
                    }}
                    className="bg-primary/10 border border-primary/20 px-3 py-1.5 rounded-lg min-h-[36px] justify-center"
                  >
                    <Text className="text-xs font-bold text-primary">Auto Fill & Pair</Text>
                  </TouchableOpacity>
                </View>

                {pinError && (
                  <View className="flex-row items-center gap-2 bg-destructive/10 border border-destructive/20 p-2.5 rounded-xl">
                    <WarningCircle size={16} color="#ef4444" />
                    <Text className="flex-1 text-xs text-destructive font-medium">
                      {pinError}
                    </Text>
                  </View>
                )}

                {pairingSuccess && (
                  <View className="flex-row items-center gap-2 bg-green-500/10 border border-green-500/30 p-2.5 rounded-xl">
                    <CheckCircle size={16} color="#22c55e" />
                    <Text className="flex-1 text-xs font-bold text-green-600 dark:text-green-400">
                      Terminal Paired Successfully! Redirecting to Cashier Dashboard...
                    </Text>
                  </View>
                )}

                <Button
                  variant="default"
                  onPress={() => submitPin(pin.join(''))}
                  disabled={isLoading || pin.join('').length !== 6 || pairingSuccess}
                  className="w-full h-12 rounded-xl flex-row items-center justify-center min-h-[48px]"
                >
                  {isLoading ? (
                    <ActivityIndicator size="small" color="#ffffff" />
                  ) : (
                    <Text className="font-bold text-primary-foreground text-sm text-center">
                      Verify & Pair Terminal
                    </Text>
                  )}
                </Button>
              </CardContent>
            )}
          </Card>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
