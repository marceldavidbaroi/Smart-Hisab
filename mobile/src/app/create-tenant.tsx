import React, { useState } from 'react';
import {
  View,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Building, Storefront, Sparkle, WarningCircle, SignOut } from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useAuthStore } from '@/store/useAuthStore';
import { useTenantStore } from '@/store/useTenantStore';
import { Text } from '@/components/ui/text';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';

export default function CreateTenantScreen() {
  const router = useRouter();
  const { colorScheme } = useAppStore();
  const { user, logout } = useAuthStore();
  const { createTenant, isLoading } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const [name, setName] = useState('');
  const [slug, setSlug] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleNameChange = (val: string) => {
    setName(val);
    setError(null);
    // Auto-generate slug from name if user hasn't explicitly edited slug heavily
    const autoSlug = val
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-');
    setSlug(autoSlug);
  };

  const handleCreate = async () => {
    if (!name.trim()) {
      setError('Please enter a store / business name.');
      return;
    }

    const cleanedSlug = (slug || name)
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9-]/g, '');

    if (!cleanedSlug) {
      setError('Please enter a valid slug identifier.');
      return;
    }

    if (!user?.id) {
      setError('Authentication session missing. Please sign in again.');
      return;
    }

    try {
      setError(null);
      await createTenant(name.trim(), cleanedSlug, user.id);
      router.replace('/(main)');
    } catch (err: any) {
      console.error('Create tenant error:', err);
      const isDuplicateSlug =
        err?.code === '23505' ||
        err?.message?.includes('tenants_slug_key') ||
        err?.message?.includes('duplicate key value');

      if (isDuplicateSlug) {
        setError(
          `The workspace slug identifier "${cleanedSlug}" is already taken by another store. Please modify the slug identifier.`
        );
      } else {
        setError(err.message || 'Failed to create workspace. Slug may already be taken.');
      }
    }
  };

  const accentColor = isDark ? '#d4984e' : '#56778a';

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1"
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', paddingHorizontal: 20, paddingVertical: 24 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Header Branding */}
          <View className="items-center mb-6">
            <View className="h-16 w-16 rounded-2xl bg-primary/15 items-center justify-center mb-3 border border-primary/20 shadow-xs">
              <Storefront size={36} color={accentColor} weight="bold" />
            </View>
            <Text className="text-2xl font-bold text-foreground text-center tracking-tight">
              Create Your Workspace
            </Text>
            <Text className="text-xs font-semibold text-muted-foreground text-center mt-1 uppercase tracking-wider">
              No active store found for {user?.email || 'your account'}
            </Text>
          </View>

          {/* Form Card */}
          <Card className="bg-card border-border shadow-sm rounded-2xl overflow-hidden">
            <CardHeader className="p-5 pb-2">
              <CardTitle className="text-lg font-bold text-foreground">
                Store Details
              </CardTitle>
              <CardDescription className="text-xs text-muted-foreground leading-relaxed">
                Set up your primary store or business location to start managing sales, inventory, and ledger.
              </CardDescription>
            </CardHeader>

            <CardContent className="p-5 pt-2 gap-4">
              {/* Store Name Input */}
              <View className="gap-1.5">
                <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                  Store / Business Name
                </Text>
                <View className="relative flex-row items-center">
                  <View className="absolute left-3.5 z-10">
                    <Building size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                  </View>
                  <Input
                    value={name}
                    onChangeText={handleNameChange}
                    placeholder="e.g. Metro Super Store"
                    placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                    className="pl-11 h-12 text-sm font-medium w-full"
                  />
                </View>
              </View>

              {/* Store Slug Input */}
              <View className="gap-1.5">
                <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                  Workspace Slug Identifier
                </Text>
                <View className="relative flex-row items-center">
                  <View className="absolute left-3.5 z-10">
                    <Sparkle size={18} color={isDark ? '#94a3b8' : '#64748b'} />
                  </View>
                  <Input
                    value={slug}
                    onChangeText={(val) => {
                      setSlug(val);
                      setError(null);
                    }}
                    placeholder="metro-super-store"
                    placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                    autoCapitalize="none"
                    className="pl-11 h-12 text-sm font-medium w-full"
                  />
                </View>
                <Text className="text-[11px] text-muted-foreground">
                  URL-friendly unique ID used for multi-tenant isolation.
                </Text>
              </View>

              {/* Error Banner */}
              {error && (
                <View className="flex-row items-center gap-2 bg-destructive/10 border border-destructive/20 p-3 rounded-xl">
                  <WarningCircle size={16} color="#ef4444" />
                  <Text className="flex-1 text-xs text-destructive font-semibold">
                    {error}
                  </Text>
                </View>
              )}

              {/* Create Action Button */}
              <Button
                variant="default"
                onPress={handleCreate}
                disabled={isLoading || !name.trim()}
                className="w-full h-12 rounded-xl mt-2 shadow-xs"
              >
                {isLoading ? (
                  <ActivityIndicator size="small" color="#ffffff" />
                ) : (
                  <Text className="font-bold text-primary-foreground text-sm">
                    Create & Continue to Dashboard
                  </Text>
                )}
              </Button>

              {/* Sign Out Option */}
              <View className="pt-2 border-t border-border mt-1">
                <Button
                  variant="ghost"
                  onPress={async () => {
                    await logout();
                    router.replace('/(auth)/login');
                  }}
                  className="w-full h-10 rounded-xl"
                >
                  <SignOut size={16} color={isDark ? '#94a3b8' : '#64748b'} />
                  <Text className="text-xs font-semibold text-muted-foreground ml-2">
                    Sign Out / Switch Account
                  </Text>
                </Button>
              </View>
            </CardContent>
          </Card>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
