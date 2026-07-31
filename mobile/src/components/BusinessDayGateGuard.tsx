import React, { useState, useEffect } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { useBusinessDayStore } from '@/store/useBusinessDayStore';
import { useTenantStore } from '@/store/useTenantStore';
import { StartBusinessDayScreen } from '@/components/StartBusinessDayScreen';

interface BusinessDayGateGuardProps {
  children: React.ReactNode;
}

export function BusinessDayGateGuard({ children }: BusinessDayGateGuardProps) {
  const { activeTenant } = useTenantStore();
  const { activeDay, isLoading, fetchActiveDay } = useBusinessDayStore();
  const [isDismissed, setIsDismissed] = useState(false);
  const [hasFetchedOnce, setHasFetchedOnce] = useState(false);

  useEffect(() => {
    if (activeTenant?.id && !activeDay) {
      fetchActiveDay(activeTenant.id).finally(() => {
        setHasFetchedOnce(true);
      });
    } else {
      setHasFetchedOnce(true);
    }
  }, [activeTenant?.id, activeDay, fetchActiveDay]);

  // If user clicked close/skip, show main app content immediately
  if (isDismissed) {
    return <>{children}</>;
  }

  // Show initial spinner only on initial load before choice is presented
  if (isLoading && !hasFetchedOnce && !activeDay) {
    return (
      <View className="flex-1 items-center justify-center bg-background">
        <ActivityIndicator size="large" color="#f59e0b" />
      </View>
    );
  }

  if (!activeDay) {
    return <StartBusinessDayScreen onClose={() => setIsDismissed(true)} />;
  }

  return <>{children}</>;
}
