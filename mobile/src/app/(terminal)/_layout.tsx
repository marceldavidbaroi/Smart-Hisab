import React from 'react';
import { View, TouchableOpacity } from 'react-native';
import { Tabs, Redirect } from 'expo-router';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { House, Users, UserCheck, DeviceMobile, Lock, Storefront } from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { TerminalStaffLogin } from '@/components/TerminalStaffLogin';
import { Text } from '@/components/ui/text';

export default function TerminalLayout() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const user = useAuthStore((s) => s.user);
  const isTerminalDevice = useAuthStore((s) => s.isTerminalDevice);
  const activeStaff = useAuthStore((s) => s.activeStaff);
  const clearStaffSession = useAuthStore((s) => s.clearStaffSession);

  const colorScheme = useAppStore((s) => s.colorScheme);
  const activeTenant = useTenantStore((s) => s.activeTenant);
  const insets = useSafeAreaInsets();
  const isDark = colorScheme === 'dark';

  React.useEffect(() => {
    if (isAuthenticated && user) {
      if (!useTenantStore.getState().activeTenant && user.tenantId) {
        useTenantStore.getState().setActiveTenant({
          id: user.tenantId,
          name: user.storeName || 'Terminal Store',
          slug: 'terminal',
          status: 'active',
        });
      } else if (!useTenantStore.getState().activeTenant && user.id) {
        useTenantStore.getState().fetchTenants(user.id);
      }
    }
  }, [isAuthenticated, user]);

  const isTerminal = isTerminalDevice || user?.isTerminalDevice;

  if (!isAuthenticated || !isTerminal) {
    return <Redirect href="/(auth)/login" />;
  }

  // Mandatory Staff Verification Gate for Paired Terminal Devices
  if (!activeStaff) {
    return <TerminalStaffLogin />;
  }

  const activeColor = isDark ? '#f59e0b' : '#d97706'; // Warm accent for Terminal POS
  const inactiveColor = isDark ? '#64748b' : '#94a3b8';

  const bottomInset = Math.max(insets.bottom, 8);
  const tabHeight = 52 + bottomInset;

  return (
    <SafeAreaView edges={['top']} className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'}`}>
      {/* Top Header Bar for Terminal POS */}
      <View className="px-4 py-2.5 bg-card border-b border-border flex-row items-center justify-between shadow-xs">
        <View className="flex-row items-center gap-2.5 flex-1">
          <View className="w-8 h-8 rounded-lg bg-amber-500/15 border border-amber-500/30 items-center justify-center">
            <Storefront size={18} color={activeColor} weight="bold" />
          </View>
          <View className="flex-1">
            <Text className="text-xs font-bold text-foreground" numberOfLines={1}>
              {activeTenant?.name || user?.storeName || 'Smart Hisab Store'}
            </Text>
            <Text className="text-[10px] text-muted-foreground font-medium" numberOfLines={1}>
              Cashier: <Text className="font-bold text-amber-600 dark:text-amber-400">{activeStaff.fullName}</Text> ({activeStaff.role})
            </Text>
          </View>
        </View>

        <TouchableOpacity
          activeOpacity={0.7}
          onPress={() => clearStaffSession()}
          className="bg-muted/50 border border-border px-3 py-1.5 rounded-lg flex-row items-center gap-1.5 min-h-[36px]"
        >
          <Lock size={14} color={isDark ? '#94a3b8' : '#64748b'} weight="bold" />
          <Text className="text-xs font-bold text-foreground">Lock</Text>
        </TouchableOpacity>
      </View>

      <Tabs
        screenOptions={{
          headerShown: false,
          tabBarActiveTintColor: activeColor,
          tabBarInactiveTintColor: inactiveColor,
          tabBarStyle: {
            backgroundColor: isDark ? '#1b262c' : '#ffffff',
            borderTopColor: isDark ? '#2e3b43' : '#e2e8f0',
            height: tabHeight,
            paddingBottom: bottomInset,
            paddingTop: 6,
            elevation: 8,
            shadowColor: '#000',
            shadowOffset: { width: 0, height: -2 },
            shadowOpacity: 0.05,
            shadowRadius: 4,
          },
          tabBarLabelStyle: {
            fontSize: 11,
            fontWeight: '600',
          },
        }}
      >
        <Tabs.Screen
          name="index"
          options={{
            title: 'Home',
            tabBarIcon: ({ color, size }) => <House size={size || 22} color={color} weight="bold" />,
          }}
        />
        <Tabs.Screen
          name="customer"
          options={{
            title: 'Customer',
            tabBarIcon: ({ color, size }) => <Users size={size || 22} color={color} weight="bold" />,
          }}
        />
        <Tabs.Screen
          name="staff"
          options={{
            title: 'Staff',
            tabBarIcon: ({ color, size }) => <UserCheck size={size || 22} color={color} weight="bold" />,
          }}
        />
        <Tabs.Screen
          name="device-info"
          options={{
            title: 'Device Info',
            tabBarIcon: ({ color, size }) => <DeviceMobile size={size || 22} color={color} weight="bold" />,
          }}
        />
      </Tabs>
    </SafeAreaView>
  );
}

