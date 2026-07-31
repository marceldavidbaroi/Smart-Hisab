import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';

interface TerminalAddModalProps {
  visible: boolean;
  onClose: () => void;
  onSubmit: (name: string) => Promise<void>;
  isLoading: boolean;
  isDark: boolean;
  accentColor: string;
  insets?: any;
}

export default function TerminalAddModal({
  visible,
  onClose,
  onSubmit,
  isLoading,
  isDark,
}: TerminalAddModalProps) {
  const [terminalName, setTerminalName] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const handleRegister = async () => {
    if (!terminalName.trim()) {
      setErrorMsg('Please enter a terminal device name.');
      return;
    }
    setErrorMsg('');
    await onSubmit(terminalName.trim());
    setTerminalName('');
  };

  const handleClose = () => {
    setTerminalName('');
    setErrorMsg('');
    onClose();
  };

  return (
    <BottomSlideModal visible={visible} onClose={handleClose} isDark={isDark}>
      <View className="mb-3 border-b border-border pb-2.5">
        <Text className="text-base font-bold text-foreground">
          Register POS Terminal
        </Text>
        <Text className="text-xs text-muted-foreground mt-0.5">
          Generate a 6-digit PIN code for device pairing
        </Text>
      </View>

      <View className="mb-5">
        <Text className="text-xs font-semibold text-muted-foreground mb-1.5">
          Terminal / Device Name *
        </Text>
        <TextInput
          value={terminalName}
          onChangeText={(val) => {
            setTerminalName(val);
            if (errorMsg) setErrorMsg('');
          }}
          placeholder="e.g. Counter POS #2 / Front Counter"
          placeholderTextColor="#94a3b8"
          className="bg-muted border border-border rounded-xl px-3.5 py-3 text-sm text-foreground"
        />
        {errorMsg ? (
          <Text className="text-xs font-semibold text-destructive mt-1">
            {errorMsg}
          </Text>
        ) : null}
      </View>

      <View className="flex-row gap-3">
        <TouchableOpacity
          onPress={handleClose}
          activeOpacity={0.7}
          className="flex-1 bg-muted border border-border py-3 rounded-xl items-center justify-center min-h-[48px]"
        >
          <Text className="text-xs font-bold text-foreground">Cancel</Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={handleRegister}
          disabled={isLoading}
          activeOpacity={0.8}
          className="flex-1 bg-primary py-3 rounded-xl items-center justify-center flex-row gap-2 min-h-[48px]"
        >
          {isLoading ? (
            <ActivityIndicator size="small" color="#ffffff" />
          ) : (
            <Text className="text-xs font-bold text-primary-foreground">
              Generate Pairing PIN
            </Text>
          )}
        </TouchableOpacity>
      </View>
    </BottomSlideModal>
  );
}
