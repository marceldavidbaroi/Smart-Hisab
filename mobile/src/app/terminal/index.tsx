import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  FlatList,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import {
  ArrowLeft,
  DeviceMobile,
  Plus,
  Copy,
  CheckCircle,
  Clock,
  Storefront,
  Trash,
  Key,
  ArrowClockwise,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { getDevicePairings, generatePairingCode, refreshDeviceToken, deleteDevicePairing, DevicePairing } from '@/services/staff';

export default function TerminalManagementScreen() {
  const router = useRouter();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';

  const [terminals, setTerminals] = useState<DevicePairing[]>([]);
  const [fetching, setFetching] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [terminalName, setTerminalName] = useState('');
  const [copiedPin, setCopiedPin] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [generatedPin, setGeneratedPin] = useState<string | null>(null);

  const accentColor = isDark ? '#d4984e' : '#56778a';

  const fetchTerminals = useCallback(async () => {
    if (!activeTenant?.id) {
      setFetching(false);
      return;
    }
    setFetching(true);
    try {
      const data = await getDevicePairings(activeTenant.id);
      setTerminals(data);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to fetch terminal devices');
    } finally {
      setFetching(false);
    }
  }, [activeTenant?.id]);

  useEffect(() => {
    fetchTerminals();
  }, [fetchTerminals]);

  const handleGenerateTerminal = async () => {
    if (!terminalName.trim()) {
      Alert.alert('Validation Error', 'Please provide a device/terminal name.');
      return;
    }

    if (!activeTenant?.id) {
      Alert.alert('Error', 'No active tenant workspace found.');
      return;
    }

    setIsLoading(true);
    try {
      const pinCode = await generatePairingCode(activeTenant.id, terminalName.trim());
      setGeneratedPin(pinCode);
      setTerminalName('');
      setShowAddForm(false);
      await fetchTerminals();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to register terminal device');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeleteTerminal = (id: string, isPairedDevice?: boolean) => {
    Alert.alert(
      'Remove Device',
      isPairedDevice
        ? 'Are you sure you want to disconnect this paired terminal device?'
        : 'Are you sure you want to revoke this 6-digit pairing PIN?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteDevicePairing(id, isPairedDevice);
              await fetchTerminals();
            } catch (err: any) {
              Alert.alert('Error', err.message || 'Failed to remove device');
            }
          },
        },
      ]
    );
  };

  const handleRefreshDeviceToken = async (item: DevicePairing) => {
    if (!activeTenant?.id) return;
    Alert.alert(
      'Generate Fresh PIN',
      `Generate a new 6-digit pairing PIN for "${item.device_name}"? This will disconnect any active session on the device until re-paired.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Generate PIN',
          onPress: async () => {
            setIsLoading(true);
            try {
              let newPin: string;
              if (item.is_paired_device) {
                newPin = await refreshDeviceToken(activeTenant.id, item.id);
              } else {
                newPin = await generatePairingCode(activeTenant.id, item.device_name);
              }
              setGeneratedPin(newPin);
              await fetchTerminals();
            } catch (err: any) {
              Alert.alert('Error', err.message || 'Failed to generate fresh pairing PIN');
            } finally {
              setIsLoading(false);
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

  return (
    <SafeAreaView className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}>
      {/* Header */}
      <View className="px-5 py-4 flex-row items-center justify-between border-b border-border bg-card">
        <TouchableOpacity
          activeOpacity={0.7}
          onPress={() => router.back()}
          className="flex-row items-center gap-2 py-1 min-h-[44px]"
        >
          <ArrowLeft size={20} color={accentColor} weight="bold" />
          <Text className="text-sm font-semibold text-primary">Back</Text>
        </TouchableOpacity>
        <Text className="text-base font-bold text-foreground">Terminal Devices</Text>
        <TouchableOpacity
          activeOpacity={0.7}
          onPress={() => setShowAddForm(!showAddForm)}
          className="w-9 h-9 rounded-xl bg-primary/10 border border-primary/20 items-center justify-center min-h-[36px]"
        >
          <Plus size={18} color={accentColor} weight="bold" />
        </TouchableOpacity>
      </View>

      <ScrollView className="flex-1 p-5" showsVerticalScrollIndicator={false}>
        {/* Workspace info */}
        <View className="bg-card border border-border rounded-2xl p-4 mb-4 shadow-xs flex-row items-center justify-between">
          <View className="flex-row items-center gap-3">
            <View className="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 items-center justify-center">
              <DeviceMobile size={22} color="#a855f7" weight="bold" />
            </View>
            <View>
              <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
                Active Store Workspace
              </Text>
              <Text className="text-sm font-bold text-foreground">
                {activeTenant?.name || 'Smart Hisab Store'}
              </Text>
            </View>
          </View>
          <View className="bg-purple-500/10 px-2.5 py-1 rounded-full border border-purple-500/20">
            <Text className="text-xs font-bold text-purple-600 dark:text-purple-400">
              {terminals.length} Registered
            </Text>
          </View>
        </View>

        {/* Add Terminal Form or Generated PIN Banner */}
        {generatedPin && (
          <Card className="bg-emerald-500/10 border-emerald-500/30 rounded-2xl p-4 mb-5 shadow-xs">
            <View className="flex-row items-center gap-2 mb-2">
              <CheckCircle size={20} color="#22c55e" weight="bold" />
              <Text className="text-sm font-bold text-green-700 dark:text-green-400">
                New Terminal Device Registered!
              </Text>
            </View>
            <Text className="text-xs text-muted-foreground mb-3 leading-relaxed">
              Use this 6-digit pairing PIN on the target POS device login screen:
            </Text>
            <View className="bg-card border border-emerald-500/40 p-3 rounded-xl flex-row items-center justify-between">
              <Text className="text-2xl font-mono font-bold text-foreground tracking-widest">
                {generatedPin}
              </Text>
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => handleCopyPin(generatedPin)}
                className="bg-emerald-500/15 border border-emerald-500/30 px-3 py-1.5 rounded-lg flex-row items-center gap-1.5 min-h-[36px]"
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
              className="mt-3 self-end"
            >
              <Text className="text-xs font-bold text-primary">Dismiss Banner</Text>
            </TouchableOpacity>
          </Card>
        )}

        {showAddForm && (
          <Card className="bg-card border-border rounded-2xl mb-5 shadow-xs overflow-hidden">
            <CardContent className="p-4 gap-3.5">
              <View className="flex-row items-center justify-between border-b border-border pb-2.5">
                <Text className="text-sm font-bold text-foreground">Register New POS Terminal</Text>
                <Key size={18} color={accentColor} weight="bold" />
              </View>

              <View className="gap-1">
                <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
                  Terminal Name *
                </Text>
                <Input
                  value={terminalName}
                  onChangeText={setTerminalName}
                  placeholder="e.g. Counter POS #2 / Front Counter"
                  placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                  className="h-11 text-sm font-medium"
                />
              </View>

              <View className="gap-1">
                <Text className="text-[11px] font-semibold text-muted-foreground uppercase">
                  Terminal Device Name *
                </Text>
                <Input
                  value={terminalName}
                  onChangeText={setTerminalName}
                  placeholder="e.g. Counter POS #2 / Front Counter"
                  placeholderTextColor={isDark ? '#64748b' : '#94a3b8'}
                  className="h-11 text-sm font-medium"
                />
              </View>

              <View className="flex-row gap-2 mt-1">
                <Button
                  variant="outline"
                  onPress={() => setShowAddForm(false)}
                  className="flex-1 h-11 rounded-xl"
                >
                  <Text className="text-xs font-bold text-foreground">Cancel</Text>
                </Button>

                <Button
                  variant="default"
                  onPress={handleGenerateTerminal}
                  disabled={isLoading}
                  className="flex-1 h-11 rounded-xl flex-row items-center justify-center"
                >
                  {isLoading ? (
                    <ActivityIndicator size="small" color="#ffffff" />
                  ) : (
                    <Text className="text-xs font-bold text-primary-foreground">
                      Generate Pairing PIN
                    </Text>
                  )}
                </Button>
              </View>
            </CardContent>
          </Card>
        )}

        {/* Terminals List Header */}
        <View className="flex-row items-center justify-between mb-3 px-0.5">
          <Text className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Registered Devices ({terminals.length})
          </Text>
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={fetchTerminals}
            className="flex-row items-center gap-1"
          >
            <ArrowClockwise size={14} color={accentColor} />
            <Text className="text-xs font-semibold text-primary">Refresh</Text>
          </TouchableOpacity>
        </View>

        {fetching ? (
          <View className="py-12 items-center justify-center">
            <ActivityIndicator size="large" color={accentColor} />
            <Text className="text-xs text-muted-foreground mt-3 font-medium">
              Loading terminal devices...
            </Text>
          </View>
        ) : terminals.length === 0 ? (
          <Card className="bg-card border-border rounded-2xl p-6 items-center justify-center my-4">
            <DeviceMobile size={32} color="#94a3b8" weight="duotone" />
            <Text className="text-sm font-bold text-foreground mt-3 text-center">
              No Terminal Devices Paired
            </Text>
            <Text className="text-xs text-muted-foreground text-center mt-1 px-4">
              Tap "+" to generate a 6-digit pairing PIN for a new cashier POS device.
            </Text>
          </Card>
        ) : (
          terminals.map((item) => (
            <View
              key={item.id}
              className="bg-card border border-border rounded-2xl p-4 mb-3 shadow-xs gap-3"
            >
              <View className="flex-row items-center justify-between">
                <View className="flex-row items-center gap-3">
                  <View className="w-10 h-10 rounded-xl bg-primary/10 border border-primary/20 items-center justify-center">
                    <DeviceMobile size={20} color={accentColor} weight="bold" />
                  </View>
                  <View>
                    <View className="flex-row items-center gap-2">
                      <Text className="text-sm font-bold text-foreground">{item.device_name}</Text>
                      {item.is_paired_device && (
                        <View className="bg-primary/15 px-2 py-0.5 rounded-md border border-primary/20">
                          <Text className="text-[10px] font-bold text-primary">
                            SL #{item.device_sl || 1}
                          </Text>
                        </View>
                      )}
                    </View>
                    <Text className="text-xs text-muted-foreground">
                      Created: {new Date(item.created_at).toLocaleDateString()}
                    </Text>
                  </View>
                </View>

                <View className="flex-row items-center gap-2">
                  <View
                    className={`px-2.5 py-1 rounded-full border ${
                      item.status === 'paired' || item.status === 'active'
                        ? 'bg-green-500/10 border-green-500/30'
                        : 'bg-amber-500/10 border-amber-500/30'
                    }`}
                  >
                    <Text
                      className={`text-[10px] font-bold uppercase ${
                        item.status === 'paired' || item.status === 'active'
                          ? 'text-green-600 dark:text-green-400'
                          : 'text-amber-600 dark:text-amber-400'
                      }`}
                    >
                      {item.status}
                    </Text>
                  </View>

                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => handleRefreshDeviceToken(item)}
                    className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 items-center justify-center min-h-[32px]"
                  >
                    <ArrowClockwise size={15} color={accentColor} weight="bold" />
                  </TouchableOpacity>

                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => handleDeleteTerminal(item.id, item.is_paired_device)}
                    className="w-8 h-8 rounded-lg bg-destructive/10 border border-destructive/20 items-center justify-center min-h-[32px]"
                  >
                    <Trash size={15} color="#ef4444" weight="bold" />
                  </TouchableOpacity>
                </View>
              </View>

              <View className="bg-muted/40 border border-border/50 rounded-xl p-3 flex-row items-center justify-between">
                <View>
                  <Text className="text-[10px] font-semibold text-muted-foreground uppercase">
                    {item.is_paired_device ? 'Fixed Unpair Code' : 'Pairing 6-Digit PIN'}
                  </Text>
                  <Text className="text-base font-mono font-bold text-foreground mt-0.5 tracking-wider">
                    {item.pairing_code.length === 6
                      ? `${item.pairing_code.slice(0, 3)} ${item.pairing_code.slice(3)}`
                      : item.pairing_code}
                  </Text>
                </View>

                <View className="flex-row items-center gap-2">
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => handleCopyPin(item.pairing_code)}
                    className="bg-card border border-border px-3 py-1.5 rounded-lg flex-row items-center gap-1 min-h-[36px]"
                  >
                    <Copy size={14} color={accentColor} />
                    <Text className="text-xs font-bold text-foreground">
                      {copiedPin === item.pairing_code ? 'Copied!' : 'Copy Code'}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          ))
        )}
      </ScrollView>
    </SafeAreaView>
  );
}
