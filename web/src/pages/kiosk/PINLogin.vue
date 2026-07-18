<template>
  <q-page class="bg-grey-2 text-dark q-pa-md flex flex-center">
    <div class="kiosk-container full-width">
      <!-- Top banner for blocked/locked states -->
      <q-banner
        v-if="errorMessage"
        class="bg-red-9 text-white rounded-borders q-mb-lg text-caption text-weight-medium"
        inline-actions
        dense
      >
        <template #avatar>
          <q-icon name="warning" color="white" size="18px" />
        </template>
        {{ errorMessage }}
        <template #action>
          <q-btn
            flat
            color="white"
            :label="$t('kioskUI.login.exitDialog.cancelBtn')"
            @click="errorMessage = ''"
            size="sm"
          />
        </template>
      </q-banner>

      <!-- Desktop & Tablet Layout (gt-sm) -->
      <div class="row q-col-gutter-lg gt-sm items-stretch">
        <!-- Left Column: Staff Grid (col-7) -->
        <div class="col-7 column">
          <q-card
            class="flat bordered bg-white q-pa-md flex-grow column justify-start text-dark"
            style="min-height: 500px"
          >
            <div class="row items-center justify-between q-mb-md">
              <div class="text-h6 text-weight-bold">{{ $t('kioskUI.selector.selectProfile') }}</div>
              <q-btn
                flat
                round
                dense
                icon="refresh"
                color="grey-7"
                @click="loadStaff"
                :loading="loading"
              />
            </div>
            <div class="scroll-container flex-grow overflow-auto" style="max-height: 400px">
              <StaffSelectorGrid
                :staff-list="staffList"
                :selected-staff-id="selectedStaff ? selectedStaff.id : null"
                @select="handleSelectStaff"
              />
            </div>
          </q-card>
        </div>

        <!-- Right Column: PIN Pad (col-5) -->
        <div class="col-5 column">
          <q-card
            class="flat bordered bg-white q-pa-md flex-grow column justify-center items-center text-dark"
          >
            <div v-if="selectedStaff" class="column items-center full-width text-center">
              <div class="text-subtitle1 text-weight-bold q-mb-xs">
                {{ $t('kioskUI.login.welcome', { name: selectedStaff.fullName }) }}
              </div>
              <div class="text-caption text-grey-7 q-mb-md">
                {{ $t('kioskUI.login.enterPin') }}
              </div>

              <div
                v-if="!kioskStore.isOnline"
                class="text-caption text-orange-9 q-mb-md text-weight-bold"
                role="alert"
                aria-live="assertive"
              >
                {{ $t('kioskUI.login.offlineAlert') }}
              </div>

              <KioskPinPad
                ref="desktopPinPad"
                :disabled="loading || !kioskStore.isOnline"
                @submit="handleSubmitPin"
              />
            </div>
            <div v-else class="column items-center text-center text-grey-6 q-pa-lg">
              <q-icon name="touch_app" size="48px" class="q-mb-sm" />
              <div class="text-subtitle2">{{ $t('kioskUI.login.selectProfilePrompt') }}</div>
            </div>
          </q-card>
        </div>
      </div>

      <!-- Mobile Layout (lt-md) -->
      <div class="lt-md">
        <!-- Panel A: Select Staff -->
        <div v-if="!selectedStaff" class="column">
          <q-card class="flat bordered bg-white q-pa-md text-dark" style="min-height: 400px">
            <div class="row items-center justify-between q-mb-md">
              <div class="text-h6 text-weight-bold">{{ $t('kioskUI.selector.selectProfile') }}</div>
              <q-btn
                flat
                round
                dense
                icon="refresh"
                color="grey-7"
                @click="loadStaff"
                :loading="loading"
              />
            </div>
            <StaffSelectorGrid
              :staff-list="staffList"
              :selected-staff-id="null"
              @select="handleSelectStaff"
            />
          </q-card>
        </div>

        <!-- Panel B: Enter PIN -->
        <div v-else class="column">
          <q-card class="flat bordered bg-white q-pa-md column items-center text-center text-dark">
            <div class="row items-center full-width q-mb-md">
              <q-btn
                flat
                round
                dense
                icon="arrow_back"
                color="grey-9"
                @click="selectedStaff = null"
              />
              <q-space />
              <span class="text-subtitle1 text-weight-bold">{{ selectedStaff.fullName }}</span>
              <q-space />
              <div style="width: 32px"></div>
            </div>
            <p class="text-caption text-grey-7 q-mb-md">{{ $t('kioskUI.login.enterPinShort') }}</p>

            <div
              v-if="!kioskStore.isOnline"
              class="text-caption text-orange-9 q-mb-md text-weight-bold"
              role="alert"
              aria-live="assertive"
            >
              {{ $t('kioskUI.login.offlineAlert') }}
            </div>

            <KioskPinPad
              ref="mobilePinPad"
              :disabled="loading || !kioskStore.isOnline"
              @submit="handleSubmitPin"
            />
          </q-card>
        </div>
      </div>

      <!-- Exit Kiosk Mode / Unpair Device Button -->
      <div class="row justify-center q-mt-xl">
        <q-btn
          flat
          dense
          color="grey-7"
          icon="power_settings_new"
          :label="$t('kioskUI.login.exitBtn')"
          class="q-px-md text-weight-bold cursor-pointer"
          @click="confirmExitKiosk = true"
        />
      </div>
    </div>

    <!-- First-Time PIN Setup Dialog -->
    <q-dialog v-model="showSetupDialog" persistent>
      <q-card
        class="bg-white text-dark border-all rounded-borders q-pa-md"
        style="width: 100%; max-width: 400px"
      >
        <q-card-section class="column items-center text-center q-pt-md">
          <q-avatar size="48px" color="grey-3" text-color="amber-9" class="q-mb-md">
            <q-icon name="lock_reset" size="28px" />
          </q-avatar>
          <div class="text-h6 text-weight-bold">{{ $t('kioskUI.login.setup.title') }}</div>
          <p class="text-caption text-grey-7 q-mt-sm">
            {{ $t('kioskUI.login.setup.subtitle') }}
          </p>
        </q-card-section>

        <q-form @submit.prevent="handlePinSetup" class="q-gutter-y-md">
          <q-card-section class="q-py-none">
            <!-- Setup Error Alert -->
            <q-banner
              v-if="setupErrorMessage"
              class="bg-red-9 text-white rounded-borders q-mb-md text-caption"
              dense
            >
              {{ setupErrorMessage }}
            </q-banner>

            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('kioskUI.login.setup.newPin')
              }}</label>
              <q-input
                v-model="newPin"
                type="password"
                filled
                placeholder="••••"
                mask="####"
                color="primary"
                class="custom-input text-center text-h6 tracking-widest"
                :rules="[
                  (val) => !!val || $t('kioskUI.login.setup.newPinRequired'),
                  (val) => val.length === 4 || $t('kioskUI.login.setup.newPinLength'),
                ]"
                hide-bottom-space
                :disable="setupLoading"
              />
            </div>

            <div>
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('kioskUI.login.setup.confirmPin')
              }}</label>
              <q-input
                v-model="confirmPin"
                type="password"
                filled
                placeholder="••••"
                mask="####"
                color="primary"
                class="custom-input text-center text-h6 tracking-widest"
                :rules="[
                  (val) => !!val || $t('kioskUI.login.setup.confirmPinRequired'),
                  (val) => val === newPin || $t('kioskUI.login.setup.confirmPinMismatch'),
                ]"
                hide-bottom-space
                :disable="setupLoading"
              />
            </div>
          </q-card-section>

          <q-card-actions class="q-px-md q-pt-md">
            <q-btn
              type="submit"
              color="primary"
              :label="$t('kioskUI.login.setup.saveBtn')"
              class="full-width q-py-sm text-weight-bold btn-gradient cursor-pointer"
              :loading="setupLoading"
              unelevated
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- Confirm Exit Kiosk Dialog -->
    <q-dialog v-model="confirmExitKiosk" persistent>
      <q-card
        class="bg-white text-dark border-all rounded-borders q-pa-md"
        style="width: 100%; max-width: 400px"
      >
        <q-card-section class="column items-center text-center q-pt-md">
          <q-avatar size="48px" color="red-1" text-color="red-9" class="q-mb-md">
            <q-icon name="warning" size="28px" />
          </q-avatar>
          <div class="text-h6 text-weight-bold">{{ $t('kioskUI.login.exitDialog.title') }}</div>
          <p class="text-caption text-grey-7 q-mt-sm">
            {{ $t('kioskUI.login.exitDialog.body') }}
          </p>
        </q-card-section>
        <q-card-actions align="right" class="q-gutter-sm">
          <q-btn
            flat
            :label="$t('kioskUI.login.exitDialog.cancelBtn')"
            color="grey-8"
            v-close-popup
            class="cursor-pointer"
          />
          <q-btn
            :label="$t('kioskUI.login.exitDialog.exitBtn')"
            color="red"
            class="text-weight-bold cursor-pointer"
            @click="handleExitKiosk"
            v-close-popup
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useKioskStore } from '../../stores/kiosk';
import StaffSelectorGrid from '../../components/kiosk/StaffSelectorGrid.vue';
import KioskPinPad from '../../components/kiosk/KioskPinPad.vue';
import type { KioskStaff } from '../../stores/kiosk';
import { showSuccess, showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const kioskStore = useKioskStore();
const { t } = useI18n();

const selectedStaff = ref<KioskStaff | null>(null);
const errorMessage = ref('');
const confirmExitKiosk = ref(false);

// First-time PIN setup state
const showSetupDialog = ref(false);
const tempPin = ref('');
const newPin = ref('');
const confirmPin = ref('');
const setupErrorMessage = ref('');
const setupLoading = ref(false);

const staffList = computed(() => kioskStore.staffList);
const loading = computed(() => kioskStore.loading);

const desktopPinPad = ref<InstanceType<typeof KioskPinPad> | null>(null);
const mobilePinPad = ref<InstanceType<typeof KioskPinPad> | null>(null);

const loadStaff = async () => {
  try {
    await kioskStore.fetchStaffList();
  } catch (err) {
    await showApiError(err, t('kioskUI.login.messages.loadStaffFailed'));
    if (!kioskStore.isDevicePaired) {
      void router.replace('/auth/login');
    }
  }
};

onMounted(() => {
  void loadStaff();
});

const handleSelectStaff = (staff: KioskStaff) => {
  selectedStaff.value = staff;
  errorMessage.value = '';
  // Clear any existing PIN inputs
  if (desktopPinPad.value) desktopPinPad.value.clear();
  if (mobilePinPad.value) mobilePinPad.value.clear();
};

const handleSubmitPin = async (pin: string) => {
  if (!selectedStaff.value) return;

  errorMessage.value = '';
  if (!kioskStore.isOnline) {
    errorMessage.value = t('kioskUI.login.messages.offlineLogin');
    // Clear pins
    if (desktopPinPad.value) desktopPinPad.value.clear();
    if (mobilePinPad.value) mobilePinPad.value.clear();
    return;
  }
  const result = await kioskStore.loginStaff(selectedStaff.value.id, pin);

  if (result.success) {
    if (result.setupRequired) {
      tempPin.value = pin;
      newPin.value = '';
      confirmPin.value = '';
      setupErrorMessage.value = '';
      showSetupDialog.value = true;
    } else {
      showSuccess(t('kioskUI.login.welcome', { name: selectedStaff.value.fullName }), {
        timeout: 1500,
      });
      void router.push({ name: 'kiosk-workspace' });
    }
  } else {
    errorMessage.value = kioskStore.failedPinMessage || t('kioskUI.login.messages.loginFailed');
    // Clear pins
    if (desktopPinPad.value) desktopPinPad.value.clear();
    if (mobilePinPad.value) mobilePinPad.value.clear();
  }
};

const handlePinSetup = async () => {
  if (!selectedStaff.value) return;
  setupErrorMessage.value = '';
  setupLoading.value = true;

  try {
    const success = await kioskStore.setPrivatePin(
      selectedStaff.value.id,
      tempPin.value,
      newPin.value,
    );

    if (success) {
      showSetupDialog.value = false;
      showSuccess(t('kioskUI.login.messages.setupSuccess'), { timeout: 1500 });
      void router.push({ name: 'kiosk-workspace' });
    } else {
      setupErrorMessage.value = t('kioskUI.login.setup.messages.setupFailed');
    }
  } catch (err) {
    const error = err as Error;
    setupErrorMessage.value = error.message || t('kioskUI.login.setup.messages.setupFailed');
  } finally {
    setupLoading.value = false;
  }
};

const handleExitKiosk = () => {
  kioskStore.unpairDevice();
  void router.push('/auth/login');
};
</script>

<style scoped lang="scss">
.kiosk-container {
  max-width: 900px;
}

.scroll-container {
  overflow-y: auto;
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

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.cursor-pointer {
  cursor: pointer;
}
</style>
