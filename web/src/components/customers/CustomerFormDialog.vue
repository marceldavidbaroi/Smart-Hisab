<template>
  <q-dialog v-model="isOpen" persistent>
    <q-card flat bordered class="q-dialog-plugin" style="width: 500px; max-width: 90vw">
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div class="text-subtitle1 text-weight-bold">
          {{ isEdit ? $t('customers.form.editTitle') : $t('customers.form.createTitle') }}
        </div>
        <q-space />
        <q-btn flat round dense icon="close" v-close-popup class="cursor-pointer" />
      </q-card-section>

      <q-card-section class="q-py-md q-px-md">
        <q-form @submit="onSubmit" class="q-gutter-y-md">
          <!-- Full Name -->
          <q-input
            v-model="form.full_name"
            :label="$t('customers.form.fullName') + ' *'"
            dense
            outlined
            :rules="[(val) => !!val || $t('customers.form.fullNameRequired')]"
            autofocus
          />

          <!-- Phone -->
          <q-input
            v-model="form.phone"
            :label="$t('customers.form.phone')"
            dense
            outlined
            type="tel"
          />

          <!-- Category -->
          <q-select
            v-model="form.category"
            :options="categoryOptions"
            :label="$t('customers.form.category') + ' *'"
            dense
            outlined
            emit-value
            map-options
            :rules="[(val) => !!val || $t('customers.form.categoryRequired')]"
          />

          <!-- Factory Unit -->
          <q-input
            v-model="form.factory_unit"
            :label="$t('customers.form.factoryUnit')"
            dense
            outlined
          />

          <!-- Contract Worker Fields -->
          <template v-if="form.category === 'contract_worker'">
            <q-input
              v-model.number="form.contract_daily_rate"
              :label="$t('customers.form.dailyRate') + ' *'"
              dense
              outlined
              type="number"
              prefix="৳"
              :rules="[
                (val) =>
                  (val !== null && val !== undefined) || $t('customers.form.dailyRateRequired'),
                (val) => val >= 0 || 'Rate must be positive',
              ]"
            />

            <!-- Contracted Shifts -->
            <q-select
              v-model="form.contract_shifts"
              :options="shiftOptions"
              :label="$t('customers.form.contractShifts')"
              dense
              outlined
              multiple
              use-chips
              emit-value
              map-options
            />
          </template>

          <!-- Is Active (Only show if editing) -->
          <div v-if="isEdit" class="row items-center q-py-xs">
            <q-toggle v-model="form.is_active" :label="$t('customers.form.isActive')" dense />
          </div>

          <!-- Actions -->
          <div class="row justify-end q-gutter-x-sm q-mt-lg">
            <q-btn
              flat
              dense
              no-caps
              :label="$t('customers.form.cancelBtn')"
              v-close-popup
              class="cursor-pointer q-px-md text-grey-7"
            />
            <q-btn
              unelevated
              dense
              no-caps
              type="submit"
              color="primary"
              :label="$t('customers.form.saveBtn')"
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
import { supabase } from '../../boot/supabase';
import { useTenantStore } from '../../stores/tenant';
import type { Customer, CustomerCategory } from '../../stores/customers';

const props = defineProps<{
  modelValue: boolean;
  customer?: Customer | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved'): void;
}>();

const { t } = useI18n();
const tenantStore = useTenantStore();

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const isEdit = computed(() => !!props.customer);
const saving = ref(false);
const shiftOptions = ref<{ label: string; value: string }[]>([]);

const form = ref<{
  full_name: string;
  category: CustomerCategory;
  phone: string | null;
  contract_daily_rate: number | null;
  contract_shifts: string[] | null;
  factory_unit: string | null;
  is_active: boolean;
}>({
  full_name: '',
  category: 'contract_worker',
  phone: '',
  contract_daily_rate: null,
  contract_shifts: [],
  factory_unit: '',
  is_active: true,
});

const categoryOptions = computed(() => [
  { label: t('customers.form.categories.contract_worker'), value: 'contract_worker' },
  { label: t('customers.form.categories.walk_in_baki'), value: 'walk_in_baki' },
]);

watch(
  () => props.customer,
  (newCust) => {
    if (newCust) {
      form.value = {
        full_name: newCust.full_name,
        category: newCust.category,
        phone: newCust.phone || '',
        contract_daily_rate: newCust.contract_daily_rate,
        contract_shifts: newCust.contract_shifts || [],
        factory_unit: newCust.factory_unit || '',
        is_active: newCust.is_active,
      };
    } else {
      form.value = {
        full_name: '',
        category: 'contract_worker',
        phone: '',
        contract_daily_rate: null,
        contract_shifts: [],
        factory_unit: '',
        is_active: true,
      };
    }
  },
  { immediate: true },
);

// Fetch available shifts in the active tenant
async function fetchShifts() {
  const tenant = tenantStore.activeTenant;
  if (!tenant) return;
  try {
    const { data, error } = await supabase
      .from('shifts')
      .select('name')
      .eq('tenant_id', tenant.id)
      .eq('is_active', true)
      .order('name');

    if (error) throw error;
    if (data) {
      shiftOptions.value = data.map((s) => ({ label: s.name, value: s.name }));
    }
  } catch (e) {
    console.error('Failed to load shifts', e);
  }
}

watch(isOpen, (newVal) => {
  if (newVal) {
    void fetchShifts();
  }
});

async function onSubmit() {
  const tenant = tenantStore.activeTenant;
  if (!tenant) return;

  saving.value = ref(true).value;
  try {
    const payload: Partial<Customer> = {
      full_name: form.value.full_name,
      category: form.value.category,
      phone: form.value.phone || null,
      factory_unit: form.value.factory_unit || null,
      is_active: form.value.is_active,
    };

    if (form.value.category === 'contract_worker') {
      payload.contract_daily_rate = form.value.contract_daily_rate;
      payload.contract_shifts = form.value.contract_shifts;
    } else {
      payload.contract_daily_rate = null;
      payload.contract_shifts = null;
    }

    if (isEdit.value && props.customer) {
      payload.id = props.customer.id;
    }

    const row = { ...payload, tenant_id: tenant.id };
    const { error } = payload.id
      ? await supabase.from('customers').update(row).eq('id', payload.id)
      : await supabase.from('customers').insert(row);

    if (error) throw error;

    emit('saved');
    isOpen.value = false;
  } catch (e) {
    console.error(e);
  } finally {
    saving.value = false;
  }
}
</script>
