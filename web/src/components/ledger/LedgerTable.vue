<template>
  <div>
    <!-- Desktop Table View -->
    <q-table
      :rows="rows"
      :columns="columns"
      row-key="id"
      flat
      bordered
      dense
      class="gt-xs bg-white text-dark"
      :loading="loading"
      :no-data-label="$t('ledger.table.noTransactions')"
      :pagination="{ rowsPerPage: 15 }"
    >
      <template #body-cell-created_at="props">
        <q-td :props="props">
          <div class="text-caption text-grey-8">{{ formatDate(props.value) }}</div>
        </q-td>
      </template>

      <template #body-cell-type="props">
        <q-td :props="props">
          <q-badge
            :color="props.value === 'inflow' ? 'positive' : 'negative'"
            class="text-weight-bold uppercase q-py-xs q-px-sm"
          >
            {{ props.value }}
          </q-badge>
        </q-td>
      </template>

      <template #body-cell-category="props">
        <q-td :props="props">
          <div class="text-weight-medium text-slate-800">{{ props.value }}</div>
        </q-td>
      </template>

      <template #body-cell-amount="props">
        <q-td :props="props">
          <span
            class="font-mono text-weight-bold"
            :class="props.row.type === 'inflow' ? 'text-positive' : 'text-negative'"
          >
            {{ props.row.type === 'inflow' ? '+' : '-' }}{{ formatMoney(props.value) }}
          </span>
        </q-td>
      </template>

      <template #body-cell-payment_method="props">
        <q-td :props="props">
          <span class="text-capitalize text-grey-8">{{ props.value.replace('_', ' ') }}</span>
        </q-td>
      </template>

      <template #body-cell-operator="props">
        <q-td :props="props">
          <span class="text-weight-medium text-slate-700">
            {{ props.row.operator_staff?.full_name || $t('ledger.table.systemOwner') }}
          </span>
        </q-td>
      </template>

      <template #body-cell-session_id="props">
        <q-td :props="props">
          <q-chip
            v-if="props.value"
            outline
            color="primary"
            size="sm"
            dense
            class="font-mono q-ma-none"
          >
            {{ props.value.substring(0, 8) }}
          </q-chip>
          <span v-else class="text-caption text-grey-5">—</span>
        </q-td>
      </template>
    </q-table>

    <!-- Mobile Stacked Card View -->
    <div class="lt-sm column q-gutter-y-md">
      <div v-if="loading" class="row justify-center q-py-lg">
        <q-spinner color="primary" size="32px" />
      </div>
      <template v-else-if="rows.length === 0">
        <div class="text-center text-grey-6 q-py-lg">{{ $t('ledger.table.noTransactions') }}</div>
      </template>
      <template v-else>
        <q-card
          v-for="row in rows"
          :key="row.id"
          flat
          bordered
          class="bg-white border-all q-pa-md cursor-pointer nav-card-hover"
        >
          <div class="row justify-between items-center q-mb-sm">
            <span class="text-caption text-grey-6">{{ formatDate(row.created_at) }}</span>
            <q-badge
              :color="row.type === 'inflow' ? 'positive' : 'negative'"
              class="text-weight-bold uppercase"
              size="sm"
            >
              {{ row.type }}
            </q-badge>
          </div>

          <div class="row justify-between items-center q-mb-xs">
            <span class="text-subtitle2 text-weight-bold text-slate-800">{{ row.category }}</span>
            <span
              class="font-mono text-weight-bold"
              :class="row.type === 'inflow' ? 'text-positive' : 'text-negative'"
            >
              {{ row.type === 'inflow' ? '+' : '-' }}{{ formatMoney(row.amount) }}
            </span>
          </div>

          <div class="row justify-between items-center text-caption text-grey-7">
            <span
              >{{ $t('ledger.table.methodLabel') }}
              <span class="text-capitalize">{{ row.payment_method.replace('_', ' ') }}</span></span
            >
            <span
              >{{ $t('ledger.table.byLabel') }}
              {{ row.operator_staff?.full_name || $t('ledger.table.systemOwner') }}</span
            >
          </div>

          <div v-if="row.notes" class="q-mt-sm text-caption text-grey-6 border-top q-pt-xs">
            <q-icon name="notes" size="14px" class="q-mr-xs" />
            {{ row.notes }}
          </div>
        </q-card>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { QTableColumn } from 'quasar';
import type { LedgerEntry } from '../../stores/ledger';
import { formatMoney } from '../../utils/format';
import { useI18n } from 'vue-i18n';

defineProps<{
  rows: LedgerEntry[];
  loading?: boolean;
}>();

const { t } = useI18n();

const columns = computed<QTableColumn[]>(() => [
  {
    name: 'created_at',
    label: t('ledger.table.cols.dateTime'),
    field: 'created_at',
    align: 'left',
    sortable: true,
  },
  {
    name: 'type',
    label: t('ledger.table.cols.type'),
    field: 'type',
    align: 'left',
    sortable: true,
  },
  {
    name: 'category',
    label: t('ledger.table.cols.category'),
    field: 'category',
    align: 'left',
    sortable: true,
  },
  {
    name: 'amount',
    label: t('ledger.table.cols.amount'),
    field: 'amount',
    align: 'right',
    sortable: true,
  },
  {
    name: 'payment_method',
    label: t('ledger.table.cols.method'),
    field: 'payment_method',
    align: 'left',
    sortable: true,
  },
  {
    name: 'operator',
    label: t('ledger.table.cols.operator'),
    field: 'operator_user_id',
    align: 'left',
  },
  {
    name: 'session_id',
    label: t('ledger.table.cols.sessionId'),
    field: 'session_id',
    align: 'center',
  },
  { name: 'notes', label: t('ledger.table.cols.notes'), field: 'notes', align: 'left' },
]);

function formatDate(dateStr: string): string {
  try {
    return new Date(dateStr).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return dateStr;
  }
}
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.05);
}
.nav-card-hover:hover {
  background-color: var(--q-grey-1);
}
</style>
