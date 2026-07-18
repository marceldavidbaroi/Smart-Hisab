<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">{{ $t('workspace.ledger.title') }}</h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('workspace.ledger.subtitle') }}
        </p>
      </div>

      <q-btn
        v-if="canWriteManual"
        unelevated
        color="primary"
        icon="add"
        :label="$t('workspace.ledger.logEntryBtn')"
        class="text-weight-bold cursor-pointer"
        @click="showEntryDialog = true"
      />
    </div>

    <!-- Filters Bar -->
    <div class="q-mb-md">
      <LedgerFiltersBar v-model="filters" :loading="ledgerStore.loading" @apply="loadLedger" />
    </div>

    <!-- Table Registry -->
    <q-card flat bordered class="q-pa-md bg-white border-all">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-subtitle1 text-weight-bold text-slate-800">{{ $t('workspace.ledger.cardTitle') }}</div>
        <q-btn
          flat
          dense
          color="primary"
          icon="refresh"
          :label="$t('common.reload')"
          class="text-weight-bold"
          @click="loadLedger"
          :loading="ledgerStore.loading"
        />
      </div>

      <LedgerTable :rows="ledgerStore.entries" :loading="ledgerStore.loading" />
    </q-card>

    <!-- Dialog Form -->
    <ManualLedgerEntryDialog v-model="showEntryDialog" @created="loadLedger" />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useLedgerStore } from '../../stores/ledger';
import { useTenantStore } from '../../stores/tenant';
import LedgerFiltersBar from '../../components/ledger/LedgerFiltersBar.vue';
import LedgerTable from '../../components/ledger/LedgerTable.vue';
import ManualLedgerEntryDialog from '../../components/ledger/ManualLedgerEntryDialog.vue';
import { showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const ledgerStore = useLedgerStore();
const tenantStore = useTenantStore();
const { t } = useI18n();

const showEntryDialog = ref(false);
const filters = ref({
  start: '',
  end: '',
  type: '',
  paymentMethod: '',
});

const canWriteManual = computed(() =>
  tenantStore.hasModulePermission('financial_ledger', 'ledger_write_manual'),
);

async function loadLedger() {
  try {
    await ledgerStore.fetchEntries(filters.value);
  } catch (err) {
    await showApiError(err, t('workspace.ledger.failedLoad'));
  }
}

onMounted(() => {
  void loadLedger();
});
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
