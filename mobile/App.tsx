import React, { useState } from 'react';
import { View, ScrollView, SafeAreaView, ActivityIndicator } from 'react-native';
import { QueryClientProvider } from '@tanstack/react-query';
import { StatusBar } from 'expo-status-bar';
import {
  Moon,
  Sun,
  RefreshCw,
  TrendingUp,
  Package,
  ShieldCheck,
  Search,
  Bell,
  UserCheck,
  Palette,
} from 'lucide-react-native';

import { queryClient } from '@/lib/query-client';
import { useAppStore } from '@/store/useAppStore';
import { useAuthStore } from '@/store/useAuthStore';
import { useDashboardData } from '@/hooks/useDashboardData';

import { Text } from '@/components/ui/text';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Separator } from '@/components/ui/separator';

function DashboardScreen() {
  const { colorScheme, toggleColorScheme } = useAppStore();
  const { user } = useAuthStore();
  const { data: metrics, isLoading, isRefetching, refetch } = useDashboardData();
  const [searchQuery, setSearchQuery] = useState('');

  const isDark = colorScheme === 'dark';

  return (
    <View className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'}`}>
      <SafeAreaView className="flex-1">
        <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
          
          {/* Header Bar */}
          <View className="flex-row items-center justify-between mb-6">
            <View className="flex-row items-center space-x-3">
              <Avatar alt="User Avatar" className="h-12 w-12 border border-border">
                <AvatarImage source={{ uri: user?.avatarUrl }} />
                <AvatarFallback>
                  <Text className="font-bold text-sm text-air-force-blue">MB</Text>
                </AvatarFallback>
              </Avatar>
              <View>
                <Text className="text-xl font-bold text-foreground">
                  {user?.storeName}
                </Text>
                <View className="flex-row items-center space-x-2 mt-0.5">
                  <Badge variant="outline" className="border-air-force-blue/40">
                    <Text className="text-xs text-air-force-blue dark:text-sunlit-clay font-medium">
                      {user?.role}
                    </Text>
                  </Badge>
                  <Text className="text-xs text-muted-foreground">• {user?.name}</Text>
                </View>
              </View>
            </View>

            {/* Dark Mode Toggle Button */}
            <Button
              variant="outline"
              size="icon"
              onPress={toggleColorScheme}
              className="rounded-full h-10 w-10 border-border"
            >
              {isDark ? (
                <Sun size={20} color="#dbad6a" />
              ) : (
                <Moon size={20} color="#628395" />
              )}
            </Button>
          </View>

          {/* Color Palette Swatches Preview */}
          <Card className="mb-6 bg-card border-border">
            <CardHeader className="pb-2">
              <View className="flex-row items-center space-x-2">
                <Palette size={18} color="#628395" />
                <CardTitle className="text-sm font-bold text-foreground">
                  Brand Color Palette
                </CardTitle>
              </View>
            </CardHeader>
            <CardContent className="pt-2">
              <View className="flex-row justify-between space-x-2">
                <View className="flex-1 items-center">
                  <View className="h-8 w-full rounded bg-air-force-blue mb-1" />
                  <Text className="text-[10px] text-muted-foreground font-medium">Air Force</Text>
                </View>
                <View className="flex-1 items-center">
                  <View className="h-8 w-full rounded bg-dusty-taupe mb-1" />
                  <Text className="text-[10px] text-muted-foreground font-medium">Dusty Taupe</Text>
                </View>
                <View className="flex-1 items-center">
                  <View className="h-8 w-full rounded bg-vanilla-custard mb-1" />
                  <Text className="text-[10px] text-muted-foreground font-medium">Vanilla</Text>
                </View>
                <View className="flex-1 items-center">
                  <View className="h-8 w-full rounded bg-sunlit-clay mb-1" />
                  <Text className="text-[10px] text-muted-foreground font-medium">Sunlit Clay</Text>
                </View>
                <View className="flex-1 items-center">
                  <View className="h-8 w-full rounded bg-light-bronze mb-1" />
                  <Text className="text-[10px] text-muted-foreground font-medium">Bronze</Text>
                </View>
              </View>
            </CardContent>
          </Card>

          {/* Search Input Bar */}
          <View className="mb-6">
            <View className="relative">
              <Input
                placeholder="Search transactions, inventory, customers..."
                value={searchQuery}
                onChangeText={setSearchQuery}
                className="pl-10 pr-4 bg-card border-border"
              />
              <View className="absolute left-3 top-3">
                <Search size={18} color="#96897b" />
              </View>
            </View>
          </View>

          {/* System Health Card (TanStack Query Integration) */}
          <Card className="mb-6 border-primary/20 bg-primary/5 dark:bg-primary/10">
            <CardHeader className="flex-row items-center justify-between pb-2">
              <View className="flex-row items-center space-x-2">
                <ShieldCheck size={20} color={isDark ? '#dbad6a' : '#628395'} />
                <CardTitle className="text-base font-bold text-primary">
                  TanStack Query Real-Time Metrics
                </CardTitle>
              </View>
              <Button
                variant="ghost"
                size="sm"
                onPress={() => refetch()}
                disabled={isRefetching}
              >
                {isRefetching ? (
                  <ActivityIndicator size="small" color={isDark ? '#dbad6a' : '#628395'} />
                ) : (
                  <RefreshCw size={16} color={isDark ? '#dbad6a' : '#628395'} />
                )}
              </Button>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <ActivityIndicator size="small" color={isDark ? '#dbad6a' : '#628395'} className="my-4" />
              ) : (
                <View className="space-y-2">
                  <View className="flex-row justify-between items-center">
                    <Text className="text-sm text-muted-foreground">System Status:</Text>
                    <Badge variant="default" className="bg-air-force-blue dark:bg-sunlit-clay">
                      <Text className="text-xs text-white dark:text-slate-950 font-semibold">
                        ✅ {metrics?.systemStatus}
                      </Text>
                    </Badge>
                  </View>
                  <View className="flex-row justify-between items-center">
                    <Text className="text-sm text-muted-foreground">Last Sync Time:</Text>
                    <Text className="text-sm font-semibold text-foreground">
                      {metrics?.lastUpdated}
                    </Text>
                  </View>
                </View>
              )}
            </CardContent>
          </Card>

          {/* Metric Cards Grid */}
          <Text className="text-lg font-bold text-foreground mb-3">
            Overview Summary
          </Text>

          <View className="flex-row space-x-3 mb-4">
            <Card className="flex-1 bg-card border-border">
              <CardHeader className="p-4 pb-2">
                <View className="flex-row items-center justify-between">
                  <Text className="text-xs font-semibold text-muted-foreground uppercase">
                    Sales Today
                  </Text>
                  <TrendingUp size={16} color="#628395" />
                </View>
              </CardHeader>
              <CardContent className="p-4 pt-0">
                <Text className="text-2xl font-black text-foreground">
                  ৳{metrics?.totalSalesToday.toLocaleString() ?? '0'}
                </Text>
                <Text className="text-xs text-air-force-blue dark:text-sunlit-clay font-medium mt-1">
                  {metrics?.ordersCountToday ?? 0} total orders
                </Text>
              </CardContent>
            </Card>

            <Card className="flex-1 bg-card border-border">
              <CardHeader className="p-4 pb-2">
                <View className="flex-row items-center justify-between">
                  <Text className="text-xs font-semibold text-muted-foreground uppercase">
                    Low Stock Alert
                  </Text>
                  <Package size={16} color="#dbad6a" />
                </View>
              </CardHeader>
              <CardContent className="p-4 pt-0">
                <Text className="text-2xl font-black text-foreground">
                  {metrics?.lowStockItemsCount ?? 0}
                </Text>
                <Text className="text-xs text-light-bronze font-medium mt-1">
                  Items require reorder
                </Text>
              </CardContent>
            </Card>
          </View>

          {/* Action List using React Native Reusables components */}
          <Card className="bg-card border-border mb-6">
            <CardHeader>
              <CardTitle className="text-lg">Quick Actions & Controls</CardTitle>
              <CardDescription>
                Powered by React Native Reusables UI primitives and Zustand state.
              </CardDescription>
            </CardHeader>
            <Separator className="my-1" />
            <CardContent className="pt-4 space-y-3">
              <Button
                variant="default"
                className="w-full justify-between flex-row px-4 bg-primary"
                onPress={() => alert('New Order Created!')}
              >
                <Text className="font-semibold text-primary-foreground">
                  Create New POS Transaction
                </Text>
                <UserCheck size={18} color={isDark ? '#0f172a' : '#ffffff'} />
              </Button>

              <Button
                variant="secondary"
                className="w-full justify-between flex-row px-4"
                onPress={() => alert('Notifications Toggled')}
              >
                <Text className="font-medium text-secondary-foreground">
                  View App Notifications
                </Text>
                <Bell size={18} color="#628395" />
              </Button>
            </CardContent>
            <CardFooter className="justify-between border-t border-border pt-3">
              <Text className="text-xs text-muted-foreground">
                Zustand Active Theme: {colorScheme.toUpperCase()}
              </Text>
              <Badge variant="outline" className="border-border">
                <Text className="text-xs font-mono text-muted-foreground">
                  React Native Reusables v1.0
                </Text>
              </Badge>
            </CardFooter>
          </Card>

        </ScrollView>
      </SafeAreaView>
      <StatusBar style={isDark ? 'light' : 'dark'} />
    </View>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <DashboardScreen />
    </QueryClientProvider>
  );
}
