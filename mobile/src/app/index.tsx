import React, { useEffect } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { Redirect } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';
import { useTenantStore } from '@/store/useTenantStore';

export default function Index() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const user = useAuthStore((s) => s.user);
  const authLoading = useAuthStore((s) => s.isLoading);

  const myTenants = useTenantStore((s) => s.myTenants);
  const tenantInitialized = useTenantStore((s) => s.isInitialized);
  const tenantLoading = useTenantStore((s) => s.isLoading);
  const fetchTenants = useTenantStore((s) => s.fetchTenants);

  useEffect(() => {
    if (isAuthenticated && user?.id && !tenantInitialized) {
      fetchTenants(user.id);
    }
  }, [isAuthenticated, user?.id, tenantInitialized, fetchTenants]);

  if (!isAuthenticated) {
    return <Redirect href="/(auth)/login" />;
  }

  if (authLoading || !tenantInitialized || tenantLoading) {
    return (
      <View className="flex-1 items-center justify-center bg-background">
        <ActivityIndicator size="large" color="#56778a" />
      </View>
    );
  }

  if (myTenants.length === 0) {
    return <Redirect href="/create-tenant" />;
  }

  return <Redirect href="/(main)" />;
}
