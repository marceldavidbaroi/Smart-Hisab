import React, { useEffect } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { Redirect } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';
import { useTenantStore } from '@/store/useTenantStore';

export default function Index() {
  const { isAuthenticated, user, isTerminalDevice, isLoading: authLoading } = useAuthStore();
  const { myTenants, isInitialized: tenantInitialized, isLoading: tenantLoading, fetchTenants } = useTenantStore();

  useEffect(() => {
    if (isAuthenticated && user?.id && !tenantInitialized && !isTerminalDevice && !user?.isTerminalDevice) {
      fetchTenants(user.id);
    }
  }, [isAuthenticated, user?.id, tenantInitialized, isTerminalDevice, user?.isTerminalDevice, fetchTenants]);

  if (!isAuthenticated) {
    return <Redirect href="/(auth)/login" />;
  }

  const isTerminal = isTerminalDevice || user?.isTerminalDevice;

  if (isTerminal) {
    return <Redirect href="/(terminal)" />;
  }

  // Show loading indicator while fetching auth session or tenants
  if (authLoading || !tenantInitialized || tenantLoading) {
    return (
      <View className="flex-1 items-center justify-center bg-background">
        <ActivityIndicator size="large" color="#56778a" />
      </View>
    );
  }

  // If user has no tenants, redirect to create-tenant page
  if (myTenants.length === 0) {
    return <Redirect href="/create-tenant" />;
  }

  // User has tenant, proceed directly to main dashboard layout
  return <Redirect href="/(main)" />;
}
