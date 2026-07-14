<template>
  <q-page class="flex flex-center bg-grey-2 q-pa-md">
    <q-card class="pairing-card no-shadow bordered rounded-borders" style="width: 100%; max-width: 400px">
      <q-card-section class="text-center q-pt-xl">
        <q-icon name="devices" size="48px" color="primary" class="q-mb-md" />
        <div class="text-h5 text-weight-bold text-slate-800">Pair Counter Device</div>
        <p class="text-slate-500 text-sm q-mt-sm">
          Enter the 6-digit pairing code from the Owner Dashboard to link this terminal.
        </p>
      </q-card-section>

      <q-card-section>
        <q-form @submit.prevent="handlePairing" class="q-gutter-y-md">
          <q-input
            v-model="pairingCode"
            filled
            mask="### ###"
            unmasked-value
            label="Pairing Code"
            placeholder="000 000"
            color="primary"
            class="custom-input q-mb-md text-center text-h6"
            :rules="[
              (val) => !!val || 'Pairing code is required',
              (val) => val.length === 6 || 'Must be exactly 6 digits'
            ]"
            hide-bottom-space
            autofocus
          />

          <q-input
            v-model="deviceName"
            filled
            label="Device Name"
            placeholder="e.g. Counter Tablet 1"
            color="primary"
            class="custom-input"
            hide-bottom-space
          />

          <q-banner v-if="errorMsg" class="bg-red-1 text-red-9 rounded-borders q-mt-md q-pa-sm text-sm no-shadow">
            <template #avatar>
              <q-icon name="error" color="red-9" />
            </template>
            {{ errorMsg }}
          </q-banner>

          <q-btn
            type="submit"
            color="primary"
            class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
            label="Pair Device"
            :loading="loading"
          />
        </q-form>
      </q-card-section>

      <q-card-section class="text-center q-pt-none q-pb-lg">
        <q-btn flat color="slate-500" no-caps class="hover-underline text-weight-medium" to="/auth/login">
          Return to Login
        </q-btn>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '../../boot/supabase';

const router = useRouter();

const pairingCode = ref('');
const deviceName = ref('Counter Tablet');
const loading = ref(false);
const errorMsg = ref('');

const handlePairing = async () => {
  if (pairingCode.value.length !== 6) return;

  loading.value = true;
  errorMsg.value = '';

  try {
    const { data, error } = await supabase.rpc('verify_pairing_code', {
      p_code: pairingCode.value,
      p_device_name: deviceName.value,
    });

    if (error) {
      errorMsg.value = error.message;
      return;
    }

    if (data && data.length > 0) {
      const result = data[0];
      if (result.success) {
        // Pairing successful
        localStorage.setItem('device_token', 'true');
        localStorage.setItem('device_tenant_id', result.tenant_id);
        localStorage.setItem('device_tenant_name', result.tenant_name);
        localStorage.setItem('device_tenant_slug', result.tenant_slug);
        
        await router.push({ name: 'counter-login' });
      } else {
        errorMsg.value = result.message || 'Invalid pairing code.';
      }
    } else {
      errorMsg.value = 'Failed to verify pairing code.';
    }
  } catch (err) {
    const errorObj = err as Error;
    errorMsg.value = errorObj.message || 'An unexpected error occurred';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped lang="scss">
.pairing-card {
  border-radius: 16px;
  background: white;
}

.rounded-btn {
  border-radius: 12px;
}

.btn-gradient {
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
  border: none;

  &:hover {
    filter: brightness(1.1);
  }
}

.custom-input :deep(.q-field__control) {
  border-radius: 12px;
  background: #f8fafc !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;

  &:hover {
    border-color: #94a3b8;
  }

  &.q-field__control--focused {
    border-color: #6366f1;
    background: #ffffff !important;
    box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15);
  }
}

.custom-input :deep(input) {
  font-weight: 600;
  letter-spacing: 2px;
}
</style>
