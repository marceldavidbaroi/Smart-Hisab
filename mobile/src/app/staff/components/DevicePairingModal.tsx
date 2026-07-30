import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, TextInput, ActivityIndicator, Alert } from 'react-native';
import { generatePairingCode } from '@/services/staff';
import { BottomSlideModal } from '@/components/ui/BottomSlideModal';

interface DevicePairingModalProps {
  visible: boolean;
  onClose: () => void;
  activeTenantId: string | undefined;
  onSuccess: () => void;
  isDark: boolean;
  insets: any;
}

export default function DevicePairingModal({
  visible,
  onClose,
  activeTenantId,
  onSuccess,
  isDark,
}: DevicePairingModalProps) {
  const [deviceNameInput, setDeviceNameInput] = useState('');
  const [generatedCode, setGeneratedCode] = useState('');
  const [generatingCode, setGeneratingCode] = useState(false);

  useEffect(() => {
    if (visible) {
      setDeviceNameInput('');
      setGeneratedCode('');
    }
  }, [visible]);

  const handleGenerateKey = async () => {
    if (!activeTenantId) return;
    if (!deviceNameInput.trim()) {
      Alert.alert('Validation Error', 'Please enter a device name (e.g. Counter 1 POS)');
      return;
    }

    setGeneratingCode(true);
    try {
      const code = await generatePairingCode(activeTenantId, deviceNameInput.trim());
      setGeneratedCode(code);
      onSuccess();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to generate pairing code');
    } finally {
      setGeneratingCode(false);
    }
  };

  const formatPairingCode = (code: string) => {
    if (code.length === 6) {
      return `${code.slice(0, 3)} ${code.slice(3)}`;
    }
    return code;
  };

  return (
    <BottomSlideModal visible={visible} onClose={onClose} isDark={isDark}>
      <View className="mb-4 border-b border-border pb-3 -mt-2">
        <Text className="text-base font-bold text-foreground">Pair POS Device</Text>
      </View>

      {!generatedCode ? (
        <>
          <Text className="text-xs text-muted-foreground mb-3">
            Enter a identifier name for your hardware terminal (e.g., Counter Tablet).
          </Text>

          <View className="mb-6">
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

          <View className="flex-row gap-3">
            <TouchableOpacity
              onPress={onClose}
              activeOpacity={0.7}
              className="flex-1 bg-muted border border-border py-3 rounded-xl items-center"
            >
              <Text className="text-xs font-bold text-foreground">Cancel</Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={handleGenerateKey}
              disabled={generatingCode}
              activeOpacity={0.8}
              className="flex-1 bg-primary py-3 rounded-xl items-center flex-row justify-center gap-2"
            >
              {generatingCode ? (
                <ActivityIndicator size="small" color="#ffffff" />
              ) : (
                <Text className="text-xs font-bold text-primary-foreground">
                  Generate Key
                </Text>
              )}
            </TouchableOpacity>
          </View>
        </>
      ) : (
        <View className="items-center py-2">
          <Text className="text-xs text-muted-foreground text-center mb-2">
            Enter this code on the device screen for <Text className="font-bold text-foreground">{deviceNameInput}</Text>:
          </Text>

          <View className="bg-muted border border-border px-6 py-3 rounded-2xl my-3 w-full items-center">
            <Text className="text-3xl font-mono font-bold text-primary tracking-widest">
              {formatPairingCode(generatedCode)}
            </Text>
          </View>

          <TouchableOpacity
            onPress={onClose}
            activeOpacity={0.8}
            className="bg-primary w-full py-3 rounded-xl items-center mt-4"
          >
            <Text className="text-xs font-bold text-primary-foreground">Done</Text>
          </TouchableOpacity>
        </View>
      )}
    </BottomSlideModal>
  );
}
