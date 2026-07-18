<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">{{ $t('workspace.finance.title') }}</h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('workspace.finance.subtitle') }}
        </p>
      </div>

      <!-- Date Range Controls -->
      <div class="row q-gutter-x-sm items-center">
        <q-input
          v-model="startDate"
          :label="$t('workspace.finance.startDate')"
          dense
          outlined
          bg-color="white"
          style="width: 160px"
          :disable="loading"
        >
          <template v-slot:append>
            <q-icon name="event" class="cursor-pointer">
              <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                <q-date v-model="startDate" mask="YYYY-MM-DD">
                  <div class="row items-center justify-end">
                    <q-btn v-close-popup :label="$t('common.close')" color="primary" flat />
                  </div>
                </q-date>
              </q-popup-proxy>
            </q-icon>
          </template>
        </q-input>
        <q-input
          v-model="endDate"
          :label="$t('workspace.finance.endDate')"
          dense
          outlined
          bg-color="white"
          style="width: 160px"
          :disable="loading"
        >
          <template v-slot:append>
            <q-icon name="event" class="cursor-pointer">
              <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                <q-date v-model="endDate" mask="YYYY-MM-DD">
                  <div class="row items-center justify-end">
                    <q-btn v-close-popup :label="$t('common.close')" color="primary" flat />
                  </div>
                </q-date>
              </q-popup-proxy>
            </q-icon>
          </template>
        </q-input>
        <q-btn
          unelevated
          dense
          color="primary"
          icon="refresh"
          :label="$t('workspace.finance.updateBtn')"
          class="q-px-sm cursor-pointer text-weight-bold"
          @click="loadData"
          :loading="loading"
        />
      </div>
    </div>

    <!-- Summary KPI metrics -->
    <div class="q-mb-lg">
      <LedgerSummaryCards :summary="ledgerStore.summary" :loading="loading" />
    </div>

    <!-- Daily Breakdown grid -->
    <q-card flat bordered class="q-pa-md bg-white border-all">
      <div class="text-subtitle1 text-weight-bold text-slate-800 q-mb-md">
        {{ $t('workspace.finance.cardTitle') }}
      </div>

      <DailyBreakdownTable :rows="dailyRows" :loading="loading" />
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useLedgerStore } from '../../stores/ledger';
import { useTenantStore } from '../../stores/tenant';
import { supabase } from '../../boot/supabase';
import LedgerSummaryCards from '../../components/ledger/LedgerSummaryCards.vue';
import DailyBreakdownTable from '../../components/ledger/DailyBreakdownTable.vue';
import type { DailyBreakdownRow } from '../../components/ledger/DailyBreakdownTable.vue';
import { showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const ledgerStore = useLedgerStore();
const tenantStore = useTenantStore();
const { t } = useI18n();

const loading = ref(false);

// Default range: Start of current month to today
const getStartOfMonth = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1).toISOString().split('T')[0];
};
const getToday = () => {
  return new Date().toISOString().split('T')[0];
};

const startDate = ref(getStartOfMonth());
const endDate = ref(getToday());
const dailyRows = ref<DailyBreakdownRow[]>([]);

async function loadData() {
  const tenantId = tenantStore.activeTenant?.id;
  if (!tenantId) return;

  loading.value = true;
  try {
    // 1. Fetch aggregates
    // Format dates to cover whole start and end days
    const startTz = `${startDate.value}T00:00:00Z`;
    const endTz = `${endDate.value}T23:59:59Z`;

    await ledgerStore.fetchSummary(startTz, endTz);

    // 2. Fetch daily breakdown rows via RPC
    const { data, error } = await supabase.rpc('get_daily_financial_breakdown', {
      p_tenant_id: tenantId,
      p_start_date: startDate.value,
      p_end_date: endDate.value,
    });
    if (error) throw error;
    dailyRows.value = (data ?? []) as DailyBreakdownRow[];
  } catch (err) {
    await showApiError(err, t('workspace.finance.failedLoad'));
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  void loadData();
});
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
