import React from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { 
  DeviceMobile, 
  Storefront, 
  ShieldCheck, 
  SignOut, 
  Key, 
  Cpu, 
  WifiHigh 
} from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';

export default function TerminalDeviceInfoScreen() {
  const router = useRouter();
  const { user, deviceToken, logout } = useAuthStore();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const accentColor = isDark ? '#f59e0b' : '#d97706';

  return (
    <ScrollView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5`}>
      {/* Device Info Header */}
      <View className="bg-card border border-amber-500/30 rounded-2xl p-5 mb-4 shadow-xs items-center">
        <View className="w-14 h-14 rounded-2xl bg-amber-500/15 border border-amber-500/30 items-center justify-center mb-3">
          <DeviceMobile size={30} color={accentColor} weight="bold" />
        </View>
        <Text className="text-xl font-bold text-foreground text-center">
          {user?.name || 'POS Terminal Device'}
        </Text>
        <Text className="text-xs text-muted-foreground text-center mt-1">
          Registered POS Cashier Device
        </Text>
        <View className="bg-emerald-500/10 border border-emerald-500/30 px-3 py-1 rounded-full mt-2.5 flex-row items-center gap-1.5">
          <View className="w-2 h-2 rounded-full bg-emerald-500" />
          <Text className="text-xs font-bold text-green-600 dark:text-green-400">
            Connected & Online
          </Text>
        </View>
      </View>

      {/* Specifications & Pairing Meta */}
      <View className="bg-card border border-border rounded-2xl p-4 mb-4 shadow-xs gap-3">
        <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
          Device Specifications
        </Text>

        <View className="flex-row items-center justify-between py-2 border-b border-border/60">
          <View className="flex-row items-center gap-2.5">
            <Storefront size={18} color="#64748b" />
            <Text className="text-xs font-medium text-muted-foreground">Store Tenant</Text>
          </View>
          <Text className="text-xs font-bold text-foreground">
            {user?.storeName || activeTenant?.name || 'Smart Hisab Store'}
          </Text>
        </View>

        <View className="flex-row items-center justify-between py-2 border-b border-border/60">
          <View className="flex-row items-center gap-2.5">
            <ShieldCheck size={18} color="#64748b" />
            <Text className="text-xs font-medium text-muted-foreground">Role Level</Text>
          </View>
          <Text className="text-xs font-bold text-amber-600 dark:text-amber-400">Cashier POS</Text>
        </View>

        <View className="flex-row items-center justify-between py-2 border-b border-border/60">
          <View className="flex-row items-center gap-2.5">
            <WifiHigh size={18} color="#64748b" />
            <Text className="text-xs font-medium text-muted-foreground">Network Sync</Text>
          </View>
          <Text className="text-xs font-bold text-green-600 dark:text-green-400">Realtime Sync</Text>
        </View>

        <View className="flex-row items-center justify-between py-2">
          <View className="flex-row items-center gap-2.5">
            <Cpu size={18} color="#64748b" />
            <Text className="text-xs font-medium text-muted-foreground">Device Token</Text>
          </View>
          <Text className="text-xs font-mono text-muted-foreground">
            {deviceToken ? `${deviceToken.slice(0, 10)}...` : user?.id || 'Active Token'}
          </Text>
        </View>
      </View>

      {/* Unpair & Logout Button */}
      <TouchableOpacity
        activeOpacity={0.7}
        onPress={async () => {
          await logout();
          router.replace('/(auth)/login');
        }}
        className="w-full h-12 bg-destructive rounded-xl flex-row items-center justify-center gap-2 shadow-xs min-h-[48px] mb-8"
      >
        <SignOut size={18} color="#ffffff" weight="bold" />
        <Text className="text-sm font-bold text-destructive-foreground">
          Logout & Unpair Device
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
}
