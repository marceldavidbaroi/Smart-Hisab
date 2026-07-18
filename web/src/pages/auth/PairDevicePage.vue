<template>
  <div class="pairing-container">
    <div class="text-subtitle1 text-weight-bold text-center text-slate-800 q-mb-md">
      {{ $t('auth.pair.title') }}
    </div>

    <q-form @submit.prevent="handlePairing" class="q-gutter-y-md">
      <div>
        <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
          >Pairing Code</label
        >
        <q-input
          v-model="pairingCode"
          filled
          mask="### ###"
          unmasked-value
          placeholder="000 000"
          color="primary"
          class="custom-input text-center text-h6"
          :rules="[
            (val) => !!val || $t('auth.pair.pairingCodeRequired'),
            (val) => val.length === 6 || $t('auth.pair.pairingCodeInvalid'),
          ]"
          hide-bottom-space
          autofocus
        />
      </div>

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
        class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
        :label="$t('auth.pair.pairDevice')"
        :loading="loading"
      />
    </q-form>

    <div class="text-center q-mt-md">
      <q-btn
        flat
        color="slate-500"
        no-caps
        class="hover-underline text-weight-medium"
        style="min-height: 48px"
        to="/auth/login"
      >
        {{ $t('auth.pair.returnLogin') }}
      </q-btn>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useKioskStore } from '../../stores/kiosk';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const kioskStore = useKioskStore();
const { t } = useI18n();

const pairingCode = ref('');
const deviceName = ref('Counter Tablet');
const loading = ref(false);
const errorMsg = ref('');

const handlePairing = async () => {
  if (pairingCode.value.length !== 6) return;

  loading.value = true;
  errorMsg.value = '';

  try {
    const success = await kioskStore.pairDevice(pairingCode.value, deviceName.value);
    if (success) {
      await router.push({ name: 'counter-login' });
    } else {
      errorMsg.value = t('auth.pair.failedPairing');
    }
  } catch (err) {
    const errorObj = err as Error;
    errorMsg.value = errorObj.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped lang="scss">
.pairing-container {
  width: 100%;
}

.block {
  display: block;
}

.rounded-btn {
  border-radius: 12px;
  min-height: 48px;
}

.btn-gradient {
  background: linear-gradient(135deg, #0e4a47 0%, #2ec4b6 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(14, 74, 71, 0.3);
  border: none;

  &:hover {
    filter: brightness(1.1);
  }
}

.custom-input :deep(.q-field__control) {
  min-height: 48px;
  border-radius: 12px;
  background: #f8fafc !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;

  &:hover {
    border-color: #94a3b8;
  }

  &.q-field__control--focused {
    border-color: #0e4a47;
    background: #ffffff !important;
    box-shadow: 0 0 0 2px rgba(14, 74, 71, 0.15);
  }
}

.custom-input :deep(input) {
  font-weight: 600;
  letter-spacing: 2px;
}
</style>
