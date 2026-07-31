import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import {
  ArrowLeft,
  DeviceMobile,
  Plus,
  Copy,
  CheckCircle,
  ShieldCheck,
  ArrowClockwise,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import {
  getDevicePairings,
  generatePairingCode,
  refreshDeviceToken,
  deleteDevicePairing,
  DevicePairing,
} from '@/services/staff';

import { SwipeableRow } from '@/components/ui/SwipeableRow';
import TerminalAddModal from './components/TerminalAddModal';
import TerminalSkeleton from './components/TerminalSkeleton';
import { WarningModal } from '@/components/ui/WarningModal';

export default function TerminalManagementScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const [terminals, setTerminals] = useState<DevicePairing[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [copiedPin, setCopiedPin] = useState<string | null>(null);
  const [generatedPin, setGeneratedPin] = useState<string | null>(null);

  const fetchTerminals = useCallback(
    async (isRefresh = false) => {
      if (!activeTenant?.id) {
        setLoading(false);
        setRefreshing(false);
        return;
      }

      if (isRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }

      try {
        const data = await getDevicePairings(activeTenant.id);
        setTerminals(data);
      } catch (err: any) {
        Alert.alert('Error', err.message || 'Failed to fetch terminal devices');
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [activeTenant?.id]
  );

  useEffect(() => {
    fetchTerminals();
  }, [fetchTerminals]);

  const handleRefresh = () => {
    fetchTerminals(true);
  };

  const handleRegisterTerminal = async (name: string) => {
    if (!activeTenant?.id) return;
    setSubmitting(true);
    try {
      const pinCode = await generatePairingCode(activeTenant.id, name);
      setGeneratedPin(pinCode);
      setModalVisible(false);
      await fetchTerminals(true);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to register terminal device');
    } finally {
      setSubmitting(false);
    }
  };

  const [deleteTargetTerminal, setDeleteTargetTerminal] = useState<DevicePairing | null>(null);
  const [isDeletingTerminal, setIsDeletingTerminal] = useState(false);

  const handleDeleteTerminal = (item: DevicePairing) => {
    setDeleteTargetTerminal(item);
  };

  const confirmDeleteTerminal = async () => {
    if (!deleteTargetTerminal) return;
    try {
      setIsDeletingTerminal(true);
      await deleteDevicePairing(deleteTargetTerminal.id, deleteTargetTerminal.is_paired_device);
      setTerminals((prev) => prev.filter((t) => t.id !== deleteTargetTerminal.id));
      setDeleteTargetTerminal(null);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to remove device');
    } finally {
      setIsDeletingTerminal(false);
    }
  };

  const handleRefreshDeviceToken = async (item: DevicePairing) => {
    if (!activeTenant?.id) return;
    Alert.alert(
      'Generate Fresh PIN',
      `Generate a new 6-digit pairing PIN for "${item.device_name}"? This will disconnect any active session until re-paired.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Generate PIN',
          onPress: async () => {
            try {
              let newPin: string;
              if (item.is_paired_device) {
                newPin = await refreshDeviceToken(activeTenant.id, item.id);
              } else {
                newPin = await generatePairingCode(activeTenant.id, item.device_name);
              }
              setGeneratedPin(newPin);
              await fetchTerminals(true);
            } catch (err: any) {
              Alert.alert('Error', err.message || 'Failed to generate fresh pairing PIN');
            }
          },
        },
      ]
    );
  };

  const handleCopyPin = (pin: string) => {
    setCopiedPin(pin);
    setTimeout(() => {
      setCopiedPin(null);
    }, 2000);
  };

  const pairedCount = terminals.filter(
    (t) => t.status === 'paired' || t.status === 'active'
  ).length;

  return (
    <View className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      {/* Top Mobile Header (Matching Staff screen structure) */}
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
            <Text className="text-base font-bold text-foreground">Terminal Devices</Text>
            <Text className="text-[11px] text-muted-foreground">
              {activeTenant?.name || 'Workspace'}
            </Text>
          </View>
        </View>

        {terminals.length > 0 && (
          <TouchableOpacity
            onPress={() => setModalVisible(true)}
            activeOpacity={0.8}
            className="bg-primary px-3.5 py-2 rounded-xl flex-row items-center gap-1.5 shadow-sm"
          >
            <Plus size={16} color="#ffffff" weight="bold" />
            <Text className="text-xs font-bold text-primary-foreground">Create Terminal</Text>
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
        {/* Total Terminal Metrics Cards */}
        <View className="flex-row gap-3 mb-4">
          <View className="flex-1 bg-card border border-border rounded-xl p-3.5 shadow-xs flex-row items-center justify-between">
            <View>
              <Text className="text-xs font-bold text-muted-foreground uppercase tracking-wide">
                Total Devices
              </Text>
              <Text className="text-2xl font-black text-foreground mt-0.5">
                {terminals.length}
              </Text>
            </View>
            <View className="w-10 h-10 rounded-xl bg-purple-500/10 items-center justify-center border border-purple-500/20">
              <DeviceMobile size={22} color="#a855f7" weight="bold" />
            </View>
          </View>

          <View className="flex-1 bg-card border border-border rounded-xl p-3.5 shadow-xs flex-row items-center justify-between">
            <View>
              <Text className="text-xs font-bold text-muted-foreground uppercase tracking-wide">
                Active Paired
              </Text>
              <Text className="text-2xl font-black text-foreground mt-0.5">{pairedCount}</Text>
            </View>
            <View className="w-10 h-10 rounded-xl bg-emerald-500/10 items-center justify-center border border-emerald-500/20">
              <ShieldCheck size={22} color="#10b981" weight="bold" />
            </View>
          </View>
        </View>

        {/* Newly Generated PIN Success Banner */}
        {generatedPin && (
          <View className="bg-emerald-500/10 border border-emerald-500/30 rounded-2xl p-4 mb-4 shadow-xs">
            <View className="flex-row items-center gap-2 mb-1.5">
              <CheckCircle size={20} color="#22c55e" weight="bold" />
              <Text className="text-sm font-bold text-green-700 dark:text-green-400">
                New Pairing PIN Generated!
              </Text>
            </View>
            <Text className="text-xs text-muted-foreground mb-3 leading-relaxed">
              Use this 6-digit pairing PIN code on your cashier POS terminal login screen:
            </Text>
            <View className="bg-card border border-emerald-500/40 p-3 rounded-xl flex-row items-center justify-between">
              <Text className="text-2xl font-mono font-bold text-foreground tracking-widest">
                {generatedPin.length === 6
                  ? `${generatedPin.slice(0, 3)} ${generatedPin.slice(3)}`
                  : generatedPin}
              </Text>
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => handleCopyPin(generatedPin)}
                className="bg-emerald-500/15 border border-emerald-500/30 px-3.5 py-2 rounded-xl flex-row items-center gap-1.5 min-h-[40px] cursor-pointer"
              >
                <Copy size={16} color="#22c55e" weight="bold" />
                <Text className="text-xs font-bold text-green-700 dark:text-green-400">
                  {copiedPin === generatedPin ? 'Copied!' : 'Copy PIN'}
                </Text>
              </TouchableOpacity>
            </View>
            <TouchableOpacity
              activeOpacity={0.7}
              onPress={() => setGeneratedPin(null)}
              className="mt-3 self-end min-h-[32px] justify-center"
            >
              <Text className="text-xs font-bold text-primary">Dismiss</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Skeleton Loading State or List */}
        {loading ? (
          <TerminalSkeleton />
        ) : (
          <View className="gap-3 mb-8">
            {terminals.length === 0 ? (
              <View className="bg-card border border-border rounded-xl p-6 items-center">
                <View className="w-12 h-12 rounded-full bg-primary/10 items-center justify-center border border-primary/20 mb-2">
                  <DeviceMobile size={24} color={accentColor} weight="bold" />
                </View>
                <Text className="text-base font-bold text-foreground mt-1">
                  No Terminal Devices Paired
                </Text>
                <Text className="text-sm text-muted-foreground text-center mt-1 mb-4">
                  Register a terminal device to pair cashier POS counters with this store.
                </Text>
                <TouchableOpacity
                  onPress={() => setModalVisible(true)}
                  activeOpacity={0.8}
                  className="bg-primary px-4 py-2.5 rounded-xl flex-row items-center gap-2 shadow-sm"
                >
                  <Plus size={16} color="#ffffff" weight="bold" />
                  <Text className="text-xs font-bold text-primary-foreground">Create Terminal</Text>
                </TouchableOpacity>
              </View>
            ) : (
              terminals.map((item, index) => (
                <SwipeableRow
                  key={item.id}
                  shouldPeek={index === 0}
                  onEdit={() => handleRefreshDeviceToken(item)}
                  onDelete={() => handleDeleteTerminal(item)}
                  accentColor={accentColor}
                >
                  <View className="bg-card border border-border rounded-2xl p-4 shadow-xs mb-3 gap-3">
                    {/* Top Device Title & Status Header */}
                    <View className="flex-row items-center justify-between">
                      <View className="flex-row items-center gap-3 flex-1 mr-2">
                        <View className="w-11 h-11 rounded-2xl bg-purple-500/10 items-center justify-center border border-purple-500/20">
                          <DeviceMobile size={22} color="#a855f7" weight="bold" />
                        </View>

                        <View className="flex-1">
                          <View className="flex-row items-center gap-2 flex-wrap">
                            <Text
                              className="text-base font-bold text-foreground"
                              numberOfLines={1}
                            >
                              {item.device_name}
                            </Text>
                            {item.is_paired_device && (
                              <View className="bg-primary/10 px-2 py-0.5 rounded-md border border-primary/20">
                                <Text className="text-[10px] font-bold text-primary">
                                  SL #{item.device_sl || 1}
                                </Text>
                              </View>
                            )}
                          </View>
                          <Text className="text-xs text-muted-foreground mt-0.5">
                            Created: {new Date(item.created_at).toLocaleDateString()}
                          </Text>
                        </View>
                      </View>

                      <View
                        className={`px-2.5 py-1 rounded-full border ${
                          item.status === 'paired' || item.status === 'active'
                            ? 'bg-emerald-500/10 border-emerald-500/30'
                            : 'bg-amber-500/10 border-amber-500/30'
                        }`}
                      >
                        <Text
                          className={`text-[10px] font-bold uppercase ${
                            item.status === 'paired' || item.status === 'active'
                              ? 'text-emerald-600 dark:text-emerald-400'
                              : 'text-amber-600 dark:text-amber-400'
                          }`}
                        >
                          {item.status}
                        </Text>
                      </View>
                    </View>

                    {/* Bottom Pairing Code / PIN Banner */}
                    <View className="bg-muted/40 border border-border/60 rounded-xl p-3 flex-row items-center justify-between">
                      <View>
                        <Text className="text-[10px] font-bold text-muted-foreground uppercase tracking-wide">
                          {item.is_paired_device ? 'Fixed Unpair Code' : 'Pairing 6-Digit PIN'}
                        </Text>
                        <Text className="text-base font-mono font-bold text-foreground mt-0.5 tracking-wider">
                          {item.pairing_code.length === 6
                            ? `${item.pairing_code.slice(0, 3)} ${item.pairing_code.slice(3)}`
                            : item.pairing_code}
                        </Text>
                      </View>

                      <TouchableOpacity
                        activeOpacity={0.7}
                        onPress={() => handleCopyPin(item.pairing_code)}
                        className="bg-card border border-border px-3.5 py-2 rounded-xl flex-row items-center gap-1.5 min-h-[40px] shadow-xs cursor-pointer"
                      >
                        <Copy size={15} color={accentColor} weight="bold" />
                        <Text className="text-xs font-bold text-foreground">
                          {copiedPin === item.pairing_code ? 'Copied!' : 'Copy Code'}
                        </Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                </SwipeableRow>
              ))
            )}
          </View>
        )}
      </ScrollView>

      {/* Bottom Sheet Registration Modal */}
      <TerminalAddModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        onSubmit={handleRegisterTerminal}
        isLoading={submitting}
        isDark={isDark}
        accentColor={accentColor}
        insets={insets}
      />

      {/* Delete Device Warning Sheet */}
      <WarningModal
        visible={Boolean(deleteTargetTerminal)}
        onClose={() => setDeleteTargetTerminal(null)}
        onConfirm={confirmDeleteTerminal}
        title="Remove Device"
        description={
          deleteTargetTerminal?.is_paired_device
            ? `Are you sure you want to disconnect paired terminal "${deleteTargetTerminal?.device_name}"?`
            : `Are you sure you want to revoke pairing PIN for "${deleteTargetTerminal?.device_name}"?`
        }
        variant="danger"
        confirmText="Remove Device"
        cancelText="Cancel"
        isLoading={isDeletingTerminal}
        isDark={isDark}
      />
    </View>
  );
}
