<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
          {{ $t('customers.list.title') }}
        </h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('customers.list.subtitle') }}
        </p>
      </div>

      <q-btn
        v-if="canWrite"
        unelevated
        color="primary"
        icon="add"
        :label="$t('customers.list.createBtn')"
        class="text-weight-bold cursor-pointer"
        @click="openCreateDialog"
      />
    </div>

    <!-- Filters Bar -->
    <div class="q-mb-md">
      <CustomerFiltersBar
        :loading="customersStore.loading"
        @apply="onApplyFilters"
        @clear="onClearFilters"
      />
    </div>

    <!-- Grouping Tabs -->
    <q-tabs
      v-model="activeTab"
      dense
      class="text-grey-7 bg-grey-2 q-mb-md rounded-borders"
      active-color="primary"
      indicator-color="primary"
      align="justify"
      narrow-indicator
    >
      <q-tab name="contract_worker" :label="$t('customers.list.categories.contract_worker')" />
      <q-tab name="walk_in_baki" :label="$t('customers.list.categories.walk_in_baki')" />
    </q-tabs>

    <!-- Tab Panels showing Grouped Customers -->
    <q-tab-panels v-model="activeTab" animated class="bg-transparent">
      <q-tab-panel name="contract_worker" class="q-pa-none">
        <q-card flat bordered class="q-pa-md bg-white border-all">
          <div class="row items-center justify-between q-mb-md">
            <div class="text-subtitle1 text-weight-bold text-slate-800">
              {{ $t('customers.list.categories.contract_worker') }}
            </div>
            <q-btn
              flat
              dense
              color="primary"
              icon="refresh"
              :label="$t('common.reload')"
              class="text-weight-bold"
              @click="loadCustomers"
              :loading="customersStore.loading"
            />
          </div>

          <CustomerTable
            :rows="contractWorkers"
            :loading="customersStore.loading"
            @edit="openEditDialog"
          />
        </q-card>
      </q-tab-panel>

      <q-tab-panel name="walk_in_baki" class="q-pa-none">
        <q-card flat bordered class="q-pa-md bg-white border-all">
          <div class="row items-center justify-between q-mb-md">
            <div class="text-subtitle1 text-weight-bold text-slate-800">
              {{ $t('customers.list.categories.walk_in_baki') }}
            </div>
            <q-btn
              flat
              dense
              color="primary"
              icon="refresh"
              :label="$t('common.reload')"
              class="text-weight-bold"
              @click="loadCustomers"
              :loading="customersStore.loading"
            />
          </div>

          <CustomerTable
            :rows="walkInBakiCustomers"
            :loading="customersStore.loading"
            @edit="openEditDialog"
          />
        </q-card>
      </q-tab-panel>
    </q-tab-panels>

    <!-- Form Dialog -->
    <CustomerFormDialog
      v-model="showFormDialog"
      :customer="selectedCustomer"
      :default-category="activeTab"
      @saved="loadCustomers"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import type { Customer, CustomerCategory } from '../../stores/customers';
import { useCustomersStore } from '../../stores/customers';
import { useTenantStore } from '../../stores/tenant';
import CustomerFiltersBar from '../../components/customers/CustomerFiltersBar.vue';
import CustomerTable from '../../components/customers/CustomerTable.vue';
import CustomerFormDialog from '../../components/customers/CustomerFormDialog.vue';
import { useFeedback } from '../../composables/useFeedback';

const customersStore = useCustomersStore();
const tenantStore = useTenantStore();
const feedback = useFeedback();
const { t } = useI18n();

const showFormDialog = ref(false);
const selectedCustomer = ref<Customer | null>(null);
const activeTab = ref<CustomerCategory>('contract_worker');

const activeFilters = ref<{
  category?: CustomerCategory | undefined;
  activeOnly?: boolean | undefined;
  search?: string | undefined;
}>({
  activeOnly: true,
});

const canWrite = computed(() =>
  tenantStore.hasModulePermission('meal_management', 'customer_write'),
);

const contractWorkers = computed(() =>
  customersStore.customers.filter((c) => c.category === 'contract_worker'),
);

const walkInBakiCustomers = computed(() =>
  customersStore.customers.filter((c) => c.category === 'walk_in_baki'),
);

async function loadCustomers() {
  try {
    await customersStore.fetchCustomers(activeFilters.value);
  } catch (err) {
    void feedback.showApiError(err, t('customers.errors.loadFailed'));
  }
}

function onApplyFilters(filters: {
  search: string;
  category: CustomerCategory | '';
  activeOnly: boolean;
}) {
  activeFilters.value = {
    search: filters.search || undefined,
    category: filters.category || undefined,
    activeOnly: filters.activeOnly,
  };
  void loadCustomers();
}

function onClearFilters() {
  activeFilters.value = {
    activeOnly: true,
  };
  void loadCustomers();
}

function openCreateDialog() {
  selectedCustomer.value = null;
  showFormDialog.value = true;
}

function openEditDialog(customer: Customer) {
  selectedCustomer.value = customer;
  showFormDialog.value = true;
}

onMounted(() => {
  void loadCustomers();
});
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
