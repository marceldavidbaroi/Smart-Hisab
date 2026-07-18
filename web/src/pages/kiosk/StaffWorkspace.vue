<!--
  Lean Mode Checklist (Phase 4):
  - [x] Staff header & Clock Out visible
  - [x] Operational session banner visible
  - [x] SessionCashBalance chip visible (Manager/Cashier + cash_balance_read)
  - [x] Active-session ledger read-only list visible (session_ledger_read)
  - [x] Hide unbuilt action cards (Record Meal, POS Sale, Cash Advance) when feature flags are disabled
-->
<template>
  <q-page class="bg-grey-2 text-dark q-pa-md">
    <div class="workspace-container q-mx-auto">
      <!-- Welcome & Shift Header -->
      <div class="row items-center justify-between q-mb-lg q-col-gutter-sm">
        <div>
          <h1 class="text-h4 text-weight-bold q-my-none text-dark">{{ $t('kioskUI.workspace.title') }}</h1>
          <p class="text-subtitle2 text-grey-7 q-my-none">
            {{ currentStaffName }} —
            <span class="capitalize text-primary font-semibold">{{ currentStaffRole }}</span>
          </p>
        </div>
        <div class="row items-center q-gutter-sm">
          <q-card class="flat bordered bg-white q-px-md q-py-sm row items-center text-dark">
            <q-icon name="timer" size="20px" color="primary" class="q-mr-sm" />
            <div class="column">
              <span class="text-caption text-grey-7 leading-none">{{ $t('kioskUI.workspace.shiftDuration') }}</span>
              <span class="text-subtitle2 text-weight-bold font-mono">{{ shiftTimeStr }}</span>
            </div>
          </q-card>
          <q-btn
            color="red-5"
            icon="logout"
            :label="$t('kioskUI.workspace.clockOutBtn')"
            class="rounded-btn q-px-md text-weight-bold cursor-pointer"
            style="min-height: 44px"
            @click="confirmClockOut = true"
            unelevated
          />
        </div>
      </div>

      <!-- Operational Session Control Banner -->
      <div v-if="isShiftSessionsEnabled" class="q-mb-lg">
        <q-card flat bordered class="bg-white text-dark q-pa-md border-all">
          <div class="row items-center justify-between no-wrap">
            <div class="row items-center q-gutter-x-md">
              <q-avatar
                size="48px"
                :color="sessionStore.hasActiveSession ? 'green-1' : 'red-1'"
                :text-color="sessionStore.hasActiveSession ? 'positive' : 'negative'"
              >
                <q-icon
                  :name="sessionStore.hasActiveSession ? 'check_circle' : 'error_outline'"
                  size="28px"
                />
              </q-avatar>
              <div>
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
                  <strong class="text-slate-800">{{
                    sessionStore.activeSession.shifts?.name || $t('sessions.banner.loadingShift')
                  }}</strong>
                  | {{ $t('kioskUI.workspace.businessDateLabel') }}
                  <strong class="text-slate-800">{{
                    sessionStore.activeSession.business_date
                  }}</strong>
                  | {{ $t('kioskUI.workspace.openedByLabel') }} <strong class="text-slate-800">{{ currentStaffName }}</strong> |
                  {{ $t('kioskUI.workspace.openingCashLabel') }}
                  <strong class="text-slate-800"
                    >{{ sessionStore.activeSession.opening_cash }} BDT</strong
                  >
                </div>
                <div v-else class="text-caption text-red-5 font-medium">
                  {{ $t('kioskUI.workspace.sessionBlockedWarning') }}
                </div>
              </div>
            </div>

            <div class="row q-gutter-x-sm items-center">
              <SessionCashBalance
                v-if="
                  isFinancialLedgerEnabled && canReadCashBalance && sessionStore.hasActiveSession
                "
                :balance="ledgerStore.cashBalance"
                class="q-mr-sm"
              />
              <q-btn
                v-if="!sessionStore.hasActiveSession && canOpenSession"
                color="primary"
                icon="vpn_key"
                :label="$t('sessions.open.openBtn')"
                unelevated
                dense
                class="q-px-md text-weight-bold rounded-btn"
                style="min-height: 40px"
                @click="showOpenDialog = true"
              />
              <q-btn
                v-if="sessionStore.hasActiveSession && canCloseSession"
                color="red-5"
                icon="lock"
                :label="$t('sessions.close.closeBtn')"
                unelevated
                dense
                class="q-px-md text-weight-bold rounded-btn"
                style="min-height: 40px"
                @click="showCloseDialog = true"
              />
            </div>
          </div>
        </q-card>
      </div>

      <!-- Quick Action Cards Grid -->
      <div class="row q-col-gutter-md q-mb-lg">
        <!-- Action 1: POS Sale -->
        <div v-if="isMealManagementEnabled" class="col-12 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-lg text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked }"
            role="button"
            tabindex="0"
            v-ripple
            @click="openPosDialog"
          >
            <q-avatar size="56px" color="green-1" text-color="green-8" class="q-mb-md">
              <q-icon name="shopping_cart" size="28px" />
            </q-avatar>
            <div class="text-subtitle1 text-weight-bold">{{ $t('kioskUI.workspace.actions.posSale.title') }}</div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none">
              {{ $t('kioskUI.workspace.actions.posSale.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Action 2: Record Meal -->
        <div v-if="isMealManagementEnabled" class="col-12 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-lg text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked }"
            role="button"
            tabindex="0"
            v-ripple
            @click="openMealDialog"
          >
            <q-avatar size="56px" color="orange-1" text-color="orange-8" class="q-mb-md">
              <q-icon name="restaurant" size="28px" />
            </q-avatar>
            <div class="text-subtitle1 text-weight-bold">{{ $t('kioskUI.workspace.actions.recordMeal.title') }}</div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none">
              {{ $t('kioskUI.workspace.actions.recordMeal.desc') }}
            </p>
          </q-card>
        </div>

        <!-- Action 3: Cash Advance -->
        <div v-if="isStaffPayrollEnabled" class="col-12 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-white border-all hover-card column justify-center items-center q-pa-lg text-dark"
            :class="{ 'opacity-50 pointer-events-none': isActionBlocked || !canLogAdvance }"
            role="button"
            tabindex="0"
            v-ripple
            @click="openAdvanceDialog"
          >
            <q-avatar size="56px" color="blue-1" text-color="blue-8" class="q-mb-md">
              <q-icon name="payments" size="28px" />
            </q-avatar>
            <div class="text-subtitle1 text-weight-bold">{{ $t('kioskUI.workspace.actions.cashAdvance.title') }}</div>
            <p class="text-caption text-grey-7 text-center q-mt-xs q-mb-none">
              {{ $t('kioskUI.workspace.actions.cashAdvance.desc') }}
            </p>
          </q-card>
        </div>
      </div>

      <!-- Shift History Logs Table -->
      <q-card class="flat bordered bg-white text-dark q-pa-md border-all">
        <div class="text-h6 text-weight-bold q-mb-md">{{ $t('workspace.ledger.cardTitle') }}</div>
        <q-table
          :rows="isFinancialLedgerEnabled && canReadSessionLedger ? ledgerStore.entries : shiftLogs"
          :columns="isFinancialLedgerEnabled && canReadSessionLedger ? ledgerColumns : logColumns"
          row-key="id"
          flat
          class="bg-white text-dark"
          :no-data-label="$t('ledger.table.noTransactions')"
          dense
        >
          <!-- Custom Type Badges -->
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

          <!-- Custom Time Format -->
          <template #body-cell-time="props">
            <q-td :props="props">
              {{ formatTime(props.row.created_at || props.row.time) }}
            </q-td>
          </template>

          <!-- Custom Value / Amount Format -->
          <template #body-cell-value="props">
            <q-td :props="props">
              <span v-if="isFinancialLedgerEnabled && canReadSessionLedger">
                {{ formatMoney(props.row.amount) }}
              </span>
              <span v-else>
                {{ props.value }}
              </span>
            </q-td>
          </template>
        </q-table>
      </q-card>
    </div>

    <!-- Confirm Clock Out Dialog -->
    <q-dialog v-model="confirmClockOut" persistent>
      <q-card class="bg-white text-dark border-all rounded-borders q-pa-md">
        <q-card-section class="row items-center">
          <q-avatar icon="logout" color="red-1" text-color="red-9" class="q-mr-md" />
          <span class="text-h6 text-weight-bold">{{ $t('kioskUI.workspace.clockOutDialog.title') }}</span>
        </q-card-section>

        <q-card-section class="q-py-md text-grey-7">
          {{ $t('kioskUI.workspace.clockOutDialog.body') }}
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat :label="$t('kioskUI.workspace.clockOutDialog.cancelBtn')" v-close-popup color="grey-7" />
          <q-btn
            flat
            :label="$t('kioskUI.workspace.clockOutDialog.confirmBtn')"
            color="red-5"
            @click="handleClockOut"
            v-close-popup
            class="text-weight-bold"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- POS Sale Dialog -->
    <q-dialog v-model="showPosDialog" persistent>
      <q-card class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">{{ $t('kioskUI.workspace.actions.posSale.title') }}</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="submitPosSale" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >{{ $t('ledger.manual.amount') }}</label
              >
              <q-input
                v-model.number="posAmount"
                type="number"
                filled
                color="primary"
                class="custom-input text-h6 font-mono"
                :rules="[(val) => (val !== null && val > 0) || $t('ledger.manual.amountMin')]"
                hide-bottom-space
              />
            </div>
            <div>
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >{{ $t('sessions.close.notesLabel') }}</label
              >
              <q-input
                v-model="posDescription"
                type="textarea"
                filled
                color="primary"
                class="custom-input"
                rows="2"
              />
            </div>
          </q-card-section>
          <q-card-actions align="right">
            <q-btn flat :label="$t('kioskUI.workspace.clockOutDialog.cancelBtn')" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              :label="$t('ledger.manual.saveBtn')"
              color="positive"
              class="q-px-md text-weight-bold cursor-pointer"
              style="min-height: 40px"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- Record Meal Dialog -->
    <q-dialog v-model="showMealDialog" persistent>
      <q-card class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">{{ $t('kioskUI.workspace.actions.recordMeal.title') }}</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="submitMeal" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >Consumer Category</label
              >
              <q-select
                v-model="mealCategory"
                :options="['Contract Employee', 'Kitchen Staff', 'Canteen Customer']"
                filled
                color="primary"
                class="custom-input"
              />
            </div>
            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >Meal Selection</label
              >
              <q-select
                v-model="mealType"
                :options="['Standard Breakfast', 'Full Lunch Set', 'Dinner Combo']"
                filled
                color="primary"
                class="custom-input"
              />
            </div>
            <div>
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >Quantity</label
              >
              <q-input
                v-model.number="mealQty"
                type="number"
                filled
                color="primary"
                class="custom-input font-mono"
                :rules="[(val) => (val !== null && val > 0) || 'Quantity must be 1 or more']"
                hide-bottom-space
              />
            </div>
          </q-card-section>
          <q-card-actions align="right">
            <q-btn flat :label="$t('kioskUI.workspace.clockOutDialog.cancelBtn')" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              :label="$t('kioskUI.workspace.actions.recordMeal.title')"
              color="warning"
              class="q-px-md text-weight-bold cursor-pointer"
              style="min-height: 40px"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- Cash Advance Dialog -->
    <q-dialog v-model="showAdvanceDialog" persistent>
      <q-card class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">{{ $t('kioskUI.workspace.actions.cashAdvance.title') }}</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="submitAdvance" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >{{ $t('ledger.manual.amount') }}</label
              >
              <q-input
                v-model.number="advanceAmount"
                type="number"
                filled
                color="primary"
                class="custom-input text-h6 font-mono"
                :rules="[(val) => (val !== null && val > 0) || $t('ledger.manual.amountMin')]"
                hide-bottom-space
              />
            </div>
            <div>
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs"
                >{{ $t('sessions.close.notesLabel') }}</label
              >
              <q-input
                v-model="advanceReason"
                type="textarea"
                filled
                color="primary"
                class="custom-input"
                rows="2"
                :rules="[(val) => !!val || $t('sessions.close.notesLabel') + ' is required']"
                hide-bottom-space
              />
            </div>
          </q-card-section>
          <q-card-actions align="right">
            <q-btn flat :label="$t('kioskUI.workspace.clockOutDialog.cancelBtn')" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              :label="$t('kioskUI.workspace.actions.cashAdvance.title')"
              color="info"
              class="q-px-md text-weight-bold cursor-pointer"
              style="min-height: 40px"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- Operational Sessions Dialogs -->
    <SessionOpenDialog v-model="showOpenDialog" @opened="handleSessionOpened" />
    <SessionCloseDialog
      v-if="sessionStore.activeSession"
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
import { showSuccess, showWarning, showError } from '../../composables/useFeedback';
import SessionOpenDialog from '../../components/sessions/SessionOpenDialog.vue';
import SessionCloseDialog from '../../components/sessions/SessionCloseDialog.vue';
import SessionCashBalance from '../../components/ledger/SessionCashBalance.vue';
import { formatMoney } from '../../utils/format';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const kioskStore = useKioskStore();
const sessionStore = useSessionStore();
const { t } = useI18n();

const currentStaffName = computed(() => kioskStore.currentStaff?.fullName || 'Staff');
const currentStaffRole = computed(() => kioskStore.currentStaff?.role || 'Operator');

// Shift sessions feature gate and permissions checks
const isShiftSessionsEnabled = ref(false);
const isFinancialLedgerEnabled = ref(false);
const isMealManagementEnabled = ref(false);
const isStaffPayrollEnabled = ref(false);

const showOpenDialog = ref(false);
const showCloseDialog = ref(false);

const ledgerStore = useLedgerStore();

const canOpenSession = computed(() =>
  kioskStore.hasStaffPermission('operational_shifts', 'sessions_open'),
);
const canCloseSession = computed(() =>
  kioskStore.hasStaffPermission('operational_shifts', 'sessions_close'),
);
const canLogAdvance = computed(() => kioskStore.hasStaffPermission('kiosk', 'log_advance'));

const canReadCashBalance = computed(() =>
  kioskStore.hasStaffPermission('financial_ledger', 'cash_balance_read'),
);
const canReadSessionLedger = computed(() =>
  kioskStore.hasStaffPermission('financial_ledger', 'session_ledger_read'),
);

const isActionBlocked = computed(() => {
  return isShiftSessionsEnabled.value && !sessionStore.hasActiveSession;
});

watch(
  () => sessionStore.activeSession,
  async (session) => {
    if (session && isFinancialLedgerEnabled.value) {
      if (canReadCashBalance.value) {
        await ledgerStore.fetchCashBalance(session.id);
      }
      if (canReadSessionLedger.value) {
        await ledgerStore.fetchEntries({ sessionId: session.id });
      }
    } else {
      ledgerStore.clearLedger();
    }
  },
  { immediate: true },
);

async function checkFeatureGate() {
  const tenantId = kioskStore.tenantId;
  if (!tenantId) return;
  try {
    const { data, error } = await supabase
      .from('tenant_settings')
      .select('enabled_features')
      .eq('tenant_id', tenantId)
      .maybeSingle();

    if (!error && data) {
      const features = data.enabled_features as Record<string, boolean> | null;
      isShiftSessionsEnabled.value = !!features?.['shift-sessions'];
      isFinancialLedgerEnabled.value = !!features?.['financial-ledger'];
      isMealManagementEnabled.value = !!features?.['meal-management'];
      isStaffPayrollEnabled.value = !!features?.['staff-payroll'];
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

// Shift duration timer
const shiftSeconds = ref(0);
let timerId: number | null = null;

const shiftTimeStr = computed(() => {
  const hrs = Math.floor(shiftSeconds.value / 3600);
  const mins = Math.floor((shiftSeconds.value % 3600) / 60);
  const secs = shiftSeconds.value % 60;
  return [
    hrs.toString().padStart(2, '0'),
    mins.toString().padStart(2, '0'),
    secs.toString().padStart(2, '0'),
  ].join(':');
});

// Logs list state
interface ShiftLog {
  id: string;
  time: Date;
  type: 'sale' | 'meal' | 'advance';
  details: string;
  value: string;
}

const shiftLogs = ref<ShiftLog[]>([]);

const logColumns = computed(() => [
  { name: 'time', align: 'left' as const, label: t('ledger.table.cols.dateTime'), field: 'time', sortable: true },
  { name: 'type', align: 'left' as const, label: t('ledger.table.cols.type'), field: 'type', sortable: true },
  { name: 'details', align: 'left' as const, label: t('ledger.table.cols.notes'), field: 'details' },
  { name: 'value', align: 'right' as const, label: t('ledger.table.cols.amount'), field: 'value' },
]);

const ledgerColumns = computed<QTableColumn[]>(() => [
  { name: 'time', align: 'left', label: t('ledger.table.cols.dateTime'), field: 'created_at', sortable: true },
  { name: 'type', align: 'left', label: t('ledger.table.cols.type'), field: 'type', sortable: true },
  { name: 'category', align: 'left', label: t('ledger.table.cols.category'), field: 'category', sortable: true },
  { name: 'value', align: 'right', label: t('ledger.table.cols.amount'), field: 'amount' },
]);

// Dialog visibilities
const confirmClockOut = ref(false);
const showPosDialog = ref(false);
const showMealDialog = ref(false);
const showAdvanceDialog = ref(false);

// Forms values
const posAmount = ref<number | null>(null);
const posDescription = ref('');

const mealCategory = ref('Contract Employee');
const mealType = ref('Full Lunch Set');
const mealQty = ref(1);

const advanceAmount = ref<number | null>(null);
const advanceReason = ref('');

onMounted(async () => {
  await checkFeatureGate();
  if (isShiftSessionsEnabled.value) {
    await sessionStore.fetchActiveSession();
  }
  timerId = window.setInterval(() => {
    shiftSeconds.value += 1;
  }, 1000);
});

onUnmounted(() => {
  if (timerId) clearInterval(timerId);
});

const handleClockOut = () => {
  kioskStore.logoutStaff();
  showSuccess(t('kioskUI.workspace.clockOutBtn') + ' completed');
  void router.push({ name: 'kiosk-login' });
};

// Open dialogs
const openPosDialog = () => {
  if (isActionBlocked.value) {
    showWarning(t('kioskUI.workspace.sessionBlockedWarning'));
    return;
  }
  posAmount.value = null;
  posDescription.value = '';
  showPosDialog.value = true;
};

const openMealDialog = () => {
  if (isActionBlocked.value) {
    showWarning(t('kioskUI.workspace.sessionBlockedWarning'));
    return;
  }
  mealCategory.value = 'Contract Employee';
  mealType.value = 'Full Lunch Set';
  mealQty.value = 1;
  showMealDialog.value = true;
};

const openAdvanceDialog = async () => {
  if (isActionBlocked.value) {
    showWarning(t('kioskUI.workspace.sessionBlockedWarning'));
    return;
  }
  if (!canLogAdvance.value) {
    await showError(t('errors.forbiddenText'));
    return;
  }
  advanceAmount.value = null;
  advanceReason.value = '';
  showAdvanceDialog.value = true;
};

// Submitting logs
const submitPosSale = () => {
  if (!posAmount.value) return;

  shiftLogs.value.unshift({
    id: Math.random().toString(36).substring(7),
    time: new Date(),
    type: 'sale',
    details: posDescription.value || 'Walk-in cash sale',
    value: `${posAmount.value.toFixed(2)} BDT`,
  });

  showPosDialog.value = false;
  showSuccess(t('kioskUI.workspace.actions.posSale.title') + ' recorded.');
};

const submitMeal = () => {
  if (!mealQty.value) return;

  shiftLogs.value.unshift({
    id: Math.random().toString(36).substring(7),
    time: new Date(),
    type: 'meal',
    details: `${mealCategory.value} - ${mealType.value}`,
    value: `${mealQty.value} Serving(s)`,
  });

  showMealDialog.value = false;
  showSuccess(t('kioskUI.workspace.actions.recordMeal.title') + ' recorded.');
};

const submitAdvance = () => {
  if (!advanceAmount.value) return;

  shiftLogs.value.unshift({
    id: Math.random().toString(36).substring(7),
    time: new Date(),
    type: 'advance',
    details: advanceReason.value,
    value: `${advanceAmount.value.toFixed(2)} BDT`,
  });

  showAdvanceDialog.value = false;
  showSuccess(t('kioskUI.workspace.actions.cashAdvance.title') + ' requested.');
};

const getTypeColor = (type: string) => {
  if (type === 'sale' || type === 'inflow') return 'positive';
  if (type === 'meal') return 'warning';
  return 'info';
};

const formatTime = (date: Date) => {
  return date.toLocaleTimeString(undefined, {
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
  min-height: 200px;

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
