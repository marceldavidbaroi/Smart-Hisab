<template>
  <q-dialog v-model="isOpen" persistent @hide="onDialogHide">
    <q-card
      flat
      bordered
      class="q-dialog-plugin text-dark bg-white"
      style="width: 750px; max-width: 95vw"
    >
      <!-- Header -->
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div>
          <div class="text-subtitle1 text-weight-bold text-primary">
            {{ $t('customers.bakiPayment.dialog.titleHistory') }}
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
          style="min-width: 48px; min-height: 48px"
        />
      </q-card-section>

      <!-- Timeline statement container -->
      <q-card-section class="q-pa-md max-height-dialog-scroll">
        <div class="row justify-between items-center q-mb-md">
          <span class="text-subtitle2 text-weight-bold text-slate-800">
            {{ $t('customers.bakiPayment.reportTitle') }}
          </span>
          <OutstandingBalanceChip :balance="customer.outstanding_balance" />
        </div>

        <div class="border-all rounded-borders q-pa-sm">
          <CustomerStatementTable :statement="statement" :loading="loadingTimeline" />
        </div>
      </q-card-section>

      <!-- Footer -->
      <q-card-actions class="q-px-md q-pb-md q-pt-none border-top row justify-end">
        <q-btn
          flat
          dense
          no-caps
          label="Close"
          v-close-popup
          class="cursor-pointer q-px-md text-grey-7"
          style="min-height: 48px; min-width: 100px"
        />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { supabase } from '../../boot/supabase';
import type { Customer } from '../../stores/customers';
import { useKioskStore } from '../../stores/kiosk';
import OutstandingBalanceChip from './OutstandingBalanceChip.vue';
import CustomerStatementTable from './CustomerStatementTable.vue';

const props = defineProps<{
  modelValue: boolean;
  customer: Customer;
  deviceToken?: string | null;
  staffId?: string | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
}>();

const loadingTimeline = ref(false);

interface TimelineEvent {
  uniqueId: string;
  date: string;
  type: 'attendance' | 'baki' | 'collection';
  description: string;
  amount: number;
  method?: string | undefined;
  notes?: string | undefined;
  session_id: string | null;
}

const statement = ref<TimelineEvent[]>([]);

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const kioskStore = useKioskStore();

function resetForm() {
  statement.value = [];
}

async function fetchTimeline() {
  const tenantId = kioskStore.tenantId;
  const token = props.deviceToken;
  const staff = props.staffId;
  if (!tenantId || !token || !staff) {
    console.error('Missing credentials for timeline fetch:', { tenantId, token, staff });
    return;
  }

  loadingTimeline.value = true;
  try {
    interface StatementRow {
      unique_id: string;
      event_date: string;
      event_type: string;
      description: string;
      amount: string | number;
      method: string | null;
      notes: string | null;
      session_id: string | null;
    }

    const { data, error } = await supabase.rpc('get_customer_statement_kiosk', {
      p_tenant_id: tenantId,
      p_device_token: token,
      p_staff_id: staff,
      p_customer_id: props.customer.id,
      p_days_count: 30,
    });
    if (error) throw error;

    statement.value = ((data as StatementRow[]) || []).map((row: StatementRow) => ({
      uniqueId: row.unique_id,
      date: row.event_date,
      type: row.event_type as 'attendance' | 'baki' | 'collection',
      description: row.description,
      amount: Number(row.amount),
      method: row.method || undefined,
      notes: row.notes || undefined,
      session_id: row.session_id,
    }));
  } catch (err) {
    console.error('Failed to load timeline:', err);
  } finally {
    loadingTimeline.value = false;
  }
}

watch(
  isOpen,
  (newVal) => {
    if (newVal) {
      resetForm();
      void fetchTimeline();
    }
  },
  { immediate: true },
);

function onDialogHide() {
  resetForm();
}
</script>

<style scoped>
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
.max-height-dialog-scroll {
  max-height: 70vh;
  overflow-y: auto;
}
.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.08);
}
</style>
