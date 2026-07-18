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
      <template v-if="!closedResult">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">{{ $t('sessions.close.title') }}</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" :disable="loading" />
        </q-card-section>

        <q-form @submit.prevent="handleSubmit" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('sessions.close.closingCash')
              }}</label>
              <q-input
                v-model.number="closingCash"
                type="number"
                filled
                dense
                color="primary"
                class="custom-input font-mono"
                :rules="[
                  (val) => (val !== null && val >= 0) || $t('sessions.close.closingCashMin'),
                ]"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('sessions.close.notesLabel')
              }}</label>
              <q-input
                v-model="notes"
                type="textarea"
                filled
                color="primary"
                class="custom-input"
                rows="3"
                :placeholder="$t('sessions.close.notesPlaceholder')"
              />
            </div>
          </q-card-section>

          <q-card-actions align="right">
            <q-btn
              flat
              :label="$t('sessions.close.cancelBtn')"
              v-close-popup
              color="grey-7"
              :disable="loading"
            />
            <q-btn
              type="submit"
              :label="$t('sessions.close.closeBtn')"
              color="red-5"
              class="q-px-md text-weight-bold"
              unelevated
              dense
              :loading="loading"
              style="min-height: 40px"
            />
          </q-card-actions>
        </q-form>
      </template>

      <!-- Post-Success Summary Panel -->
      <template v-else>
        <q-card-section class="column items-center justify-center q-pb-none">
          <q-avatar
            icon="check_circle"
            color="green-1"
            text-color="green"
            size="72px"
            class="q-mb-sm"
          />
          <div class="text-h6 text-weight-bold text-center">
            {{ $t('sessions.close.reconciled') }}
          </div>
        </q-card-section>

        <q-card-section class="q-py-md text-slate-800">
          <div class="column q-gutter-y-sm text-subtitle2">
            <div class="row justify-between">
              <span class="text-grey-7">{{ $t('sessions.close.countedCash') }}</span>
              <span class="font-mono text-weight-bold">{{ closingCash.toFixed(2) }} BDT</span>
            </div>
            <div class="row justify-between">
              <span class="text-grey-7">{{ $t('sessions.close.expectedCash') }}</span>
              <span class="font-mono text-weight-bold"
                >{{ closedResult.expected_cash.toFixed(2) }} BDT</span
              >
            </div>
            <q-separator />
            <div class="row justify-between text-h6 q-mt-xs">
              <span class="text-weight-bold">{{ $t('sessions.close.variance') }}</span>
              <span
                class="font-mono text-weight-bold"
                :class="closedResult.variance === 0 ? 'text-positive' : 'text-negative'"
              >
                {{ closedResult.variance > 0 ? '+' : '' }}{{ closedResult.variance.toFixed(2) }} BDT
              </span>
            </div>
          </div>
          <div
            v-if="closedResult.variance !== 0"
            class="q-mt-md q-pa-sm bg-red-1 text-negative rounded-borders text-caption"
          >
            ⚠️ <strong>{{ $t('sessions.close.varianceException') }}</strong>
            {{ $t('sessions.close.varianceWarning') }}
          </div>
        </q-card-section>

        <q-card-actions align="center">
          <q-btn
            color="primary"
            :label="$t('sessions.close.dismissBtn')"
            class="q-px-md text-weight-bold full-width"
            unelevated
            dense
            @click="handleDismiss"
            style="min-height: 40px"
          />
        </q-card-actions>
      </template>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useSessionStore } from '../../stores/session';
import { useKioskStore } from '../../stores/kiosk';
import { showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const props = defineProps<{
  modelValue: boolean;
  sessionId: string;
}>();

interface ClosedResult {
  expected_cash: number;
  variance: number;
  status: string;
}

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'closed', result: ClosedResult): void;
}>();

const sessionStore = useSessionStore();
const kioskStore = useKioskStore();
const { t } = useI18n();

const closingCash = ref<number>(0);
const notes = ref<string>('');
const loading = ref(false);

const closedResult = ref<ClosedResult | null>(null);

async function handleSubmit() {
  loading.value = true;
  try {
    const deviceToken = kioskStore.deviceToken;
    const staff = kioskStore.currentStaff;
    if (!deviceToken || !staff) {
      throw new Error(t('sessions.open.messages.unauthenticated'));
    }

    // exactOptionalPropertyTypes compliance
    const closeParams: {
      sessionId: string;
      closingCash: number;
      deviceToken: string;
      staffId: string;
      notes?: string;
    } = {
      sessionId: props.sessionId,
      closingCash: closingCash.value,
      deviceToken,
      staffId: staff.id,
    };
    if (notes.value.trim()) {
      closeParams.notes = notes.value.trim();
    }

    const res = await sessionStore.closeSession(closeParams);

    if (res && res.length > 0) {
      closedResult.value = res[0] as ClosedResult;
    } else {
      closedResult.value = { expected_cash: 0, variance: 0, status: 'closed' };
    }
  } catch (err: unknown) {
    await showApiError(err, t('sessions.close.messages.closeFailed'));
  } finally {
    loading.value = false;
  }
}

function handleDismiss() {
  if (closedResult.value) {
    emit('closed', closedResult.value);
  }
  emit('update:modelValue', false);
  closedResult.value = null;
  closingCash.value = 0;
  notes.value = '';
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
