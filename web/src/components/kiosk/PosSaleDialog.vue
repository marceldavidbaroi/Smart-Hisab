<template>
  <q-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    persistent
  >
    <q-card
      flat
      bordered
      class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md"
      style="width: 480px; max-width: 100vw"
    >
      <q-card-section class="row items-center q-pb-sm q-px-none q-pt-none">
        <div class="text-h6 text-weight-bold">
          {{
            isEdit
              ? $t('kioskUI.workspace.pos.editTitle')
              : $t('kioskUI.workspace.actions.posSale.title')
          }}
        </div>
        <q-space />
        <q-btn
          icon="close"
          flat
          round
          dense
          color="grey-7"
          class="cursor-pointer"
          :disable="saving"
          v-close-popup
        />
      </q-card-section>

      <q-form @submit.prevent="onSubmit" class="q-gutter-y-md">
        <div v-if="!isEdit">
          <q-btn-toggle
            v-model="mode"
            spread
            no-caps
            toggle-color="primary"
            class="full-width"
            style="min-height: 48px"
            :options="modeOptions"
            :disable="saving"
          />
        </div>

        <template v-if="mode === 'single' || isEdit">
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('kioskUI.workspace.pos.source')
            }}</label>
            <q-btn-toggle
              v-model="paymentMethod"
              spread
              no-caps
              toggle-color="primary"
              class="full-width"
              style="min-height: 48px"
              :options="sourceOptions"
              :disable="saving"
            />
          </div>
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('ledger.manual.amount')
            }}</label>
            <q-input
              v-model.number="amount"
              type="number"
              filled
              color="primary"
              class="custom-input text-h6 font-mono"
              :rules="[(val) => (val !== null && val > 0) || $t('ledger.manual.amountMin')]"
              hide-bottom-space
              :disable="saving"
            />
          </div>
        </template>

        <template v-else>
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('kioskUI.workspace.pos.bulkCash')
            }}</label>
            <q-input
              v-model.number="bulkCash"
              type="number"
              filled
              color="primary"
              class="custom-input font-mono"
              :disable="saving"
              hide-bottom-space
            />
          </div>
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('kioskUI.workspace.pos.bulkOnline')
            }}</label>
            <q-input
              v-model.number="bulkOnline"
              type="number"
              filled
              color="primary"
              class="custom-input font-mono"
              :disable="saving"
              hide-bottom-space
            />
          </div>
          <div class="text-caption text-grey-7">
            {{ $t('kioskUI.workspace.pos.bulkHint') }}
          </div>
        </template>

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
            rows="2"
            :disable="saving"
          />
        </div>

        <div class="row q-col-gutter-sm">
          <div class="col-6">
            <q-btn
              flat
              class="full-width cursor-pointer"
              style="min-height: 48px"
              :label="$t('kioskUI.workspace.clockOutDialog.cancelBtn')"
              color="grey-7"
              :disable="saving"
              v-close-popup
            />
          </div>
          <div class="col-6">
            <q-btn
              type="submit"
              unelevated
              color="positive"
              class="full-width text-weight-bold cursor-pointer"
              style="min-height: 48px"
              :label="isEdit ? $t('kioskUI.workspace.pos.saveEdit') : $t('ledger.manual.saveBtn')"
              :loading="saving"
            />
          </div>
        </div>
      </q-form>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useLedgerStore, type PosPaymentMethod } from '../../stores/ledger';
import { showApiError, showSuccess } from '../../composables/useFeedback';

const props = defineProps<{
  modelValue: boolean;
  sessionId: string;
  editEntry?: {
    id: string;
    amount: number;
    payment_method: string;
    notes: string | null;
  } | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved'): void;
}>();

const { t } = useI18n();
const ledgerStore = useLedgerStore();

const saving = ref(false);
const mode = ref<'single' | 'bulk'>('single');
const paymentMethod = ref<PosPaymentMethod>('cash');
const amount = ref<number | null>(null);
const bulkCash = ref<number | null>(null);
const bulkOnline = ref<number | null>(null);
const notes = ref('');

const isEdit = computed(() => !!props.editEntry);

const modeOptions = computed(() => [
  { label: t('kioskUI.workspace.pos.modeSingle'), value: 'single' },
  { label: t('kioskUI.workspace.pos.modeBulk'), value: 'bulk' },
]);

const sourceOptions = computed(() => [
  { label: t('kioskUI.workspace.pos.cash'), value: 'cash' },
  { label: t('kioskUI.workspace.pos.online'), value: 'mobile_wallet' },
]);

function resetForm() {
  mode.value = 'single';
  paymentMethod.value = 'cash';
  amount.value = null;
  bulkCash.value = null;
  bulkOnline.value = null;
  notes.value = '';
  if (props.editEntry) {
    mode.value = 'single';
    amount.value = props.editEntry.amount;
    paymentMethod.value =
      props.editEntry.payment_method === 'mobile_wallet' ? 'mobile_wallet' : 'cash';
    notes.value = props.editEntry.notes || '';
  }
}

watch(
  () => props.modelValue,
  (open) => {
    if (open) resetForm();
  },
);

async function onSubmit() {
  saving.value = true;
  try {
    if (isEdit.value && props.editEntry) {
      if (!amount.value || amount.value <= 0) return;
      await ledgerStore.editPosSale({
        ledgerId: props.editEntry.id,
        amount: amount.value,
        paymentMethod: paymentMethod.value,
        notes: notes.value.trim() || null,
      });
      showSuccess(t('kioskUI.workspace.pos.editSuccess'));
    } else if (mode.value === 'bulk') {
      const cash = bulkCash.value && bulkCash.value > 0 ? bulkCash.value : 0;
      const online = bulkOnline.value && bulkOnline.value > 0 ? bulkOnline.value : 0;
      if (cash <= 0 && online <= 0) {
        await showApiError(new Error(t('kioskUI.workspace.pos.bulkRequired')));
        return;
      }
      const noteText = notes.value.trim() || null;
      if (cash > 0) {
        await ledgerStore.logPosSale({
          sessionId: props.sessionId,
          amount: cash,
          paymentMethod: 'cash',
          notes: noteText,
        });
      }
      if (online > 0) {
        await ledgerStore.logPosSale({
          sessionId: props.sessionId,
          amount: online,
          paymentMethod: 'mobile_wallet',
          notes: noteText,
        });
      }
      showSuccess(t('kioskUI.workspace.pos.saveSuccess'));
    } else {
      if (!amount.value || amount.value <= 0) return;
      await ledgerStore.logPosSale({
        sessionId: props.sessionId,
        amount: amount.value,
        paymentMethod: paymentMethod.value,
        notes: notes.value.trim() || null,
      });
      showSuccess(t('kioskUI.workspace.pos.saveSuccess'));
    }
    emit('update:modelValue', false);
    emit('saved');
  } catch (err) {
    await showApiError(err, t('kioskUI.workspace.pos.saveFailed'));
  } finally {
    saving.value = false;
  }
}
</script>
