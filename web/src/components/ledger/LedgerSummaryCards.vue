<template>
  <div class="row q-col-gutter-md">
    <!-- Inflow Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.inflow') }}</span>
            <q-icon name="trending_up" size="20px" class="text-positive" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-positive q-mt-xs">
            {{ formatMoney(summary?.total_inflow ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Outflow Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.outflow') }}</span>
            <q-icon name="trending_down" size="20px" class="text-negative" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-negative q-mt-xs">
            {{ formatMoney(summary?.total_outflow ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Net Profit / Loss Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.netProfit') }}</span>
            <q-icon
              :name="(summary?.net_profit_loss ?? 0) >= 0 ? 'show_chart' : 'error_outline'"
              size="20px"
              :class="(summary?.net_profit_loss ?? 0) >= 0 ? 'text-positive' : 'text-negative'"
            />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div
            v-else
            class="text-h6 text-weight-bold font-mono q-mt-xs"
            :class="(summary?.net_profit_loss ?? 0) >= 0 ? 'text-positive' : 'text-negative'"
          >
            {{ formatMoney(summary?.net_profit_loss ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Outstanding Receivables Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.receivables') }}</span>
            <q-icon name="call_received" size="20px" class="text-indigo" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-indigo q-mt-xs">
            {{ formatMoney(summary?.outstanding_receivables ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Outstanding Payables Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.payables') }}</span>
            <q-icon name="call_made" size="20px" class="text-orange-9" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-orange-9 q-mt-xs">
            {{ formatMoney(summary?.outstanding_payables ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- POS Sales Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.posRevenue') }}</span>
            <q-icon name="point_of_sale" size="20px" class="text-primary" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-primary q-mt-xs">
            {{ formatMoney(summary?.cash_sales_pos ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Market Expenses Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.procurement') }}</span>
            <q-icon name="shopping_cart" size="20px" class="text-blue-grey-7" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-blue-grey-7 q-mt-xs">
            {{ formatMoney(summary?.market_expenses ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Payroll Expenses Card -->
    <div class="col-12 col-sm-6 col-md-3">
      <q-card flat bordered class="bg-white border-all">
        <q-card-section class="q-py-sm">
          <div class="row justify-between items-center no-wrap">
            <span class="text-caption text-grey-7 text-weight-medium">{{ $t('ledger.summary.payroll') }}</span>
            <q-icon name="payments" size="20px" class="text-teal" />
          </div>
          <div v-if="loading" class="q-mt-sm">
            <q-skeleton type="text" width="60%" height="24px" />
          </div>
          <div v-else class="text-h6 text-weight-bold font-mono text-teal q-mt-xs">
            {{ formatMoney(summary?.payroll_expenses ?? 0) }}
          </div>
        </q-card-section>
      </q-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { FinancialSummary } from '../../stores/ledger';
import { formatMoney } from '../../utils/format';

defineProps<{
  summary: FinancialSummary | null;
  loading?: boolean;
}>();
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
