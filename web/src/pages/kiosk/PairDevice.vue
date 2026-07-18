<template>
  <q-page class="flex flex-center bg-grey-2 text-dark q-pa-md">
     <div class="pair-card-container full-width">
       <q-card class="flat bordered bg-white q-pa-lg text-dark">
         <q-card-section class="column items-center q-pb-none text-center">
           <q-avatar size="64px" color="grey-3" text-color="primary" class="q-mb-md">
             <q-icon name="devices" size="36px" />
           </q-avatar>
           <h1 class="text-h5 text-weight-bold q-my-none">{{ $t('kioskUI.pair.title') }}</h1>
           <p class="text-caption text-grey-7 q-mt-xs q-mb-md">
             {{ $t('kioskUI.pair.subtitle') }}
           </p>
         </q-card-section>
 
         <q-form @submit.prevent="handlePairDevice" class="q-gutter-y-md">
           <q-card-section class="q-py-none">
             <!-- Error Alert -->
             <q-banner
               v-if="errorMessage"
               class="bg-red-9 text-white rounded-borders q-mb-md text-caption"
               inline-actions
               dense
             >
               <template #avatar>
                 <q-icon name="error" color="white" size="18px" />
               </template>
               {{ errorMessage }}
             </q-banner>
 
             <div class="q-mb-md">
               <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                 >{{ $t('kioskUI.pair.deviceName') }}</label
               >
               <q-input
                 v-model="deviceName"
                 type="text"
                 filled
                 placeholder="e.g. Counter Tablet A"
                 color="primary"
                 class="custom-input"
                 :rules="[(val) => !!val || $t('kioskUI.pair.deviceNameRequired')]"
                 hide-bottom-space
                 :disable="loading"
               />
             </div>
 
             <div>
               <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                 >{{ $t('kioskUI.pair.pairingCode') }}</label
               >
               <q-input
                 v-model="pairingCode"
                 type="text"
                 filled
                 placeholder="000 000"
                 mask="### ###"
                 unmasked-value
                 color="primary"
                 class="custom-input text-center text-h5 font-mono tracking-widest"
                 :rules="[
                   (val) => !!val || $t('kioskUI.pair.pairingCodeRequired'),
                   (val) => val.length === 6 || $t('kioskUI.pair.pairingCodeLength'),
                 ]"
                 hide-bottom-space
                 :disable="loading"
               />
             </div>
           </q-card-section>
 
           <q-card-actions class="q-px-md q-pt-md">
             <q-btn
               type="submit"
               color="primary"
               :label="$t('kioskUI.pair.confirmBtn')"
               class="full-width q-py-sm text-weight-bold btn-gradient cursor-pointer"
               :loading="loading"
               unelevated
             />
           </q-card-actions>
         </q-form>
       </q-card>
     </div>
   </q-page>
</template>
 
<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useKioskStore } from '../../stores/kiosk';
import { showSuccess } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';
 
const router = useRouter();
const kioskStore = useKioskStore();
const { t } = useI18n();
 
const deviceName = ref('Counter Tablet');
const pairingCode = ref('');
const errorMessage = ref('');
 
const loading = computed(() => kioskStore.loading);
 
const handlePairDevice = async () => {
  errorMessage.value = '';
  try {
    const success = await kioskStore.pairDevice(pairingCode.value, deviceName.value);
    if (success) {
      showSuccess(t('kioskUI.pair.messages.pairSuccess'), { timeout: 2000 });
      void router.push({ name: 'kiosk-login' });
    }
  } catch (err) {
    const error = err as Error;
    errorMessage.value = error.message || t('kioskUI.pair.messages.pairFailed');
  }
};
</script>
 
<style scoped lang="scss">
.pair-card-container {
  max-width: 420px;
}
 
.custom-input :deep(.q-field__control) {
  border-radius: 12px;
  background: #ffffff !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;
  transition: all 0.2s ease;
 
  &:hover {
    border-color: #94a3b8;
  }
 
  &.q-field__control--focused {
    border-color: var(--q-primary) !important;
  }
}
 
.btn-gradient {
  border-radius: 12px;
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.15);
  border: none;
 
  &:hover {
    filter: brightness(1.1);
  }
}
 
.cursor-pointer {
  cursor: pointer;
}
</style>
