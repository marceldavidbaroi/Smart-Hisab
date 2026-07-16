<template>
  <q-page class="bg-grey-10 text-white q-pa-md">
    <div class="workspace-container q-mx-auto">
      <!-- Welcome & Shift Header -->
      <div class="row items-center justify-between q-mb-lg q-col-gutter-sm">
        <div>
          <h1 class="text-h4 text-weight-bold q-my-none">Kiosk Workspace</h1>
          <p class="text-subtitle2 text-grey-5 q-my-none">
            {{ currentStaffName }} —
            <span class="capitalize text-primary">{{ currentStaffRole }}</span>
          </p>
        </div>
        <div class="row items-center q-gutter-sm">
          <q-card class="flat bordered bg-grey-9 q-px-md q-py-sm row items-center">
            <q-icon name="timer" size="20px" color="primary" class="q-mr-sm" />
            <div class="column">
              <span class="text-caption text-grey-5 leading-none">Shift Duration</span>
              <span class="text-subtitle2 text-weight-bold font-mono">{{ shiftTimeStr }}</span>
            </div>
          </q-card>
          <q-btn
            color="red-5"
            icon="logout"
            label="Clock Out"
            class="rounded-btn q-px-md text-weight-bold cursor-pointer"
            style="min-height: 44px"
            @click="confirmClockOut = true"
            unelevated
          />
        </div>
      </div>

      <!-- Quick Action Cards Grid -->
      <div class="row q-col-gutter-md q-mb-lg">
        <!-- Action 1: POS Sale -->
        <div class="col-12 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-grey-9 border-grey-8 hover-card column justify-center items-center q-pa-lg"
            role="button"
            tabindex="0"
            v-ripple
            @click="openPosDialog"
          >
            <q-avatar size="56px" color="green-10" text-color="green-4" class="q-mb-md">
              <q-icon name="shopping_cart" size="28px" />
            </q-avatar>
            <div class="text-subtitle1 text-weight-bold">POS Cash Sale</div>
            <p class="text-caption text-grey-5 text-center q-mt-xs q-mb-none">
              Record a direct cash purchase or walk-in transaction.
            </p>
          </q-card>
        </div>

        <!-- Action 2: Record Meal -->
        <div class="col-12 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-grey-9 border-grey-8 hover-card column justify-center items-center q-pa-lg"
            role="button"
            tabindex="0"
            v-ripple
            @click="openMealDialog"
          >
            <q-avatar size="56px" color="orange-10" text-color="orange-4" class="q-mb-md">
              <q-icon name="restaurant" size="28px" />
            </q-avatar>
            <div class="text-subtitle1 text-weight-bold">Record Meal</div>
            <p class="text-caption text-grey-5 text-center q-mt-xs q-mb-none">
              Deduct or log meals for staff and contract employees.
            </p>
          </q-card>
        </div>

        <!-- Action 3: Cash Advance -->
        <div class="col-12 col-sm-4">
          <q-card
            flat
            bordered
            class="action-card cursor-pointer transition-all bg-grey-9 border-grey-8 hover-card column justify-center items-center q-pa-lg"
            role="button"
            tabindex="0"
            v-ripple
            @click="openAdvanceDialog"
          >
            <q-avatar size="56px" color="blue-10" text-color="blue-4" class="q-mb-md">
              <q-icon name="payments" size="28px" />
            </q-avatar>
            <div class="text-subtitle1 text-weight-bold">Cash Advance</div>
            <p class="text-caption text-grey-5 text-center q-mt-xs q-mb-none">
              Distribute/request cash payroll advances for staff.
            </p>
          </q-card>
        </div>
      </div>

      <!-- Shift History Logs Table -->
      <q-card class="flat bordered bg-grey-9 q-pa-md">
        <div class="text-h6 text-weight-bold q-mb-md">Logged Transactions (This Shift)</div>
        <q-table
          :rows="shiftLogs"
          :columns="logColumns"
          row-key="id"
          flat
          dark
          class="bg-transparent text-white"
          no-data-label="No transactions logged during this session."
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
              {{ formatTime(props.row.time) }}
            </q-td>
          </template>
        </q-table>
      </q-card>
    </div>

    <!-- Confirm Clock Out Dialog -->
    <q-dialog v-model="confirmClockOut" persistent>
      <q-card class="bg-grey-9 text-white border-all rounded-borders q-pa-md">
        <q-card-section class="row items-center">
          <q-avatar icon="logout" color="red-9" text-color="white" class="q-mr-md" />
          <span class="text-h6 text-weight-bold">Clock Out / Logout?</span>
        </q-card-section>

        <q-card-section class="q-py-md text-grey-4">
          This will terminate your current active shift session on this terminal. Any uncommitted
          logs will be lost.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" v-close-popup color="grey-5" />
          <q-btn
            flat
            label="Clock Out"
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
      <q-card class="bg-grey-9 text-white border-all rounded-borders dialog-card q-pa-md">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">Record POS Cash Sale</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-5" />
        </q-card-section>

        <q-form @submit.prevent="submitPosSale" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Sale Value (BDT)</label
              >
              <q-input
                v-model.number="posAmount"
                type="number"
                filled
                color="primary"
                dark
                class="custom-dark-input text-h6 font-mono"
                :rules="[(val) => (!!val && val > 0) || 'Amount must be greater than zero']"
                hide-bottom-space
              />
            </div>
            <div>
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Optional Description</label
              >
              <q-input
                v-model="posDescription"
                type="textarea"
                filled
                color="primary"
                dark
                class="custom-dark-input"
                rows="2"
              />
            </div>
          </q-card-section>
          <q-card-actions align="right">
            <q-btn flat label="Cancel" v-close-popup color="grey-5" />
            <q-btn
              type="submit"
              label="Record Sale"
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
      <q-card class="bg-grey-9 text-white border-all rounded-borders dialog-card q-pa-md">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">Record Staff / Worker Meal</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-5" />
        </q-card-section>

        <q-form @submit.prevent="submitMeal" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Consumer Category</label
              >
              <q-select
                v-model="mealCategory"
                :options="['Contract Employee', 'Kitchen Staff', 'Canteen Customer']"
                filled
                color="primary"
                dark
                class="custom-dark-input"
              />
            </div>
            <div class="q-mb-md">
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Meal Selection</label
              >
              <q-select
                v-model="mealType"
                :options="['Standard Breakfast', 'Full Lunch Set', 'Dinner Combo']"
                filled
                color="primary"
                dark
                class="custom-dark-input"
              />
            </div>
            <div>
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Quantity</label
              >
              <q-input
                v-model.number="mealQty"
                type="number"
                filled
                color="primary"
                dark
                class="custom-dark-input font-mono"
                :rules="[(val) => (!!val && val > 0) || 'Quantity must be 1 or more']"
                hide-bottom-space
              />
            </div>
          </q-card-section>
          <q-card-actions align="right">
            <q-btn flat label="Cancel" v-close-popup color="grey-5" />
            <q-btn
              type="submit"
              label="Record Meal"
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
      <q-card class="bg-grey-9 text-white border-all rounded-borders dialog-card q-pa-md">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">Request Cash Payroll Advance</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-5" />
        </q-card-section>

        <q-form @submit.prevent="submitAdvance" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Advance Amount (BDT)</label
              >
              <q-input
                v-model.number="advanceAmount"
                type="number"
                filled
                color="primary"
                dark
                class="custom-dark-input text-h6 font-mono"
                :rules="[(val) => (!!val && val > 0) || 'Amount must be greater than zero']"
                hide-bottom-space
              />
            </div>
            <div>
              <label class="block text-caption text-grey-4 text-weight-medium q-mb-xs"
                >Reason / Note</label
              >
              <q-input
                v-model="advanceReason"
                type="textarea"
                filled
                color="primary"
                dark
                class="custom-dark-input"
                rows="2"
                :rules="[(val) => !!val || 'Reason is required']"
                hide-bottom-space
              />
            </div>
          </q-card-section>
          <q-card-actions align="right">
            <q-btn flat label="Cancel" v-close-popup color="grey-5" />
            <q-btn
              type="submit"
              label="Request Advance"
              color="info"
              class="q-px-md text-weight-bold cursor-pointer"
              style="min-height: 40px"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useKioskStore } from '../../stores/kiosk';
import { useQuasar } from 'quasar';

const router = useRouter();
const kioskStore = useKioskStore();
const $q = useQuasar();

const currentStaffName = computed(() => kioskStore.currentStaff?.fullName || 'Staff');
const currentStaffRole = computed(() => kioskStore.currentStaff?.role || 'Operator');

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

const logColumns = [
  { name: 'time', align: 'left' as const, label: 'Logged Time', field: 'time', sortable: true },
  { name: 'type', align: 'left' as const, label: 'Action Type', field: 'type', sortable: true },
  { name: 'details', align: 'left' as const, label: 'Operational Details', field: 'details' },
  { name: 'value', align: 'right' as const, label: 'Value / Amount', field: 'value' },
];

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

onMounted(() => {
  timerId = window.setInterval(() => {
    shiftSeconds.value += 1;
  }, 1000);
});

onUnmounted(() => {
  if (timerId) clearInterval(timerId);
});

const handleClockOut = () => {
  kioskStore.logoutStaff();
  $q.notify({
    type: 'positive',
    message: 'Staff session closed.',
    position: 'top',
  });
  void router.push({ name: 'kiosk-login' });
};

// Open dialogs
const openPosDialog = () => {
  posAmount.value = null;
  posDescription.value = '';
  showPosDialog.value = true;
};

const openMealDialog = () => {
  mealCategory.value = 'Contract Employee';
  mealType.value = 'Full Lunch Set';
  mealQty.value = 1;
  showMealDialog.value = true;
};

const openAdvanceDialog = () => {
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
  $q.notify({
    type: 'positive',
    message: 'POS Cash Sale recorded.',
    position: 'top',
  });
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
  $q.notify({
    type: 'positive',
    message: 'Meal operation recorded.',
    position: 'top',
  });
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
  $q.notify({
    type: 'positive',
    message: 'Cash advance requested successfully.',
    position: 'top',
  });
};

const getTypeColor = (type: string) => {
  if (type === 'sale') return 'positive';
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
  border-color: rgba(255, 255, 255, 0.25);
  background: rgba(255, 255, 255, 0.05);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.rounded-btn {
  border-radius: 12px;
}

.dialog-card {
  width: 100%;
  max-width: 450px;
}

.custom-dark-input :deep(.q-field__control) {
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.03) !important;
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white !important;
  transition: all 0.2s ease;

  &:hover {
    border-color: rgba(255, 255, 255, 0.25);
  }

  &.q-field__control--focused {
    border-color: var(--q-primary) !important;
  }
}

.border-all {
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.border-grey-8 {
  border-color: rgba(255, 255, 255, 0.08) !important;
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
</style>
