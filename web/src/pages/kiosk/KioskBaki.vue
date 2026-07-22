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
            {{ $t('customers.baki.title') }}
          </h1>
          <p class="text-caption text-grey-7 q-ma-none q-mt-xs">
            {{ $t('customers.baki.subtitle') }}
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
          :placeholder="$t('customers.baki.searchPlaceholder')"
          style="min-height: 48px"
        >
          <template v-slot:prepend>
            <q-icon name="search" />
          </template>
        </q-input>
      </div>
    </div>

    <!-- Session Warning Banner (Write Blocked) -->
    <div v-if="isWriteBlocked" class="q-mb-md">
      <q-banner class="bg-amber-1 text-amber-9 border-all rounded-borders q-pa-sm">
        <template v-slot:avatar>
          <q-icon name="warning" color="warning" size="sm" />
        </template>
        <span class="text-caption text-weight-medium">
          {{ $t('customers.baki.noSessionWarning') }}
        </span>
      </q-banner>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="32px" />
    </div>

    <!-- Walk-in Baki Customer Cards List -->
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

            <q-card-actions class="q-px-md q-pb-md q-pt-none border-top">
              <q-btn
                unelevated
                no-caps
                color="primary"
                icon="add"
                :label="$t('customers.baki.addBakiBtn')"
                class="full-width text-weight-bold cursor-pointer"
                style="min-height: 48px"
                :disable="isWriteBlocked"
                @click="openAddBaki(customer)"
              />
            </q-card-actions>
          </q-card>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center text-grey-6 q-py-xl text-subtitle2">
        {{ $t('customers.baki.empty') }}
      </div>
    </div>

    <BakiEntryDialog
      v-if="showEntryDialog && selectedCustomer"
      v-model="showEntryDialog"
      :customer="selectedCustomer"
      :session-id="sessionId"
      :business-date="businessDate"
      :session-shift-name="sessionStore.activeSession?.shifts?.name ?? null"
      :device-token="kioskStore.deviceToken ?? null"
      :staff-id="kioskStore.currentStaff?.id ?? null"
      @saved="onBakiSaved"
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
import BakiEntryDialog from '../../components/customers/BakiEntryDialog.vue';

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
const showEntryDialog = ref(false);
const selectedCustomer = ref<Customer | null>(null);

// Computed Gates & Permissions
const canWriteBaki = computed(() => kioskStore.hasStaffPermission('meal_management', 'baki_write'));
const hasActiveSession = computed(() => !!sessionStore.activeSession);
const isWriteBlocked = computed(() => !hasActiveSession.value || !canWriteBaki.value);

const sessionId = computed(() => sessionStore.activeSession?.id || '');
const businessDate = computed(() => sessionStore.activeSession?.business_date || '');

// Filtered Walk-in Baki Customers
const filteredCustomers = computed(() => {
  const q = (searchQuery.value || '').toLowerCase().trim();
  const rawBakiCustomers = customersStore.customers.filter((c) => c.category === 'walk_in_baki');
  if (!q) return rawBakiCustomers;
  return rawBakiCustomers.filter(
    (c) => c.full_name.toLowerCase().includes(q) || (c.phone && c.phone.toLowerCase().includes(q)),
  );
});

function goBack() {
  void router.push({ name: 'kiosk-workspace' });
}

function openAddBaki(customer: Customer) {
  selectedCustomer.value = customer;
  showEntryDialog.value = true;
}

async function onBakiSaved() {
  await fetchData();
}

async function fetchData() {
  const tenantId = kioskStore.tenantId;
  if (!tenantId) return;

  loading.value = true;
  try {
    // 1. Fetch active session
    await sessionStore.fetchActiveSession();

    // 2. Fetch active walk-in baki customers
    await customersStore.fetchCustomers({
      activeOnly: true,
      category: 'walk_in_baki',
    });
  } catch (err) {
    void feedback.showApiError(err, t('customers.baki.errors.loadFailed'));
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
