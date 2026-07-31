import React, { useState, useEffect } from 'react';
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
  Plus,
  ForkKnife,
  Calendar,
  PencilSimple,
  Trash,
} from 'phosphor-react-native';
import { useAppStore } from '@/store/useAppStore';
import { useTenantStore } from '@/store/useTenantStore';
import {
  getMealConfigs,
  deleteMealConfig,
  MealConfig,
} from '@/services/mealConfig';
import { SwipeableRow } from '@/components/ui/SwipeableRow';
import MealConfigAddEditModal from './components/MealConfigAddEditModal';
import MealConfigSkeleton from './components/MealConfigSkeleton';

export default function MealConfigScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { colorScheme } = useAppStore();
  const { activeTenant } = useTenantStore();
  const isDark = colorScheme === 'dark';
  const accentColor = isDark ? '#d4984e' : '#56778a';

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [configs, setConfigs] = useState<MealConfig[]>([]);

  const [modalVisible, setModalVisible] = useState(false);
  const [editingConfig, setEditingConfig] = useState<MealConfig | null>(null);

  useEffect(() => {
    if (activeTenant?.id) {
      fetchConfigs();
    }
  }, [activeTenant?.id]);

  const fetchConfigs = async (isRefresh = false) => {
    if (!activeTenant?.id) return;

    if (isRefresh) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }

    try {
      const data = await getMealConfigs(activeTenant.id);
      setConfigs(data);
    } catch (err: any) {
      console.error('Error fetching meal configs:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleOpenAdd = () => {
    setEditingConfig(null);
    setModalVisible(true);
  };

  const handleOpenEdit = (config: MealConfig) => {
    setEditingConfig(config);
    setModalVisible(true);
  };

  const handleDelete = (id: string) => {
    Alert.alert(
      'Delete Meal Config',
      'Are you sure you want to delete this meal configuration?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteMealConfig(id);
              // Targeted local cache mutation
              setConfigs((prev) => prev.filter((item) => item.id !== id));
            } catch (err: any) {
              Alert.alert('Error', err.message || 'Failed to delete configuration');
            }
          },
        },
      ]
    );
  };

  const handleModalSuccess = (savedConfig: MealConfig, isEdit: boolean) => {
    if (isEdit) {
      setConfigs((prev) =>
        prev.map((item) => (item.id === savedConfig.id ? savedConfig : item))
      );
    } else {
      setConfigs((prev) => [savedConfig, ...prev]);
    }
  };

  return (
    <View
      style={{ paddingTop: insets.top }}
      className={`flex-1 ${isDark ? 'dark bg-background' : 'bg-slate-50/50'}`}
    >
      {/* Top Header */}
      <View className="px-5 py-4 flex-row items-center justify-between border-b border-border bg-card">
        <View className="flex-row items-center gap-3">
          <TouchableOpacity
            onPress={() => router.back()}
            activeOpacity={0.7}
            className="w-10 h-10 rounded-xl bg-muted items-center justify-center border border-border min-h-[48px] min-w-[48px]"
          >
            <ArrowLeft size={20} color={isDark ? '#f8fafc' : '#0f172a'} weight="bold" />
          </TouchableOpacity>
          <View>
            <Text className="text-base font-bold text-foreground">Meal Configurations</Text>
            <Text className="text-xs text-muted-foreground">Manage meal rate rules & notes</Text>
          </View>
        </View>

        {configs.length > 0 && (
          <TouchableOpacity
            onPress={handleOpenAdd}
            activeOpacity={0.7}
            className="w-10 h-10 rounded-xl bg-primary items-center justify-center min-h-[48px] min-w-[48px]"
          >
            <Plus size={20} color="#ffffff" weight="bold" />
          </TouchableOpacity>
        )}
      </View>

      {/* Main Content Area */}
      <ScrollView
        contentContainerStyle={{ padding: 20, paddingBottom: 40 }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => fetchConfigs(true)}
            tintColor={accentColor}
          />
        }
      >
        {loading ? (
          <MealConfigSkeleton />
        ) : configs.length === 0 ? (
          /* Empty State */
          <View className="bg-card border border-border rounded-2xl p-6 items-center justify-center gap-4 my-6">
            <View className="w-16 h-16 rounded-2xl bg-teal-500/10 items-center justify-center border border-teal-500/20">
              <ForkKnife size={32} color={accentColor} weight="bold" />
            </View>
            <View className="items-center gap-1">
              <Text className="text-base font-bold text-foreground text-center">
                No Meal Configurations
              </Text>
              <Text className="text-xs text-muted-foreground text-center px-4">
                Add rate rules and meal details to enable automatic charging.
              </Text>
            </View>
            <TouchableOpacity
              onPress={handleOpenAdd}
              activeOpacity={0.8}
              className="bg-primary px-5 h-12 rounded-xl flex-row items-center justify-center gap-2 min-h-[48px]"
            >
              <Plus size={18} color="#ffffff" weight="bold" />
              <Text className="text-sm font-bold text-primary-foreground">
                Add Meal Config
              </Text>
            </TouchableOpacity>
          </View>
        ) : (
          /* Meal Config Cards List */
          <View className="gap-3">
            {configs.map((config, index) => (
              <SwipeableRow
                key={config.id}
                onEdit={() => handleOpenEdit(config)}
                onDelete={() => handleDelete(config.id)}
                accentColor={accentColor}
                shouldPeek={index === 0}
              >
                <TouchableOpacity
                  activeOpacity={0.9}
                  onPress={() => handleOpenEdit(config)}
                  className="bg-card border border-border rounded-2xl p-4 gap-3 shadow-xs"
                >
                  <View className="flex-row items-center justify-between">
                    <View className="flex-row items-center gap-2">
                      <View className="w-8 h-8 rounded-lg bg-teal-500/10 items-center justify-center border border-teal-500/20">
                        <ForkKnife size={18} color={accentColor} weight="bold" />
                      </View>
                      <Text className="text-lg font-bold text-primary">
                        ৳ {Number(config.rate).toFixed(2)}
                      </Text>
                    </View>

                    <View className="bg-muted px-2.5 py-1 rounded-full border border-border flex-row items-center gap-1">
                      <Calendar size={12} color={isDark ? '#94a3b8' : '#64748b'} weight="bold" />
                      <Text className="text-[11px] font-semibold text-muted-foreground">
                        {config.effective_from}
                      </Text>
                    </View>
                  </View>

                  {config.note ? (
                    <Text className="text-xs text-foreground font-medium leading-relaxed bg-slate-100 dark:bg-slate-800/60 p-2.5 rounded-xl">
                      {config.note}
                    </Text>
                  ) : (
                    <Text className="text-xs text-muted-foreground italic">
                      No meal details note specified
                    </Text>
                  )}
                </TouchableOpacity>
              </SwipeableRow>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Add / Edit Bottom Slide Modal */}
      <MealConfigAddEditModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        editingConfig={editingConfig}
        activeTenantId={activeTenant?.id}
        onSuccess={handleModalSuccess}
        isDark={isDark}
        accentColor={accentColor}
      />
    </View>
  );
}
