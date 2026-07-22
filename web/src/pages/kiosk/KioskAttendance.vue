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
            {{ $t('customers.attendance.title') }}
          </h1>
          <p class="text-caption text-grey-7 q-ma-none q-mt-xs">
            {{ $t('customers.attendance.subtitle') }}
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
          :placeholder="$t('customers.attendance.searchPlaceholder')"
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
          {{ $t('customers.attendance.noSessionWarning') }}
        </span>
      </q-banner>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="32px" />
    </div>

    <!-- Customer Cards List -->
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
                  <!-- Attended shifts badges -->
                  <div class="q-mt-sm row items-center wrap">
                    <q-badge
                      v-for="shift in getAttendedShifts(customer.id)"
                      :key="shift"
                      color="green-1"
                      text-color="positive"
                      class="text-weight-bold q-py-xs q-px-sm border-all q-mr-xs q-mb-xs"
                      style="border-color: rgba(76, 175, 80, 0.2)"
                    >
                      <q-icon name="check_circle" size="12px" class="q-mr-xs" />
                      {{ shift }}
                    </q-badge>

                    <!-- Session Addons badges -->
                    <q-badge
                      v-for="addon in getCustomerAddons(customer.id)"
                      :key="addon.id"
                      color="amber-1"
                      text-color="warning"
                      class="text-weight-bold q-py-xs q-px-sm border-all q-mr-xs q-mb-xs"
                      style="border-color: rgba(245, 158, 11, 0.2)"
                    >
                      <q-icon name="add_circle" size="12px" class="q-mr-xs" />
                      {{ addon.items_description }} (৳{{ addon.amount }})
                    </q-badge>
                  </div>
                </div>
                <div class="text-right shrink-0 q-ml-sm">
                  <div class="text-caption text-grey-6">
                    {{ $t('customers.attendance.dashboard.dailyCost') }}
                  </div>
                  <div class="text-subtitle2 text-weight-bold text-dark font-mono">
                    ৳{{ customer.contract_daily_rate || 0 }}
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
                :label="$t('customers.attendance.addAttendanceBtn')"
                class="full-width text-weight-bold cursor-pointer"
                style="min-height: 48px"
                :disable="isWriteBlocked"
                @click="openAddAttendance(customer)"
              />
            </q-card-actions>
          </q-card>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center text-grey-6 q-py-xl text-subtitle2">
        {{ $t('customers.attendance.empty') }}
      </div>
    </div>

    <AttendanceEntryDialog
      v-if="showEntryDialog && selectedCustomer"
      v-model="showEntryDialog"
      :customer="selectedCustomer"
      :active-shifts="activeShifts"
      :attendance-today="customersStore.attendanceToday"
      :business-date="businessDate"
      :session-id="sessionId"
      :device-token="kioskStore.deviceToken ?? null"
      :staff-id="kioskStore.currentStaff?.id ?? null"
      @saved="onAttendanceSaved"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { supabase } from '../../boot/supabase';
import { useKioskStore } from '../../stores/kiosk';
import { useSessionStore } from '../../stores/session';
import { useCustomersStore } from '../../stores/customers';
import type { Customer } from '../../stores/customers';
import { useFeedback } from '../../composables/useFeedback';
import AttendanceEntryDialog from '../../components/customers/AttendanceEntryDialog.vue';

interface Shift {
  name: string;
}

const router = useRouter();
const { t } = useI18n();
const kioskStore = useKioskStore();
const sessionStore = useSessionStore();
const customersStore = useCustomersStore();
const feedback = useFeedback();

// View States
const searchQuery = ref('');
const loading = ref(false);
const activeShifts = ref<Shift[]>([]);

// Dialog States
const showEntryDialog = ref(false);
const selectedCustomer = ref<Customer | null>(null);

// Computed Gates & Permissions
const canWriteAttendance = computed(() =>
  kioskStore.hasStaffPermission('meal_management', 'attendance_write'),
);
const hasActiveSession = computed(() => !!sessionStore.activeSession);
const isWriteBlocked = computed(() => !hasActiveSession.value || !canWriteAttendance.value);

const businessDate = computed(() => sessionStore.activeSession?.business_date || '');
const sessionId = computed(() => sessionStore.activeSession?.id || '');

// Filtered Contract Workers
const filteredCustomers = computed(() => {
  const q = (searchQuery.value || '').toLowerCase().trim();
  const rawContractWorkers = customersStore.customers.filter(
    (c) => c.category === 'contract_worker',
  );
  if (!q) return rawContractWorkers;
  return rawContractWorkers.filter(
    (c) => c.full_name.toLowerCase().includes(q) || (c.phone && c.phone.toLowerCase().includes(q)),
  );
});

function goBack() {
  void router.push({ name: 'kiosk-workspace' });
}

function openAddAttendance(customer: Customer) {
  selectedCustomer.value = customer;
  showEntryDialog.value = true;
}

async function onAttendanceSaved() {
  await fetchData();
}

function getAttendedShifts(customerId: string): string[] {
  const record = customersStore.attendanceToday.find((a) => a.customer_id === customerId);
  return record ? record.attended_shifts : [];
}

function getCustomerAddons(customerId: string) {
  return customersStore.sessionBakiTransactions.filter((b) => b.customer_id === customerId);
}

async function fetchData() {
  const tenantId = kioskStore.tenantId;
  if (!tenantId) return;

  loading.value = true;
  try {
    // 1. Fetch active session
    await sessionStore.fetchActiveSession();

    // 2. Fetch active shifts
    const { data: shifts, error: shiftsErr } = await supabase.rpc('list_active_shifts', {
      p_tenant_id: tenantId,
      p_device_token: kioskStore.deviceToken,
    });
    if (shiftsErr) throw shiftsErr;
    activeShifts.value = (shifts ?? []) as Shift[];

    // 3. Fetch active contract workers
    await customersStore.fetchCustomers({
      activeOnly: true,
      category: 'contract_worker',
    });

    // 4. Fetch attendance list for session's business date
    if (sessionStore.activeSession) {
      await customersStore.fetchAttendanceForDate(sessionStore.activeSession.business_date);
      await customersStore
        .fetchSessionBakiTransactions(sessionStore.activeSession.id)
        .catch(() => null);
    }
  } catch (err) {
    void feedback.showApiError(err, t('customers.attendance.errors.loadFailed'));
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
