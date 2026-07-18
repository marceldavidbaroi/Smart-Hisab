<template>
  <div>
    <!-- Desktop Unified Table View -->
    <q-table
      :rows="sortedTimeline"
      :columns="columns"
      row-key="uniqueId"
      flat
      bordered
      dense
      class="gt-xs bg-white text-dark"
      :loading="loading"
      :no-data-label="$t('customers.detail.emptyStatement')"
      :pagination="{ rowsPerPage: 15 }"
    >
      <template #body-cell-date="props">
        <q-td :props="props">
          <span class="text-caption text-grey-8">{{ formatDate(props.value) }}</span>
        </q-td>
      </template>

      <template #body-cell-type="props">
        <q-td :props="props">
          <q-badge
            :color="getTypeColor(props.value)"
            class="text-weight-bold uppercase q-py-xs q-px-sm"
          >
            {{ $t(`customers.detail.types.${props.value}`) }}
          </q-badge>
        </q-td>
      </template>

      <template #body-cell-amount="props">
        <q-td :props="props">
          <span
            class="font-mono text-weight-bold"
            :class="props.row.type === 'collection' ? 'text-positive' : 'text-negative'"
          >
            {{ props.row.type === 'collection' ? '-' : '+' }}{{ formatValue(props.value) }}
          </span>
        </q-td>
      </template>

      <template #body-cell-method="props">
        <q-td :props="props">
          <span v-if="props.value" class="text-capitalize text-grey-8">
            {{ $t(`customers.collections.methods.${props.value}`) }}
          </span>
          <span v-else class="text-grey-5">—</span>
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
          <span v-else class="text-grey-5">—</span>
        </q-td>
      </template>
    </q-table>

    <!-- Mobile Unified Card View -->
    <div class="lt-sm column q-gutter-y-sm">
      <div v-if="loading" class="row justify-center q-py-lg">
        <q-spinner color="primary" size="32px" />
      </div>
      <template v-else-if="sortedTimeline.length === 0">
        <div class="text-center text-grey-6 q-py-lg">
          {{ $t('customers.detail.emptyStatement') }}
        </div>
      </template>
      <template v-else>
        <q-card
          v-for="item in sortedTimeline"
          :key="item.uniqueId"
          flat
          bordered
          class="bg-white border-all q-pa-md"
        >
          <div class="row justify-between items-center q-mb-sm">
            <span class="text-caption text-grey-6">{{ formatDate(item.date) }}</span>
            <q-badge
              :color="getTypeColor(item.type)"
              class="text-weight-bold uppercase q-py-xs q-px-sm"
              style="font-size: 10px"
            >
              {{ $t(`customers.detail.types.${item.type}`) }}
            </q-badge>
          </div>

          <div class="text-weight-medium text-dark text-sm q-mb-xs">
            {{ item.description }}
          </div>

          <div v-if="item.notes" class="text-caption text-grey-6 q-mb-sm">
            {{ item.notes }}
          </div>

          <div class="row justify-between items-center q-mt-sm">
            <div class="row items-center q-gutter-x-sm">
              <q-chip
                v-if="item.session_id"
                outline
                color="primary"
                size="xs"
                dense
                class="font-mono"
              >
                S: {{ item.session_id.substring(0, 8) }}
              </q-chip>
              <span v-if="item.method" class="text-caption text-grey-7">
                {{ $t(`customers.collections.methods.${item.method}`) }}
              </span>
            </div>
            <span
              class="font-mono text-weight-bold text-md"
              :class="item.type === 'collection' ? 'text-positive' : 'text-negative'"
            >
              {{ item.type === 'collection' ? '-' : '+' }}{{ formatValue(item.amount) }}
            </span>
          </div>
        </q-card>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatMoney } from '../../utils/format';

interface AttendanceItem {
  id: string;
  business_date: string;
  attended_shifts: string[];
  rate_applied: number;
  session_id: string;
}

interface BakiItem {
  id: string;
  business_date: string;
  items_description: string;
  amount: number;
  session_id: string;
}

interface CollectionItem {
  id: string;
  collected_at: string;
  amount: number;
  payment_method: string;
  session_id: string | null;
  notes: string | null;
}

const props = defineProps<{
  attendance: AttendanceItem[];
  baki: BakiItem[];
  collections: CollectionItem[];
  loading?: boolean;
}>();

const { t, locale } = useI18n();

interface TimelineEvent {
  uniqueId: string;
  date: string; // ISO or Date string
  type: 'attendance' | 'baki' | 'collection';
  description: string;
  amount: number;
  method?: string | undefined;
  notes?: string | undefined;
  session_id: string | null;
}

const sortedTimeline = computed<TimelineEvent[]>(() => {
  const list: TimelineEvent[] = [];

  props.attendance.forEach((a) => {
    list.push({
      uniqueId: `att-${a.id}`,
      date: a.business_date,
      type: 'attendance',
      description: `${t('customers.detail.types.attendance')} (${a.attended_shifts.join(', ')})`,
      amount: Number(a.rate_applied),
      session_id: a.session_id,
    });
  });

  props.baki.forEach((b) => {
    list.push({
      uniqueId: `baki-${b.id}`,
      date: b.business_date,
      type: 'baki',
      description: b.items_description,
      amount: Number(b.amount),
      session_id: b.session_id,
    });
  });

  props.collections.forEach((c) => {
    list.push({
      uniqueId: `col-${c.id}`,
      date: c.collected_at,
      type: 'collection',
      description: t('customers.detail.types.collection'),
      amount: Number(c.amount),
      method: c.payment_method,
      notes: c.notes || undefined,
      session_id: c.session_id,
    });
  });

  // Sort descending
  return list.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
});

const columns = computed(() => [
  {
    name: 'date',
    align: 'left' as const,
    label: t('customers.detail.cols.date'),
    field: 'date',
    sortable: true,
  },
  {
    name: 'type',
    align: 'left' as const,
    label: t('customers.detail.cols.type'),
    field: 'type',
    sortable: true,
  },
  {
    name: 'description',
    align: 'left' as const,
    label: t('customers.detail.cols.description'),
    field: 'description',
  },
  {
    name: 'amount',
    align: 'left' as const,
    label: t('customers.detail.cols.amount'),
    field: 'amount',
    sortable: true,
  },
  {
    name: 'method',
    align: 'left' as const,
    label: t('customers.detail.cols.method'),
    field: 'method',
  },
  {
    name: 'session_id',
    align: 'left' as const,
    label: t('customers.detail.cols.session'),
    field: 'session_id',
  },
]);

function formatDate(dateStr: string): string {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  return date.toLocaleDateString(locale.value === 'bn' ? 'bn-BD' : 'en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatValue(amount: number): string {
  return formatMoney(amount, locale.value === 'bn' ? 'bn' : 'en');
}

function getTypeColor(type: 'attendance' | 'baki' | 'collection'): string {
  switch (type) {
    case 'attendance':
      return 'blue-7';
    case 'baki':
      return 'orange-8';
    case 'collection':
      return 'positive';
  }
}
</script>
