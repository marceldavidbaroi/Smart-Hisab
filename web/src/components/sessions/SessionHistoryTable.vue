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
      :no-data-label="$t('sessions.history.noSessions')"
      :pagination="{ rowsPerPage: 15 }"
    >
      <template #body-cell-business_date="props">
        <q-td :props="props">
          <div class="text-weight-medium text-slate-800">{{ props.value }}</div>
        </q-td>
      </template>

      <template #body-cell-shift_name="props">
        <q-td :props="props">
          <q-chip
            outline
            color="indigo"
            size="sm"
            dense
            class="text-weight-bold uppercase q-ma-none"
          >
            {{ props.value }}
          </q-chip>
        </q-td>
      </template>

      <template #body-cell-variance="props">
        <q-td :props="props">
          <div v-if="props.row.status === 'open'" class="text-caption text-grey-5">—</div>
          <div
            v-else-if="props.value !== null"
            class="text-weight-bold font-mono"
            :class="props.value === 0 ? 'text-positive' : 'text-negative'"
          >
            {{ props.value > 0 ? '+' : '' }}{{ props.value.toFixed(2) }}
          </div>
          <div v-else class="text-caption text-grey-5">—</div>
        </q-td>
      </template>

      <template #body-cell-opening_cash="props">
        <q-td :props="props">
          <span class="font-mono">{{ props.value.toFixed(2) }}</span>
        </q-td>
      </template>

      <template #body-cell-closing_cash="props">
        <q-td :props="props">
          <span v-if="props.value === null" class="text-caption text-grey-5">—</span>
          <span v-else class="font-mono">{{ props.value.toFixed(2) }}</span>
        </q-td>
      </template>

      <template #body-cell-expected_cash="props">
        <q-td :props="props">
          <span v-if="props.value === null" class="text-caption text-grey-5">—</span>
          <span v-else class="font-mono">{{ props.value.toFixed(2) }}</span>
        </q-td>
      </template>

      <template #body-cell-status="props">
        <q-td :props="props">
          <q-badge
            :color="props.value === 'open' ? 'positive' : 'grey-7'"
            class="text-weight-bold uppercase q-py-xs q-px-sm"
          >
            {{ props.value }}
          </q-badge>
        </q-td>
      </template>

      <template #body-cell-actions="props">
        <q-td :props="props" class="text-center">
          <q-btn
            v-if="canReopen && props.row.status === 'closed'"
            flat
            dense
            color="warning"
            icon="redo"
            :label="$t('sessions.history.reopenBtn')"
            class="text-weight-bold"
            @click="$emit('reopen', props.row.id)"
          />
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
        <div class="text-center text-grey-6 q-py-lg">{{ $t('sessions.history.noSessions') }}</div>
      </template>
      <template v-else>
        <q-card v-for="row in rows" :key="row.id" flat bordered class="q-pa-md bg-white text-dark">
          <div class="row items-center justify-between q-mb-sm">
            <span class="text-weight-bold text-slate-800">{{ row.business_date }}</span>
            <q-badge
              :color="row.status === 'open' ? 'positive' : 'grey-7'"
              class="text-weight-bold uppercase"
            >
              {{ row.status }}
            </q-badge>
          </div>
          <div class="row items-center q-mb-md">
            <q-chip
              outline
              color="indigo"
              size="sm"
              dense
              class="text-weight-bold uppercase q-ma-none"
            >
              {{ row.shifts?.name || $t('sessions.history.unknownShift') }}
            </q-chip>
          </div>
          <div class="column q-gutter-y-xs text-xs text-slate-700">
            <div class="row justify-between">
              <span class="text-grey-6">{{ $t('sessions.history.openedBy') }}</span>
              <span>{{ row.opened_by_staff?.full_name || $t('sessions.history.systemUser') }}</span>
            </div>
            <div class="row justify-between">
              <span class="text-grey-6">{{ $t('sessions.history.openingCash') }}</span>
              <span class="font-mono">{{ row.opening_cash.toFixed(2) }} BDT</span>
            </div>
            <template v-if="row.status === 'closed'">
              <div class="row justify-between">
                <span class="text-grey-6">{{ $t('sessions.history.closingCount') }}</span>
                <span class="font-mono">{{ row.closing_cash?.toFixed(2) }} BDT</span>
              </div>
              <div class="row justify-between">
                <span class="text-grey-6">{{ $t('sessions.history.expected') }}</span>
                <span class="font-mono">{{ row.expected_cash?.toFixed(2) }} BDT</span>
              </div>
              <div class="row justify-between text-weight-bold">
                <span class="text-grey-6">{{ $t('sessions.history.variance') }}</span>
                <span
                  v-if="row.variance !== null"
                  :class="row.variance === 0 ? 'text-positive' : 'text-negative'"
                  class="font-mono"
                >
                  {{ row.variance > 0 ? '+' : '' }}{{ row.variance.toFixed(2) }} BDT
                </span>
                <span v-else class="text-grey-5">—</span>
              </div>
            </template>
          </div>
          <!-- Mobile Actions -->
          <div class="row justify-end q-mt-sm" v-if="canReopen && row.status === 'closed'">
            <q-btn
              flat
              dense
              color="warning"
              icon="redo"
              :label="$t('sessions.history.reopenSessionBtn')"
              class="text-weight-bold text-xs"
              @click="$emit('reopen', row.id)"
            />
          </div>
        </q-card>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { OperationalSession } from '../../stores/session';
import { useI18n } from 'vue-i18n';

type SessionWithStaff = OperationalSession & {
  opened_by_staff?: { full_name: string } | null;
};

defineProps<{
  rows: SessionWithStaff[];
  loading: boolean;
  canReopen: boolean;
}>();

defineEmits<{
  (e: 'reopen', sessionId: string): void;
}>();

const { t } = useI18n();

const columns = computed(() => [
  {
    name: 'business_date',
    align: 'left' as const,
    label: t('sessions.history.cols.businessDate'),
    field: 'business_date',
    sortable: true,
  },
  {
    name: 'shift_name',
    align: 'left' as const,
    label: t('sessions.history.cols.shift'),
    field: (row: SessionWithStaff) => row.shifts?.name || t('sessions.history.unknownShift'),
    sortable: true,
  },
  {
    name: 'status',
    align: 'center' as const,
    label: t('sessions.history.cols.status'),
    field: 'status',
    sortable: true,
  },
  {
    name: 'opened_by',
    align: 'left' as const,
    label: t('sessions.history.cols.openedBy'),
    field: (row: SessionWithStaff) =>
      row.opened_by_staff?.full_name || t('sessions.history.systemUser'),
    sortable: true,
  },
  {
    name: 'opening_cash',
    align: 'right' as const,
    label: t('sessions.history.cols.openingCash'),
    field: 'opening_cash',
    sortable: true,
  },
  {
    name: 'closing_cash',
    align: 'right' as const,
    label: t('sessions.history.cols.closingCash'),
    field: 'closing_cash',
    sortable: true,
  },
  {
    name: 'expected_cash',
    align: 'right' as const,
    label: t('sessions.history.cols.expectedCash'),
    field: 'expected_cash',
    sortable: true,
  },
  {
    name: 'variance',
    align: 'right' as const,
    label: t('sessions.history.cols.variance'),
    field: 'variance',
    sortable: true,
  },
  {
    name: 'actions',
    align: 'center' as const,
    label: t('sessions.history.cols.actions'),
    field: 'id',
  },
]);
</script>
