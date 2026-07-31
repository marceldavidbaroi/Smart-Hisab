import React from 'react';
import { View, Text, TouchableOpacity, Modal, ActivityIndicator } from 'react-native';
import { ShieldCheck, Lock, ArrowLeft, X } from 'phosphor-react-native';
import { KioskStaff } from '@/services/staff';
import { Customer } from '@/services/customer';

interface StaffAuthModalProps {
  visible: boolean;
  onClose: () => void;
  customer: Customer | null;
  staffList: KioskStaff[];
  selectedStaff: KioskStaff | null;
  setSelectedStaff: (staff: KioskStaff | null) => void;
  fetchingStaff: boolean;
  pinDigits: string;
  setPinDigits: (val: string) => void;
  pinError: string | null;
  setPinError: (err: string | null) => void;
  isSubmittingPin: boolean;
  onKeyPress: (num: string) => void;
  isDark: boolean;
}

export default function StaffAuthModal({
  visible,
  onClose,
  customer,
  staffList,
  selectedStaff,
  setSelectedStaff,
  fetchingStaff,
  pinDigits,
  setPinDigits,
  pinError,
  setPinError,
  isSubmittingPin,
  onKeyPress,
  isDark,
}: StaffAuthModalProps) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View className="flex-1 bg-black/60 items-center justify-center p-5">
        <View className={`bg-card border border-border rounded-3xl p-5 w-full max-w-sm shadow-xl ${isDark ? 'dark' : ''}`}>
          <View className="flex-row items-center justify-between mb-4">
            <Text className="text-base font-bold text-foreground">
              {customer ? `Customer: ${customer.full_name}` : 'Staff Authentication'}
            </Text>
            <TouchableOpacity
              onPress={onClose}
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
                        onPress={() => onKeyPress(num)}
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
                    onPress={() => onKeyPress('0')}
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
  );
}
