<template>
  <q-card flat bordered class="q-pa-sm bg-grey-2 border-all row q-col-gutter-sm items-center">
    <div class="col-12 col-sm-3">
      <q-input
        v-model="filters.start"
        :label="$t('ledger.filters.startDate')"
        dense
        outlined
        bg-color="white"
        :disable="loading"
      >
        <template v-slot:append>
          <q-icon name="event" class="cursor-pointer">
            <q-popup-proxy cover transition-show="scale" transition-hide="scale">
              <q-date v-model="filters.start" mask="YYYY-MM-DD">
                <div class="row items-center justify-end">
                  <q-btn
                    v-close-popup
                    :label="$t('ledger.filters.closeBtn')"
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
    <div class="col-12 col-sm-3">
      <q-input
        v-model="filters.end"
        :label="$t('ledger.filters.endDate')"
        dense
        outlined
        bg-color="white"
        :disable="loading"
      >
        <template v-slot:append>
          <q-icon name="event" class="cursor-pointer">
            <q-popup-proxy cover transition-show="scale" transition-hide="scale">
              <q-date v-model="filters.end" mask="YYYY-MM-DD">
                <div class="row items-center justify-end">
                  <q-btn
                    v-close-popup
                    :label="$t('ledger.filters.closeBtn')"
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
    <div class="col-6 col-sm-2">
      <q-select
        v-model="filters.type"
        :options="typeOptions"
        :label="$t('ledger.filters.type')"
        dense
        outlined
        emit-value
        map-options
        bg-color="white"
        :disable="loading"
      />
    </div>
    <div class="col-6 col-sm-2">
      <q-select
        v-model="filters.paymentMethod"
        :options="paymentMethodOptions"
        :label="$t('ledger.filters.paymentMethod')"
        dense
        outlined
        emit-value
        map-options
        bg-color="white"
        :disable="loading"
      />
    </div>
    <div class="col-12 col-sm-2 flex items-center justify-end q-gutter-x-xs">
      <q-btn
        flat
        dense
        color="grey-7"
        icon="clear"
        :label="$t('ledger.filters.clearBtn')"
        @click="clearFilters"
        :disable="loading"
        class="cursor-pointer font-semibold"
      />
      <q-btn
        unelevated
        dense
        color="primary"
        icon="filter_alt"
        :label="$t('ledger.filters.applyBtn')"
        @click="applyFilters"
        :loading="loading"
        class="cursor-pointer font-semibold q-px-sm"
      />
    </div>
  </q-card>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';

export interface LedgerFilters {
  start?: string;
  end?: string;
  type?: string;
  paymentMethod?: string;
}

const props = defineProps<{
  modelValue: LedgerFilters;
  loading?: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: LedgerFilters): void;
  (e: 'apply'): void;
}>();

const { t } = useI18n();

const filters = ref<LedgerFilters>({ ...props.modelValue });

watch(
  () => props.modelValue,
  (newVal) => {
    filters.value = { ...newVal };
  },
  { deep: true },
);

const typeOptions = computed(() => [
  { label: t('ledger.filters.types.all'), value: '' },
  { label: t('ledger.filters.types.inflow'), value: 'inflow' },
  { label: t('ledger.filters.types.outflow'), value: 'outflow' },
]);

const paymentMethodOptions = computed(() => [
  { label: t('ledger.filters.methods.all'), value: '' },
  { label: t('ledger.filters.methods.cash'), value: 'cash' },
  { label: t('ledger.filters.methods.bankTransfer'), value: 'bank_transfer' },
  { label: t('ledger.filters.methods.mobileWallet'), value: 'mobile_wallet' },
]);

function applyFilters() {
  emit('update:modelValue', { ...filters.value });
  emit('apply');
}

function clearFilters() {
  filters.value = {
    start: '',
    end: '',
    type: '',
    paymentMethod: '',
  };
  applyFilters();
}
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
