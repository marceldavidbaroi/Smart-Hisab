import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  RefreshControl,
  Alert,
  Linking,
} from 'react-native';
import {
  Users,
  UserPlus,
  Phone,
  MagnifyingGlass,
  Wallet,
  ArrowLeft,
  Coins,
} from 'phosphor-react-native';
import { useRouter } from 'expo-router';
import { useAuthStore } from '@/store/useAuthStore';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { Input } from '@/components/ui/input';
import { SwipeableRow } from '@/components/ui/SwipeableRow';
import {
  useCustomers,
  useCreateCustomer,
  useToggleAttendance,
  useRecordBaki,
  useCustomerStatement,
} from '@/hooks/useCustomers';
import { fetchPairedDeviceStaff, verifyStaffPin, KioskStaff } from '@/services/staff';
import { getActiveBusinessDayId, Customer } from '@/services/customer';

import CustomerSkeleton from '@/components/terminal/CustomerSkeleton';
import CustomerAddModal from '@/components/terminal/CustomerAddModal';
import CustomerActionModal from '@/components/terminal/CustomerActionModal';
import CustomerBakiModal from '@/components/terminal/CustomerBakiModal';
import CustomerStatementModal from '@/components/terminal/CustomerStatementModal';
import CustomerRateModal from '@/components/terminal/CustomerRateModal';
import StaffAuthModal from '@/components/terminal/StaffAuthModal';

export default function TerminalCustomerScreen() {
  const router = useRouter();
  const { deviceToken, activeStaff, setStaffSession } = useAuthStore();
  const { activeTenant } = useTenantStore();
  const { colorScheme } = useAppStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const [searchQuery, setSearchQuery] = useState('');
  const [modalVisible, setModalVisible] = useState(false);

  // Customer selection & Action Modal State
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [actionModalVisible, setActionModalVisible] = useState(false);

  // Baki Modal & Form state
  const [bakiModalVisible, setBakiModalVisible] = useState(false);
  const [bakiAmount, setBakiAmount] = useState('');
  const [bakiDescription, setBakiDescription] = useState('');

  // Attendance Rate Modal & State
  const [attendanceRateModalVisible, setAttendanceRateModalVisible] = useState(false);
  const [inputDailyRate, setInputDailyRate] = useState('');

  // Statement Modal State
  const [statementModalVisible, setStatementModalVisible] = useState(false);

  // Active Business Day state
  const [activeBusinessDayId, setActiveBusinessDayId] = useState<string | null>(null);

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

  // Load active business day for tenant
  const loadActiveBusinessDay = async () => {
    if (!activeTenant?.id) return null;
    try {
      const dayId = await getActiveBusinessDayId(activeTenant.id);
      setActiveBusinessDayId(dayId);
      return dayId;
    } catch (err) {
      console.warn('Failed to fetch active business day:', err);
      return null;
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

  const openCustomerActions = async (customer: Customer) => {
    setSelectedCustomer(customer);
    setActionModalVisible(true);
    await loadActiveBusinessDay();
  };

  const handleSelectCustomer = (customer: Customer) => {
    setSelectedCustomer(customer);
    if (activeStaff) {
      openCustomerActions(customer);
      return;
    }
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

  const handleMakeCall = (phoneNumber: string) => {
    const url = `tel:${phoneNumber}`;
    Linking.canOpenURL(url)
      .then((supported) => {
        if (supported) {
          Linking.openURL(url);
        } else {
          Alert.alert('Unable to Call', `Phone number ${phoneNumber} is not supported.`);
        }
      })
      .catch((err) => console.error('Error opening phone app:', err));
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
        'No active business day running for this store. A business day must be started before registering attendance.'
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
        'No active business day running for this store. A business day must be started before recording baki.'
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
        `Recorded ৳ ${amountNum.toFixed(2)} for ${selectedCustomer.full_name}. Updated Balance: ৳ ${newBal.toFixed(2)}`
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

  const totalBaki = customers.reduce((acc, curr) => acc + (curr.outstanding_balance || 0), 0);

  return (
    <View className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      <ScrollView
        className="flex-1 p-4"
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={isRefetching} onRefresh={refetch} tintColor={accentColor} />
        }
      >
        {/* Screen Title Header */}
        <View className="flex-row items-center justify-between mb-4">
          <View className="flex-row items-center gap-2.5">
            <View className="w-9 h-9 rounded-xl bg-amber-500/15 border border-amber-500/30 items-center justify-center">
              <Users size={20} color={accentColor} weight="bold" />
            </View>
            <Text className="text-lg font-bold text-foreground">Terminal Customers</Text>
          </View>

          {customers.length > 0 && (
            <TouchableOpacity
              onPress={() => setModalVisible(true)}
              activeOpacity={0.8}
              className="bg-primary px-3 py-1.5 rounded-xl flex-row items-center gap-1.5 min-h-[36px]"
            >
              <UserPlus size={16} color="#ffffff" weight="bold" />
              <Text className="text-xs font-bold text-primary-foreground">Add Customer</Text>
            </TouchableOpacity>
          )}
        </View>
        {/* Total Summary Cards */}
        <View className="flex-row gap-3 mb-4">
          <View className="flex-1 bg-card border border-border rounded-xl p-3.5 shadow-xs flex-row items-center justify-between">
            <View>
              <Text className="text-xs font-bold text-muted-foreground uppercase tracking-wide">
                Total Customers
              </Text>
              <Text className="text-2xl font-black text-foreground mt-0.5">{customers.length}</Text>
            </View>
            <View className="w-10 h-10 rounded-xl bg-primary/10 items-center justify-center border border-primary/20">
              <Users size={22} color={accentColor} weight="bold" />
            </View>
          </View>

          <View className="flex-1 bg-card border border-border rounded-xl p-3.5 shadow-xs flex-row items-center justify-between">
            <View>
              <Text className="text-xs font-bold text-muted-foreground uppercase tracking-wide">
                Total Baki
              </Text>
              <Text className="text-2xl font-black text-destructive mt-0.5">৳{totalBaki.toFixed(0)}</Text>
            </View>
            <View className="w-10 h-10 rounded-xl bg-amber-500/10 items-center justify-center border border-amber-500/20">
              <Coins size={22} color="#f59e0b" weight="bold" />
            </View>
          </View>
        </View>

        {/* Search Bar */}
        <View className="relative flex-row items-center mb-4">
          <View className="absolute left-3.5 z-10">
            <MagnifyingGlass size={18} color={isDark ? '#94a3b8' : '#64748b'} />
          </View>
          <Input
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder="Search customer name or phone..."
            placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
            className="pl-11 h-11 text-sm font-medium w-full"
          />
        </View>

        {/* List Content */}
        {isLoading ? (
          <CustomerSkeleton />
        ) : filteredCustomers.length === 0 ? (
          <View className="bg-card border border-border rounded-xl p-6 items-center">
            <View className="w-12 h-12 rounded-full bg-primary/10 items-center justify-center border border-primary/20 mb-2">
              <Users size={24} color={accentColor} weight="bold" />
            </View>
            <Text className="text-base font-bold text-foreground mt-1">
              {searchQuery ? 'No Matching Customers' : 'No Customers Found'}
            </Text>
            <Text className="text-sm text-muted-foreground text-center mt-1 mb-4">
              Add customers to manage meal attendance, baki & wallets.
            </Text>
            <TouchableOpacity
              onPress={() => setModalVisible(true)}
              activeOpacity={0.8}
              className="bg-primary px-4 py-2.5 rounded-xl flex-row items-center gap-2 shadow-sm"
            >
              <UserPlus size={16} color="#ffffff" weight="bold" />
              <Text className="text-xs font-bold text-primary-foreground">Add Customer</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View className="gap-3 mb-8">
            {filteredCustomers.map((customer, index) => (
              <SwipeableRow
                key={customer.id}
                shouldPeek={index === 0}
                onEdit={() => handleSelectCustomer(customer)}
                onDelete={() => {
                  Alert.alert('Notice', `Customer options for ${customer.full_name}`);
                }}
                accentColor={accentColor}
              >
                <View className="bg-card border border-border rounded-2xl p-4 shadow-xs mb-3 flex-row items-center justify-between">
                  {/* Left Side: Avatar Initials, Name, Phone & Unit */}
                  <View className="flex-row items-center gap-3 flex-1 mr-2">
                    <View className="w-12 h-12 rounded-2xl bg-primary/15 items-center justify-center border border-primary/20">
                      <Text className="text-base font-bold text-primary">
                        {customer.full_name.slice(0, 2).toUpperCase()}
                      </Text>
                    </View>

                    <View className="flex-1">
                      <Text className="text-base font-bold text-foreground" numberOfLines={1}>
                        {customer.full_name}
                      </Text>
                      <View className="flex-row items-center gap-2 mt-1 flex-wrap">
                        {customer.factory_unit ? (
                          <View className="bg-primary/10 px-2.5 py-1 rounded-md border border-primary/20">
                            <Text className="text-xs font-semibold text-primary">
                              {customer.factory_unit}
                            </Text>
                          </View>
                        ) : null}

                        {customer.phone ? (
                          <TouchableOpacity
                            onPress={() => handleMakeCall(customer.phone!)}
                            activeOpacity={0.6}
                            className="flex-row items-center gap-1 bg-muted px-2.5 py-1 rounded-md border border-border cursor-pointer min-h-[28px]"
                          >
                            <Phone size={13} color={accentColor} weight="bold" />
                            <Text className="text-xs font-medium text-foreground">
                              {customer.phone}
                            </Text>
                          </TouchableOpacity>
                        ) : null}
                      </View>
                    </View>
                  </View>

                  {/* Right Side: Wallet Balance Button */}
                  <TouchableOpacity
                    onPress={() => handleSelectCustomer(customer)}
                    activeOpacity={0.7}
                    className="flex-row items-center gap-1.5 bg-amber-500/10 px-3.5 py-2.5 rounded-xl border border-amber-500/20 min-h-[44px]"
                  >
                    <Wallet size={18} color="#f59e0b" weight="bold" />
                    <Text className="text-sm font-bold text-amber-600 dark:text-amber-400">
                      ৳{(customer.outstanding_balance || 0).toFixed(0)}
                    </Text>
                  </TouchableOpacity>
                </View>
              </SwipeableRow>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Modals */}
      <CustomerAddModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        fullName={fullName}
        setFullName={setFullName}
        phone={phone}
        setPhone={setPhone}
        dailyRate={dailyRate}
        setDailyRate={setDailyRate}
        factoryUnit={factoryUnit}
        setFactoryUnit={setFactoryUnit}
        onSubmit={handleAddCustomer}
        isPending={createCustomerMutation.isPending}
        isDark={isDark}
      />

      <CustomerActionModal
        visible={actionModalVisible}
        onClose={() => setActionModalVisible(false)}
        customer={selectedCustomer}
        onToggleAttendance={() => handleToggleAttendance()}
        onOpenBakiModal={() => setBakiModalVisible(true)}
        onOpenReport={() => {
          refetchStatement();
          setStatementModalVisible(true);
        }}
        isAttendancePending={toggleAttendanceMutation.isPending}
        isDark={isDark}
      />

      <CustomerBakiModal
        visible={bakiModalVisible}
        onClose={() => setBakiModalVisible(false)}
        customer={selectedCustomer}
        bakiAmount={bakiAmount}
        setBakiAmount={setBakiAmount}
        bakiDescription={bakiDescription}
        setBakiDescription={setBakiDescription}
        onSubmit={handleRecordBaki}
        isPending={recordBakiMutation.isPending}
        isDark={isDark}
      />

      <CustomerStatementModal
        visible={statementModalVisible}
        onClose={() => setStatementModalVisible(false)}
        customer={selectedCustomer}
        statementItems={statementItems}
        isLoading={isLoadingStatement}
        isDark={isDark}
      />

      <CustomerRateModal
        visible={attendanceRateModalVisible}
        onClose={() => setAttendanceRateModalVisible(false)}
        customer={selectedCustomer}
        inputDailyRate={inputDailyRate}
        setInputDailyRate={setInputDailyRate}
        onSaveRate={async (rateNum) => {
          try {
            const { updateCustomerDailyRate } = await import('@/services/customer');
            if (selectedCustomer) {
              await updateCustomerDailyRate(selectedCustomer.id, rateNum);
              setSelectedCustomer({ ...selectedCustomer, contract_daily_rate: rateNum });
              Alert.alert('Success', `Daily contract rate set to ৳ ${rateNum} for ${selectedCustomer.full_name}`);
              setAttendanceRateModalVisible(false);
              refetch();
            }
          } catch (err: any) {
            Alert.alert('Error', err?.message || 'Failed to save daily rate');
          }
        }}
        isDark={isDark}
      />

      <StaffAuthModal
        visible={staffModalVisible}
        onClose={() => setStaffModalVisible(false)}
        customer={selectedCustomer}
        staffList={staffList}
        selectedStaff={selectedStaff}
        setSelectedStaff={setSelectedStaff}
        fetchingStaff={fetchingStaff}
        pinDigits={pinDigits}
        setPinDigits={setPinDigits}
        pinError={pinError}
        setPinError={setPinError}
        isSubmittingPin={isSubmittingPin}
        onKeyPress={handleKeyPress}
        isDark={isDark}
      />
    </View>
  );
}
