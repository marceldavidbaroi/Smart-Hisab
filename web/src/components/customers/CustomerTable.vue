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
      :no-data-label="$t('customers.list.empty')"
      :pagination="{ rowsPerPage: 15 }"
    >
      <template #body-cell-full_name="props">
        <q-td
          :props="props"
          class="cursor-pointer text-weight-bold text-primary"
          @click="goToDetail(props.row.id)"
        >
          {{ props.value }}
        </q-td>
      </template>

      <template #body-cell-category="props">
        <q-td :props="props">
          <q-badge
            :color="props.value === 'contract_worker' ? 'primary' : 'teal'"
            class="text-weight-bold uppercase q-py-xs q-px-sm"
          >
            {{ $t(`customers.list.categories.${props.value}`) }}
          </q-badge>
        </q-td>
      </template>

      <template #body-cell-phone="props">
        <q-td :props="props">
          <span class="text-grey-8">{{ props.value || '—' }}</span>
        </q-td>
      </template>

      <template #body-cell-outstanding_balance="props">
        <q-td :props="props">
          <span
            class="font-mono text-weight-bold"
            :class="
              props.value > 0 ? 'text-negative' : props.value < 0 ? 'text-positive' : 'text-grey-7'
            "
          >
            {{ formatValue(props.value) }}
          </span>
        </q-td>
      </template>

      <template #body-cell-factory_unit="props">
        <q-td :props="props">
          <span class="text-grey-8">{{ props.value || '—' }}</span>
        </q-td>
      </template>

      <template #body-cell-is_active="props">
        <q-td :props="props">
          <q-badge :color="props.value ? 'green' : 'grey-5'" class="text-weight-bold">
            {{
              props.value ? $t('customers.list.cols.active') : $t('customers.list.cols.inactive')
            }}
          </q-badge>
        </q-td>
      </template>

      <template #body-cell-actions="props">
        <q-td :props="props" class="text-right">
          <q-btn
            flat
            round
            dense
            color="primary"
            icon="edit"
            class="cursor-pointer"
            @click.stop="editCustomer(props.row)"
          />
        </q-td>
      </template>
    </q-table>

    <!-- Mobile Stacked Card View -->
    <div class="lt-sm column q-gutter-y-sm">
      <div v-if="loading" class="row justify-center q-py-lg">
        <q-spinner color="primary" size="32px" />
      </div>
      <template v-else-if="rows.length === 0">
        <div class="text-center text-grey-6 q-py-lg">{{ $t('customers.list.empty') }}</div>
      </template>
      <template v-else>
        <q-card
          v-for="row in rows"
          :key="row.id"
          flat
          bordered
          class="bg-white border-all q-pa-md cursor-pointer nav-card-hover"
          @click="goToDetail(row.id)"
        >
          <div class="row justify-between items-start q-mb-xs">
            <span class="text-subtitle2 text-weight-bold text-primary">{{ row.full_name }}</span>
            <q-badge
              :color="row.category === 'contract_worker' ? 'primary' : 'teal'"
              class="text-weight-bold uppercase q-py-xs q-px-sm"
              style="font-size: 10px"
            >
              {{ $t(`customers.list.categories.${row.category}`) }}
            </q-badge>
          </div>

          <div class="row justify-between items-center q-mt-sm">
            <div class="column">
              <span v-if="row.phone" class="text-caption text-grey-7">
                <q-icon name="phone" size="12px" class="q-mr-xs" />{{ row.phone }}
              </span>
              <span v-if="row.factory_unit" class="text-caption text-grey-7">
                <q-icon name="business" size="12px" class="q-mr-xs" />{{ row.factory_unit }}
              </span>
            </div>
            <div class="text-right column">
              <span class="text-caption text-grey-6">{{
                $t('customers.list.cols.outstanding')
              }}</span>
              <span
                class="font-mono text-weight-bold text-md"
                :class="
                  row.outstanding_balance > 0
                    ? 'text-negative'
                    : row.outstanding_balance < 0
                      ? 'text-positive'
                      : 'text-grey-7'
                "
              >
                {{ formatValue(row.outstanding_balance) }}
              </span>
            </div>
          </div>

          <q-separator class="q-my-sm" />

          <div class="row justify-between items-center">
            <q-badge :color="row.is_active ? 'green' : 'grey-5'">
              {{
                row.is_active
                  ? $t('customers.list.cols.active')
                  : $t('customers.list.cols.inactive')
              }}
            </q-badge>
            <q-btn
              flat
              round
              dense
              color="primary"
              icon="edit"
              class="cursor-pointer"
              @click.stop="editCustomer(row)"
            />
          </div>
        </q-card>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useTenantStore } from '../../stores/tenant';
import type { Customer } from '../../stores/customers';
import { formatMoney } from '../../utils/format';

defineProps<{
  rows: Customer[];
  loading?: boolean;
}>();

const emit = defineEmits<{
  (e: 'edit', customer: Customer): void;
}>();

const { t, locale } = useI18n();
const router = useRouter();
const tenantStore = useTenantStore();

const columns = computed(() => [
  {
    name: 'full_name',
    align: 'left' as const,
    label: t('customers.list.cols.name'),
    field: 'full_name',
    sortable: true,
  },
  {
    name: 'category',
    align: 'left' as const,
    label: t('customers.list.cols.category'),
    field: 'category',
    sortable: true,
  },
  {
    name: 'phone',
    align: 'left' as const,
    label: t('customers.list.cols.phone'),
    field: 'phone',
    sortable: true,
  },
  {
    name: 'outstanding_balance',
    align: 'left' as const,
    label: t('customers.list.cols.outstanding'),
    field: 'outstanding_balance',
    sortable: true,
  },
  {
    name: 'factory_unit',
    align: 'left' as const,
    label: t('customers.list.cols.factoryUnit'),
    field: 'factory_unit',
    sortable: true,
  },
  {
    name: 'is_active',
    align: 'left' as const,
    label: t('customers.list.cols.status'),
    field: 'is_active',
    sortable: true,
  },
  {
    name: 'actions',
    align: 'right' as const,
    label: '',
    field: 'actions',
  },
]);

function formatValue(val: number) {
  const abs = Math.abs(val);
  const formatted = formatMoney(abs, locale.value === 'bn' ? 'bn' : 'en');
  if (val < 0) {
    return `-${formatted} (Prepaid)`;
  }
  return formatted;
}

function goToDetail(customerId: string) {
  const slug = tenantStore.activeTenant?.slug;
  if (slug) {
    void router.push({
      name: 'workspace-customer-detail',
      params: { tenantSlug: slug, customerId },
    });
  }
}

function editCustomer(customer: Customer) {
  emit('edit', customer);
}
</script>
