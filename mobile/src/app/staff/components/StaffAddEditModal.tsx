import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  Switch,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react-native';
import { Check, Key } from 'phosphor-react-native';
import { createStaffMember, updateStaffMember, StaffMember, StaffRole } from '@/services/staff';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';

interface StaffAddEditModalProps {
  visible: boolean;
  onClose: () => void;
  editingStaff: StaffMember | null;
  activeTenantId: string | undefined;
  rolesList: StaffRole[];
  onSuccess: () => void;
  onResetPin?: (staff: StaffMember) => void;
  isDark: boolean;
  accentColor: string;
  insets: any;
}

export default function StaffAddEditModal({
  visible,
  onClose,
  editingStaff,
  activeTenantId,
  rolesList,
  onSuccess,
  onResetPin,
  isDark,
  accentColor,
}: StaffAddEditModalProps) {
  const [formName, setFormName] = useState('');
  const [formPhone, setFormPhone] = useState('');
  const [formRole, setFormRole] = useState('Staff');
  const [formTerminalAccess, setFormTerminalAccess] = useState(true);
  const [formIsActive, setFormIsActive] = useState(true);
  const [submittingStaff, setSubmittingStaff] = useState(false);

  useEffect(() => {
    if (visible) {
      if (editingStaff) {
        setFormName(editingStaff.full_name);
        setFormPhone(editingStaff.phone || '');
        setFormRole(editingStaff.role || 'Staff');
        setFormTerminalAccess(editingStaff.allow_terminal_login);
        setFormIsActive(editingStaff.is_active);
      } else {
        setFormName('');
        setFormPhone('');
        setFormRole(rolesList[0]?.name || 'Staff');
        setFormTerminalAccess(true);
        setFormIsActive(true);
      }
    }
  }, [visible, editingStaff, rolesList]);

  const handleSubmitStaff = async () => {
    if (!activeTenantId) return;
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
          tenant_id: activeTenantId,
          full_name: formName.trim(),
          phone: formPhone.trim(),
          role: formRole,
          allow_terminal_login: formTerminalAccess,
        });
      }
      onSuccess();
      onClose();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to save staff member');
    } finally {
      setSubmittingStaff(false);
    }
  };

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="mb-4 border-b border-border pb-3 -mt-2">
        <Text className="text-base font-bold text-foreground">
          {editingStaff ? 'Edit Staff Member' : 'Add New Staff'}
        </Text>
      </View>

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

      <View className="mb-4">
        <Text className="text-xs font-semibold text-muted-foreground mb-2">Assign Role</Text>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 8, paddingRight: 8 }}
          className="flex-row"
        >
          {(rolesList.length > 0
            ? rolesList.map((r) => r.name)
            : ['Staff', 'Cashier', 'Manager', 'Cook']
          ).map((roleName) => {
            const isSelected = formRole === roleName;
            return (
              <TouchableOpacity
                key={roleName}
                onPress={() => setFormRole(roleName)}
                activeOpacity={0.7}
                className={`px-4 py-2 rounded-xl border flex-row items-center gap-1.5 ${
                  isSelected
                    ? 'bg-primary border-primary shadow-xs'
                    : 'bg-muted border-border'
                }`}
              >
                {isSelected && <Check size={14} color="#ffffff" weight="bold" />}
                <Text
                  className={`text-xs font-bold ${
                    isSelected ? 'text-primary-foreground' : 'text-foreground'
                  }`}
                >
                  {roleName}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      <View className="flex-row items-center justify-between mb-4 bg-muted/60 p-3.5 rounded-xl border border-border">
        <View className="flex-1 mr-2">
          <Text className="text-xs font-bold text-foreground">Allow Terminal Login</Text>
          <Text className="text-[10px] text-muted-foreground mt-0.5">
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

      {editingStaff && formTerminalAccess && onResetPin && (
        <TouchableOpacity
          onPress={() => {
            onClose();
            onResetPin(editingStaff);
          }}
          activeOpacity={0.7}
          className="mb-5 bg-amber-500/10 border border-amber-500/20 py-2.5 px-3 rounded-xl flex-row items-center justify-center gap-2"
        >
          <Key size={16} color="#f59e0b" weight="bold" />
          <Text className="text-xs font-bold text-amber-600 dark:text-amber-400">
            Reset 4-Digit Terminal PIN Code
          </Text>
        </TouchableOpacity>
      )}

      <View className="flex-row gap-3">
        <TouchableOpacity
          onPress={onClose}
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
    </BottomSlideModal>
  );
}
