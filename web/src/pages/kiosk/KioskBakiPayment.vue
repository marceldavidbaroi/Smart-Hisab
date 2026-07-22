<template>
  <q-page class="q-pa-md bg-grey-2 text-dark">
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
            {{ $t('customers.bakiPayment.title') }}
          </h1>
          <p class="text-caption text-grey-7 q-ma-none q-mt-xs">
            {{ $t('customers.bakiPayment.subtitle') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Action Row / Toolbar -->
    <div class="row q-col-gutter-sm items-center q-mb-md">
      <!-- Search Box -->
      <div class="col-12 col-sm-8 col-md-6">
        <q-input
          v-model="searchQuery"
          dense
          outlined
          bg-color="white"
          clearable
          :placeholder="$t('customers.bakiPayment.searchPlaceholder')"
          style="min-height: 48px"
        >
          <template v-slot:prepend>
            <q-icon name="search" />
          </template>
        </q-input>
      </div>
    </div>

    <!-- Session Warning Banner (Write Blocked for Cash) -->
    <div v-if="!hasActiveSession" class="q-mb-md">
      <q-banner class="bg-amber-1 text-amber-9 border-all rounded-borders q-pa-sm">
        <template v-slot:avatar>
          <q-icon name="warning" color="warning" size="sm" />
        </template>
        <span class="text-caption text-weight-medium">
          {{ $t('customers.bakiPayment.noSessionWarning') }}
        </span>
      </q-banner>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="32px" />
    </div>

    <!-- Dues Customer Cards List -->
    <div v-else>
      <div v-if="filteredCustomers.length > 0" class="row q-col-gutter-md">
        <div
          v-for="customer in filteredCustomers"
          :key="customer.id"
          class="col-12 col-sm-6 col-md-4"
        >
          <q-card flat bordered class="bg-white border-all hover-card column justify-between h-100">
            <q-card-section class="q-pa-md col">
              <div class="row justify-between items-start no-wrap">
                <div class="col ellipsis">
                  <div class="text-subtitle1 text-weight-bold text-primary ellipsis">
                    {{ customer.full_name }}
                  </div>
                  <div class="text-caption text-grey-7 q-mt-xs row items-center">
                    <q-icon name="phone" size="14px" class="q-mr-xs text-grey-6" />
                    <span class="ellipsis">{{ customer.phone || 'No Phone' }}</span>
                  </div>
                  <div class="text-caption text-grey-7 q-mt-xs row items-center">
                    <q-icon name="business" size="14px" class="q-mr-xs text-grey-6" />
                    <span class="ellipsis">{{ customer.factory_unit || 'No Institution' }}</span>
                  </div>
                  <!-- Outstanding balance chip -->
                  <div class="q-mt-sm">
                    <OutstandingBalanceChip :balance="customer.outstanding_balance" />
                  </div>
                </div>
              </div>
            </q-card-section>

            <q-card-actions class="q-px-md q-pb-md q-pt-none border-top row q-col-gutter-xs">
              <div class="col-6">
                <q-btn
                  unelevated
                  no-caps
                  color="primary"
                  icon="payment"
                  :label="$t('customers.bakiPayment.payBtn')"
                  class="full-width text-weight-bold cursor-pointer"
                  style="min-height: 48px"
                  :disable="isWriteBlocked && !hasActiveSession"
                  @click="openPayDialog(customer)"
                />
              </div>
              <div class="col-6">
                <q-btn
                  outline
                  no-caps
                  color="primary"
                  icon="history"
                  :label="$t('customers.bakiPayment.historyBtn')"
                  class="full-width text-weight-bold cursor-pointer"
                  style="min-height: 48px"
                  @click="openHistoryDialog(customer)"
                />
              </div>
            </q-card-actions>
          </q-card>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center text-grey-6 q-py-xl text-subtitle2">
        {{ $t('customers.bakiPayment.empty') }}
      </div>
    </div>

    <!-- Payment Form Dialog -->
    <BakiPaymentRegisterDialog
      v-if="showPayDialog && selectedCustomer"
      v-model="showPayDialog"
      :customer="selectedCustomer"
      :session-id="sessionId"
      :business-date="businessDate"
      :device-token="kioskStore.deviceToken ?? null"
      :staff-id="kioskStore.currentStaff?.id ?? null"
      @saved="onPaymentSaved"
    />

    <!-- History Timeline Dialog -->
    <BakiHistoryTimelineDialog
      v-if="showHistoryDialog && selectedCustomer"
      v-model="showHistoryDialog"
      :customer="selectedCustomer"
      :device-token="kioskStore.deviceToken ?? null"
      :staff-id="kioskStore.currentStaff?.id ?? null"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useKioskStore } from '../../stores/kiosk';
import { useSessionStore } from '../../stores/session';
import { useCustomersStore } from '../../stores/customers';
import type { Customer } from '../../stores/customers';
import { useFeedback } from '../../composables/useFeedback';
import OutstandingBalanceChip from '../../components/customers/OutstandingBalanceChip.vue';
import BakiPaymentRegisterDialog from '../../components/customers/BakiPaymentRegisterDialog.vue';
import BakiHistoryTimelineDialog from '../../components/customers/BakiHistoryTimelineDialog.vue';

const router = useRouter();
const { t } = useI18n();
const kioskStore = useKioskStore();
const sessionStore = useSessionStore();
const customersStore = useCustomersStore();
const feedback = useFeedback();

// View States
const searchQuery = ref('');
const loading = ref(false);

// Dialog States
const showPayDialog = ref(false);
const showHistoryDialog = ref(false);
const selectedCustomer = ref<Customer | null>(null);

// Computed Gates & Permissions
const canWriteCollection = computed(() =>
  kioskStore.hasStaffPermission('meal_management', 'collections_write'),
);
const hasActiveSession = computed(() => !!sessionStore.activeSession);
const isWriteBlocked = computed(() => !canWriteCollection.value);

const sessionId = computed(() => sessionStore.activeSession?.id || '');
const businessDate = computed(() => sessionStore.activeSession?.business_date || '');

// Filtered Dues Customers (outstanding_balance > 0)
const filteredCustomers = computed(() => {
  const q = (searchQuery.value || '').toLowerCase().trim();
  const rawDuesCustomers = customersStore.customers.filter((c) => c.outstanding_balance > 0);
  if (!q) return rawDuesCustomers;
  return rawDuesCustomers.filter(
    (c) => c.full_name.toLowerCase().includes(q) || (c.phone && c.phone.toLowerCase().includes(q)),
  );
});

function goBack() {
  void router.push({ name: 'kiosk-workspace' });
}

function openPayDialog(customer: Customer) {
  selectedCustomer.value = customer;
  showPayDialog.value = true;
}

function openHistoryDialog(customer: Customer) {
  selectedCustomer.value = customer;
  showHistoryDialog.value = true;
}

async function onPaymentSaved() {
  await fetchData();
}

async function fetchData() {
  const tenantId = kioskStore.tenantId;
  if (!tenantId) return;

  loading.value = true;
  try {
    // 1. Fetch active session
    await sessionStore.fetchActiveSession();

    // 2. Fetch active customers
    await customersStore.fetchCustomers({
      activeOnly: true,
    });
  } catch (err) {
    void feedback.showApiError(err, t('customers.bakiPayment.errors.loadFailed'));
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  void fetchData();
});
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
.hover-card {
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}
.hover-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}
.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.08);
}
.h-100 {
  height: 100%;
}
</style>
