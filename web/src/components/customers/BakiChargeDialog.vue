<template>
  <q-dialog v-model="isOpen" persistent>
    <q-card flat bordered class="q-dialog-plugin" style="width: 450px; max-width: 90vw">
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div class="text-subtitle1 text-weight-bold">{{ $t('customers.baki.title') }}</div>
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
            :label="$t('customers.baki.customer') + ' *'"
            dense
            outlined
            emit-value
            map-options
            :rules="[(val) => !!val || $t('customers.baki.customerRequired')]"
            :disable="saving"
          />
          <div v-else class="text-subtitle2 text-weight-bold q-pb-xs">
            {{ $t('customers.baki.customer') }}: {{ preselectedCustomerName }}
          </div>

          <!-- Description -->
          <q-input
            v-model="form.itemsDescription"
            :label="$t('customers.baki.itemsDescription') + ' *'"
            dense
            outlined
            :rules="[(val) => !!val || $t('customers.baki.itemsRequired')]"
            :disable="saving"
          />

          <!-- Amount -->
          <q-input
            v-model.number="form.amount"
            :label="$t('customers.baki.amount') + ' *'"
            dense
            outlined
            type="number"
            prefix="৳"
            :rules="[
              (val) => (val !== null && val !== undefined) || $t('customers.baki.amountRequired'),
              (val) => val > 0 || $t('customers.baki.amountMin'),
            ]"
            :disable="saving"
          />

          <!-- Actions -->
          <div class="row justify-end q-gutter-x-sm q-mt-lg">
            <q-btn
              flat
              dense
              no-caps
              :label="$t('customers.baki.cancelBtn')"
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
              :label="$t('customers.baki.saveBtn')"
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
  sessionId: string;
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
  itemsDescription: '',
  amount: null as number | null,
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

watch(isOpen, (newVal) => {
  if (newVal) {
    form.value = {
      customerId: props.preselectedCustomerId || '',
      itemsDescription: '',
      amount: null,
    };
  }
});

async function onSubmit() {
  const custId = props.preselectedCustomerId || form.value.customerId;
  if (!custId) return;

  saving.value = true;
  try {
    const newBalance = await customersStore.recordBaki({
      customerId: custId,
      sessionId: props.sessionId,
      itemsDescription: form.value.itemsDescription,
      amount: form.value.amount || 0,
      deviceToken: props.deviceToken,
      staffId: props.staffId,
    });

    feedback.showSuccess(t('customers.baki.success'));
    emit('saved', newBalance);
    isOpen.value = false;
  } catch (e) {
    void feedback.showApiError(e);
  } finally {
    saving.value = false;
  }
}
</script>
