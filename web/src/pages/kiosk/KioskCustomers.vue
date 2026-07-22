<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <!-- Header with Back Button -->
    <div class="row items-center justify-between q-mb-md">
      <div class="row items-center q-gutter-x-sm">
        <q-btn
          flat
          round
          dense
          icon="arrow_back"
          color="primary"
          class="cursor-pointer"
          style="min-width: 48px; min-height: 48px"
          @click="goBack"
        />
        <div>
          <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
            {{ $t('customers.list.title') }}
          </h1>
          <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
            {{ $t('customers.list.subtitle') }}
          </p>
        </div>
      </div>

      <q-btn
        v-if="canWrite"
        unelevated
        color="primary"
        icon="add"
        :label="$t('customers.list.createBtn')"
        class="text-weight-bold cursor-pointer q-py-sm q-px-md"
        style="min-height: 48px"
        @click="openCreateDialog"
      />
    </div>

    <!-- Search / Filter Bar -->
    <div class="q-mb-md">
      <q-card flat bordered class="q-pa-sm bg-grey-2 border-all row q-col-gutter-sm items-center">
        <div class="col-12 col-sm-9">
          <q-input
            v-model="searchQuery"
            :label="$t('customers.list.searchPlaceholder')"
            dense
            outlined
            bg-color="white"
            clearable
            :disable="loading"
            @update:model-value="onSearch"
          >
            <template v-slot:prepend>
              <q-icon name="search" />
            </template>
          </q-input>
        </div>
        <div class="col-12 col-sm-3 flex items-center justify-end">
          <q-btn
            flat
            dense
            color="primary"
            icon="refresh"
            :label="$t('common.reload')"
            class="text-weight-bold cursor-pointer"
            style="min-height: 48px; min-width: 100px"
            @click="loadCustomers"
            :loading="loading"
          />
        </div>
      </q-card>
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
          <div class="text-subtitle1 text-weight-bold text-slate-800 q-mb-md">
            {{ $t('customers.list.categories.contract_worker') }}
          </div>

          <CustomerTable :rows="contractWorkers" :loading="loading" @edit="openEditDialog" />
        </q-card>
      </q-tab-panel>

      <q-tab-panel name="walk_in_baki" class="q-pa-none">
        <q-card flat bordered class="q-pa-md bg-white border-all">
          <div class="text-subtitle1 text-weight-bold text-slate-800 q-mb-md">
            {{ $t('customers.list.categories.walk_in_baki') }}
          </div>

          <CustomerTable :rows="walkInBakiCustomers" :loading="loading" @edit="openEditDialog" />
        </q-card>
      </q-tab-panel>
    </q-tab-panels>

    <!-- Form Dialog -->
    <CustomerFormDialog
      v-model="showFormDialog"
      :customer="selectedCustomer"
      :device-token="kioskStore.deviceToken"
      :staff-id="kioskStore.currentStaff?.id || null"
      :default-category="activeTab"
      @saved="loadCustomers"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import type { Customer, CustomerCategory } from '../../stores/customers';
import { useCustomersStore } from '../../stores/customers';
import { useKioskStore } from '../../stores/kiosk';
import CustomerTable from '../../components/customers/CustomerTable.vue';
import CustomerFormDialog from '../../components/customers/CustomerFormDialog.vue';
import { useFeedback } from '../../composables/useFeedback';

const router = useRouter();
const { t } = useI18n();
const feedback = useFeedback();

const customersStore = useCustomersStore();
const kioskStore = useKioskStore();

const activeTab = ref<CustomerCategory>('contract_worker');
const searchQuery = ref('');
const showFormDialog = ref(false);
const selectedCustomer = ref<Customer | null>(null);

const loading = computed(() => customersStore.loading);

const canWrite = computed(() => kioskStore.hasStaffPermission('meal_management', 'customer_write'));

const contractWorkers = computed(() =>
  customersStore.customers.filter((c) => c.category === 'contract_worker'),
);

const walkInBakiCustomers = computed(() =>
  customersStore.customers.filter((c) => c.category === 'walk_in_baki'),
);

async function loadCustomers() {
  try {
    await customersStore.fetchCustomers({
      activeOnly: true,
      search: searchQuery.value || undefined,
    });
  } catch (err) {
    void feedback.showApiError(err, t('customers.errors.loadFailed'));
  }
}

function onSearch() {
  void loadCustomers();
}

function goBack() {
  void router.push({ name: 'kiosk-workspace' });
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
