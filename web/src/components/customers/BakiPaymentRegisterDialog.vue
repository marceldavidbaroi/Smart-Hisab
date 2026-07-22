<template>
  <q-dialog v-model="isOpen" persistent @hide="onDialogHide">
    <q-card
      flat
      bordered
      class="q-dialog-plugin text-dark bg-white"
      style="width: 450px; max-width: 90vw"
    >
      <!-- Header -->
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div>
          <div class="text-subtitle1 text-weight-bold text-primary">
            {{ $t('customers.bakiPayment.dialog.titlePayment') }}
          </div>
          <div class="text-caption text-grey-7">
            {{ customer.full_name }} {{ customer.phone ? `(${customer.phone})` : '' }}
          </div>
        </div>
        <q-space />
        <q-btn
          flat
          round
          dense
          icon="close"
          v-close-popup
          class="cursor-pointer"
          :disable="saving"
          style="min-width: 48px; min-height: 48px"
        />
      </q-card-section>

      <!-- Form Area -->
      <q-card-section class="q-pa-md">
        <q-form @submit.prevent="onSubmit" class="q-gutter-y-sm">
          <!-- Total Outstanding Due Info -->
          <div
            class="row justify-between items-center bg-red-1 text-negative border-all rounded-borders q-pa-sm q-mb-xs"
          >
            <span class="text-caption text-weight-bold">
              {{ $t('customers.bakiPayment.dialog.totalDue') }}
            </span>
            <span class="text-subtitle1 text-weight-bold font-mono">
              ৳{{ formatMoneyDisplay(customer.outstanding_balance) }}
            </span>
          </div>

          <!-- Date Field -->
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
              {{ $t('customers.bakiPayment.dialog.date') }} *
            </label>
            <q-input
              v-model="form.date"
              dense
              outlined
              bg-color="white"
              mask="XXXX-XX-XX"
              :rules="[(val) => !!val || $t('customers.bakiPayment.dialog.dateRequired')]"
              :disable="saving"
              hide-bottom-space
            >
              <template v-slot:append>
                <q-icon name="event" class="cursor-pointer">
                  <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                    <q-date v-model="form.date" mask="YYYY-MM-DD">
                      <div class="row items-center justify-end">
                        <q-btn v-close-popup label="Close" color="primary" flat />
                      </div>
                    </q-date>
                  </q-popup-proxy>
                </q-icon>
              </template>
            </q-input>
          </div>

          <!-- Amount Input with Pay Full Due button -->
          <div>
            <div class="row justify-between items-center q-mb-xs">
              <label class="text-caption text-grey-7 text-weight-medium">
                {{ $t('customers.bakiPayment.dialog.amount') }} *
              </label>
              <q-btn
                flat
                dense
                no-caps
                color="primary"
                :label="$t('customers.bakiPayment.dialog.payFullDue')"
                class="cursor-pointer text-caption font-medium q-px-xs"
                style="min-height: 28px"
                :disable="saving || customer.outstanding_balance <= 0"
                @click="fillFullDue"
              />
            </div>
            <q-input
              v-model.number="form.amount"
              dense
              outlined
              bg-color="white"
              type="number"
              prefix="৳"
              :rules="[
                (val) =>
                  (val !== null && val !== undefined) ||
                  $t('customers.bakiPayment.dialog.amountRequired'),
                (val) => val > 0 || $t('customers.bakiPayment.dialog.amountMin'),
              ]"
              :disable="saving"
              hide-bottom-space
            />
          </div>

          <!-- Payment Method -->
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
              {{ $t('customers.bakiPayment.dialog.paymentMethod') }} *
            </label>
            <q-btn-toggle
              v-model="form.paymentMethod"
              spread
              no-caps
              toggle-color="primary"
              toggle-text-color="white"
              text-color="grey-7"
              bg-color="grey-2"
              unelevated
              :options="paymentMethodOptions"
              :disable="saving"
              style="min-height: 40px"
            />
            <!-- Cash warning if session closed -->
            <div
              v-if="form.paymentMethod === 'cash' && !sessionId"
              class="text-caption text-negative q-mt-xs text-weight-medium"
            >
              {{ $t('customers.bakiPayment.dialog.sessionRequiredCash') }}
            </div>
          </div>

          <!-- Notes -->
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
              {{ $t('customers.bakiPayment.dialog.notes') }}
            </label>
            <q-input v-model="form.notes" dense outlined bg-color="white" :disable="saving" />
          </div>

          <!-- Action Footer -->
          <div class="row justify-end q-gutter-x-sm q-mt-lg border-top q-pt-md">
            <q-btn
              flat
              dense
              no-caps
              :label="$t('customers.bakiPayment.dialog.cancelBtn')"
              v-close-popup
              class="cursor-pointer q-px-md text-grey-7"
              style="min-height: 48px; min-width: 80px"
              :disable="saving"
            />
            <q-btn
              unelevated
              dense
              no-caps
              type="submit"
              color="primary"
              :label="$t('customers.bakiPayment.dialog.saveBtn')"
              :loading="saving"
              :disable="isSaveDisabled"
              class="cursor-pointer q-px-md font-bold"
              style="min-height: 48px; min-width: 120px"
            />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import type { Customer } from '../../stores/customers';
import { useCustomersStore } from '../../stores/customers';
import { useFeedback } from '../../composables/useFeedback';
import { formatMoney } from '../../utils/format';

const props = defineProps<{
  modelValue: boolean;
  customer: Customer;
  sessionId?: string | null;
  businessDate?: string | null;
  deviceToken?: string | null;
  staffId?: string | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved', newBalance: number): void;
}>();

const { t, locale } = useI18n();
const customersStore = useCustomersStore();
const feedback = useFeedback();

const saving = ref(false);

const form = ref({
  date: '',
  amount: null as number | null,
  paymentMethod: 'cash',
  notes: '',
});

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const paymentMethodOptions = computed(() => [
  { label: t('customers.collections.methods.cash'), value: 'cash' },
  { label: t('customers.collections.methods.mobile_wallet'), value: 'mobile_wallet' },
  { label: t('customers.collections.methods.bank_transfer'), value: 'bank_transfer' },
]);

const isSaveDisabled = computed(() => {
  if (saving.value) return true;
  if (!form.value.date || form.value.amount === null || form.value.amount <= 0) return true;
  if (form.value.paymentMethod === 'cash' && !props.sessionId) return true;
  return false;
});

function formatMoneyDisplay(val: number): string {
  return formatMoney(val, locale.value === 'bn' ? 'bn' : 'en');
}

function fillFullDue() {
  if (props.customer.outstanding_balance > 0) {
    form.value.amount = props.customer.outstanding_balance;
  }
}

function resetForm() {
  const d = new Date();
  const todayStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  form.value.date = props.businessDate || todayStr;
  form.value.amount = null;
  form.value.paymentMethod = props.sessionId ? 'cash' : 'mobile_wallet';
  form.value.notes = '';
  saving.value = false;
}

watch(
  isOpen,
  (newVal) => {
    if (newVal) {
      resetForm();
    }
  },
  { immediate: true },
);

function onDialogHide() {
  resetForm();
}

async function onSubmit() {
  if (isSaveDisabled.value) return;

  saving.value = true;
  try {
    const collectedAtIso = `${form.value.date}T12:00:00Z`;

    const newBalance = await customersStore.recordCollection({
      customerId: props.customer.id,
      sessionId: form.value.paymentMethod === 'cash' ? props.sessionId || null : null,
      amount: form.value.amount || 0,
      paymentMethod: form.value.paymentMethod,
      notes: form.value.notes || undefined,
      deviceToken: props.deviceToken,
      staffId: props.staffId,
      collectedAt: collectedAtIso,
    });

    feedback.showSuccess(t('customers.bakiPayment.dialog.success'));
    emit('saved', newBalance);
    isOpen.value = false;
  } catch (err) {
    void feedback.showApiError(err);
  } finally {
    saving.value = false;
  }
}
</script>

<style scoped>
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
.font-medium {
  font-weight: 500;
}
.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.08);
}
</style>
