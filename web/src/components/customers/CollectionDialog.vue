<template>
  <q-dialog v-model="isOpen" persistent>
    <q-card flat bordered class="q-dialog-plugin" style="width: 450px; max-width: 90vw">
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div class="text-subtitle1 text-weight-bold">{{ $t('customers.collections.title') }}</div>
        <q-space />
        <q-btn flat round dense icon="close" v-close-popup class="cursor-pointer" />
      </q-card-section>

      <q-card-section class="q-py-md q-px-md">
        <q-form @submit="onSubmit" class="q-gutter-y-md">
          <!-- Customer Selection (if not preselected) -->
          <q-select
            v-if="!preselectedCustomerId"
            v-model="form.customerId"
            :options="customerOptions"
            :label="$t('customers.collections.customer') + ' *'"
            dense
            outlined
            emit-value
            map-options
            :rules="[(val) => !!val || $t('customers.collections.customerRequired')]"
            :disable="saving"
          />
          <div v-else class="text-subtitle2 text-weight-bold q-pb-xs">
            {{ $t('customers.collections.customer') }}: {{ preselectedCustomerName }}
          </div>

          <!-- Amount -->
          <q-input
            v-model.number="form.amount"
            :label="$t('customers.collections.amount') + ' *'"
            dense
            outlined
            type="number"
            prefix="৳"
            :rules="[
              (val) =>
                (val !== null && val !== undefined) || $t('customers.collections.amountRequired'),
              (val) => val > 0 || $t('customers.collections.amountMin'),
            ]"
            :disable="saving"
          />

          <!-- Payment Method -->
          <q-select
            v-model="form.paymentMethod"
            :options="paymentMethodOptions"
            :label="$t('customers.collections.paymentMethod') + ' *'"
            dense
            outlined
            emit-value
            map-options
            :rules="[(val) => !!val || $t('customers.collections.paymentMethodRequired')]"
            :disable="saving"
          />

          <!-- Notes -->
          <q-input
            v-model="form.notes"
            :label="$t('customers.collections.notes')"
            dense
            outlined
            :disable="saving"
          />

          <!-- Actions -->
          <div class="row justify-end q-gutter-x-sm q-mt-lg">
            <q-btn
              flat
              dense
              no-caps
              :label="$t('customers.collections.cancelBtn')"
              v-close-popup
              class="cursor-pointer q-px-md text-grey-7"
              :disable="saving"
            />
            <q-btn
              unelevated
              dense
              no-caps
              type="submit"
              color="primary"
              :label="$t('customers.collections.saveBtn')"
              :loading="saving"
              class="cursor-pointer q-px-md"
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
import { useCustomersStore } from '../../stores/customers';
import { useFeedback } from '../../composables/useFeedback';

const props = defineProps<{
  modelValue: boolean;
  preselectedCustomerId?: string | null;
  sessionId?: string | null;
  deviceToken?: string | null | undefined;
  staffId?: string | null | undefined;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved', newBalance: number): void;
}>();

const { t } = useI18n();
const customersStore = useCustomersStore();
const feedback = useFeedback();

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const saving = ref(false);
const form = ref({
  customerId: '',
  amount: null as number | null,
  paymentMethod: 'cash',
  notes: '',
});

const customerOptions = computed(() => {
  return customersStore.customers
    .filter((c) => c.is_active)
    .map((c) => ({
      label: `${c.full_name} (${c.factory_unit || 'No Unit'}) - Balance: ৳${c.outstanding_balance}`,
      value: c.id,
    }));
});

const preselectedCustomerName = computed(() => {
  if (!props.preselectedCustomerId) return '';
  const c = customersStore.customers.find((x) => x.id === props.preselectedCustomerId);
  return c ? c.full_name : '';
});

const paymentMethodOptions = computed(() => [
  { label: t('customers.collections.methods.cash'), value: 'cash' },
  { label: t('customers.collections.methods.mobile_wallet'), value: 'mobile_wallet' },
  { label: t('customers.collections.methods.bank_transfer'), value: 'bank_transfer' },
]);

watch(isOpen, (newVal) => {
  if (newVal) {
    form.value = {
      customerId: props.preselectedCustomerId || '',
      amount: null,
      paymentMethod: 'cash',
      notes: '',
    };
  }
});

async function onSubmit() {
  const custId = props.preselectedCustomerId || form.value.customerId;
  if (!custId) return;

  saving.value = true;
  try {
    const newBalance = await customersStore.recordCollection({
      customerId: custId,
      sessionId: props.sessionId || null,
      amount: form.value.amount || 0,
      paymentMethod: form.value.paymentMethod,
      notes: form.value.notes,
      deviceToken: props.deviceToken,
      staffId: props.staffId,
    });

    feedback.showSuccess(t('customers.collections.success'));
    emit('saved', newBalance);
    isOpen.value = false;
  } catch (e) {
    void feedback.showApiError(e);
  } finally {
    saving.value = false;
  }
}
</script>
