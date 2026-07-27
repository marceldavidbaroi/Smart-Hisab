import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Moon, Sun, Bell, Shield, Faders } from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';

export default function SettingsScreen() {
  const { colorScheme, toggleColorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';

  return (
    <SafeAreaView edges={['top', 'left', 'right']} className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'} p-6`}>
      <View className="mb-6 pb-4 border-b border-border">
        <Text className="text-muted-foreground text-xs font-semibold uppercase tracking-wider">
          Preferences & Configuration
        </Text>
        <Text className="text-2xl font-bold text-foreground mt-1">
          Settings
        </Text>
      </View>

      <View className="gap-4">
        {/* Dark Mode Toggle */}
        <TouchableOpacity
          activeOpacity={0.7}
          onPress={toggleColorScheme}
          className="bg-card border border-border rounded-2xl p-5 shadow-xs flex-row items-center justify-between"
        >
          <View className="flex-row items-center gap-4">
            <View className="h-12 w-12 rounded-xl bg-primary/10 items-center justify-center">
              {isDark ? (
                <Sun size={24} color="#d4984e" />
              ) : (
                <Moon size={24} color="#56778a" />
              )}
            </View>
            <View>
              <Text className="text-foreground font-bold text-base">Theme Appearance</Text>
              <Text className="text-muted-foreground text-xs mt-0.5">
                Current mode: <Text className="font-bold text-primary">{colorScheme.toUpperCase()}</Text>
              </Text>
            </View>
          </View>
        </TouchableOpacity>

        {/* Notifications Setting */}
        <View className="bg-card border border-border rounded-2xl p-5 shadow-xs flex-row items-center gap-4">
          <View className="h-12 w-12 rounded-xl bg-primary/10 items-center justify-center">
            <Bell size={24} color={isDark ? '#d4984e' : '#56778a'} />
          </View>
          <View className="flex-1">
            <Text className="text-foreground font-bold text-base">Notifications</Text>
            <Text className="text-muted-foreground text-xs mt-0.5">Alerts for low inventory and daily reports</Text>
          </View>
        </View>

        {/* Security & Terminal Setting */}
        <View className="bg-card border border-border rounded-2xl p-5 shadow-xs flex-row items-center gap-4">
          <View className="h-12 w-12 rounded-xl bg-primary/10 items-center justify-center">
            <Shield size={24} color={isDark ? '#d4984e' : '#56778a'} />
          </View>
          <View className="flex-1">
            <Text className="text-foreground font-bold text-base">Security & PIN</Text>
            <Text className="text-muted-foreground text-xs mt-0.5">Manage terminal pairing and passcode</Text>
          </View>
        </View>
      </View>
    </SafeAreaView>
  );
}
