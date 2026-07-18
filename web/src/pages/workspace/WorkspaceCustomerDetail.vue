<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <!-- Back Header -->
    <div class="row items-center q-mb-md">
      <q-btn
        flat
        dense
        no-caps
        color="primary"
        icon="arrow_back"
        :label="$t('customers.detail.backBtn')"
        class="cursor-pointer"
        @click="goBack"
      />
    </div>

    <!-- Loading spinner -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="32px" />
    </div>

    <!-- Error state -->
    <div v-else-if="!customer" class="text-center text-grey-6 q-py-xl">
      Failed to load customer profile.
    </div>

    <!-- Main Content -->
    <template v-else>
      <!-- Profile Summary Card -->
      <q-card flat bordered class="q-pa-md q-mb-md bg-white border-all">
        <div class="row justify-between items-start no-wrap q-col-gutter-sm">
          <div>
            <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
              {{ customer.full_name }}
            </h1>
            <div class="row items-center q-gutter-x-md q-mt-xs">
              <q-badge :color="customer.category === 'contract_worker' ? 'primary' : 'teal'">
                {{ $t(`customers.list.categories.${customer.category}`) }}
              </q-badge>
              <span v-if="customer.phone" class="text-caption text-grey-7">
                <q-icon name="phone" size="14px" class="q-mr-xs" />{{ customer.phone }}
              </span>
              <span v-if="customer.factory_unit" class="text-caption text-grey-7">
                <q-icon name="business" size="14px" class="q-mr-xs" />{{ customer.factory_unit }}
              </span>
            </div>
          </div>

          <div class="column items-end">
            <!-- Balance Indicator -->
            <OutstandingBalanceChip :balance="customer.outstanding_balance" class="q-mb-sm" />

            <!-- Profile Actions -->
            <div class="row q-gutter-x-sm">
              <q-btn
                v-if="canWriteCustomer"
                flat
                dense
                no-caps
                color="primary"
                icon="edit"
                :label="$t('customers.detail.editBtn')"
                class="cursor-pointer font-semibold q-px-sm"
                @click="showFormDialog = true"
              />
              <q-btn
                v-if="canWriteCollection"
                unelevated
                dense
                no-caps
                color="primary"
                icon="payments"
                :label="$t('customers.detail.collectBtn')"
                class="cursor-pointer font-semibold q-px-md"
                @click="showCollectionDialog = true"
              />
            </div>
          </div>
        </div>
      </q-card>

      <!-- Statement Timeline -->
      <q-card flat bordered class="q-pa-md bg-white border-all">
        <div class="text-subtitle1 text-weight-bold text-slate-800 q-mb-md">
          {{ $t('customers.detail.title') }}
        </div>

        <CustomerStatementTable
          :attendance="attendance"
          :baki="baki"
          :collections="collections"
          :loading="loadingStatement"
        />
      </q-card>
    </template>

    <!-- Dialog Forms -->
    <CustomerFormDialog
      v-if="customer"
      v-model="showFormDialog"
      :customer="customer"
      @saved="onCustomerUpdated"
    />

    <CollectionDialog
      v-if="customer"
      v-model="showCollectionDialog"
      :preselected-customer-id="customer.id"
      :session-id="null"
      @saved="onCollectionRecorded"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '../../boot/supabase';
import { useTenantStore } from '../../stores/tenant';
import type { Customer } from '../../stores/customers';
import OutstandingBalanceChip from '../../components/customers/OutstandingBalanceChip.vue';
import CustomerStatementTable from '../../components/customers/CustomerStatementTable.vue';
import CustomerFormDialog from '../../components/customers/CustomerFormDialog.vue';
import CollectionDialog from '../../components/customers/CollectionDialog.vue';

const route = useRoute();
const router = useRouter();
const tenantStore = useTenantStore();

const customerId = computed(() => route.params.customerId as string);

const loading = ref(true);
const loadingStatement = ref(true);
const customer = ref<Customer | null>(null);

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

const attendance = ref<AttendanceItem[]>([]);
const baki = ref<BakiItem[]>([]);
const collections = ref<CollectionItem[]>([]);

const showFormDialog = ref(false);
const showCollectionDialog = ref(false);

const canWriteCustomer = computed(() =>
  tenantStore.hasModulePermission('meal_management', 'customer_write'),
);

const canWriteCollection = computed(() =>
  tenantStore.hasModulePermission('meal_management', 'collections_write'),
);

function goBack() {
  const slug = tenantStore.activeTenant?.slug;
  if (slug) {
    void router.push({ name: 'workspace-customers', params: { tenantSlug: slug } });
  }
}

async function loadProfile() {
  const tenant = tenantStore.activeTenant;
  if (!tenant) return;

  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('tenant_id', tenant.id)
      .eq('id', customerId.value)
      .single();

    if (error) throw error;
    customer.value = data as Customer;
  } catch (e) {
    console.error('Failed to load customer profile', e);
  } finally {
    loading.value = false;
  }
}

async function loadStatement() {
  const tenant = tenantStore.activeTenant;
  if (!tenant) return;

  loadingStatement.value = true;
  try {
    const [attRes, bakiRes, colRes] = await Promise.all([
      supabase
        .from('customer_daily_attendance')
        .select('*')
        .eq('tenant_id', tenant.id)
        .eq('customer_id', customerId.value)
        .order('business_date', { ascending: false }),
      supabase
        .from('baki_transactions')
        .select('*')
        .eq('tenant_id', tenant.id)
        .eq('customer_id', customerId.value)
        .order('business_date', { ascending: false }),
      supabase
        .from('customer_collections')
        .select('*')
        .eq('tenant_id', tenant.id)
        .eq('customer_id', customerId.value)
        .order('collected_at', { ascending: false }),
    ]);

    if (attRes.error) throw attRes.error;
    if (bakiRes.error) throw bakiRes.error;
    if (colRes.error) throw colRes.error;

    attendance.value = attRes.data ?? [];
    baki.value = bakiRes.data ?? [];
    collections.value = colRes.data ?? [];
  } catch (e) {
    console.error('Failed to load statement lists', e);
  } finally {
    loadingStatement.value = false;
  }
}

function onCustomerUpdated() {
  void loadProfile();
}

function onCollectionRecorded(newBalance: number) {
  if (customer.value) {
    customer.value.outstanding_balance = newBalance;
  }
  void loadStatement();
}

onMounted(() => {
  void loadProfile();
  void loadStatement();
});
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
