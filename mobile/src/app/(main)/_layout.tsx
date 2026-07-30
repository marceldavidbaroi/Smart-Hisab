import React, { useEffect } from 'react';
import { View } from 'react-native';
import { Tabs, Redirect } from 'expo-router';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { House, Stack, Gear, User } from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { useShiftStore } from '@/store/useShiftStore';
import { Header } from '@/components/Header';

export default function MainLayout() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const user = useAuthStore((s) => s.user);
  const isTerminalDevice = useAuthStore((s) => s.isTerminalDevice);
  
  const colorScheme = useAppStore((s) => s.colorScheme);
  
  const myTenants = useTenantStore((s) => s.myTenants);
  const activeTenant = useTenantStore((s) => s.activeTenant);
  const isInitialized = useTenantStore((s) => s.isInitialized);
  const fetchTenants = useTenantStore((s) => s.fetchTenants);

  const shifts = useShiftStore((s) => s.shifts);
  const shiftInitialized = useShiftStore((s) => s.isInitialized);
  const fetchShifts = useShiftStore((s) => s.fetchShifts);
  const insets = useSafeAreaInsets();
  const isDark = colorScheme === 'dark';

  useEffect(() => {
    if (isAuthenticated && user) {
      if (isTerminalDevice || user.isTerminalDevice) {
        if (!useTenantStore.getState().activeTenant && user.tenantId) {
          useTenantStore.getState().setActiveTenant({
            id: user.tenantId,
            name: user.storeName || 'Terminal Store',
            slug: 'terminal',
            status: 'active',
          });
        }
      } else if (!isInitialized && user.id) {
        fetchTenants(user.id);
      }
    }
  }, [isAuthenticated, user, isInitialized, isTerminalDevice, fetchTenants]);

  useEffect(() => {
    if (isAuthenticated && activeTenant?.id && !shiftInitialized) {
      fetchShifts(activeTenant.id);
    }
  }, [isAuthenticated, activeTenant?.id, shiftInitialized, fetchShifts]);

  if (!isAuthenticated) {
    return <Redirect href="/(auth)/login" />;
  }

  const isTerminal = isTerminalDevice || user?.isTerminalDevice;

  if (isTerminal) {
    return <Redirect href="/(terminal)" />;
  }

  // Redirect to tenant creation page if initialized and user has no active tenants (non-terminal user)
  if (isInitialized && myTenants.length === 0) {
    return <Redirect href="/create-tenant" />;
  }

  const activeColor = isDark ? '#dbad6a' : '#628395';
  const inactiveColor = isDark ? '#64748b' : '#94a3b8';

  const bottomInset = Math.max(insets.bottom, 8);
  const tabHeight = 52 + bottomInset;

  return (
    <SafeAreaView edges={['top']} className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'}`}>
      {/* Clean Modern Top Header with Tenant Selector */}
      <Header />

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
          name="operation"
          options={{
            title: 'Operation',
            tabBarIcon: ({ color, size }) => <Stack size={size || 22} color={color} weight="bold" />,
          }}
        />
        <Tabs.Screen
          name="settings"
          options={{
            title: 'Settings',
            tabBarIcon: ({ color, size }) => <Gear size={size || 22} color={color} weight="bold" />,
          }}
        />
        <Tabs.Screen
          name="profile"
          options={{
            title: 'Profile',
            tabBarIcon: ({ color, size }) => <User size={size || 22} color={color} weight="bold" />,
          }}
        />
      </Tabs>
    </SafeAreaView>
  );
}
