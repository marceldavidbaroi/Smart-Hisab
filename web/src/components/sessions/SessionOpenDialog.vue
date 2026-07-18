<template>
  <q-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    persistent
  >
    <q-card
      class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md"
      style="width: 450px; max-width: 90vw"
    >
      <q-card-section class="row items-center q-pb-none">
        <div class="text-h6 text-weight-bold">{{ $t('sessions.open.title') }}</div>
        <q-space />
        <q-btn icon="close" flat round dense v-close-popup color="grey-7" :disable="loading" />
      </q-card-section>

      <q-form @submit.prevent="handleSubmit" class="q-gutter-y-md q-mt-sm">
        <q-card-section class="q-py-none">
          <div class="q-mb-md">
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('sessions.open.selectShift')
            }}</label>
            <q-select
              v-model="selectedShift"
              :options="shiftOptions"
              option-value="value"
              option-label="label"
              emit-value
              map-options
              filled
              dense
              color="primary"
              class="custom-input"
              :rules="[(val) => !!val || $t('sessions.open.shiftRequired')]"
              hide-bottom-space
              :loading="loadingShifts"
            />
          </div>

          <div class="q-mb-md">
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('sessions.open.openingCash')
            }}</label>
            <q-input
              v-model.number="openingCash"
              type="number"
              filled
              dense
              color="primary"
              class="custom-input font-mono"
              :rules="[(val) => (val !== null && val >= 0) || $t('sessions.open.openingCashMin')]"
              hide-bottom-space
            />
          </div>

          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('sessions.open.businessDate')
            }}</label>
            <q-input
              v-model="businessDate"
              filled
              dense
              color="primary"
              class="custom-input font-mono"
              mask="date"
              :rules="[(val) => !!val || $t('sessions.open.businessDateRequired')]"
              hide-bottom-space
            >
              <template v-slot:append>
                <q-icon name="event" class="cursor-pointer">
                  <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                    <q-date v-model="businessDate" mask="YYYY-MM-DD">
                      <div class="row items-center justify-end">
                        <q-btn
                          v-close-popup
                          :label="$t('sessions.open.closeBtn')"
                          color="primary"
                          flat
                        />
                      </div>
                    </q-date>
                  </q-popup-proxy>
                </q-icon>
              </template>
            </q-input>
          </div>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn
            flat
            :label="$t('sessions.open.cancelBtn')"
            v-close-popup
            color="grey-7"
            :disable="loading"
          />
          <q-btn
            type="submit"
            :label="$t('sessions.open.openBtn')"
            color="primary"
            class="q-px-md text-weight-bold"
            unelevated
            dense
            :loading="loading"
            style="min-height: 40px"
          />
        </q-card-actions>
      </q-form>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '../../boot/supabase';
import { useSessionStore } from '../../stores/session';
import { useKioskStore } from '../../stores/kiosk';
import { showSuccess, showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const props = defineProps<{
  modelValue: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'opened', sessionId: string): void;
}>();

const sessionStore = useSessionStore();
const kioskStore = useKioskStore();
const { t } = useI18n();

const selectedShift = ref<string | null>(null);
const openingCash = ref<number>(0);
const businessDate = ref<string>(new Date().toISOString().split('T')[0] || '');

const loading = ref(false);
const loadingShifts = ref(false);

interface ShiftRow {
  id: string;
  name: string;
  start_time: string;
  end_time: string;
}

const shifts = ref<ShiftRow[]>([]);

const shiftOptions = computed(() => {
  return shifts.value.map((s) => ({
    label: `${s.name} (${String(s.start_time).substring(0, 5)} - ${String(s.end_time).substring(0, 5)})`,
    value: s.id,
  }));
});

async function loadShifts() {
  const tenantId = kioskStore.tenantId;
  const deviceToken = kioskStore.deviceToken;
  if (!tenantId || !deviceToken) return;
  loadingShifts.value = true;
  try {
    const { data, error } = await supabase.rpc('list_active_shifts', {
      p_tenant_id: tenantId,
      p_device_token: deviceToken,
    });
    if (error) throw error;
    shifts.value = (data || []) as ShiftRow[];
    if (shifts.value.length > 0) {
      const firstShift = shifts.value[0];
      if (firstShift) {
        selectedShift.value = firstShift.id;
      }
    }
  } catch (err: unknown) {
    await showApiError(err, t('sessions.open.messages.loadShiftsFailed'));
  } finally {
    loadingShifts.value = false;
  }
}

onMounted(() => {
  void loadShifts();
});

async function handleSubmit() {
  if (!selectedShift.value) return;
  loading.value = true;
  try {
    const deviceToken = kioskStore.deviceToken;
    const staff = kioskStore.currentStaff;
    if (!deviceToken || !staff) {
      throw new Error(t('sessions.open.messages.unauthenticated'));
    }
    const sessionId = await sessionStore.openSession({
      shiftId: selectedShift.value,
      openingCash: openingCash.value,
      businessDate: businessDate.value,
      deviceToken,
      staffId: staff.id,
    });
    emit('opened', sessionId);
    emit('update:modelValue', false);
    showSuccess(t('sessions.open.messages.openSuccess'));
  } catch (err: unknown) {
    await showApiError(err, t('sessions.open.messages.openFailed'));
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.dialog-card {
  border-radius: 12px;
}
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
