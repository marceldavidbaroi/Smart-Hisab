import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Modal,
  Switch,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import {
  ArrowLeft,
  UserPlus,
  Key,
  DeviceMobile,
  Users,
  ShieldCheck,
  CheckCircle,
  Plus,
  PencilSimple,
  Copy,
  X,
  Phone,
  User,
  Sliders,
  Check,
  Trash,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import {
  getStaffMembers,
  createStaffMember,
  updateStaffMember,
  resetStaffPin,
  getStaffRoles,
  getDevicePairings,
  generatePairingCode,
  deleteDevicePairing,
  StaffMember,
  StaffRole,
  DevicePairing,
} from '@/services/staff';

type TabType = 'staff' | 'roles' | 'keys';

export default function StaffManagementScreen() {
  const router = useRouter();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const [activeTab, setActiveTab] = useState<TabType>('staff');
  const [loading, setLoading] = useState(true);

  // Data states
  const [staffList, setStaffList] = useState<StaffMember[]>([]);
  const [rolesList, setRolesList] = useState<StaffRole[]>([]);
  const [pairingsList, setPairingsList] = useState<DevicePairing[]>([]);

  // Add / Edit Staff Modal state
  const [staffModalVisible, setStaffModalVisible] = useState(false);
  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null);
  const [formName, setFormName] = useState('');
  const [formPhone, setFormPhone] = useState('');
  const [formRole, setFormRole] = useState('Staff');
  const [formTerminalAccess, setFormTerminalAccess] = useState(true);
  const [formIsActive, setFormIsActive] = useState(true);
  const [submittingStaff, setSubmittingStaff] = useState(false);

  // PIN Reveal Modal state
  const [pinModalVisible, setPinModalVisible] = useState(false);
  const [tempPin, setTempPin] = useState('');
  const [targetStaffName, setTargetStaffName] = useState('');

  // Device Pairing Modal state
  const [pairingModalVisible, setPairingModalVisible] = useState(false);
  const [deviceNameInput, setDeviceNameInput] = useState('');
  const [generatedCode, setGeneratedCode] = useState('');
  const [generatingCode, setGeneratingCode] = useState(false);

  useEffect(() => {
    if (activeTenant?.id) {
      fetchData();
    }
  }, [activeTenant?.id]);

  const fetchData = async () => {
    if (!activeTenant?.id) return;
    setLoading(true);
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
    }
  };

  // Open modal for adding new staff
  const handleOpenAddStaff = () => {
    setEditingStaff(null);
    setFormName('');
    setFormPhone('');
    setFormRole(rolesList[0]?.name || 'Staff');
    setFormTerminalAccess(true);
    setFormIsActive(true);
    setStaffModalVisible(true);
  };

  // Open modal for editing existing staff
  const handleOpenEditStaff = (staff: StaffMember) => {
    setEditingStaff(staff);
    setFormName(staff.full_name);
    setFormPhone(staff.phone || '');
    setFormRole(staff.role || 'Staff');
    setFormTerminalAccess(staff.allow_terminal_login);
    setFormIsActive(staff.is_active);
    setStaffModalVisible(true);
  };

  // Submit staff form (Create or Update)
  const handleSubmitStaff = async () => {
    if (!activeTenant?.id) return;
    if (!formName.trim()) {
      Alert.alert('Validation Error', 'Please enter staff full name');
      return;
    }

    setSubmittingStaff(true);
    try {
      if (editingStaff) {
        await updateStaffMember(editingStaff.id, {
          full_name: formName.trim(),
          phone: formPhone.trim(),
          role: formRole,
          allow_terminal_login: formTerminalAccess,
          is_active: formIsActive,
        });
      } else {
        await createStaffMember({
          tenant_id: activeTenant.id,
          full_name: formName.trim(),
          phone: formPhone.trim(),
          role: formRole,
          allow_terminal_login: formTerminalAccess,
        });
      }
      setStaffModalVisible(false);
      fetchData();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to save staff member');
    } finally {
      setSubmittingStaff(false);
    }
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

  // Generate Device Pairing Key
  const handleGenerateKey = async () => {
    if (!activeTenant?.id) return;
    if (!deviceNameInput.trim()) {
      Alert.alert('Validation Error', 'Please enter a device name (e.g. Counter 1 POS)');
      return;
    }

    setGeneratingCode(true);
    try {
      const code = await generatePairingCode(activeTenant.id, deviceNameInput.trim());
      setGeneratedCode(code);
      fetchData();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to generate pairing code');
    } finally {
      setGeneratingCode(false);
    }
  };

  const handleDeletePairingKey = (id: string, isPairedDevice?: boolean) => {
    Alert.alert(
      'Remove Device Pairing',
      isPairedDevice
        ? 'Disconnect this paired terminal hardware device?'
        : 'Revoke this 6-digit device pairing key?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteDevicePairing(id, isPairedDevice);
              fetchData();
            } catch (err: any) {
              Alert.alert('Error', err.message || 'Failed to remove device');
            }
          },
        },
      ]
    );
  };

  const formatPairingCode = (code: string) => {
    if (code.length === 6) {
      return `${code.slice(0, 3)} ${code.slice(3)}`;
    }
    return code;
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
            <Text className="text-base font-bold text-foreground">Staff & Access Keys</Text>
            <Text className="text-[11px] text-muted-foreground">
              {activeTenant?.name || 'Workspace'}
            </Text>
          </View>
        </View>

        <TouchableOpacity
          onPress={handleOpenAddStaff}
          activeOpacity={0.8}
          className="bg-primary px-3.5 py-2 rounded-xl flex-row items-center gap-1.5 shadow-sm"
        >
          <UserPlus size={16} color="#ffffff" weight="bold" />
          <Text className="text-xs font-bold text-primary-foreground">Add Staff</Text>
        </TouchableOpacity>
      </View>

      {/* Main Content Area */}
      <ScrollView className="flex-1 p-4" showsVerticalScrollIndicator={false}>
        {/* Quick Summary Cards */}
        <View className="flex-row gap-2.5 mb-4">
          <View className="flex-1 bg-card border border-border rounded-xl p-3 shadow-xs">
            <Text className="text-[10px] font-semibold text-muted-foreground uppercase">
              Total Staff
            </Text>
            <Text className="text-lg font-bold text-foreground mt-0.5">{staffList.length}</Text>
          </View>

          <View className="flex-1 bg-card border border-border rounded-xl p-3 shadow-xs">
            <Text className="text-[10px] font-semibold text-muted-foreground uppercase">
              Terminal Access
            </Text>
            <Text className="text-lg font-bold text-foreground mt-0.5">
              {staffList.filter((s) => s.allow_terminal_login).length}
            </Text>
          </View>

          <View className="flex-1 bg-card border border-border rounded-xl p-3 shadow-xs">
            <Text className="text-[10px] font-semibold text-muted-foreground uppercase">
              Paired Devices
            </Text>
            <Text className="text-lg font-bold text-foreground mt-0.5">{pairingsList.length}</Text>
          </View>
        </View>

        {/* Segmented Control Tabs */}
        <View className="flex-row bg-muted rounded-xl p-1 mb-4 border border-border">
          <TouchableOpacity
            onPress={() => setActiveTab('staff')}
            activeOpacity={0.7}
            className={`flex-1 py-2 rounded-lg items-center ${
              activeTab === 'staff' ? 'bg-card shadow-xs' : ''
            }`}
          >
            <Text
              className={`text-xs font-bold ${
                activeTab === 'staff' ? 'text-foreground' : 'text-muted-foreground'
              }`}
            >
              Staff ({staffList.length})
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setActiveTab('roles')}
            activeOpacity={0.7}
            className={`flex-1 py-2 rounded-lg items-center ${
              activeTab === 'roles' ? 'bg-card shadow-xs' : ''
            }`}
          >
            <Text
              className={`text-xs font-bold ${
                activeTab === 'roles' ? 'text-foreground' : 'text-muted-foreground'
              }`}
            >
              Roles ({rolesList.length})
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setActiveTab('keys')}
            activeOpacity={0.7}
            className={`flex-1 py-2 rounded-lg items-center ${
              activeTab === 'keys' ? 'bg-card shadow-xs' : ''
            }`}
          >
            <Text
              className={`text-xs font-bold ${
                activeTab === 'keys' ? 'text-foreground' : 'text-muted-foreground'
              }`}
            >
              Device Keys ({pairingsList.length})
            </Text>
          </TouchableOpacity>
        </View>

        {/* Loading Indicator */}
        {loading ? (
          <View className="py-12 items-center justify-center">
            <ActivityIndicator size="large" color={accentColor} />
            <Text className="text-xs text-muted-foreground mt-2">Loading staff data...</Text>
          </View>
        ) : (
          <>
            {/* TAB 1: STAFF LIST */}
            {activeTab === 'staff' && (
              <View className="gap-3 mb-8">
                {staffList.length === 0 ? (
                  <View className="bg-card border border-border rounded-xl p-6 items-center">
                    <Users size={32} color={accentColor} weight="bold" />
                    <Text className="text-sm font-bold text-foreground mt-2">
                      No Staff Members Found
                    </Text>
                    <Text className="text-xs text-muted-foreground text-center mt-1">
                      Add staff members to grant terminal access and POS permissions.
                    </Text>
                  </View>
                ) : (
                  staffList.map((staff) => (
                    <View
                      key={staff.id}
                      className="bg-card border border-border rounded-xl p-4 shadow-xs flex-row items-center justify-between"
                    >
                      <View className="flex-1 flex-row items-center gap-3">
                        <View className="w-10 h-10 rounded-full bg-primary/15 items-center justify-center border border-primary/20">
                          <Text className="text-sm font-bold text-primary">
                            {staff.full_name.slice(0, 2).toUpperCase()}
                          </Text>
                        </View>
                        <View className="flex-1">
                          <View className="flex-row items-center gap-2">
                            <Text className="text-sm font-bold text-foreground">
                              {staff.full_name}
                            </Text>
                            <View className="bg-primary/10 px-2 py-0.5 rounded-full border border-primary/20">
                              <Text className="text-[10px] font-semibold text-primary">
                                {staff.role}
                              </Text>
                            </View>
                          </View>
                          {staff.phone ? (
                            <Text className="text-xs text-muted-foreground mt-0.5">
                              {staff.phone}
                            </Text>
                          ) : null}
                        </View>
                      </View>

                      {/* Right Action Icons & Toggle */}
                      <View className="flex-row items-center gap-2">
                        {staff.allow_terminal_login && (
                          <TouchableOpacity
                            onPress={() => handleResetPin(staff)}
                            activeOpacity={0.7}
                            className="w-8 h-8 rounded-lg bg-amber-500/10 items-center justify-center border border-amber-500/20"
                          >
                            <Key size={16} color="#f59e0b" weight="bold" />
                          </TouchableOpacity>
                        )}

                        <TouchableOpacity
                          onPress={() => handleOpenEditStaff(staff)}
                          activeOpacity={0.7}
                          className="w-8 h-8 rounded-lg bg-muted items-center justify-center border border-border"
                        >
                          <PencilSimple size={16} color={accentColor} weight="bold" />
                        </TouchableOpacity>

                        <Switch
                          value={staff.allow_terminal_login}
                          onValueChange={() => handleToggleTerminal(staff)}
                          trackColor={{ false: '#94a3b8', true: accentColor }}
                          thumbColor="#ffffff"
                        />
                      </View>
                    </View>
                  ))
                )}
              </View>
            )}

            {/* TAB 2: ROLES */}
            {activeTab === 'roles' && (
              <View className="gap-3 mb-8">
                {rolesList.length === 0 ? (
                  <View className="bg-card border border-border rounded-xl p-6 items-center">
                    <Sliders size={32} color={accentColor} weight="bold" />
                    <Text className="text-sm font-bold text-foreground mt-2">
                      No Staff Roles Defined
                    </Text>
                    <Text className="text-xs text-muted-foreground text-center mt-1">
                      Roles define permissions for POS operations and shift tracking.
                    </Text>
                  </View>
                ) : (
                  rolesList.map((role) => {
                    const count = staffList.filter((s) => s.role === role.name).length;
                    return (
                      <View
                        key={role.id}
                        className="bg-card border border-border rounded-xl p-4 shadow-xs flex-row items-center justify-between"
                      >
                        <View className="flex-1">
                          <View className="flex-row items-center gap-2">
                            <Text className="text-sm font-bold text-foreground">{role.name}</Text>
                            {role.is_system_role && (
                              <View className="bg-muted px-2 py-0.5 rounded-full border border-border">
                                <Text className="text-[10px] font-semibold text-muted-foreground">
                                  System
                                </Text>
                              </View>
                            )}
                          </View>
                          {role.description ? (
                            <Text className="text-xs text-muted-foreground mt-1">
                              {role.description}
                            </Text>
                          ) : null}
                        </View>

                        <View className="bg-primary/10 px-3 py-1 rounded-lg border border-primary/20">
                          <Text className="text-xs font-bold text-primary">{count} Staff</Text>
                        </View>
                      </View>
                    );
                  })
                )}
              </View>
            )}

            {/* TAB 3: DEVICE PAIRING KEYS */}
            {activeTab === 'keys' && (
              <View className="gap-3 mb-8">
                <TouchableOpacity
                  onPress={() => {
                    setDeviceNameInput('');
                    setGeneratedCode('');
                    setPairingModalVisible(true);
                  }}
                  activeOpacity={0.8}
                  className="bg-card border border-dashed border-primary/40 rounded-xl p-4 items-center justify-center flex-row gap-2 shadow-xs mb-2"
                >
                  <DeviceMobile size={20} color={accentColor} weight="bold" />
                  <Text className="text-xs font-bold text-primary">Pair New POS Terminal Device</Text>
                </TouchableOpacity>

                {pairingsList.length === 0 ? (
                  <View className="bg-card border border-border rounded-xl p-6 items-center">
                    <Key size={32} color={accentColor} weight="bold" />
                    <Text className="text-sm font-bold text-foreground mt-2">
                      No Paired Devices
                    </Text>
                    <Text className="text-xs text-muted-foreground text-center mt-1">
                      Generate pairing keys to link tablet or phone POS hardware.
                    </Text>
                  </View>
                ) : (
                  pairingsList.map((pairing) => (
                    <View
                      key={pairing.id}
                      className="bg-card border border-border rounded-xl p-4 shadow-xs flex-row items-center justify-between"
                    >
                      <View className="flex-1">
                        <Text className="text-sm font-bold text-foreground">
                          {pairing.device_name}
                        </Text>
                        <Text className="text-xs font-mono text-muted-foreground mt-0.5">
                          Key: {formatPairingCode(pairing.pairing_code)}
                        </Text>
                      </View>

                      <View className="flex-row items-center gap-2">
                        <View
                          className={`px-2.5 py-1 rounded-full border ${
                            pairing.status === 'active' || pairing.status === 'paired'
                              ? 'bg-green-500/10 border-green-500/20'
                              : 'bg-amber-500/10 border-amber-500/20'
                          }`}
                        >
                          <Text
                            className={`text-[10px] font-bold uppercase ${
                              pairing.status === 'active' || pairing.status === 'paired'
                                ? 'text-green-600 dark:text-green-400'
                                : 'text-amber-600 dark:text-amber-400'
                            }`}
                          >
                            {pairing.status}
                          </Text>
                        </View>

                        <TouchableOpacity
                          activeOpacity={0.7}
                          onPress={() => handleDeletePairingKey(pairing.id, pairing.is_paired_device)}
                          className="w-8 h-8 rounded-lg bg-destructive/10 border border-destructive/20 items-center justify-center min-h-[32px]"
                        >
                          <Trash size={15} color="#ef4444" weight="bold" />
                        </TouchableOpacity>
                      </View>
                    </View>
                  ))
                )}
              </View>
            )}
          </>
        )}
      </ScrollView>

      {/* 1. ADD / EDIT STAFF MODAL */}
      <Modal
        visible={staffModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setStaffModalVisible(false)}
      >
        <View className="flex-1 bg-black/60 justify-center p-4">
          <View className="bg-card border border-border rounded-2xl p-5 shadow-xl">
            <View className="flex-row items-center justify-between mb-4 border-b border-border pb-3">
              <Text className="text-base font-bold text-foreground">
                {editingStaff ? 'Edit Staff Member' : 'Add New Staff'}
              </Text>
              <TouchableOpacity onPress={() => setStaffModalVisible(false)}>
                <X size={20} color={accentColor} weight="bold" />
              </TouchableOpacity>
            </View>

            {/* Input Name */}
            <View className="mb-3">
              <Text className="text-xs font-semibold text-muted-foreground mb-1">Full Name</Text>
              <TextInput
                value={formName}
                onChangeText={setFormName}
                placeholder="e.g. Rahat Ahmed"
                placeholderTextColor="#94a3b8"
                className="bg-muted border border-border rounded-xl px-3.5 py-2.5 text-sm text-foreground"
              />
            </View>

            {/* Input Phone */}
            <View className="mb-3">
              <Text className="text-xs font-semibold text-muted-foreground mb-1">Phone Number</Text>
              <TextInput
                value={formPhone}
                onChangeText={setFormPhone}
                placeholder="e.g. 01700000000"
                keyboardType="phone-pad"
                placeholderTextColor="#94a3b8"
                className="bg-muted border border-border rounded-xl px-3.5 py-2.5 text-sm text-foreground"
              />
            </View>

            {/* Role Selection Pills */}
            <View className="mb-4">
              <Text className="text-xs font-semibold text-muted-foreground mb-1.5">Assign Role</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} className="flex-row gap-2">
                {(rolesList.length > 0 ? rolesList.map((r) => r.name) : ['Staff', 'Cashier', 'Manager']).map(
                  (roleName) => (
                    <TouchableOpacity
                      key={roleName}
                      onPress={() => setFormRole(roleName)}
                      activeOpacity={0.7}
                      className={`px-3 py-1.5 rounded-lg border ${
                        formRole === roleName
                          ? 'bg-primary border-primary'
                          : 'bg-muted border-border'
                      }`}
                    >
                      <Text
                        className={`text-xs font-bold ${
                          formRole === roleName ? 'text-primary-foreground' : 'text-foreground'
                        }`}
                      >
                        {roleName}
                      </Text>
                    </TouchableOpacity>
                  )
                )}
              </ScrollView>
            </View>

            {/* Terminal Login Access Toggle */}
            <View className="flex-row items-center justify-between mb-4 bg-muted/60 p-3 rounded-xl border border-border">
              <View className="flex-1 mr-2">
                <Text className="text-xs font-bold text-foreground">Allow Terminal Login</Text>
                <Text className="text-[10px] text-muted-foreground">
                  Enables 4-digit PIN login on POS device kiosks.
                </Text>
              </View>
              <Switch
                value={formTerminalAccess}
                onValueChange={setFormTerminalAccess}
                trackColor={{ false: '#94a3b8', true: accentColor }}
                thumbColor="#ffffff"
              />
            </View>

            {/* Action Buttons */}
            <View className="flex-row gap-2 mt-2">
              <TouchableOpacity
                onPress={() => setStaffModalVisible(false)}
                activeOpacity={0.7}
                className="flex-1 bg-muted border border-border py-3 rounded-xl items-center"
              >
                <Text className="text-xs font-bold text-foreground">Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                onPress={handleSubmitStaff}
                disabled={submittingStaff}
                activeOpacity={0.8}
                className="flex-1 bg-primary py-3 rounded-xl items-center flex-row justify-center gap-2"
              >
                {submittingStaff ? (
                  <ActivityIndicator size="small" color="#ffffff" />
                ) : (
                  <Text className="text-xs font-bold text-primary-foreground">
                    {editingStaff ? 'Save Changes' : 'Create Staff'}
                  </Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* 2. PIN REVEAL MODAL */}
      <Modal
        visible={pinModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setPinModalVisible(false)}
      >
        <View className="flex-1 bg-black/60 justify-center p-4">
          <View className="bg-card border border-border rounded-2xl p-6 shadow-xl items-center">
            <View className="w-12 h-12 rounded-full bg-amber-500/15 items-center justify-center border border-amber-500/20 mb-3">
              <Key size={24} color="#f59e0b" weight="bold" />
            </View>

            <Text className="text-base font-bold text-foreground text-center">
              Temporary Terminal PIN
            </Text>
            <Text className="text-xs text-muted-foreground text-center mt-1 mb-4">
              Generated for <Text className="font-bold text-foreground">{targetStaffName}</Text>
            </Text>

            <View className="bg-muted border border-border px-6 py-3 rounded-2xl mb-4">
              <Text className="text-3xl font-mono font-bold text-primary tracking-widest">
                {tempPin}
              </Text>
            </View>

            <Text className="text-[11px] text-amber-600 dark:text-amber-400 font-semibold text-center mb-6">
              Write this down. This PIN code will not be shown again.
            </Text>

            <TouchableOpacity
              onPress={() => setPinModalVisible(false)}
              activeOpacity={0.8}
              className="bg-primary w-full py-3 rounded-xl items-center"
            >
              <Text className="text-xs font-bold text-primary-foreground">Got It</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* 3. DEVICE PAIRING KEY MODAL */}
      <Modal
        visible={pairingModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setPairingModalVisible(false)}
      >
        <View className="flex-1 bg-black/60 justify-center p-4">
          <View className="bg-card border border-border rounded-2xl p-5 shadow-xl">
            <View className="flex-row items-center justify-between mb-4 border-b border-border pb-3">
              <Text className="text-base font-bold text-foreground">Pair POS Device</Text>
              <TouchableOpacity onPress={() => setPairingModalVisible(false)}>
                <X size={20} color={accentColor} weight="bold" />
              </TouchableOpacity>
            </View>

            {!generatedCode ? (
              <>
                <Text className="text-xs text-muted-foreground mb-3">
                  Enter a identifier name for your hardware terminal (e.g., Counter Tablet).
                </Text>

                <View className="mb-4">
                  <Text className="text-xs font-semibold text-muted-foreground mb-1">
                    Device Name
                  </Text>
                  <TextInput
                    value={deviceNameInput}
                    onChangeText={setDeviceNameInput}
                    placeholder="e.g. Front Desk POS"
                    placeholderTextColor="#94a3b8"
                    className="bg-muted border border-border rounded-xl px-3.5 py-2.5 text-sm text-foreground"
                  />
                </View>

                <TouchableOpacity
                  onPress={handleGenerateKey}
                  disabled={generatingCode}
                  activeOpacity={0.8}
                  className="bg-primary w-full py-3 rounded-xl items-center flex-row justify-center gap-2"
                >
                  {generatingCode ? (
                    <ActivityIndicator size="small" color="#ffffff" />
                  ) : (
                    <Text className="text-xs font-bold text-primary-foreground">
                      Generate 6-Digit Pairing Key
                    </Text>
                  )}
                </TouchableOpacity>
              </>
            ) : (
              <View className="items-center py-2">
                <Text className="text-xs text-muted-foreground text-center mb-2">
                  Enter this code on the device screen for <Text className="font-bold text-foreground">{deviceNameInput}</Text>:
                </Text>

                <View className="bg-muted border border-border px-6 py-3 rounded-2xl my-3">
                  <Text className="text-3xl font-mono font-bold text-primary tracking-widest">
                    {formatPairingCode(generatedCode)}
                  </Text>
                </View>

                <TouchableOpacity
                  onPress={() => setPairingModalVisible(false)}
                  activeOpacity={0.8}
                  className="bg-primary w-full py-3 rounded-xl items-center mt-4"
                >
                  <Text className="text-xs font-bold text-primary-foreground">Done</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </View>
  );
}
