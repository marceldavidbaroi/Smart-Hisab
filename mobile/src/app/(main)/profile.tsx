import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Image,
  Alert,
  Modal,
  TextInput,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  User,
  SignOut,
  Buildings,
  EnvelopeSimple,
  ShieldCheck,
  Trash,
  Warning,
  X,
  CheckCircle,
} from 'phosphor-react-native';
import { useAuthStore } from '@/store/useAuthStore';
import { useTenantStore, Tenant } from '@/store/useTenantStore';
import { useAppStore } from '@/store/useAppStore';
import { supabase } from '@/lib/supabase';
import { WarningModal } from '@/components/ui/WarningModal';

export default function ProfileScreen() {
  const { user, logout } = useAuthStore();
  const { myTenants, activeTenant, fetchTenants, setActiveTenant } = useTenantStore();
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';

  // Modal display states
  const [showDeleteTenantModal, setShowDeleteTenantModal] = useState(false);
  const [showDeleteProfileModal, setShowDeleteProfileModal] = useState(false);

  // Tenant deletion state
  const [selectedTenantId, setSelectedTenantId] = useState<string>('');
  const [tenantConfirmText, setTenantConfirmText] = useState('');
  const [isDeletingTenant, setIsDeletingTenant] = useState(false);

  // Profile deletion state
  const [profileConfirmText, setProfileConfirmText] = useState('');
  const [isDeletingProfile, setIsDeletingProfile] = useState(false);

  useEffect(() => {
    if (user?.id) {
      void fetchTenants(user.id);
    }
  }, [user?.id]);

  useEffect(() => {
    if (activeTenant?.id) {
      setSelectedTenantId(activeTenant.id);
    } else if (myTenants.length > 0 && myTenants[0].tenants?.id) {
      setSelectedTenantId(myTenants[0].tenants.id);
    }
  }, [activeTenant, myTenants]);

  // Derived selected tenant target
  const selectedTenantObj: Tenant | null =
    myTenants.find((m) => m.tenants?.id === selectedTenantId)?.tenants || activeTenant;

  const expectedTenantConfirm = selectedTenantObj ? `DELETE_${selectedTenantObj.name}` : '';
  const isTenantMatch = tenantConfirmText.trim() === expectedTenantConfirm;

  const expectedProfileConfirm = 'DELETE PROFILE';
  const isProfileMatch = profileConfirmText.trim() === expectedProfileConfirm;

  const handleSignOut = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out of your account?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Sign Out',
          style: 'default',
          onPress: logout,
        },
      ]
    );
  };

  const openDeleteTenant = () => {
    if (activeTenant?.id) {
      setSelectedTenantId(activeTenant.id);
    }
    setTenantConfirmText('');
    setShowDeleteTenantModal(true);
  };

  const openDeleteProfile = () => {
    setProfileConfirmText('');
    setShowDeleteProfileModal(true);
  };

  const handleConfirmDeleteTenant = async () => {
    if (!selectedTenantObj || !isTenantMatch || isDeletingTenant) return;
    setIsDeletingTenant(true);
    try {
      const { error } = await supabase.from('tenants').delete().eq('id', selectedTenantObj.id);
      if (error) throw error;

      setShowDeleteTenantModal(false);
      setTenantConfirmText('');

      Alert.alert('Success', `Tenant "${selectedTenantObj.name}" deleted successfully.`);

      if (user?.id) {
        const refreshed = await fetchTenants(user.id);
        if (refreshed.length === 0) {
          await logout();
        } else {
          setActiveTenant(refreshed[0].tenants);
        }
      }
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to delete tenant');
    } finally {
      setIsDeletingTenant(false);
    }
  };

  const handleConfirmDeleteProfile = async () => {
    if (!isProfileMatch || isDeletingProfile) return;
    setIsDeletingProfile(true);
    try {
      const { error } = await supabase.rpc('delete_own_account');
      if (error) throw error;

      setShowDeleteProfileModal(false);
      setProfileConfirmText('');

      Alert.alert('Success', 'Profile deleted successfully.', [
        { text: 'OK', onPress: logout },
      ]);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to delete profile');
    } finally {
      setIsDeletingProfile(false);
    }
  };

  return (
    <SafeAreaView edges={['top', 'left', 'right']} className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50'}`}>
      <ScrollView contentContainerStyle={{ padding: 24, paddingBottom: 40 }}>
        {/* Profile Header */}
        <View className="mb-6 pb-4 border-b border-border">
          <Text className="text-muted-foreground text-xs font-semibold uppercase tracking-wider">
            User Account
          </Text>
          <Text className="text-2xl font-bold text-foreground mt-1">
            Profile & Settings
          </Text>
        </View>

        {/* User Info Card */}
        <View className="bg-card border border-border rounded-2xl p-5 mb-4 shadow-xs items-center">
          {user?.avatarUrl ? (
            <Image
              source={{ uri: user.avatarUrl }}
              className="w-20 h-20 rounded-full border-2 border-primary mb-3"
            />
          ) : (
            <View className="w-20 h-20 rounded-full bg-primary/15 items-center justify-center mb-3 border border-primary/20">
              <User size={36} color={isDark ? '#d4984e' : '#56778a'} />
            </View>
          )}

          <Text className="text-xl font-bold text-foreground text-center">
            {user?.name || 'Store Manager'}
          </Text>
          <Text className="text-muted-foreground text-xs text-center mt-1">
            {user?.email || 'manager@smarthisab.com'}
          </Text>
        </View>

        {/* Details List */}
        <View className="bg-card border border-border rounded-2xl p-4 shadow-xs gap-3 mb-6">
          <View className="flex-row items-center gap-3">
            <EnvelopeSimple size={18} color={isDark ? '#94a3b8' : '#64748b'} />
            <Text className="text-xs font-medium text-foreground flex-1">{user?.email || 'N/A'}</Text>
          </View>
          <View className="flex-row items-center gap-3">
            <Buildings size={18} color={isDark ? '#94a3b8' : '#64748b'} />
            <Text className="text-xs font-medium text-foreground flex-1">
              {activeTenant?.name || 'Smart Hisab Main Branch'}
            </Text>
          </View>
          <View className="flex-row items-center gap-3">
            <ShieldCheck size={18} color={isDark ? '#94a3b8' : '#64748b'} />
            <Text className="text-xs font-medium text-foreground flex-1">Role: Administrator / Owner</Text>
          </View>
        </View>

        {/* Sign Out Action */}
        <TouchableOpacity
          onPress={handleSignOut}
          activeOpacity={0.8}
          className="bg-card border border-border py-3.5 rounded-xl flex-row items-center justify-center gap-2 mb-8"
        >
          <SignOut size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          <Text className="text-foreground font-semibold text-base">Sign Out</Text>
        </TouchableOpacity>

        {/* Danger Zone */}
        <View className="pt-4 border-t border-border">
          <View className="flex-row items-center gap-2 mb-3">
            <Warning size={20} color="#ef4444" />
            <Text className="text-destructive font-bold text-sm uppercase tracking-wider">
              Danger Zone
            </Text>
          </View>

          <View className="gap-4">
            {/* Delete Tenant Card */}
            <View className="bg-card border border-destructive/30 rounded-2xl p-4 shadow-xs">
              <View className="mb-3">
                <Text className="text-base font-bold text-foreground">
                  Delete Tenant
                </Text>
                <Text className="text-xs text-muted-foreground mt-1 leading-5">
                  Permanently delete a tenant workspace, operational records, and associated data.
                </Text>
              </View>
              <TouchableOpacity
                onPress={openDeleteTenant}
                activeOpacity={0.8}
                disabled={isDeletingTenant || isDeletingProfile}
                className="bg-destructive/10 border border-destructive/30 py-3 rounded-xl flex-row items-center justify-center gap-2"
              >
                <Trash size={16} color="#ef4444" />
                <Text className="text-destructive font-semibold text-sm">
                  Delete Tenant
                </Text>
              </TouchableOpacity>
            </View>

            {/* Delete Profile Card */}
            <View className="bg-card border border-destructive/30 rounded-2xl p-4 shadow-xs">
              <View className="mb-3">
                <Text className="text-base font-bold text-foreground">
                  Delete Profile
                </Text>
                <Text className="text-xs text-muted-foreground mt-1 leading-5">
                  Permanently delete your profile account credentials and all personal account data.
                </Text>
              </View>
              <TouchableOpacity
                onPress={openDeleteProfile}
                activeOpacity={0.8}
                disabled={isDeletingTenant || isDeletingProfile}
                className="bg-destructive/10 border border-destructive/30 py-3 rounded-xl flex-row items-center justify-center gap-2"
              >
                <Trash size={16} color="#ef4444" />
                <Text className="text-destructive font-semibold text-sm">
                  Delete Profile
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </ScrollView>

      {/* Delete Tenant Slide Sheet */}
      <WarningModal
        visible={showDeleteTenantModal}
        onClose={() => setShowDeleteTenantModal(false)}
        onConfirm={handleConfirmDeleteTenant}
        title="Delete Tenant Workspace"
        description={`Permanently delete workspace "${selectedTenantObj?.name || 'Selected Tenant'}" and all its operational data. This action cannot be undone.`}
        variant="danger"
        confirmText="Delete Workspace"
        cancelText="Cancel"
        isLoading={isDeletingTenant}
        isDark={isDark}
        requiredConfirmText={expectedTenantConfirm}
        confirmInputPlaceholder={expectedTenantConfirm}
      />

      {/* Delete Profile Slide Sheet */}
      <WarningModal
        visible={showDeleteProfileModal}
        onClose={() => setShowDeleteProfileModal(false)}
        onConfirm={handleConfirmDeleteProfile}
        title="Delete User Profile"
        description="Permanently delete your profile account credentials and all personal account data. This action cannot be undone."
        variant="danger"
        confirmText="Delete Profile"
        cancelText="Cancel"
        isLoading={isDeletingProfile}
        isDark={isDark}
        requiredConfirmText="DELETE PROFILE"
        confirmInputPlaceholder="DELETE PROFILE"
      />
    </SafeAreaView>
  );
}
