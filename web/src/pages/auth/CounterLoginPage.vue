<template>
  <q-page class="flex flex-center bg-grey-2 q-pa-md fullscreen" style="min-height: 100vh">
    <q-card
      class="pin-card no-shadow bordered rounded-borders bg-white"
      style="width: 100%; max-width: 450px"
    >
      <q-card-section class="text-center q-pt-xl q-pb-md">
        <q-avatar size="72px" color="primary" text-color="white" class="q-mb-md shadow-2 font-bold">
          {{ tenantName ? tenantName.charAt(0).toUpperCase() : 'C' }}
        </q-avatar>
        <div class="text-h5 text-weight-bold text-slate-800">{{ tenantName || 'Canteen' }}</div>
        <p class="text-slate-500 text-sm q-mt-sm">{{ $t('auth.counter.enterPin') }}</p>
      </q-card-section>

      <q-card-section class="q-px-xl">
        <!-- Setup New PIN Form -->
        <q-form v-if="setupRequired" @submit.prevent="handlePinSetup" class="q-gutter-y-md">
          <q-banner class="bg-amber-1 text-amber-9 rounded-borders q-mb-md text-sm no-shadow">
            <template #avatar>
              <q-icon name="info" color="amber-9" />
            </template>
            {{ $t('auth.counter.setPinBanner') }}
          </q-banner>

          <q-input
            v-model="newPin"
            type="password"
            filled
            mask="####"
            unmasked-value
            :label="$t('auth.counter.newPinLabel')"
            color="primary"
            class="custom-input q-mb-md text-center text-h6"
            :rules="[
              (val) => !!val || $t('auth.counter.pinRequired'),
              (val) => val.length === 4 || $t('auth.counter.pinInvalid'),
            ]"
            hide-bottom-space
            autofocus
          />

          <q-input
            v-model="confirmPin"
            type="password"
            filled
            mask="####"
            unmasked-value
            :label="$t('auth.counter.confirmPinLabel')"
            color="primary"
            class="custom-input q-mb-md text-center text-h6"
            :rules="[
              (val) => !!val || $t('auth.counter.confirmRequired'),
              (val) => val === newPin || $t('auth.counter.pinMismatch'),
            ]"
            hide-bottom-space
          />

          <q-banner
            v-if="errorMsg"
            class="bg-red-1 text-red-9 rounded-borders q-mt-md q-pa-sm text-sm no-shadow"
          >
            <template #avatar>
              <q-icon name="error" color="red-9" />
            </template>
            {{ errorMsg }}
          </q-banner>

          <q-btn
            type="submit"
            color="primary"
            class="full-width q-py-sm rounded-btn btn-gradient q-mt-md text-weight-bold"
            :label="$t('auth.counter.saveClockIn')"
            :loading="loading"
          />
        </q-form>

        <!-- Login PIN Form -->
        <q-form v-else @submit.prevent="handleLogin" class="q-gutter-y-md">
          <q-input
            v-model="pin"
            type="password"
            filled
            mask="####"
            unmasked-value
            placeholder="••••"
            color="primary"
            class="custom-input q-mb-md text-center text-h4 font-bold"
            :rules="[
              (val) => !!val || $t('auth.counter.pinRequired'),
              (val) => val.length === 4 || $t('auth.counter.pinInvalid'),
            ]"
            hide-bottom-space
            autofocus
            input-class="tracking-widest"
          />

          <q-banner
            v-if="errorMsg"
            class="bg-red-1 text-red-9 rounded-borders q-mt-md q-pa-sm text-sm no-shadow"
          >
            <template #avatar>
              <q-icon name="error" color="red-9" />
            </template>
            {{ errorMsg }}
          </q-banner>

          <q-banner
            v-if="successMsg"
            class="bg-green-1 text-green-9 rounded-borders q-mt-md q-pa-sm text-sm no-shadow"
          >
            <template #avatar>
              <q-icon name="check_circle" color="green-9" />
            </template>
            {{ successMsg }}
          </q-banner>

          <q-btn
            type="submit"
            color="primary"
            class="full-width q-py-md rounded-btn btn-gradient q-mt-lg text-weight-bold text-h6"
            :label="$t('auth.counter.clockIn')"
            :loading="loading"
          />
        </q-form>
      </q-card-section>

      <q-card-section class="text-center q-pt-md q-pb-lg">
        <q-btn flat color="red-5" no-caps class="text-weight-medium" @click="unpairDevice">
          {{ $t('auth.counter.unpairTerminal') }}
        </q-btn>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '../../boot/supabase';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const { t } = useI18n();

const tenantId = ref('');
const tenantName = ref('');
const tenantSlug = ref('');

const pin = ref('');
const newPin = ref('');
const confirmPin = ref('');
const tempPin = ref('');

const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const setupRequired = ref(false);
const staffIdToSetup = ref('');

onMounted(() => {
  const deviceToken = localStorage.getItem('device_token');
  if (!deviceToken) {
    void router.replace('/auth/pair-device');
    return;
  }
  tenantId.value = localStorage.getItem('device_tenant_id') || '';
  tenantName.value = localStorage.getItem('device_tenant_name') || '';
  tenantSlug.value = localStorage.getItem('device_tenant_slug') || '';
});

const handleLogin = async () => {
  if (pin.value.length !== 4) return;

  loading.value = true;
  errorMsg.value = '';
  successMsg.value = '';

  try {
    const { data, error } = await supabase.rpc('verify_staff_pin', {
      p_tenant_id: tenantId.value,
      p_pin: pin.value,
    });

    if (error) {
      errorMsg.value = error.message;
      return;
    }

    if (data && data.success) {
      if (data.setup_required) {
        setupRequired.value = true;
        staffIdToSetup.value = data.staff_id;
        tempPin.value = pin.value;
        pin.value = ''; // clear original pin input
      } else {
        // Success! Logged in.
        // Store staff session info in localStorage or store
        localStorage.setItem('staff_session_id', data.staff_id);
        localStorage.setItem('staff_session_name', data.full_name);
        localStorage.setItem('staff_session_role', data.role);

        successMsg.value = t('auth.counter.welcomeStaff', {
          name: data.full_name,
          role: data.role,
        });

        setTimeout(() => {
          void router.push(`/${tenantSlug.value}/counter/dashboard`);
        }, 1000);
      }
    } else {
      errorMsg.value = data?.message || t('auth.counter.invalidPin');
      pin.value = '';
    }
  } catch (err) {
    const errorObj = err as Error;
    errorMsg.value = errorObj.message || t('feedback.somethingWentWrong');
    pin.value = '';
  } finally {
    loading.value = false;
  }
};

const handlePinSetup = async () => {
  if (newPin.value.length !== 4 || newPin.value !== confirmPin.value) return;

  loading.value = true;
  errorMsg.value = '';

  try {
    const { data, error } = await supabase.rpc('set_staff_pin', {
      p_staff_id: staffIdToSetup.value,
      p_temp_pin: tempPin.value,
      p_new_pin: newPin.value,
    });

    if (error) {
      errorMsg.value = error.message;
      return;
    }

    if (data) {
      // Setup complete. Transition back to login mode so they can login with new PIN.
      setupRequired.value = false;
      newPin.value = '';
      confirmPin.value = '';
      tempPin.value = '';
      successMsg.value = t('auth.counter.setPinSuccess');
    } else {
      errorMsg.value = t('auth.counter.failedSetPin');
    }
  } catch (err) {
    const errorObj = err as Error;
    errorMsg.value = errorObj.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};

const unpairDevice = () => {
  localStorage.removeItem('device_token');
  localStorage.removeItem('device_tenant_id');
  localStorage.removeItem('device_tenant_name');
  localStorage.removeItem('device_tenant_slug');
  localStorage.removeItem('staff_session_id');
  localStorage.removeItem('staff_session_name');
  localStorage.removeItem('staff_session_role');

  void router.push('/auth/login');
};
</script>

<style scoped lang="scss">
.pin-card {
  border-radius: 24px;
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

.tracking-widest {
  letter-spacing: 0.25em !important;
}
</style>
