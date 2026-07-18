<template>
  <q-dialog
    :model-value="modelValue"
    @update:model-value="emit('update:modelValue', $event)"
    persistent
  >
    <q-card style="width: 480px; max-width: 90vw" class="bg-white text-dark q-pa-sm">
      <q-card-section class="row items-center q-pb-none">
        <div class="text-h6 text-weight-bold text-slate-800">{{ $t('ledger.manual.title') }}</div>
        <q-space />
        <q-btn icon="close" flat round dense v-close-popup class="cursor-pointer text-grey-6" />
      </q-card-section>

      <q-card-section class="q-pt-md">
        <q-form @submit.prevent="handleSave" class="q-gutter-md">
          <!-- Direction Type -->
          <div class="row q-col-gutter-sm">
            <div class="col-12">
              <q-select
                v-model="form.type"
                :options="typeOptions"
                :label="$t('ledger.manual.txType')"
                outlined
                dense
                emit-value
                map-options
                @update:model-value="handleTypeChange"
                :rules="[(val) => !!val || $t('ledger.manual.typeRequired')]"
              />
            </div>
          </div>

          <!-- Category -->
          <div class="row q-col-gutter-sm">
            <div class="col-12">
              <q-select
                v-model="form.category"
                :options="filteredCategoryOptions"
                :label="$t('ledger.manual.category')"
                outlined
                dense
                emit-value
                map-options
                :rules="[(val) => !!val || $t('ledger.manual.categoryRequired')]"
              />
            </div>
          </div>

          <!-- Amount -->
          <div class="row q-col-gutter-sm">
            <div class="col-12">
              <q-input
                v-model.number="form.amount"
                :label="$t('ledger.manual.amount')"
                type="number"
                step="0.01"
                outlined
                dense
                prefix="৳"
                :rules="[
                  (val) => (val !== null && val !== undefined) || $t('ledger.manual.amountRequired'),
                  (val) => val > 0 || $t('ledger.manual.amountMin'),
                ]"
              />
            </div>
          </div>

          <!-- Payment Method -->
          <div class="row q-col-gutter-sm">
            <div class="col-12">
              <q-select
                v-model="form.paymentMethod"
                :options="paymentMethodOptions"
                :label="$t('ledger.manual.paymentMethod')"
                outlined
                dense
                emit-value
                map-options
                :rules="[(val) => !!val || $t('ledger.manual.paymentMethodRequired')]"
              />
            </div>
          </div>

          <!-- Notes -->
          <div class="row q-col-gutter-sm">
            <div class="col-12">
              <q-input
                v-model="form.notes"
                :label="$t('ledger.manual.notesLabel')"
                type="textarea"
                rows="2"
                outlined
                dense
              />
            </div>
          </div>

          <!-- Actions -->
          <div class="row justify-end q-mt-md q-gutter-x-sm">
            <q-btn
              flat
              :label="$t('ledger.manual.cancelBtn')"
              color="grey-7"
              v-close-popup
              :disable="saving"
              class="cursor-pointer font-semibold"
            />
            <q-btn
              unelevated
              :label="$t('ledger.manual.saveBtn')"
              color="primary"
              type="submit"
              :loading="saving"
              class="cursor-pointer font-semibold q-px-md"
            />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useLedgerStore } from '../../stores/ledger';
import { showSuccess, showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

defineProps<{
  modelValue: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'created', id: string): void;
}>();

const ledgerStore = useLedgerStore();
const saving = ref(false);
const { t } = useI18n();

const form = ref({
  type: 'outflow',
  category: 'Overhead',
  amount: null as number | null,
  paymentMethod: 'cash',
  notes: '',
});

const typeOptions = computed(() => [
  { label: t('ledger.manual.types.inflow'), value: 'inflow' },
  { label: t('ledger.manual.types.outflow'), value: 'outflow' },
]);

const categoryOptions = computed(() => [
  { label: t('ledger.manual.categories.manualInflow'), value: 'Manual Inflow', type: 'inflow' },
  { label: t('ledger.manual.categories.overhead'), value: 'Overhead', type: 'outflow' },
  { label: t('ledger.manual.categories.manualOutflow'), value: 'Manual Outflow', type: 'outflow' },
]);

const filteredCategoryOptions = computed(() => {
  return categoryOptions.value.filter((opt) => opt.type === form.value.type);
});

const paymentMethodOptions = computed(() => [
  { label: t('ledger.manual.methods.cash'), value: 'cash' },
  { label: t('ledger.manual.methods.bankTransfer'), value: 'bank_transfer' },
  { label: t('ledger.manual.methods.mobileWallet'), value: 'mobile_wallet' },
]);

function handleTypeChange(newType: string) {
  if (newType === 'inflow') {
    form.value.category = 'Manual Inflow';
  } else {
    form.value.category = 'Overhead';
  }
}

async function handleSave() {
  if (form.value.amount === null || form.value.amount <= 0) return;
  saving.value = true;
  try {
    const entryId = await ledgerStore.logManualEntry({
      type: form.value.type as 'inflow' | 'outflow',
      category: form.value.category,
      amount: form.value.amount,
      paymentMethod: form.value.paymentMethod,
      notes: form.value.notes || null,
    });
    showSuccess(t('ledger.manual.messages.createSuccess'));
    emit('created', entryId);
    emit('update:modelValue', false);
    // Reset form
    form.value = {
      type: 'outflow',
      category: 'Overhead',
      amount: null,
      paymentMethod: 'cash',
      notes: '',
    };
  } catch (err) {
    await showApiError(err, t('ledger.manual.messages.saveFailed'));
  } finally {
    saving.value = false;
  }
}
</script>
