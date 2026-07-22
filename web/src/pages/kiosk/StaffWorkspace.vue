<template>
  <q-page class="bg-grey-2 text-dark q-pa-md">
    <div class="workspace-container q-mx-auto">
      <!-- Welcome & Clock Header — stacks on phone -->
      <div class="row q-col-gutter-sm q-mb-lg items-start items-md-center">
        <div class="col-12 col-md">
          <h1 class="text-h5 text-weight-bold q-my-none text-dark">
            {{ $t('kioskUI.workspace.title') }}
          </h1>
          <p class="text-subtitle2 text-grey-7 q-my-none ellipsis">
            {{ currentStaffName }} —
            <span class="capitalize text-primary font-semibold">{{ currentStaffRole }}</span>
          </p>
        </div>
        <div class="col-12 col-md-auto">
          <q-card
            flat
            bordered
            class="bg-white q-px-md q-py-sm row items-center text-dark"
            style="min-height: 48px"
          >
            <q-icon name="schedule" size="22px" color="primary" class="q-mr-sm" />
            <div class="column">
              <span class="text-subtitle2 text-weight-bold font-mono leading-none">{{
                clockTimeStr
              }}</span>
              <span class="text-caption text-grey-7">{{ clockDateStr }}</span>
            </div>
          </q-card>
        </div>
      </div>

      <!-- Operational Session Control Banner -->
      <div v-if="isShiftSessionsEnabled" class="q-mb-lg">
        <q-card flat bordered class="bg-white text-dark q-pa-md border-all">
          <div class="row q-col-gutter-md items-start items-md-center">
            <div class="col-12 col-md">
              <div class="row items-start no-wrap q-gutter-x-sm">
                <q-avatar
                  size="48px"
                  class="shrink-0"
                  :color="sessionStore.hasActiveSession ? 'green-1' : 'red-1'"
                  :text-color="sessionStore.hasActiveSession ? 'positive' : 'negative'"
                >
                  <q-icon
                    :name="sessionStore.hasActiveSession ? 'check_circle' : 'error_outline'"
                    size="28px"
                  />
                </q-avatar>
                <div class="col" style="min-width: 0">
                  <div class="text-subtitle1 text-weight-bold">
                    {{
                      sessionStore.hasActiveSession
                        ? $t('kioskUI.workspace.statusOpen')
                        : $t('kioskUI.workspace.statusClosed')
                    }}
                  </div>
                  <div
                    v-if="sessionStore.hasActiveSession && sessionStore.activeSession"
                    class="text-caption text-grey-7"
                  >
                    {{ $t('kioskUI.workspace.shiftLabel') }}
                    <strong>{{
                      sessionStore.activeSession.shifts?.name || $t('sessions.banner.loadingShift')
                    }}</strong>
                    · {{ $t('kioskUI.workspace.businessDateLabel') }}
                    <strong>{{ sessionStore.activeSession.business_date }}</strong>
                    · {{ $t('kioskUI.workspace.openedByLabel') }}
                    <strong>{{ currentStaffName }}</strong>
                    · {{ $t('kioskUI.workspace.openingCashLabel') }}
                    <strong>{{ sessionStore.activeSession.opening_cash }} BDT</strong>
                  </div>
                  <div v-else class="text-caption text-negative text-weight-medium">
                    {{ $t('kioskUI.workspace.sessionBlockedWarning') }}
                  </div>
                </div>
              </div>
            </div>

            <div class="col-12 col-md-auto">
              <div class="row q-gutter-sm items-center wrap">
                <SessionCashBalance
                  v-if="
                    isFinancialLedgerEnabled && canReadCashBalance && sessionStore.hasActiveSession
                  "
                  :balance="ledgerStore.cashBalance"
                />
                <q-btn
                  v-if="!sessionStore.hasActiveSession && canOpenSession"
                  color="primary"
                  icon="vpn_key"
                  :label="$t('sessions.open.openBtn')"
                  unelevated
                  class="q-px-md text-weight-bold rounded-btn col-grow"
                  style="min-height: 48px"
                  @click="showOpenDialog = true"
                />
                <q-btn
                  v-if="sessionStore.hasActiveSession && canCloseSession"
                  color="red-5"
                  icon="lock"
                  :label="$t('sessions.close.closeBtn')"
                  unelevated
                  class="q-px-md text-weight-bold rounded-btn col-grow"
                  style="min-height: 48px"
                  @click="showCloseDialog = true"
                />
              </div>
            </div>
          </div>
        </q-card>
      </div>

      <!-- Quick Action Cards — 2-col phone / 3-col sm+ -->
      <div class="row q-col-gutter-sm q-col-gutter-md-md q-mb-lg">
        <!-- Daily Transaction (POS) -->
        <div v-if="canLogPos" class="col-6 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-md text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked }"
            role="button"
            tabindex="0"
            v-ripple
            @click="openPosDialog"
          >
            <q-avatar size="48px" color="green-1" text-color="green-8" class="q-mb-sm">
              <q-icon name="point_of_sale" size="26px" />
            </q-avatar>
            <div class="text-subtitle2 text-weight-bold text-center">
              {{ $t('kioskUI.workspace.actions.posSale.title') }}
            </div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none gt-sm">
              {{ $t('kioskUI.workspace.actions.posSale.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Customer Attendance -->
        <div v-if="isMealManagementEnabled && canReadAttendance" class="col-6 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-md text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked }"
            role="button"
            tabindex="0"
            v-ripple
            @click="goToKioskAttendance"
          >
            <q-avatar size="48px" color="deep-purple-1" text-color="deep-purple-8" class="q-mb-sm">
              <q-icon name="event_available" size="26px" />
            </q-avatar>
            <div class="text-subtitle2 text-weight-bold text-center">
              {{ $t('kioskUI.workspace.actions.mealAttendance.title') }}
            </div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none gt-sm">
              {{ $t('kioskUI.workspace.actions.mealAttendance.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Baki -->
        <div v-if="isMealManagementEnabled && canLogBaki" class="col-6 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-md text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked }"
            role="button"
            tabindex="0"
            v-ripple
            @click="goToKioskBaki"
          >
            <q-avatar size="48px" color="red-1" text-color="red-8" class="q-mb-sm">
              <q-icon name="assignment_late" size="26px" />
            </q-avatar>
            <div class="text-subtitle2 text-weight-bold text-center">
              {{ $t('kioskUI.workspace.actions.bakiCharge.title') }}
            </div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none gt-sm">
              {{ $t('kioskUI.workspace.actions.bakiCharge.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Customer Book -->
        <div v-if="isMealManagementEnabled && canReadCustomers" class="col-6 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-md text-dark"
            role="button"
            tabindex="0"
            v-ripple
            @click="goToKioskCustomers"
          >
            <q-avatar size="48px" color="teal-1" text-color="teal-8" class="q-mb-sm">
              <q-icon name="menu_book" size="26px" />
            </q-avatar>
            <div class="text-subtitle2 text-weight-bold text-center">
              {{ $t('kioskUI.workspace.actions.customers.title') }}
            </div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none gt-sm">
              {{ $t('kioskUI.workspace.actions.customers.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Baki Payment -->
        <div v-if="isMealManagementEnabled && canLogCollection" class="col-6 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-md text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked }"
            role="button"
            tabindex="0"
            v-ripple
            @click="goToKioskBakiPayment"
          >
            <q-avatar size="48px" color="teal-1" text-color="teal-8" class="q-mb-sm">
              <q-icon name="payments" size="26px" />
            </q-avatar>
            <div class="text-subtitle2 text-weight-bold text-center">
              {{ $t('kioskUI.workspace.actions.collection.title') }}
            </div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none gt-sm">
              {{ $t('kioskUI.workspace.actions.collection.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Advance Payment -->
        <div v-if="isMealManagementEnabled && canLogCollection" class="col-6 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-md text-dark"
            role="button"
            tabindex="0"
            v-ripple
            @click="goToAdvancePayment"
          >
            <q-avatar size="48px" color="blue-1" text-color="blue-8" class="q-mb-sm">
              <q-icon name="account_balance_wallet" size="26px" />
            </q-avatar>
            <div class="text-subtitle2 text-weight-bold text-center">
              {{ $t('kioskUI.workspace.actions.advancePayment.title') }}
            </div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none gt-sm">
              {{ $t('kioskUI.workspace.actions.advancePayment.desc') }}
            </p>
          </q-card>
        </div>
      </div>

      <!-- Shift History Logs & Customer Add-ons Card -->
      <q-card class="flat bordered bg-white text-dark border-all q-mb-md">
        <q-tabs
          v-model="workspaceTab"
          dense
          class="text-grey-7"
          active-color="primary"
          indicator-color="primary"
          align="justify"
          narrow-indicator
          style="min-height: 48px"
        >
          <q-tab
            name="ledger"
            :label="$t('ledger.title') || 'Transactions'"
            class="cursor-pointer"
          />
          <q-tab
            name="addons"
            :label="$t('customers.baki.title') || 'Customer Add-ons'"
            class="cursor-pointer"
          />
        </q-tabs>

        <q-separator />

        <q-tab-panels v-model="workspaceTab" animated class="bg-white text-dark">
          <!-- Ledger Tab -->
          <q-tab-panel name="ledger" class="q-pa-md">
            <div class="text-h6 text-weight-bold q-mb-md">
              {{ $t('workspace.ledger.cardTitle') }}
            </div>
            <q-table
              v-if="isFinancialLedgerEnabled && canReadSessionLedger"
              :rows="ledgerStore.entries"
              :columns="ledgerColumns"
              row-key="id"
              flat
              class="bg-white text-dark gt-sm"
              :no-data-label="$t('ledger.table.noTransactions')"
              dense
            >
              <template #body-cell-type="props">
                <q-td :props="props">
                  <q-badge
                    :color="getTypeColor(props.row.type)"
                    class="text-weight-bold uppercase q-py-xs q-px-sm"
                  >
                    {{ props.row.type }}
                  </q-badge>
                </q-td>
              </template>
              <template #body-cell-time="props">
                <q-td :props="props">
                  {{ formatTime(props.row.created_at) }}
                </q-td>
              </template>
              <template #body-cell-value="props">
                <q-td :props="props">
                  {{ formatMoney(props.row.amount) }}
                </q-td>
              </template>
              <template #body-cell-actions="props">
                <q-td :props="props">
                  <q-btn
                    v-if="canEditPosRow(props.row)"
                    flat
                    dense
                    color="primary"
                    icon="edit"
                    class="cursor-pointer"
                    style="min-height: 44px; min-width: 44px"
                    @click="openPosEdit(props.row)"
                  />
                  <span v-else-if="props.row.category === 'POS'" class="text-caption text-grey-6">
                    {{ $t('kioskUI.workspace.pos.editClosed') }}
                  </span>
                </q-td>
              </template>
            </q-table>

            <!-- Mobile card list -->
            <div
              v-if="isFinancialLedgerEnabled && canReadSessionLedger"
              class="lt-md column q-gutter-y-sm"
            >
              <q-card
                v-for="row in ledgerStore.entries"
                :key="row.id"
                flat
                bordered
                class="q-pa-md bg-grey-1"
              >
                <div class="row items-start justify-between">
                  <div>
                    <div class="text-subtitle2 text-weight-bold">{{ row.category }}</div>
                    <div class="text-caption text-grey-7">{{ formatTime(row.created_at) }}</div>
                    <q-badge
                      :color="getTypeColor(row.type)"
                      class="text-weight-bold uppercase q-mt-xs"
                    >
                      {{ row.type }}
                    </q-badge>
                    <div class="text-caption q-mt-xs text-grey-8">
                      {{ paymentLabel(row.payment_method) }}
                    </div>
                  </div>
                  <div class="column items-end">
                    <div class="text-subtitle1 text-weight-bold font-mono">
                      {{ formatMoney(row.amount) }}
                    </div>
                    <q-btn
                      v-if="canEditPosRow(row)"
                      flat
                      dense
                      color="primary"
                      icon="edit"
                      class="cursor-pointer q-mt-xs"
                      style="min-height: 44px; min-width: 44px"
                      @click="openPosEdit(row)"
                    />
                  </div>
                </div>
              </q-card>
              <div
                v-if="!ledgerStore.entries.length"
                class="text-caption text-grey-6 text-center q-pa-md"
              >
                {{ $t('ledger.table.noTransactions') }}
              </div>
            </div>
          </q-tab-panel>

          <!-- Addons Tab -->
          <q-tab-panel name="addons" class="q-pa-md">
            <div class="text-h6 text-weight-bold q-mb-md">
              {{ $t('customers.baki.title') || 'Customer Add-ons' }}
            </div>

            <q-table
              :rows="customersStore.sessionBakiTransactions"
              :columns="addonColumns"
              row-key="id"
              flat
              class="bg-white text-dark gt-sm"
              :no-data-label="$t('ledger.table.noTransactions') || 'No add-ons recorded'"
              dense
            >
              <template #body-cell-time="props">
                <q-td :props="props">
                  {{ formatTime(props.row.created_at) }}
                </q-td>
              </template>
              <template #body-cell-value="props">
                <q-td :props="props"> ৳{{ props.row.amount }} </q-td>
              </template>
            </q-table>

            <!-- Mobile Add-ons list -->
            <div class="lt-md column q-gutter-y-sm">
              <q-card
                v-for="row in customersStore.sessionBakiTransactions"
                :key="row.id"
                flat
                bordered
                class="q-pa-md bg-grey-1"
              >
                <div class="row items-start justify-between">
                  <div>
                    <div class="text-subtitle2 text-weight-bold">{{ row.customer_name }}</div>
                    <div class="text-caption text-grey-7">{{ formatTime(row.created_at) }}</div>
                    <div class="text-caption q-mt-xs text-grey-8">
                      {{ row.items_description }}
                    </div>
                  </div>
                  <div class="column items-end">
                    <div class="text-subtitle1 text-weight-bold font-mono">৳{{ row.amount }}</div>
                  </div>
                </div>
              </q-card>
              <div
                v-if="!customersStore.sessionBakiTransactions.length"
                class="text-caption text-grey-6 text-center q-pa-md"
              >
                No add-ons recorded
              </div>
            </div>
          </q-tab-panel>
        </q-tab-panels>
      </q-card>
    </div>

    <PosSaleDialog
      v-if="sessionStore.activeSession && showPosDialog"
      v-model="showPosDialog"
      :session-id="sessionStore.activeSession.id"
      :edit-entry="posEditEntry"
      @saved="onPosRecorded"
    />

    <!-- Operational Sessions Dialogs -->
    <SessionOpenDialog
      v-if="showOpenDialog"
      v-model="showOpenDialog"
      @opened="handleSessionOpened"
    />
    <SessionCloseDialog
      v-if="sessionStore.activeSession && showCloseDialog"
      v-model="showCloseDialog"
      :session-id="sessionStore.activeSession.id"
      @closed="handleSessionClosed"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import type { QTableColumn } from 'quasar';
import { useKioskStore } from '../../stores/kiosk';
import { useSessionStore } from '../../stores/session';
import { useLedgerStore } from '../../stores/ledger';
import { supabase } from '../../boot/supabase';
import { showWarning } from '../../composables/useFeedback';
import SessionOpenDialog from '../../components/sessions/SessionOpenDialog.vue';
import SessionCloseDialog from '../../components/sessions/SessionCloseDialog.vue';
import SessionCashBalance from '../../components/ledger/SessionCashBalance.vue';
import PosSaleDialog from '../../components/kiosk/PosSaleDialog.vue';
import { formatMoney } from '../../utils/format';
import { useI18n } from 'vue-i18n';
import { useCustomersStore } from '../../stores/customers';

import type { LedgerEntry } from '../../stores/ledger';

const router = useRouter();
const kioskStore = useKioskStore();
const sessionStore = useSessionStore();
const { t, locale } = useI18n();

const currentStaffName = computed(() => kioskStore.currentStaff?.fullName || 'Staff');
const currentStaffRole = computed(() => kioskStore.currentStaff?.role || 'Operator');

// Shift sessions feature gate and permissions checks
const isShiftSessionsEnabled = ref(false);
const isFinancialLedgerEnabled = ref(false);
const isMealManagementEnabled = ref(false);

const showOpenDialog = ref(false);
const showCloseDialog = ref(false);

const customersStore = useCustomersStore();

const workspaceTab = ref('ledger');

const addonColumns = computed<QTableColumn[]>(() => [
  {
    name: 'time',
    align: 'left',
    label: t('ledger.table.cols.dateTime'),
    field: 'created_at',
    sortable: true,
  },
  {
    name: 'customer',
    align: 'left',
    label: t('customers.baki.customer') || 'Customer',
    field: 'customer_name',
    sortable: true,
  },
  {
    name: 'description',
    align: 'left',
    label: t('customers.baki.itemsDescription') || 'Description',
    field: 'items_description',
    sortable: true,
  },
  {
    name: 'value',
    align: 'right',
    label: t('ledger.table.cols.amount'),
    field: 'amount',
    sortable: true,
  },
]);

const canLogBaki = computed(() => kioskStore.hasStaffPermission('meal_management', 'baki_write'));
const canLogCollection = computed(() =>
  kioskStore.hasStaffPermission('meal_management', 'collections_write'),
);
const canReadCustomers = computed(() =>
  kioskStore.hasStaffPermission('meal_management', 'customer_read'),
);
const canReadAttendance = computed(() =>
  kioskStore.hasStaffPermission('meal_management', 'attendance_read'),
);
const canLogPos = computed(
  () => isFinancialLedgerEnabled.value && kioskStore.hasStaffPermission('kiosk', 'log_pos'),
);

function goToKioskCustomers() {
  void router.push({ name: 'kiosk-customers' });
}

function goToKioskAttendance() {
  void router.push({ name: 'kiosk-attendance' });
}

function goToKioskBaki() {
  void router.push({ name: 'kiosk-baki' });
}

function goToKioskBakiPayment() {
  void router.push({ name: 'kiosk-baki-payment' });
}

const ledgerStore = useLedgerStore();

const canOpenSession = computed(() =>
  kioskStore.hasStaffPermission('operational_shifts', 'sessions_open'),
);
const canCloseSession = computed(() =>
  kioskStore.hasStaffPermission('operational_shifts', 'sessions_close'),
);

const canReadCashBalance = computed(() =>
  kioskStore.hasStaffPermission('financial_ledger', 'cash_balance_read'),
);
const canReadSessionLedger = computed(() =>
  kioskStore.hasStaffPermission('financial_ledger', 'session_ledger_read'),
);

const isActionBlocked = computed(() => {
  return isShiftSessionsEnabled.value && !sessionStore.hasActiveSession;
});

function goToAdvancePayment() {
  void router.push({ name: 'kiosk-advance-payment' });
}

watch(
  () => sessionStore.activeSession,
  async (session) => {
    if (session) {
      if (isFinancialLedgerEnabled.value) {
        await ledgerStore.fetchPosEditWindow().catch(() => null);
        if (canReadCashBalance.value) {
          await ledgerStore.fetchCashBalance(session.id);
        }
        if (canReadSessionLedger.value) {
          await ledgerStore.fetchEntries({ sessionId: session.id });
        }
      }
      if (isMealManagementEnabled.value) {
        await customersStore.fetchSessionBakiTransactions(session.id).catch(() => null);
      }
    } else {
      ledgerStore.clearLedger();
      customersStore.clearAttendanceToday();
    }
  },
  { immediate: true },
);

async function onPosRecorded() {
  if (!sessionStore.activeSession) return;
  if (canReadSessionLedger.value) {
    await ledgerStore.fetchEntries({ sessionId: sessionStore.activeSession.id });
  }
  if (canReadCashBalance.value) {
    await ledgerStore.fetchCashBalance(sessionStore.activeSession.id);
  }
}
async function checkFeatureGate() {
  const tenantId = kioskStore.tenantId;
  const deviceToken = kioskStore.deviceToken;
  if (!tenantId || !deviceToken) return;
  try {
    const { data, error } = await supabase.rpc('get_enabled_features', {
      p_tenant_id: tenantId,
      p_device_token: deviceToken,
    });

    if (!error && data) {
      const features = data as Record<string, boolean>;
      isShiftSessionsEnabled.value = !!features['shift-sessions'];
      isFinancialLedgerEnabled.value = !!features['financial-ledger'];
      isMealManagementEnabled.value = !!features['meal-management'];
    }
  } catch (err) {
    console.error('Failed to load tenant settings in kiosk workspace:', err);
  }
}

const handleSessionOpened = async () => {
  await sessionStore.fetchActiveSession();
};

const handleSessionClosed = () => {
  sessionStore.clearSession();
};

// Live clock
const now = ref(new Date());
let timerId: number | null = null;

const clockLocale = computed(() =>
  locale.value?.toString().startsWith('bn') ? 'bn-BD' : undefined,
);

const clockTimeStr = computed(() =>
  now.value.toLocaleTimeString(clockLocale.value, {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }),
);

const clockDateStr = computed(() =>
  now.value.toLocaleDateString(clockLocale.value, {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }),
);

// Logs list state removed — session ledger is source of truth

const ledgerColumns = computed<QTableColumn[]>(() => [
  {
    name: 'time',
    align: 'left',
    label: t('ledger.table.cols.dateTime'),
    field: 'created_at',
    sortable: true,
  },
  {
    name: 'type',
    align: 'left',
    label: t('ledger.table.cols.type'),
    field: 'type',
    sortable: true,
  },
  {
    name: 'category',
    align: 'left',
    label: t('ledger.table.cols.category'),
    field: 'category',
    sortable: true,
  },
  { name: 'value', align: 'right', label: t('ledger.table.cols.amount'), field: 'amount' },
  {
    name: 'actions',
    align: 'right',
    label: t('kioskUI.workspace.pos.actions'),
    field: 'id',
  },
]);

// Dialog visibilities
const showPosDialog = ref(false);
const posEditEntry = ref<{
  id: string;
  amount: number;
  payment_method: string;
  notes: string | null;
} | null>(null);

onMounted(async () => {
  await checkFeatureGate();
  if (isShiftSessionsEnabled.value) {
    await sessionStore.fetchActiveSession();
  }
  now.value = new Date();
  timerId = window.setInterval(() => {
    now.value = new Date();
  }, 1000);
});

onUnmounted(() => {
  if (timerId) clearInterval(timerId);
});

const openPosDialog = () => {
  if (isActionBlocked.value) {
    showWarning(t('kioskUI.workspace.sessionBlockedWarning'));
    return;
  }
  if (!canLogPos.value) {
    showWarning(t('kioskUI.workspace.pos.permissionDenied'));
    return;
  }
  posEditEntry.value = null;
  showPosDialog.value = true;
};

function canEditPosRow(row: LedgerEntry) {
  return (
    canLogPos.value &&
    row.category === 'POS' &&
    ledgerStore.isPosEditable(row.created_at, sessionStore.hasActiveSession)
  );
}

function openPosEdit(row: LedgerEntry) {
  if (!canEditPosRow(row)) {
    showWarning(t('kioskUI.workspace.pos.editClosed'));
    return;
  }
  posEditEntry.value = {
    id: row.id,
    amount: row.amount,
    payment_method: row.payment_method,
    notes: row.notes,
  };
  showPosDialog.value = true;
}

function paymentLabel(method: string) {
  if (method === 'mobile_wallet') return t('kioskUI.workspace.pos.online');
  if (method === 'cash') return t('kioskUI.workspace.pos.cash');
  return method;
}

const getTypeColor = (type: string) => {
  if (type === 'sale' || type === 'inflow') return 'positive';
  if (type === 'meal') return 'warning';
  return 'info';
};

const formatTime = (date: Date | string) => {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleTimeString(undefined, {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
};
</script>

<style scoped lang="scss">
.workspace-container {
  max-width: 1000px;
}

.action-card {
  border-radius: 16px;
  border-width: 1.5px;
  min-height: 120px;
  height: 100%;

  &:focus-visible {
    outline: 2px solid var(--q-primary);
    outline-offset: 2px;
  }
}

.hover-card:hover {
  border-color: var(--q-primary);
  background: rgba(99, 102, 241, 0.04);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.05);
}

.rounded-btn {
  border-radius: 12px;
}

.dialog-card {
  width: 100%;
  max-width: 450px;
}

.custom-input :deep(.q-field__control) {
  border-radius: 12px;
  background: #ffffff !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;
  transition: all 0.2s ease;

  &:hover {
    border-color: #94a3b8;
  }

  &.q-field__control--focused {
    border-color: var(--q-primary) !important;
  }
}

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.cursor-pointer {
  cursor: pointer;
}

.transition-all {
  transition: all 0.25s ease;
}

.leading-none {
  line-height: 1.2;
}

.pointer-events-none {
  pointer-events: none;
}

.opacity-50 {
  opacity: 0.5;
}
</style>
