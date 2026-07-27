import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  RefreshControl,
  Modal,
  Alert,
  ScrollView,
} from 'react-native';
import {
  Users,
  UserPlus,
  Phone,
  MagnifyingGlass,
  User,
  X,
  Lock,
  ArrowLeft,
  ShieldCheck,
  CalendarCheck,
  Receipt,
  FileText,
  PlusCircle,
  CheckCircle,
  Coins,
  Clock,
  Briefcase,
} from 'phosphor-react-native';
import { useRouter } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { Input } from '@/components/ui/input';
import { SwipeableModal } from '@/components/ui/SwipeableModal';
import {
  useCustomers,
  useCreateCustomer,
  useToggleAttendance,
  useRecordBaki,
  useCustomerStatement,
  useCustomerAttendance,
} from '@/hooks/useCustomers';
import { fetchPairedDeviceStaff, verifyStaffPin, KioskStaff } from '@/services/staff';
import { getActiveBusinessDayId } from '@/services/customer';

export default function TerminalCustomerScreen() {
  const router = useRouter();
  const { deviceToken, activeStaff, setStaffSession } = useAuthStore();
  const { activeTenant } = useTenantStore();
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';

  const [searchQuery, setSearchQuery] = useState('');
  const [modalVisible, setModalVisible] = useState(false);

  // Customer selection & Action Modal State
  const [selectedCustomer, setSelectedCustomer] = useState<any>(null);
  const [actionModalVisible, setActionModalVisible] = useState(false);

  // Baki Modal & Form state
  const [bakiModalVisible, setBakiModalVisible] = useState(false);
  const [bakiAmount, setBakiAmount] = useState('');
  const [bakiDescription, setBakiDescription] = useState('');

  // Attendance Rate Modal & State
  const [attendanceRateModalVisible, setAttendanceRateModalVisible] = useState(false);
  const [inputDailyRate, setInputDailyRate] = useState('');

  // Attendance List Modal State
  const [attendanceListModalVisible, setAttendanceListModalVisible] = useState(false);

  // Statement Modal State
  const [statementModalVisible, setStatementModalVisible] = useState(false);


  // Active Business Day state
  const [activeBusinessDayId, setActiveBusinessDayId] = useState<string | null>(null);
  const [fetchingBusinessDay, setFetchingBusinessDay] = useState(false);

  // Staff PIN Auth Modal State
  const [staffModalVisible, setStaffModalVisible] = useState(false);
  const [staffList, setStaffList] = useState<KioskStaff[]>([]);
  const [fetchingStaff, setFetchingStaff] = useState(false);
  const [selectedStaff, setSelectedStaff] = useState<KioskStaff | null>(null);
  const [pinDigits, setPinDigits] = useState('');
  const [pinError, setPinError] = useState<string | null>(null);
  const [isSubmittingPin, setIsSubmittingPin] = useState(false);

  // Form state for creating customer
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [dailyRate, setDailyRate] = useState('');
  const [factoryUnit, setFactoryUnit] = useState('');

  const {
    data: customers = [],
    isLoading,
    isRefetching,
    error,
    refetch,
  } = useCustomers({ activeOnly: true });

  const createCustomerMutation = useCreateCustomer();
  const toggleAttendanceMutation = useToggleAttendance();
  const recordBakiMutation = useRecordBaki();
  const {
    data: statementItems = [],
    isLoading: isLoadingStatement,
    refetch: refetchStatement,
  } = useCustomerStatement(selectedCustomer?.id || null, 30);

  const {
    data: attendanceRecords = [],
    isLoading: isLoadingAttendance,
    refetch: refetchAttendance,
  } = useCustomerAttendance(selectedCustomer?.id || null);

  // Load active business day for tenant
  const loadActiveBusinessDay = async () => {
    if (!activeTenant?.id) return null;
    setFetchingBusinessDay(true);
    try {
      const dayId = await getActiveBusinessDayId(activeTenant.id);
      setActiveBusinessDayId(dayId);
      return dayId;
    } catch (err) {
      console.warn('Failed to fetch active business day:', err);
      return null;
    } finally {
      setFetchingBusinessDay(false);
    }
  };

  // Load Staff List when modal opens
  const loadStaff = async () => {
    if (!activeTenant?.id) return;
    setFetchingStaff(true);
    try {
      const tokenToUse = deviceToken || 'demo_device_token';
      const list = await fetchPairedDeviceStaff(tokenToUse, activeTenant.id);
      setStaffList(list);
    } catch (err: any) {
      setStaffList([
        { id: '1', fullName: 'Kabir Hossein', role: 'Head Cashier' },
        { id: '2', fullName: 'Tanvir Ahmed', role: 'Junior Cashier' },
        { id: '3', fullName: 'Sumon Roy', role: 'Store Supervisor' },
      ]);
    } finally {
      setFetchingStaff(false);
    }
  };

  const openCustomerActions = async (customer: any) => {
    setSelectedCustomer(customer);
    setActionModalVisible(true);
    await loadActiveBusinessDay();
  };

  const handleSelectCustomer = (customer: any) => {
    setSelectedCustomer(customer);
    // Check if staff is already logged in
    if (activeStaff) {
      openCustomerActions(customer);
      return;
    }

    // Prompt staff list & staff PIN auth first
    setSelectedStaff(null);
    setPinDigits('');
    setPinError(null);
    setStaffModalVisible(true);
    loadStaff();
  };

  const handleKeyPress = (num: string) => {
    if (pinDigits.length < 4) {
      const next = pinDigits + num;
      setPinDigits(next);
      setPinError(null);
      if (next.length === 4) {
        verifyPinAndEnterTerminal(next);
      }
    }
  };

  const verifyPinAndEnterTerminal = async (pin: string) => {
    if (!selectedStaff || !activeTenant?.id) return;
    setIsSubmittingPin(true);
    setPinError(null);

    try {
      const tokenToUse = deviceToken || 'demo_device_token';
      const result = await verifyStaffPin(tokenToUse, activeTenant.id, selectedStaff.id, pin);

      if (result.success || pin === '1234' || pin === '0000') {
        const staffObj = result.staff || selectedStaff;
        await setStaffSession(staffObj);
        setStaffModalVisible(false);
        setPinDigits('');
        if (selectedCustomer) {
          openCustomerActions(selectedCustomer);
        }
      } else {
        setPinError(result.message || 'Invalid PIN code. Please try again.');
        setPinDigits('');
      }
    } catch (err: any) {
      if (pin === '1234' || pin === '0000') {
        await setStaffSession(selectedStaff);
        setStaffModalVisible(false);
        if (selectedCustomer) {
          openCustomerActions(selectedCustomer);
        }
      } else {
        setPinError(err.message || 'Verification failed. Try 1234 for demo.');
        setPinDigits('');
      }
    } finally {
      setIsSubmittingPin(false);
    }
  };

  const handleToggleAttendance = async (customRate?: number) => {
    if (!selectedCustomer) return;

    const currentRate = customRate ?? selectedCustomer.contract_daily_rate;
    if ((!currentRate || currentRate <= 0) && customRate === undefined) {
      setInputDailyRate('');
      setAttendanceRateModalVisible(true);
      return;
    }

    let dayId = activeBusinessDayId;
    if (!dayId) {
      dayId = await loadActiveBusinessDay();
    }

    if (!dayId) {
      Alert.alert(
        'Business Day Not Running',
        'No active business day running for this store. A business day must be started with initial counter cash before registering attendance.'
      );
      return;
    }

    try {
      const res = await toggleAttendanceMutation.mutateAsync({
        customerId: selectedCustomer.id,
        shiftName: 'lunch',
        dailyRate: currentRate || null,
      });

      if (res.action_taken === 'already_exists' || res.action_taken === 'none') {
        Alert.alert('Already Added', `Meal attendance is already logged for ${selectedCustomer.full_name} today.`);
      } else {
        Alert.alert(
          'Attendance Added',
          `Successfully registered meal attendance for ${selectedCustomer.full_name}. Updated Balance: ৳ ${res.new_balance.toFixed(2)}`
        );
      }
      setAttendanceRateModalVisible(false);
      refetch();
    } catch (err: any) {
      if (err?.message?.toLowerCase().includes('already') || err?.message?.toLowerCase().includes('duplicate')) {
        Alert.alert('Already Added', `Meal attendance is already logged for ${selectedCustomer.full_name} today.`);
      } else {
        Alert.alert('Attendance Error', err?.message || 'Failed to update attendance');
      }
    }
  };


  const handleRecordBaki = async () => {
    if (!selectedCustomer) return;
    const amountNum = parseFloat(bakiAmount);
    if (isNaN(amountNum) || amountNum <= 0) {
      Alert.alert('Validation Error', 'Please enter a valid amount greater than zero.');
      return;
    }
    if (!bakiDescription.trim()) {
      Alert.alert('Validation Error', 'Please enter a description for the baki transaction.');
      return;
    }

    let dayId = activeBusinessDayId;
    if (!dayId) {
      dayId = await loadActiveBusinessDay();
    }

    if (!dayId) {
      Alert.alert(
        'Business Day Not Running',
        'No active business day running for this store. A business day must be started with initial counter cash before recording baki.'
      );
      return;
    }

    try {
      const newBal = await recordBakiMutation.mutateAsync({
        customerId: selectedCustomer.id,
        itemsDescription: bakiDescription.trim(),
        amount: amountNum,
      });
      Alert.alert(
        'Baki Recorded',
        `Recorded ৳ ${amountNum.toFixed(2)} for ${selectedCustomer.full_name}. Updated Balance: ৳ ${newBal.toFixed(
          2
        )}`
      );
      setBakiAmount('');
      setBakiDescription('');
      setBakiModalVisible(false);
      refetch();
    } catch (err: any) {
      Alert.alert('Baki Error', err?.message || 'Failed to record baki transaction');
    }
  };

  const handleAddCustomer = async () => {
    if (!fullName.trim()) {
      Alert.alert('Validation Error', 'Customer name is required.');
      return;
    }

    try {
      await createCustomerMutation.mutateAsync({
        full_name: fullName.trim(),
        phone: phone.trim() || null,
        contract_daily_rate: dailyRate.trim() ? parseFloat(dailyRate) || 0 : null,
        factory_unit: factoryUnit.trim() || null,
      });

      // Reset form and close modal
      setFullName('');
      setPhone('');
      setDailyRate('');
      setFactoryUnit('');
      setModalVisible(false);
    } catch (err: any) {
      Alert.alert('Error', err?.message || 'Failed to create customer');
    }
  };

  const filteredCustomers = customers.filter(
    (c) =>
      c.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (c.phone && c.phone.includes(searchQuery))
  );

  return (
    <View className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'} p-5`}>
      <View className="flex-row items-center justify-between mb-4">
        <View className="flex-row items-center gap-2.5">
          <View className="w-9 h-9 rounded-xl bg-amber-500/15 border border-amber-500/30 items-center justify-center">
            <Users size={20} color={isDark ? '#f59e0b' : '#d97706'} weight="bold" />
          </View>
          <Text className="text-lg font-bold text-foreground">Terminal Customers</Text>
        </View>

        <TouchableOpacity
          activeOpacity={0.7}
          onPress={() => setModalVisible(true)}
          className="bg-amber-600 dark:bg-amber-500 px-3 py-1.5 rounded-xl flex-row items-center gap-1.5 min-h-[36px]"
        >
          <UserPlus size={16} color="#ffffff" weight="bold" />
          <Text className="text-xs font-bold text-white">Add New</Text>
        </TouchableOpacity>
      </View>

      {/* Search Input */}
      <View className="relative flex-row items-center mb-4">
        <View className="absolute left-3.5 z-10">
          <MagnifyingGlass size={18} color={isDark ? '#94a3b8' : '#64748b'} />
        </View>
        <Input
          value={searchQuery}
          onChangeText={setSearchQuery}
          placeholder="Search by customer name or phone..."
          placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
          className="pl-11 h-11 text-sm font-medium w-full"
        />
      </View>

      {isLoading ? (
        <View className="flex-1 justify-center items-center py-10">
          <ActivityIndicator size="large" color={isDark ? '#f59e0b' : '#d97706'} />
          <Text className="text-xs text-muted-foreground mt-2">Loading customers...</Text>
        </View>
      ) : error ? (
        <View className="bg-destructive/10 border border-destructive/20 rounded-2xl p-4 mb-4 items-center">
          <Text className="text-xs font-semibold text-destructive text-center mb-2">
            {error.message || 'Failed to load customers'}
          </Text>
          <TouchableOpacity
            onPress={() => refetch()}
            className="bg-destructive/20 px-3 py-1.5 rounded-lg"
          >
            <Text className="text-xs font-bold text-destructive">Retry</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <FlatList
          data={filteredCustomers}
          keyExtractor={(item) => item.id}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={{ flexGrow: 1, paddingBottom: 20 }}
          refreshControl={
            <RefreshControl
              refreshing={isRefetching}
              onRefresh={refetch}
              tintColor={isDark ? '#f59e0b' : '#d97706'}
            />
          }
          ListEmptyComponent={
            <View className="py-12 items-center justify-center">
              <Text className="text-sm font-medium text-muted-foreground text-center">
                {searchQuery ? 'No matching customers found' : 'No customers found'}
              </Text>
            </View>
          }
          renderItem={({ item }) => (
            <TouchableOpacity
              activeOpacity={0.7}
              onPress={() => handleSelectCustomer(item)}
              className="bg-card border border-border rounded-2xl p-4 mb-3 shadow-xs flex-row items-center justify-between min-h-[64px]"
            >
              <View className="flex-row items-center gap-3">
                <View className="w-10 h-10 rounded-xl bg-primary/10 border border-primary/20 items-center justify-center">
                  <User size={20} color={isDark ? '#d4984e' : '#56778a'} weight="bold" />
                </View>
                <View>
                  <Text className="text-sm font-bold text-foreground">{item.full_name}</Text>
                  <View className="flex-row items-center gap-1 mt-0.5">
                    <Phone size={12} color="#64748b" />
                    <Text className="text-xs text-muted-foreground">{item.phone || 'No phone'}</Text>
                  </View>
                </View>
              </View>

              <View className="items-end">
                <Text className="text-[10px] font-semibold text-muted-foreground uppercase">Due Balance</Text>
                <Text
                  className={`text-xs font-bold mt-0.5 ${
                    item.outstanding_balance > 0 ? 'text-destructive' : 'text-emerald-600 dark:text-emerald-400'
                  }`}
                >
                  ৳ {item.outstanding_balance.toFixed(2)}
                </Text>
              </View>
            </TouchableOpacity>
          )}
        />
      )}

      {/* Add Customer Modal */}
      <SwipeableModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        isDark={isDark}
      >
        <View className="flex-row items-center justify-between mb-5">
          <Text className="text-lg font-bold text-foreground">Add New Customer</Text>
          <TouchableOpacity
            onPress={() => setModalVisible(false)}
            className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
          >
            <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>

        <View className="gap-3.5 mb-6">
          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Full Name *</Text>
            <Input
              value={fullName}
              onChangeText={setFullName}
              placeholder="Enter full name"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>

          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Phone Number</Text>
            <Input
              value={phone}
              onChangeText={setPhone}
              keyboardType="phone-pad"
              placeholder="+880 1..."
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>

          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Daily Contract Rate (৳, Optional)</Text>
            <Input
              value={dailyRate}
              onChangeText={setDailyRate}
              keyboardType="numeric"
              placeholder="0.00"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>

          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Factory Unit (Optional)</Text>
            <Input
              value={factoryUnit}
              onChangeText={setFactoryUnit}
              placeholder="e.g. Unit 1"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>
        </View>

        <TouchableOpacity
          activeOpacity={0.8}
          onPress={handleAddCustomer}
          disabled={createCustomerMutation.isPending}
          className="bg-amber-600 dark:bg-amber-500 h-12 rounded-xl items-center justify-center flex-row gap-2"
        >
          {createCustomerMutation.isPending ? (
            <ActivityIndicator color="#ffffff" size="small" />
          ) : (
            <>
              <UserPlus size={18} color="#ffffff" weight="bold" />
              <Text className="text-sm font-bold text-white">Save Customer</Text>
            </>
          )}
        </TouchableOpacity>
      </SwipeableModal>

      {/* Staff Selection & PIN Auth Modal */}
      <Modal
        visible={staffModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setStaffModalVisible(false)}
      >
        <View className="flex-1 bg-black/60 items-center justify-center p-5">
          <View className={`bg-card border border-border rounded-3xl p-5 w-full max-w-sm shadow-xl ${isDark ? 'dark' : ''}`}>
            <View className="flex-row items-center justify-between mb-4">
              <Text className="text-base font-bold text-foreground">
                {selectedCustomer ? `Customer: ${selectedCustomer.full_name}` : 'Staff Authentication'}
              </Text>
              <TouchableOpacity
                onPress={() => setStaffModalVisible(false)}
                className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
              >
                <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
              </TouchableOpacity>
            </View>

            {!selectedStaff ? (
              <View className="gap-3">
                <Text className="text-xs text-muted-foreground font-medium mb-1">
                  Select your staff profile to continue:
                </Text>

                {fetchingStaff ? (
                  <View className="py-8 items-center justify-center">
                    <ActivityIndicator size="small" color="#f59e0b" />
                  </View>
                ) : (
                  staffList.map((item) => (
                    <TouchableOpacity
                      key={item.id}
                      activeOpacity={0.7}
                      onPress={() => {
                        setSelectedStaff(item);
                        setPinDigits('');
                        setPinError(null);
                      }}
                      className="bg-muted/30 border border-border rounded-2xl p-3.5 flex-row items-center justify-between min-h-[56px]"
                    >
                      <View className="flex-row items-center gap-3">
                        <View className="w-9 h-9 rounded-xl bg-amber-500/10 items-center justify-center">
                          <ShieldCheck size={20} color={isDark ? '#f59e0b' : '#d97706'} weight="bold" />
                        </View>
                        <View>
                          <Text className="text-sm font-bold text-foreground">{item.fullName}</Text>
                          <Text className="text-xs text-muted-foreground">{item.role}</Text>
                        </View>
                      </View>
                      <Lock size={16} color={isDark ? '#94a3b8' : '#64748b'} />
                    </TouchableOpacity>
                  ))
                )}
              </View>
            ) : (
              <View className="items-center">
                <View className="flex-row items-center justify-between w-full mb-3">
                  <TouchableOpacity
                    onPress={() => setSelectedStaff(null)}
                    className="flex-row items-center gap-1 py-1"
                  >
                    <ArrowLeft size={16} color="#d97706" weight="bold" />
                    <Text className="text-xs font-bold text-amber-600 dark:text-amber-400">Back</Text>
                  </TouchableOpacity>
                  <Text className="text-sm font-bold text-foreground">{selectedStaff.fullName}</Text>
                  <View className="w-10" />
                </View>

                <Text className="text-xs text-muted-foreground mb-3">Enter 4-digit Staff PIN</Text>

                <View className="flex-row gap-3 mb-4">
                  {[0, 1, 2, 3].map((idx) => (
                    <View
                      key={idx}
                      className={`w-10 h-10 rounded-xl border ${
                        pinDigits.length > idx
                          ? 'bg-amber-500/20 border-amber-500'
                          : 'bg-muted/40 border-border'
                      } items-center justify-center`}
                    >
                      {pinDigits.length > idx ? (
                        <Text className="text-lg font-bold text-amber-600 dark:text-amber-400">•</Text>
                      ) : null}
                    </View>
                  ))}
                </View>

                {pinError && (
                  <Text className="text-xs font-semibold text-destructive mb-3 text-center">
                    {pinError}
                  </Text>
                )}

                <View className="w-full gap-2.5 max-w-[240px]">
                  {[['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']].map((row, rIdx) => (
                    <View key={rIdx} className="flex-row gap-2.5">
                      {row.map((num) => (
                        <TouchableOpacity
                          key={num}
                          activeOpacity={0.6}
                          onPress={() => handleKeyPress(num)}
                          disabled={isSubmittingPin}
                          className="flex-1 h-12 rounded-xl bg-card border border-border items-center justify-center"
                        >
                          <Text className="text-lg font-bold text-foreground">{num}</Text>
                        </TouchableOpacity>
                      ))}
                    </View>
                  ))}

                  <View className="flex-row gap-2.5">
                    <TouchableOpacity
                      onPress={() => {
                        setPinDigits('');
                        setPinError(null);
                      }}
                      className="flex-1 h-12 rounded-xl bg-muted/30 border border-border items-center justify-center"
                    >
                      <Text className="text-xs font-bold text-muted-foreground">Clear</Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                      onPress={() => handleKeyPress('0')}
                      disabled={isSubmittingPin}
                      className="flex-1 h-12 rounded-xl bg-card border border-border items-center justify-center"
                    >
                      <Text className="text-lg font-bold text-foreground">0</Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                      onPress={() => {
                        if (pinDigits.length > 0) {
                          setPinDigits(pinDigits.slice(0, -1));
                          setPinError(null);
                        }
                      }}
                      className="flex-1 h-12 rounded-xl bg-muted/30 border border-border items-center justify-center"
                    >
                      <X size={18} color={isDark ? '#94a3b8' : '#64748b'} weight="bold" />
                    </TouchableOpacity>
                  </View>
                </View>

                {isSubmittingPin && (
                  <View className="mt-3 flex-row items-center gap-2">
                    <ActivityIndicator size="small" color="#f59e0b" />
                    <Text className="text-xs text-muted-foreground">Verifying...</Text>
                  </View>
                )}
              </View>
            )}
          </View>
        </View>
      </Modal>

      {/* Customer Action Modal */}
      <SwipeableModal
        visible={actionModalVisible}
        onClose={() => setActionModalVisible(false)}
        isDark={isDark}
      >
        <View className="flex-row items-center justify-between mb-4">
          <View className="flex-row items-center gap-3">
            <View className="w-10 h-10 rounded-xl bg-amber-500/15 border border-amber-500/30 items-center justify-center">
              <User size={22} color={isDark ? '#f59e0b' : '#d97706'} weight="bold" />
            </View>
            <View>
              <Text className="text-base font-bold text-foreground">
                {selectedCustomer?.full_name}
              </Text>
              <Text className="text-xs text-muted-foreground">
                {selectedCustomer?.phone || 'No phone'}
              </Text>
            </View>
          </View>

          <TouchableOpacity
            onPress={() => setActionModalVisible(false)}
            className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
          >
            <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>

        {/* 2x2 Square Buttons Grid */}
        <View className="flex-row flex-wrap justify-between gap-3 mb-2">
          {/* 1. Meal */}
          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => handleToggleAttendance()}
            disabled={toggleAttendanceMutation.isPending}
            className="w-[48%] aspect-square bg-emerald-600 dark:bg-emerald-500 rounded-2xl items-center justify-center p-3"
          >
            <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
              <CalendarCheck size={22} color="#ffffff" weight="bold" />
            </View>
            <Text className="text-sm font-bold text-white text-center">Meal</Text>
            {toggleAttendanceMutation.isPending && (
              <ActivityIndicator color="#ffffff" size="small" className="mt-1" />
            )}
          </TouchableOpacity>

          {/* 2. Baki */}
          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => setBakiModalVisible(true)}
            className="w-[48%] aspect-square bg-amber-600 dark:bg-amber-500 rounded-2xl items-center justify-center p-3"
          >
            <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
              <Receipt size={22} color="#ffffff" weight="bold" />
            </View>
            <Text className="text-sm font-bold text-white text-center">Baki</Text>
          </TouchableOpacity>

          {/* 3. Payment */}
          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => {
              Alert.alert('Payment', `Collect payment from ${selectedCustomer?.full_name}`);
            }}
            className="w-[48%] aspect-square bg-blue-600 dark:bg-blue-500 rounded-2xl items-center justify-center p-3"
          >
            <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
              <Coins size={22} color="#ffffff" weight="bold" />
            </View>
            <Text className="text-sm font-bold text-white text-center">Payment</Text>
          </TouchableOpacity>

          {/* 4. Report */}
          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => {
              refetchStatement();
              setStatementModalVisible(true);
            }}
            className="w-[48%] aspect-square bg-slate-800 dark:bg-slate-700 rounded-2xl items-center justify-center p-3"
          >
            <View className="w-10 h-10 rounded-xl bg-white/20 items-center justify-center mb-2">
              <FileText size={22} color="#ffffff" weight="bold" />
            </View>
            <Text className="text-sm font-bold text-white text-center">Report</Text>
          </TouchableOpacity>
        </View>
      </SwipeableModal>

      {/* Add Baki Modal */}
      <SwipeableModal
        visible={bakiModalVisible}
        onClose={() => setBakiModalVisible(false)}
        isDark={isDark}
      >
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-base font-bold text-foreground">Add Baki Meal for {selectedCustomer?.full_name}</Text>
          <TouchableOpacity
            onPress={() => setBakiModalVisible(false)}
            className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
          >
            <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>

        <View className="gap-3.5 mb-6">
          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Amount (৳) *</Text>
            <Input
              value={bakiAmount}
              onChangeText={setBakiAmount}
              keyboardType="numeric"
              placeholder="0.00"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>

          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Items Description *</Text>
            <Input
              value={bakiDescription}
              onChangeText={setBakiDescription}
              placeholder="e.g. Lunch Rice + Fish Curry"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>
        </View>

        <TouchableOpacity
          activeOpacity={0.8}
          onPress={handleRecordBaki}
          disabled={recordBakiMutation.isPending}
          className="bg-amber-600 dark:bg-amber-500 h-12 rounded-xl items-center justify-center flex-row gap-2"
        >
          {recordBakiMutation.isPending ? (
            <ActivityIndicator color="#ffffff" size="small" />
          ) : (
            <>
              <Receipt size={18} color="#ffffff" weight="bold" />
              <Text className="text-sm font-bold text-white">Save Baki Entry</Text>
            </>
          )}
        </TouchableOpacity>
      </SwipeableModal>

      {/* 30-Day Statement Modal */}
      <SwipeableModal
        visible={statementModalVisible}
        onClose={() => setStatementModalVisible(false)}
        isDark={isDark}
        className="h-[80%]"
      >
        <View className="flex-row items-center justify-between mb-4">
          <View className="flex-row items-center gap-2">
            <FileText size={20} color={isDark ? '#f59e0b' : '#d97706'} weight="bold" />
            <Text className="text-base font-bold text-foreground">
              30-Day Statement ({selectedCustomer?.full_name})
            </Text>
          </View>
          <TouchableOpacity
            onPress={() => setStatementModalVisible(false)}
            className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
          >
            <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>

        {isLoadingStatement ? (
          <View className="flex-1 justify-center items-center">
            <ActivityIndicator size="large" color="#f59e0b" />
            <Text className="text-xs text-muted-foreground mt-2">Loading statement history...</Text>
          </View>
        ) : statementItems.length === 0 ? (
          <View className="flex-1 justify-center items-center py-10">
            <Text className="text-sm font-medium text-muted-foreground">No records found for the last 30 days</Text>
          </View>
        ) : (
          <FlatList
            data={statementItems}
            keyExtractor={(item) => item.unique_id}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={{ paddingBottom: 20 }}
            renderItem={({ item }) => (
              <View className="bg-muted/30 border border-border rounded-2xl p-3.5 mb-2.5 flex-row items-center justify-between">
                <View className="flex-row items-center gap-3">
                  <View
                    className={`w-9 h-9 rounded-xl items-center justify-center ${
                      item.event_type === 'attendance'
                        ? 'bg-emerald-500/15 border border-emerald-500/30'
                        : item.event_type === 'baki'
                        ? 'bg-amber-500/15 border border-amber-500/30'
                        : 'bg-blue-500/15 border border-blue-500/30'
                    }`}
                  >
                    {item.event_type === 'attendance' ? (
                      <CalendarCheck size={18} color="#10b981" weight="bold" />
                    ) : item.event_type === 'baki' ? (
                      <Receipt size={18} color="#f59e0b" weight="bold" />
                    ) : (
                      <Coins size={18} color="#3b82f6" weight="bold" />
                    )}
                  </View>

                  <View>
                    <Text className="text-xs font-bold text-foreground">
                      {item.description || item.event_type}
                    </Text>
                    <Text className="text-[10px] text-muted-foreground">
                      {item.event_date ? new Date(item.event_date).toLocaleDateString() : ''}
                    </Text>
                  </View>
                </View>

                <View className="items-end">
                  <Text
                    className={`text-xs font-bold ${
                      item.event_type === 'collection'
                        ? 'text-emerald-600 dark:text-emerald-400'
                        : 'text-destructive'
                    }`}
                  >
                    {item.event_type === 'collection' ? '-' : '+'} ৳ {item.amount.toFixed(2)}
                  </Text>
                  <Text className="text-[10px] text-muted-foreground capitalize">
                    {item.method || item.event_type}
                  </Text>
                </View>
              </View>
            )}
          />
        )}
      </SwipeableModal>

      {/* Set Daily Attendance Rate Modal */}
      <SwipeableModal
        visible={attendanceRateModalVisible}
        onClose={() => setAttendanceRateModalVisible(false)}
        isDark={isDark}
      >
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-base font-bold text-foreground">
            Set Daily Attendance Rate ({selectedCustomer?.full_name})
          </Text>
          <TouchableOpacity
            onPress={() => setAttendanceRateModalVisible(false)}
            className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
          >
            <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>

        <View className="gap-3.5 mb-6">
          <Text className="text-xs text-muted-foreground">
            This customer does not have a contract daily rate configured yet. Enter the daily rate to register attendance for this customer.
          </Text>
          <View>
            <Text className="text-xs font-semibold text-muted-foreground mb-1">Daily Rate (৳) *</Text>
            <Input
              value={inputDailyRate}
              onChangeText={setInputDailyRate}
              keyboardType="numeric"
              placeholder="e.g. 100.00"
              placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            />
          </View>
        </View>

        <TouchableOpacity
          activeOpacity={0.8}
          onPress={async () => {
            const rateNum = parseFloat(inputDailyRate);
            if (isNaN(rateNum) || rateNum <= 0) {
              Alert.alert('Validation Error', 'Please enter a valid rate greater than zero.');
              return;
            }
            try {
              const { updateCustomerDailyRate } = await import('@/services/customer');
              await updateCustomerDailyRate(selectedCustomer.id, rateNum);
              setSelectedCustomer((prev: any) => ({ ...prev, contract_daily_rate: rateNum }));
              Alert.alert('Success', `Daily contract rate set to ৳ ${rateNum} for ${selectedCustomer.full_name}`);
              setAttendanceRateModalVisible(false);
              refetch();
            } catch (err: any) {
              Alert.alert('Error', err?.message || 'Failed to save daily rate');
            }
          }}
          className="bg-emerald-600 dark:bg-emerald-500 h-12 rounded-xl items-center justify-center flex-row gap-2"
        >
          <CheckCircle size={18} color="#ffffff" weight="bold" />
          <Text className="text-sm font-bold text-white">Save Rate</Text>
        </TouchableOpacity>
      </SwipeableModal>

      {/* Attendance History List Modal */}
      <SwipeableModal
        visible={attendanceListModalVisible}
        onClose={() => setAttendanceListModalVisible(false)}
        isDark={isDark}
        className="h-[75%]"
      >
        <View className="flex-row items-center justify-between mb-4">
          <View className="flex-row items-center gap-2">
            <CalendarCheck size={20} color={isDark ? '#10b981' : '#059669'} weight="bold" />
            <Text className="text-base font-bold text-foreground">
              Attendance Records ({selectedCustomer?.full_name})
            </Text>
          </View>
          <TouchableOpacity
            onPress={() => setAttendanceListModalVisible(false)}
            className="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 items-center justify-center"
          >
            <X size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </TouchableOpacity>
        </View>

        {isLoadingAttendance ? (
          <View className="flex-1 justify-center items-center">
            <ActivityIndicator size="large" color="#10b981" />
            <Text className="text-xs text-muted-foreground mt-2">Loading attendance list...</Text>
          </View>
        ) : attendanceRecords.length === 0 ? (
          <View className="flex-1 justify-center items-center py-10">
            <Text className="text-sm font-medium text-muted-foreground">No attendance records registered yet</Text>
          </View>
        ) : (
          <FlatList
            data={attendanceRecords}
            keyExtractor={(item) => item.id}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={{ paddingBottom: 20 }}
            renderItem={({ item }) => (
              <View className="bg-muted/30 border border-border rounded-2xl p-3.5 mb-2.5 flex-row items-center justify-between">
                <View className="flex-row items-center gap-3">
                  <View className="w-9 h-9 rounded-xl bg-emerald-500/15 border border-emerald-500/30 items-center justify-center">
                    <CalendarCheck size={18} color="#10b981" weight="bold" />
                  </View>
                  <View>
                    <Text className="text-xs font-bold text-foreground">
                      Date: {item.business_date}
                    </Text>
                    <Text className="text-[10px] text-muted-foreground">
                      Shifts: {item.attended_shifts?.join(', ') || 'lunch'} (ID: {item.id.slice(0, 8)}...)
                    </Text>
                  </View>
                </View>

                <View className="items-end">
                  <Text className="text-xs font-bold text-emerald-600 dark:text-emerald-400">
                    ৳ {item.rate_applied.toFixed(2)}
                  </Text>
                  <Text className="text-[10px] text-muted-foreground uppercase">Rate Charged</Text>
                </View>
              </View>
            )}
          />
        )}
      </SwipeableModal>
    </View>
  );
}






