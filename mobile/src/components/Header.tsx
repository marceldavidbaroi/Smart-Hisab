import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Modal,
  FlatList,
  Pressable,
  Image,
} from 'react-native';
import { useRouter } from 'expo-router';
import {
  Storefront,
  CaretDown,
  Check,
  Plus,
  Moon,
  Sun,
  User,
  SignOut,
} from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore, Tenant } from '@/store/useTenantStore';

export function Header() {
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const { colorScheme, toggleColorScheme } = useAppStore();
  const { activeTenant, myTenants, setActiveTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  const accentColor = isDark ? '#dbad6a' : '#628395';

  const handleSelectTenant = (tenant: Tenant) => {
    setActiveTenant(tenant);
    setIsDropdownOpen(false);
  };

  const handleCreateNewTenant = () => {
    setIsDropdownOpen(false);
    router.push('/create-tenant');
  };

  return (
    <View className="bg-card border-b border-border px-4 py-3 shadow-xs">
      <View className="flex-row items-center justify-between">
        {/* Left: Tenant Selector Button */}
        <TouchableOpacity
          activeOpacity={0.7}
          onPress={() => setIsDropdownOpen(true)}
          className="flex-row items-center gap-2 bg-muted/60 dark:bg-muted/30 px-3 py-2 rounded-xl border border-border/80"
        >
          <View className="h-7 w-7 rounded-lg bg-primary/15 items-center justify-center border border-primary/20">
            <Storefront size={16} color={accentColor} weight="bold" />
          </View>
          
          <View className="max-w-[170px]">
            <Text className="text-[10px] font-semibold text-muted-foreground uppercase tracking-wider leading-none">
              Store Workspace
            </Text>
            <Text
              numberOfLines={1}
              className="text-xs font-bold text-foreground mt-0.5"
            >
              {activeTenant?.name || 'Select Store'}
            </Text>
          </View>

          <CaretDown size={14} color={isDark ? '#94a3b8' : '#64748b'} weight="bold" />
        </TouchableOpacity>

        {/* Right: Actions (Theme Toggle & User Avatar) */}
        <View className="flex-row items-center gap-2">
          {/* Theme Toggle */}
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={toggleColorScheme}
            className="w-9 h-9 rounded-xl bg-muted/50 items-center justify-center border border-border"
          >
            {isDark ? (
              <Sun size={18} color="#d4984e" weight="bold" />
            ) : (
              <Moon size={18} color="#56778a" weight="bold" />
            )}
          </TouchableOpacity>

          {/* User Avatar */}
          {user?.avatarUrl ? (
            <Image
              source={{ uri: user.avatarUrl }}
              className="w-9 h-9 rounded-xl border border-border"
            />
          ) : (
            <View className="w-9 h-9 rounded-xl bg-primary/10 items-center justify-center border border-primary/20">
              <User size={18} color={accentColor} weight="bold" />
            </View>
          )}
        </View>
      </View>

      {/* Tenant Switcher Dropdown Modal */}
      <Modal
        visible={isDropdownOpen}
        transparent
        animationType="fade"
        onRequestClose={() => setIsDropdownOpen(false)}
      >
        <Pressable
          className="flex-1 bg-black/50 justify-start pt-16 px-4"
          onPress={() => setIsDropdownOpen(false)}
        >
          <Pressable
            className={`bg-card border border-border rounded-2xl p-4 shadow-xl max-h-[420px] ${
              isDark ? 'dark' : ''
            }`}
            onPress={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <View className="flex-row items-center justify-between pb-3 border-b border-border mb-3">
              <View className="flex-row items-center gap-2">
                <Storefront size={18} color={accentColor} weight="bold" />
                <Text className="text-sm font-bold text-foreground">
                  Switch Workspace
                </Text>
              </View>
              <Text className="text-xs text-muted-foreground font-semibold">
                {myTenants.length} {myTenants.length === 1 ? 'Store' : 'Stores'}
              </Text>
            </View>

            {/* Tenant List */}
            <FlatList
              data={myTenants}
              keyExtractor={(item) => item.id}
              showsVerticalScrollIndicator={false}
              renderItem={({ item }) => {
                const tenant = item.tenants;
                if (!tenant) return null;
                const isSelected = activeTenant?.id === tenant.id;

                return (
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => handleSelectTenant(tenant)}
                    className={`flex-row items-center justify-between p-3 rounded-xl mb-1.5 border ${
                      isSelected
                        ? 'bg-primary/10 border-primary/40'
                        : 'bg-muted/30 border-transparent'
                    }`}
                  >
                    <View className="flex-row items-center gap-3 flex-1 pr-2">
                      <View className={`w-9 h-9 rounded-lg items-center justify-center ${
                        isSelected ? 'bg-primary/20' : 'bg-muted/60'
                      }`}>
                        <Storefront
                          size={18}
                          color={isSelected ? accentColor : (isDark ? '#94a3b8' : '#64748b')}
                          weight={isSelected ? 'bold' : 'regular'}
                        />
                      </View>
                      <View className="flex-1">
                        <Text className={`text-xs font-bold ${
                          isSelected ? 'text-primary' : 'text-foreground'
                        }`}>
                          {tenant.name}
                        </Text>
                        <Text className="text-[11px] text-muted-foreground mt-0.5">
                          @{tenant.slug}
                        </Text>
                      </View>
                    </View>

                    {isSelected && (
                      <Check size={18} color={accentColor} weight="bold" />
                    )}
                  </TouchableOpacity>
                );
              }}
            />

            {/* Modal Actions Footer */}
            <View className="pt-3 border-t border-border mt-2 gap-2">
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={handleCreateNewTenant}
                className="flex-row items-center justify-center gap-2 bg-primary py-2.5 px-4 rounded-xl"
              >
                <Plus size={16} color="#ffffff" weight="bold" />
                <Text className="text-xs font-bold text-primary-foreground">
                  Add New Store / Business
                </Text>
              </TouchableOpacity>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}
