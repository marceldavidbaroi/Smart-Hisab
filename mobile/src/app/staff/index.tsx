import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  RefreshControl,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import {
  ArrowLeft,
  UserPlus,
  Key,
  Users,
  ShieldCheck,
  PencilSimple,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import {
  getStaffMembers,
  updateStaffMember,
  resetStaffPin,
  getStaffRoles,
  getDevicePairings,
  StaffMember,
  StaffRole,
  DevicePairing,
} from '@/services/staff';

import StaffAddEditModal from './components/StaffAddEditModal';
import PinRevealModal from './components/PinRevealModal';
import DevicePairingModal from './components/DevicePairingModal';
import StaffSkeleton from './components/StaffSkeleton';

export default function StaffManagementScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Data states
  const [staffList, setStaffList] = useState<StaffMember[]>([]);
  const [rolesList, setRolesList] = useState<StaffRole[]>([]);
  const [pairingsList, setPairingsList] = useState<DevicePairing[]>([]);

  // Modals state
  const [staffModalVisible, setStaffModalVisible] = useState(false);
  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null);

  const [pinModalVisible, setPinModalVisible] = useState(false);
  const [tempPin, setTempPin] = useState('');
  const [targetStaffName, setTargetStaffName] = useState('');

  const [pairingModalVisible, setPairingModalVisible] = useState(false);

  useEffect(() => {
    if (activeTenant?.id) {
      fetchData();
    }
  }, [activeTenant?.id]);

  const fetchData = async (isRefresh = false) => {
    if (!activeTenant?.id) return;
    
    if (isRefresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }

    try {
      const [staffData, rolesData, pairingData] = await Promise.all([
        getStaffMembers(activeTenant.id).catch(() => []),
        getStaffRoles(activeTenant.id).catch(() => []),
        getDevicePairings(activeTenant.id).catch(() => []),
      ]);
      setStaffList(staffData);
      setRolesList(rolesData);
      setPairingsList(pairingData);
    } catch (err: any) {
      console.error('Error loading staff data:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    fetchData(true);
  };

  // Open modal for adding new staff
  const handleOpenAddStaff = () => {
    setEditingStaff(null);
    setStaffModalVisible(true);
  };

  // Open modal for editing existing staff
  const handleOpenEditStaff = (staff: StaffMember) => {
    setEditingStaff(staff);
    setStaffModalVisible(true);
  };

  // Toggle terminal access directly from list
  const handleToggleTerminal = async (staff: StaffMember) => {
    try {
      const updatedValue = !staff.allow_terminal_login;
      setStaffList((prev) =>
        prev.map((item) =>
          item.id === staff.id ? { ...item, allow_terminal_login: updatedValue } : item
        )
      );
      await updateStaffMember(staff.id, { allow_terminal_login: updatedValue });
    } catch (err: any) {
      Alert.alert('Error', 'Failed to update terminal access');
      fetchData();
    }
  };

  // Reset PIN for staff member
  const handleResetPin = async (staff: StaffMember) => {
    try {
      const pin = await resetStaffPin(staff.id);
      setTempPin(pin);
      setTargetStaffName(staff.full_name);
      setPinModalVisible(true);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to reset PIN code');
    }
  };

  return (
    <View className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      {/* Top Mobile Header */}
      <View className="bg-card border-b border-border px-4 py-3 pt-12 flex-row items-center justify-between shadow-xs">
        <View className="flex-row items-center gap-3">
          <TouchableOpacity
            onPress={() => router.back()}
            activeOpacity={0.7}
            className="w-9 h-9 rounded-full bg-muted items-center justify-center border border-border"
          >
            <ArrowLeft size={18} color={accentColor} weight="bold" />
          </TouchableOpacity>
          <View>
            <Text className="text-base font-bold text-foreground">Staff Management</Text>
            <Text className="text-[11px] text-muted-foreground">
              {activeTenant?.name || 'Workspace'}
            </Text>
          </View>
        </View>

        {staffList.length > 0 && (
          <TouchableOpacity
            onPress={handleOpenAddStaff}
            activeOpacity={0.8}
            className="bg-primary px-3.5 py-2 rounded-xl flex-row items-center gap-1.5 shadow-sm"
          >
            <UserPlus size={16} color="#ffffff" weight="bold" />
            <Text className="text-xs font-bold text-primary-foreground">Create Staff</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Main Content Area */}
      <ScrollView 
        className="flex-1 p-4" 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl 
            refreshing={refreshing} 
            onRefresh={handleRefresh} 
            tintColor={accentColor} 
          />
        }
      >
        {/* Total Staff Summary Cards */}
        <View className="flex-row gap-3 mb-4">
          <View className="flex-1 bg-card border border-border rounded-xl p-3.5 shadow-xs flex-row items-center justify-between">
            <View>
              <Text className="text-[10px] font-semibold text-muted-foreground uppercase">
                Total Staff
              </Text>
              <Text className="text-xl font-bold text-foreground mt-0.5">{staffList.length}</Text>
            </View>
            <View className="w-9 h-9 rounded-xl bg-primary/10 items-center justify-center border border-primary/20">
              <Users size={20} color={accentColor} weight="bold" />
            </View>
          </View>

          <View className="flex-1 bg-card border border-border rounded-xl p-3.5 shadow-xs flex-row items-center justify-between">
            <View>
              <Text className="text-[10px] font-semibold text-muted-foreground uppercase">
                Terminal Access
              </Text>
              <Text className="text-xl font-bold text-foreground mt-0.5">
                {staffList.filter((s) => s.allow_terminal_login).length}
              </Text>
            </View>
            <View className="w-9 h-9 rounded-xl bg-amber-500/10 items-center justify-center border border-amber-500/20">
              <ShieldCheck size={20} color="#f59e0b" weight="bold" />
            </View>
          </View>
        </View>

        {/* Loading Indicator */}
        {loading ? (
          <StaffSkeleton />
        ) : (
          /* STAFF LIST */
          <View className="gap-3 mb-8">
            {staffList.length === 0 ? (
              <View className="bg-card border border-border rounded-xl p-6 items-center">
                <View className="w-12 h-12 rounded-full bg-primary/10 items-center justify-center border border-primary/20 mb-2">
                  <Users size={24} color={accentColor} weight="bold" />
                </View>
                <Text className="text-sm font-bold text-foreground mt-1">
                  No Staff Members Found
                </Text>
                <Text className="text-xs text-muted-foreground text-center mt-1 mb-4">
                  Add staff members to assign roles & terminal PIN access.
                </Text>
                <TouchableOpacity
                  onPress={handleOpenAddStaff}
                  activeOpacity={0.8}
                  className="bg-primary px-4 py-2.5 rounded-xl flex-row items-center gap-2 shadow-sm"
                >
                  <UserPlus size={16} color="#ffffff" weight="bold" />
                  <Text className="text-xs font-bold text-primary-foreground">Create Staff</Text>
                </TouchableOpacity>
              </View>
            ) : (
              staffList.map((staff) => (
                <View
                  key={staff.id}
                  className="bg-card border border-border rounded-2xl p-4 shadow-xs mb-3"
                >
                  {/* Main Header Row - Tap to Edit */}
                  <TouchableOpacity
                    onPress={() => handleOpenEditStaff(staff)}
                    activeOpacity={0.7}
                    className="flex-row items-center justify-between mb-3 cursor-pointer"
                  >
                    <View className="flex-row items-center gap-3 flex-1 mr-2">
                      <View className="w-11 h-11 rounded-2xl bg-primary/15 items-center justify-center border border-primary/20">
                        <Text className="text-sm font-bold text-primary">
                          {staff.full_name.slice(0, 2).toUpperCase()}
                        </Text>
                      </View>

                      <View className="flex-1">
                        <Text className="text-sm font-bold text-foreground" numberOfLines={1}>
                          {staff.full_name}
                        </Text>
                        <View className="flex-row items-center gap-2 mt-1">
                          <View className="bg-primary/10 px-2 py-0.5 rounded-md border border-primary/20">
                            <Text className="text-[10px] font-semibold text-primary">
                              {staff.role}
                            </Text>
                          </View>
                          {staff.phone ? (
                            <Text className="text-xs text-muted-foreground">
                              {staff.phone}
                            </Text>
                          ) : null}
                        </View>
                      </View>
                    </View>

                    {/* Active Status Badge & Edit Indicator */}
                    <View className="flex-row items-center gap-2">
                      <View
                        className={`px-2.5 py-1 rounded-full border ${
                          staff.is_active
                            ? 'bg-emerald-500/10 border-emerald-500/20'
                            : 'bg-muted border-border'
                        }`}
                      >
                        <Text
                          className={`text-[10px] font-bold ${
                            staff.is_active
                              ? 'text-emerald-600 dark:text-emerald-400'
                              : 'text-muted-foreground'
                          }`}
                        >
                          {staff.is_active ? 'Active' : 'Inactive'}
                        </Text>
                      </View>
                      <View className="w-7 h-7 rounded-lg bg-muted items-center justify-center border border-border">
                        <PencilSimple size={14} color={accentColor} weight="bold" />
                      </View>
                    </View>
                  </TouchableOpacity>

                  {/* Bottom Control Row - Independent Switch */}
                  <View className="flex-row items-center justify-between pt-2.5 border-t border-border/60">
                    <View className="flex-row items-center gap-1.5">
                      <Text className="text-[11px] font-medium text-muted-foreground">Wallet Balance:</Text>
                      <Text className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                        ৳{(staff.current_balance || 0).toFixed(2)}
                      </Text>
                    </View>

                    <View className="flex-row items-center gap-2">
                      <Text className="text-[11px] font-medium text-muted-foreground">
                        Terminal POS Access
                      </Text>
                      <Switch
                        value={staff.allow_terminal_login}
                        onValueChange={() => handleToggleTerminal(staff)}
                        trackColor={{ false: '#94a3b8', true: accentColor }}
                        thumbColor="#ffffff"
                      />
                    </View>
                  </View>
                </View>
              ))
            )}
          </View>
        )}
      </ScrollView>

      {/* Modular Modals */}
      <StaffAddEditModal
        visible={staffModalVisible}
        onClose={() => setStaffModalVisible(false)}
        editingStaff={editingStaff}
        activeTenantId={activeTenant?.id}
        rolesList={rolesList}
        onSuccess={fetchData}
        onResetPin={handleResetPin}
        isDark={isDark}
        accentColor={accentColor}
        insets={insets}
      />

      <PinRevealModal
        visible={pinModalVisible}
        onClose={() => setPinModalVisible(false)}
        tempPin={tempPin}
        targetStaffName={targetStaffName}
        isDark={isDark}
        insets={insets}
      />

      <DevicePairingModal
        visible={pairingModalVisible}
        onClose={() => setPairingModalVisible(false)}
        activeTenantId={activeTenant?.id}
        onSuccess={fetchData}
        isDark={isDark}
        insets={insets}
      />
    </View>
  );
}
