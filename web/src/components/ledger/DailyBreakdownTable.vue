<template>
  <div>
    <!-- Desktop Table View -->
    <q-table
      :rows="rows"
      :columns="columns"
      row-key="transaction_date"
      flat
      bordered
      dense
      class="gt-xs bg-white text-dark"
      :loading="loading"
      :no-data-label="$t('ledger.daily.noRecords')"
      :pagination="{ rowsPerPage: 10 }"
    >
      <template #body-cell-transaction_date="props">
        <q-td :props="props">
          <div class="text-weight-bold text-slate-800">{{ formatDate(props.value) }}</div>
        </q-td>
      </template>

      <template #body-cell-total_inflow="props">
        <q-td :props="props">
          <span class="font-mono text-positive">{{ formatMoney(props.value) }}</span>
        </q-td>
      </template>

      <template #body-cell-total_outflow="props">
        <q-td :props="props">
          <span class="font-mono text-negative">{{ formatMoney(props.value) }}</span>
        </q-td>
      </template>

      <template #body-cell-net_profit="props">
        <q-td :props="props">
          <span
            class="font-mono text-weight-bold"
            :class="props.value >= 0 ? 'text-positive' : 'text-negative'"
          >
            {{ props.value >= 0 ? '+' : '' }}{{ formatMoney(props.value) }}
          </span>
        </q-td>
      </template>

      <!-- Category Dynamic Cells -->
      <template v-for="col in categoryCols" :key="col" #[`body-cell-${col}`]="props">
        <q-td :props="props">
          <span v-if="props.value" class="font-mono">{{ formatMoney(props.value) }}</span>
          <span v-else class="text-grey-4">—</span>
        </q-td>
      </template>
    </q-table>

    <!-- Mobile Card Stack -->
    <div class="lt-sm column q-gutter-y-md">
      <div v-if="loading" class="row justify-center q-py-lg">
        <q-spinner color="primary" size="32px" />
      </div>
      <template v-else-if="rows.length === 0">
        <div class="text-center text-grey-6 q-py-lg">{{ $t('ledger.daily.noRecords') }}</div>
      </template>
      <template v-else>
        <q-card
          v-for="row in rows"
          :key="row.transaction_date"
          flat
          bordered
          class="bg-white border-all q-pa-md"
        >
          <div class="row justify-between items-center border-bottom q-pb-sm q-mb-sm">
            <span class="text-subtitle2 text-weight-bold text-slate-800">{{
              formatDate(row.transaction_date)
            }}</span>
            <span
              class="font-mono text-weight-bold"
              :class="row.net_profit >= 0 ? 'text-positive' : 'text-negative'"
            >
              {{ $t('ledger.daily.netLabel') }} {{ row.net_profit >= 0 ? '+' : ''
              }}{{ formatMoney(row.net_profit) }}
            </span>
          </div>

          <div class="row text-caption text-grey-8 q-col-gutter-xs">
            <div class="col-6">
              {{ $t('ledger.daily.inflowLabel') }}
              <span class="text-positive text-weight-medium">{{
                formatMoney(row.total_inflow)
              }}</span>
            </div>
            <div class="col-6">
              {{ $t('ledger.daily.outflowLabel') }}
              <span class="text-negative text-weight-medium">{{
                formatMoney(row.total_outflow)
              }}</span>
            </div>
          </div>

          <div class="q-mt-sm border-top q-pt-sm">
            <div class="text-xxs text-grey-5 uppercase tracking-wider text-weight-bold q-mb-xs">
              {{ $t('ledger.daily.categoryCosts') }}
            </div>
            <div class="row q-col-gutter-xs text-caption">
              <div v-if="row.pos_sales" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.pos') }}
                <span class="text-dark text-weight-medium">{{ formatMoney(row.pos_sales) }}</span>
              </div>
              <div v-if="row.debt_collections" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.collections') }}
                <span class="text-dark text-weight-medium">{{
                  formatMoney(row.debt_collections)
                }}</span>
              </div>
              <div v-if="row.raw_materials" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.rawMaterials') }}
                <span class="text-dark text-weight-medium">{{
                  formatMoney(row.raw_materials)
                }}</span>
              </div>
              <div v-if="row.payroll_expenses" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.payroll') }}
                <span class="text-dark text-weight-medium">{{
                  formatMoney(row.payroll_expenses)
                }}</span>
              </div>
              <div v-if="row.supplier_payouts" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.supplierPay') }}
                <span class="text-dark text-weight-medium">{{
                  formatMoney(row.supplier_payouts)
                }}</span>
              </div>
              <div v-if="row.staff_advances" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.staffAdvance') }}
                <span class="text-dark text-weight-medium">{{
                  formatMoney(row.staff_advances)
                }}</span>
              </div>
              <div v-if="row.overhead_expenses" class="col-6 text-grey-7">
                {{ $t('ledger.daily.categories.overhead') }}
                <span class="text-dark text-weight-medium">{{
                  formatMoney(row.overhead_expenses)
                }}</span>
              </div>
            </div>
          </div>
        </q-card>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { QTableColumn } from 'quasar';
import { formatMoney } from '../../utils/format';
import { useI18n } from 'vue-i18n';

export interface DailyBreakdownRow {
  transaction_date: string;
  total_inflow: number;
  total_outflow: number;
  net_profit: number;
  pos_sales?: number;
  debt_collections?: number;
  raw_materials?: number;
  payroll_expenses?: number;
  supplier_payouts?: number;
  staff_advances?: number;
  overhead_expenses?: number;
}

defineProps<{
  rows: DailyBreakdownRow[];
  loading?: boolean;
}>();

const { t } = useI18n();

const columns = computed<QTableColumn[]>(() => [
  {
    name: 'transaction_date',
    label: t('ledger.daily.cols.date'),
    field: 'transaction_date',
    align: 'left',
    sortable: true,
  },
  {
    name: 'total_inflow',
    label: t('ledger.daily.cols.inflow'),
    field: 'total_inflow',
    align: 'right',
    sortable: true,
  },
  {
    name: 'total_outflow',
    label: t('ledger.daily.cols.outflow'),
    field: 'total_outflow',
    align: 'right',
    sortable: true,
  },
  {
    name: 'net_profit',
    label: t('ledger.daily.cols.netProfit'),
    field: 'net_profit',
    align: 'right',
    sortable: true,
  },
  { name: 'pos_sales', label: t('ledger.daily.cols.posSales'), field: 'pos_sales', align: 'right' },
  {
    name: 'debt_collections',
    label: t('ledger.daily.cols.debtCollection'),
    field: 'debt_collections',
    align: 'right',
  },
  {
    name: 'raw_materials',
    label: t('ledger.daily.cols.rawMaterials'),
    field: 'raw_materials',
    align: 'right',
  },
  {
    name: 'payroll_expenses',
    label: t('ledger.daily.cols.payroll'),
    field: 'payroll_expenses',
    align: 'right',
  },
  {
    name: 'supplier_payouts',
    label: t('ledger.daily.cols.supplierPayouts'),
    field: 'supplier_payouts',
    align: 'right',
  },
  {
    name: 'staff_advances',
    label: t('ledger.daily.cols.staffAdvances'),
    field: 'staff_advances',
    align: 'right',
  },
  {
    name: 'overhead_expenses',
    label: t('ledger.daily.cols.overhead'),
    field: 'overhead_expenses',
    align: 'right',
  },
]);

const categoryCols = [
  'pos_sales',
  'debt_collections',
  'raw_materials',
  'payroll_expenses',
  'supplier_payouts',
  'staff_advances',
  'overhead_expenses',
] as const;

function formatDate(dateStr: string): string {
  try {
    return new Date(dateStr).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      timeZone: 'UTC',
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
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
