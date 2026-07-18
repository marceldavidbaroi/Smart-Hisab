<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
          {{ $t('attendance.title') }}
        </h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('attendance.subtitle') }}
        </p>
      </div>
    </div>

    <!-- Toolbar: Date Picker, Search & View Tabs -->
    <div class="row q-col-gutter-sm items-center q-mb-md">
      <!-- Tabs (Daily, Weekly, Monthly) -->
      <div class="col-12 col-md-5">
        <q-tabs
          v-model="activeTab"
          dense
          class="text-grey-7 bg-grey-2 rounded-borders"
          active-color="primary"
          indicator-color="primary"
          align="justify"
          narrow-indicator
          style="min-height: 48px"
        >
          <q-tab name="daily" :label="$t('attendance.views.daily')" />
          <q-tab name="weekly" :label="$t('attendance.views.weekly')" />
          <q-tab name="monthly" :label="$t('attendance.views.monthly')" />
        </q-tabs>
      </div>

      <!-- Date / Month Picker -->
      <div class="col-12 col-sm-6 col-md-3">
        <q-input
          v-if="activeTab !== 'monthly'"
          v-model="selectedDate"
          dense
          outlined
          bg-color="white"
          :label="$t('attendance.daily.dateLabel')"
          mask="XXXX-XX-XX"
        >
          <template v-slot:append>
            <q-icon name="event" class="cursor-pointer">
              <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                <q-date v-model="selectedDate" mask="YYYY-MM-DD" @update:model-value="onDateChange">
                  <div class="row items-center justify-end">
                    <q-btn v-close-popup label="Close" color="primary" flat />
                  </div>
                </q-date>
              </q-popup-proxy>
            </q-icon>
          </template>
        </q-input>

        <!-- Monthly picker (Month & Year select) -->
        <div v-else class="row q-col-gutter-xs">
          <div class="col-7">
            <q-select
              v-model="selectedMonth"
              :options="monthOptions"
              emit-value
              map-options
              dense
              outlined
              bg-color="white"
              :label="$t('attendance.monthly.monthLabel')"
              @update:model-value="onMonthYearChange"
            />
          </div>
          <div class="col-5">
            <q-select
              v-model="selectedYear"
              :options="yearOptions"
              dense
              outlined
              bg-color="white"
              label="Year"
              @update:model-value="onMonthYearChange"
            />
          </div>
        </div>
      </div>

      <!-- Search Box -->
      <div class="col-12 col-sm-6 col-md-4">
        <q-input
          v-model="searchQuery"
          dense
          outlined
          bg-color="white"
          clearable
          :placeholder="$t('attendance.daily.searchPlaceholder')"
        >
          <template v-slot:prepend>
            <q-icon name="search" />
          </template>
        </q-input>
      </div>
    </div>

    <!-- Active Session Status Alert Banner -->
    <div v-if="!activeSession && activeTab === 'daily'" class="q-mb-md">
      <q-banner class="bg-amber-1 text-amber-9 border-all rounded-borders q-pa-sm">
        <template v-slot:avatar>
          <q-icon name="warning" color="warning" size="sm" />
        </template>
        <span class="text-caption text-weight-medium">
          {{ $t('attendance.daily.noSessionWarning') }}
        </span>
      </q-banner>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="32px" />
    </div>

    <div v-else>
      <!-- DAILY VIEW -->
      <div v-if="activeTab === 'daily'" class="row q-col-gutter-md">
        <div
          v-for="customer in filteredCustomers"
          :key="customer.id"
          class="col-12 col-sm-6 col-md-4"
        >
          <q-card flat bordered class="bg-white border-all hover-card column justify-between">
            <q-card-section class="q-pa-md">
              <div class="row justify-between items-start no-wrap">
                <div>
                  <div
                    class="text-subtitle1 text-weight-bold text-primary cursor-pointer"
                    @click="viewBreakdown(customer)"
                  >
                    {{ customer.full_name }}
                  </div>
                  <div class="text-caption text-grey-7 q-mt-xs">
                    <q-icon name="phone" size="14px" class="q-mr-xs text-grey-6" />{{
                      customer.phone
                    }}
                  </div>
                  <div class="text-caption text-grey-7 q-mt-xs">
                    <q-icon name="business" size="14px" class="q-mr-xs text-grey-6" />{{
                      customer.factory_unit || 'No Institution'
                    }}
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-caption text-grey-6">Daily Cost</div>
                  <div class="text-subtitle2 text-weight-bold text-dark font-mono">
                    ৳{{ customer.contract_daily_rate }}
                  </div>
                </div>
              </div>

              <q-separator class="q-my-md" />

              <!-- Shifts list for this customer -->
              <div>
                <div class="text-subtitle2 text-weight-bold text-slate-800 q-mb-sm">
                  Contracted Shifts
                </div>
                <div class="column q-gutter-y-sm">
                  <div
                    v-for="shift in getCustomerShifts(customer)"
                    :key="shift.name"
                    class="row items-center justify-between q-py-xs border-bottom"
                  >
                    <div class="text-weight-medium text-slate-700">
                      {{ shift.name }}
                    </div>
                    <q-btn
                      dense
                      unelevated
                      no-caps
                      :color="isAttended(customer.id, shift.name) ? 'primary' : 'grey-2'"
                      :text-color="isAttended(customer.id, shift.name) ? 'white' : 'grey-8'"
                      class="text-weight-bold q-px-md rounded-borders cursor-pointer"
                      style="min-height: 40px; min-width: 120px"
                      @click="onShiftClick(customer, shift.name)"
                    >
                      <q-icon
                        :name="
                          isAttended(customer.id, shift.name)
                            ? 'check_circle'
                            : 'radio_button_unchecked'
                        "
                        size="16px"
                        class="q-mr-xs"
                      />
                      {{ isAttended(customer.id, shift.name) ? 'Present' : 'Mark Present' }}
                    </q-btn>
                  </div>
                </div>
              </div>
            </q-card-section>
          </q-card>
        </div>
        <div v-if="filteredCustomers.length === 0" class="col-12 text-center text-grey-6 q-py-xl">
          {{ $t('attendance.empty') }}
        </div>
      </div>

      <!-- WEEKLY VIEW -->
      <div v-else-if="activeTab === 'weekly'">
        <q-card flat bordered class="bg-white border-all q-pa-md">
          <div class="row items-center justify-between q-mb-md">
            <div class="text-subtitle1 text-weight-bold text-slate-800">
              {{ $t('attendance.weekly.weekLabel') }}: {{ formatWeekRange }}
            </div>
          </div>

          <q-table
            :rows="filteredCustomers"
            :columns="weeklyColumns"
            row-key="id"
            flat
            bordered
            dense
            :no-data-label="$t('attendance.empty')"
            :pagination="{ rowsPerPage: 20 }"
          >
            <template #body-cell-customer_name="props">
              <q-td
                :props="props"
                class="text-weight-medium text-primary cursor-pointer"
                @click="viewBreakdown(props.row)"
              >
                {{ props.row.full_name }}
              </q-td>
            </template>
            <template
              v-for="day in weekDays"
              :key="day.dateStr"
              v-slot:[`body-cell-${day.key}`]="props"
            >
              <q-td :props="props" class="text-center">
                <div
                  v-if="getAttendedShiftsForDate(props.row.id, day.dateStr).length > 0"
                  class="row justify-center q-gutter-xs"
                >
                  <q-chip
                    v-for="s in getAttendedShiftsForDate(props.row.id, day.dateStr)"
                    :key="s"
                    dense
                    color="primary"
                    text-color="white"
                    class="q-ma-none text-weight-bold font-mono"
                    size="xs"
                  >
                    {{ s.substring(0, 1).toUpperCase() }}
                  </q-chip>
                </div>
                <span v-else class="text-grey-4">—</span>
              </q-td>
            </template>
          </q-table>
        </q-card>
      </div>

      <!-- MONTHLY VIEW -->
      <div v-else-if="activeTab === 'monthly'">
        <q-card flat bordered class="bg-white border-all q-pa-md">
          <q-table
            :rows="monthlySummaries"
            :columns="monthlyColumns"
            row-key="customerId"
            flat
            bordered
            dense
            :no-data-label="$t('attendance.empty')"
            :pagination="{ rowsPerPage: 20 }"
          >
            <template #body-cell-name="props">
              <q-td
                :props="props"
                class="text-weight-medium text-primary cursor-pointer"
                @click="viewBreakdownById(props.row.customerId)"
              >
                {{ props.row.name }}
              </q-td>
            </template>
            <template #body-cell-dailyRate="props">
              <q-td :props="props" class="font-mono"> ৳{{ props.value }} </q-td>
            </template>
            <template #body-cell-attendanceCharged="props">
              <q-td :props="props" class="font-mono text-weight-bold text-negative">
                ৳{{ props.value }}
              </q-td>
            </template>
            <template #body-cell-extrasCharged="props">
              <q-td :props="props" class="font-mono text-weight-bold text-negative">
                ৳{{ props.value }}
              </q-td>
            </template>
            <template #body-cell-totalPaid="props">
              <q-td :props="props" class="font-mono text-weight-bold text-positive">
                ৳{{ props.value }}
              </q-td>
            </template>
            <template #body-cell-netBalance="props">
              <q-td :props="props" class="font-mono text-weight-bold"> ৳{{ props.value }} </q-td>
            </template>
            <template #body-cell-actions="props">
              <q-td :props="props" class="text-right">
                <q-btn
                  flat
                  dense
                  no-caps
                  color="primary"
                  icon="visibility"
                  :label="$t('attendance.monthly.actions.breakdown')"
                  class="cursor-pointer text-weight-bold q-px-sm"
                  @click="viewBreakdownById(props.row.customerId)"
                />
              </q-td>
            </template>
          </q-table>
        </q-card>
      </div>
    </div>

    <!-- Mark Shift Present / Edit Confirm Dialog -->
    <q-dialog v-model="showMarkDialog" persistent>
      <q-card style="width: 500px; max-width: 90vw" class="text-dark bg-white">
        <q-card-section class="row items-center border-bottom q-py-sm">
          <div class="text-subtitle1 text-weight-bold">
            {{ $t('attendance.daily.confirmMarkPresent') }}
          </div>
          <q-space />
          <q-btn flat round dense icon="close" v-close-popup class="cursor-pointer" />
        </q-card-section>

        <q-card-section class="q-py-md q-px-md">
          <div class="q-mb-md">
            {{
              $t('attendance.daily.confirmMarkPresentMsg', {
                name: dialogCustomer?.full_name,
                shift: dialogShift,
              })
            }}
          </div>

          <div class="text-subtitle2 text-weight-bold text-slate-800 q-mb-xs">
            {{ $t('attendance.daily.extraItemsTitle') }}
          </div>

          <!-- Dynamic list of extra items -->
          <div
            v-for="(item, index) in extraItems"
            :key="index"
            class="row q-col-gutter-xs items-center q-mb-sm"
          >
            <div class="col-7">
              <q-input
                v-model="item.description"
                dense
                outlined
                :label="$t('attendance.daily.itemDescriptionLabel')"
              />
            </div>
            <div class="col-4">
              <q-input
                v-model.number="item.amount"
                dense
                outlined
                type="number"
                prefix="৳"
                :label="$t('attendance.daily.itemAmountLabel')"
              />
            </div>
            <div class="col-1 text-center">
              <q-btn
                flat
                round
                dense
                color="negative"
                icon="delete"
                class="cursor-pointer"
                @click="removeExtraItem(index)"
              />
            </div>
          </div>

          <q-btn
            flat
            dense
            no-caps
            color="primary"
            icon="add"
            :label="$t('attendance.daily.addExtraBtn')"
            class="cursor-pointer q-mt-xs font-semibold"
            @click="addExtraItem"
          />
        </q-card-section>

        <q-card-actions align="right" class="q-pb-md q-px-md border-top">
          <q-btn
            flat
            dense
            no-caps
            :label="$t('attendance.daily.cancelBtn')"
            v-close-popup
            class="cursor-pointer q-px-md text-grey-7"
          />
          <q-btn
            unelevated
            dense
            no-caps
            color="primary"
            :label="$t('attendance.daily.saveBtn')"
            class="cursor-pointer q-px-md font-bold"
            :loading="saving"
            @click="submitMarkPresent"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Unmark Shift Absent Confirm Dialog -->
    <q-dialog v-model="showUnmarkDialog" persistent>
      <q-card style="width: 450px; max-width: 90vw" class="text-dark bg-white">
        <q-card-section class="row items-center border-bottom q-py-sm">
          <div class="text-subtitle1 text-weight-bold">
            {{ $t('attendance.daily.confirmMarkAbsent') }}
          </div>
          <q-space />
          <q-btn flat round dense icon="close" v-close-popup class="cursor-pointer" />
        </q-card-section>

        <q-card-section class="q-py-md q-px-md">
          {{
            $t('attendance.daily.confirmMarkAbsentMsg', {
              name: dialogCustomer?.full_name,
              shift: dialogShift,
            })
          }}
        </q-card-section>

        <q-card-actions align="right" class="q-pb-md q-px-md border-top">
          <q-btn
            flat
            dense
            no-caps
            :label="$t('attendance.daily.cancelBtn')"
            v-close-popup
            class="cursor-pointer q-px-md text-grey-7"
          />
          <q-btn
            unelevated
            dense
            no-caps
            color="negative"
            label="Confirm Absent"
            class="cursor-pointer q-px-md font-bold"
            :loading="saving"
            @click="submitMarkAbsent"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Breakdown Lookup Dialog -->
    <q-dialog
      v-model="showBreakdownDialog"
      maximized
      transition-show="slide-up"
      transition-hide="slide-down"
    >
      <q-card class="bg-grey-1 text-dark">
        <q-header class="bg-white text-dark bordered">
          <q-toolbar>
            <q-toolbar-title class="text-weight-bold">
              {{ breakdownCustomer?.full_name }} — {{ $t('attendance.breakdown.title') }}
            </q-toolbar-title>
            <q-btn flat round dense icon="close" v-close-popup class="cursor-pointer" />
          </q-toolbar>
        </q-header>

        <q-page-container class="q-pa-md">
          <q-card flat bordered class="q-pa-md q-mb-md bg-white border-all">
            <div class="row justify-between items-center">
              <div>
                <div class="text-h6 text-weight-bold">{{ breakdownCustomer?.full_name }}</div>
                <div class="text-caption text-grey-7">
                  Phone: {{ breakdownCustomer?.phone || 'N/A' }} | Unit:
                  {{ breakdownCustomer?.factory_unit || 'N/A' }}
                </div>
              </div>
              <div class="text-right">
                <div class="text-caption text-grey-6">Outstanding Balance</div>
                <div class="text-h6 font-mono text-weight-bold text-negative">
                  ৳{{ breakdownCustomer?.outstanding_balance }}
                </div>
              </div>
            </div>
          </q-card>

          <q-card flat bordered class="q-pa-md bg-white border-all">
            <div class="text-subtitle1 text-weight-bold text-slate-800 q-mb-md">
              {{ $t('attendance.breakdown.subtitle') }}
            </div>

            <CustomerStatementTable
              :attendance="breakdownAttendance"
              :baki="breakdownBaki"
              :collections="breakdownCollections"
              :loading="loadingBreakdown"
            />
          </q-card>
        </q-page-container>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { supabase } from '../../boot/supabase';
import { useTenantStore } from '../../stores/tenant';
import { useSessionStore } from '../../stores/session';
import type { Customer } from '../../stores/customers';
import { showSuccess, showWarning, showApiError } from '../../composables/useFeedback';
import CustomerStatementTable from '../../components/customers/CustomerStatementTable.vue';

// Types
interface Shift {
  name: string;
}

interface AttendanceRecord {
  id: string;
  customer_id: string;
  session_id: string;
  business_date: string;
  attended_shifts: string[];
  rate_applied: number;
}

interface BakiItem {
  id: string;
  customer_id: string;
  session_id: string;
  business_date: string;
  items_description: string;
  amount: number;
}

interface CollectionItem {
  id: string;
  customer_id: string;
  session_id: string | null;
  collected_at: string;
  amount: number;
  payment_method: string;
  notes: string | null;
}

interface MonthlySummary {
  customerId: string;
  name: string;
  dailyRate: number;
  daysAttended: number;
  mealCount: number;
  attendanceCharged: number;
  extrasCharged: number;
  totalPaid: number;
  netBalance: number;
}

const { t } = useI18n();
const tenantStore = useTenantStore();
const sessionStore = useSessionStore();

// View States
const activeTab = ref('daily');
const selectedDate = ref(new Date().toISOString().split('T')[0] || '');
const searchQuery = ref('');
const loading = ref(false);

const activeSession = computed(() => sessionStore.activeSession);

// Month selection options
const currentYear = new Date().getFullYear();
const selectedMonth = ref(new Date().getMonth() + 1);
const selectedYear = ref(currentYear);

const monthOptions = [
  { label: 'January', value: 1 },
  { label: 'February', value: 2 },
  { label: 'March', value: 3 },
  { label: 'April', value: 4 },
  { label: 'May', value: 5 },
  { label: 'June', value: 6 },
  { label: 'July', value: 7 },
  { label: 'August', value: 8 },
  { label: 'September', value: 9 },
  { label: 'October', value: 10 },
  { label: 'November', value: 11 },
  { label: 'December', value: 12 },
];

const yearOptions = computed(() => {
  const list = [];
  for (let y = currentYear - 2; y <= currentYear + 1; y++) {
    list.push(y);
  }
  return list;
});

// Domain Lists
const customers = ref<Customer[]>([]);
const activeShifts = ref<Shift[]>([]);
const attendanceList = ref<AttendanceRecord[]>([]);
const bakiTransactions = ref<BakiItem[]>([]);
const collectionsList = ref<CollectionItem[]>([]);

// Filtered Customers
const filteredCustomers = computed(() => {
  const q = (searchQuery.value || '').toLowerCase().trim();
  if (!q) return customers.value;
  return customers.value.filter(
    (c) => c.full_name.toLowerCase().includes(q) || (c.phone && c.phone.toLowerCase().includes(q)),
  );
});

// Daily view helpers
function isAttended(customerId: string, shiftName: string): boolean {
  const record = attendanceList.value.find(
    (a) => a.customer_id === customerId && a.business_date === selectedDate.value,
  );
  return record ? record.attended_shifts.includes(shiftName) : false;
}

function getCustomerShifts(customer: Customer) {
  if (customer.contract_shifts && customer.contract_shifts.length > 0) {
    const contractedLower = customer.contract_shifts.map((s) => s.toLowerCase().trim());
    return activeShifts.value.filter((s) => contractedLower.includes(s.name.toLowerCase().trim()));
  }
  return activeShifts.value;
}

// Mark Dialog States
const showMarkDialog = ref(false);
const showUnmarkDialog = ref(false);
const dialogCustomer = ref<Customer | null>(null);
const dialogShift = ref('');
const extraItems = ref<{ description: string; amount: number }[]>([]);
const saving = ref(false);

function addExtraItem() {
  extraItems.value.push({ description: '', amount: 0 });
}

function removeExtraItem(index: number) {
  extraItems.value.splice(index, 1);
}

function onShiftClick(customer: Customer, shiftName: string) {
  // If editing historical dates where there is no active session, prevent writing
  if (!activeSession.value || activeSession.value.business_date !== selectedDate.value) {
    showWarning(
      t('attendance.daily.editWarning', { date: activeSession.value?.business_date || 'N/A' }),
    );
    return;
  }

  dialogCustomer.value = customer;
  dialogShift.value = shiftName;

  const attended = isAttended(customer.id, shiftName);
  if (attended) {
    showUnmarkDialog.value = true;
  } else {
    extraItems.value = [];
    showMarkDialog.value = true;
  }
}

async function submitMarkPresent() {
  if (!dialogCustomer.value || !activeSession.value) return;
  saving.value = true;
  try {
    // 1. Toggle Attendance
    const { error: attError } = await supabase.rpc('toggle_contract_attendance', {
      p_tenant_id: tenantStore.activeTenant?.id,
      p_customer_id: dialogCustomer.value.id,
      p_session_id: activeSession.value.id,
      p_shift_name: dialogShift.value,
    });
    if (attError) throw attError;

    // 2. Insert any Extras
    for (const item of extraItems.value) {
      if (item.description.trim() && item.amount > 0) {
        const { error: bakiError } = await supabase.rpc('record_baki_transaction', {
          p_tenant_id: tenantStore.activeTenant?.id,
          p_customer_id: dialogCustomer.value.id,
          p_session_id: activeSession.value.id,
          p_items_description: item.description.trim(),
          p_amount: item.amount,
        });
        if (bakiError) throw bakiError;
      }
    }

    showSuccess(t('attendance.feedback.saved'));
    showMarkDialog.value = false;
    await fetchData();
  } catch (err) {
    void showApiError(err, t('attendance.errors.toggleFailed'));
  } finally {
    saving.value = false;
  }
}

async function submitMarkAbsent() {
  if (!dialogCustomer.value || !activeSession.value) return;
  saving.value = true;
  try {
    const { error } = await supabase.rpc('toggle_contract_attendance', {
      p_tenant_id: tenantStore.activeTenant?.id,
      p_customer_id: dialogCustomer.value.id,
      p_session_id: activeSession.value.id,
      p_shift_name: dialogShift.value,
    });
    if (error) throw error;

    showSuccess(t('attendance.feedback.saved'));
    showUnmarkDialog.value = false;
    await fetchData();
  } catch (err) {
    void showApiError(err, t('attendance.errors.toggleFailed'));
  } finally {
    saving.value = false;
  }
}

// WEEKLY VIEW HELPERS
const weekDays = computed(() => {
  const base = new Date(selectedDate.value);
  const day = base.getDay();
  // Monday is 1, Sunday is 0. Calculate Monday offset
  const diff = base.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(base.setDate(diff));

  const list = [];
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  for (let i = 0; i < 7; i++) {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    const dateStr = d.toISOString().split('T')[0] || '';
    list.push({
      key: `day_${i}`,
      label: `${dayNames[i]} (${d.getMonth() + 1}/${d.getDate()})`,
      dateStr,
    });
  }
  return list;
});

const formatWeekRange = computed(() => {
  if (weekDays.value.length === 0) return '';
  const first = weekDays.value[0]?.dateStr;
  const last = weekDays.value[6]?.dateStr;
  return `${first} to ${last}`;
});

const weeklyColumns = computed(() => {
  const base = [
    {
      name: 'customer_name',
      align: 'left' as const,
      label: 'Customer Name',
      field: 'full_name',
      sortable: true,
    },
  ];
  const dayCols = weekDays.value.map((day) => ({
    name: day.key,
    align: 'center' as const,
    label: day.label,
    field: day.key,
  }));
  return [...base, ...dayCols];
});

function getAttendedShiftsForDate(customerId: string, dateStr: string): string[] {
  const record = attendanceList.value.find(
    (a) => a.customer_id === customerId && a.business_date === dateStr,
  );
  return record ? record.attended_shifts : [];
}

// MONTHLY VIEW HELPERS
const monthlyColumns = computed(() => [
  {
    name: 'name',
    align: 'left' as const,
    label: t('attendance.monthly.cols.name'),
    field: 'name',
    sortable: true,
  },
  {
    name: 'dailyRate',
    align: 'left' as const,
    label: t('attendance.monthly.cols.dailyRate'),
    field: 'dailyRate',
    sortable: true,
  },
  {
    name: 'daysAttended',
    align: 'left' as const,
    label: t('attendance.monthly.cols.daysAttended'),
    field: 'daysAttended',
    sortable: true,
  },
  {
    name: 'attendanceCharged',
    align: 'left' as const,
    label: t('attendance.monthly.cols.attendanceCharged'),
    field: 'attendanceCharged',
    sortable: true,
  },
  {
    name: 'extrasCharged',
    align: 'left' as const,
    label: t('attendance.monthly.cols.extrasCharged'),
    field: 'extrasCharged',
    sortable: true,
  },
  {
    name: 'totalPaid',
    align: 'left' as const,
    label: t('attendance.monthly.cols.totalPaid'),
    field: 'totalPaid',
    sortable: true,
  },
  {
    name: 'netBalance',
    align: 'left' as const,
    label: t('attendance.monthly.cols.netBalance'),
    field: 'netBalance',
    sortable: true,
  },
  {
    name: 'actions',
    align: 'right' as const,
    label: '',
    field: 'actions',
  },
]);

const monthlySummaries = computed(() => {
  const summaries: MonthlySummary[] = [];

  const yearStr = selectedYear.value;
  const monthStr = String(selectedMonth.value).padStart(2, '0');
  const monthStart = `${yearStr}-${monthStr}-01`;
  // calculate last day
  const lastDayVal = new Date(selectedYear.value, selectedMonth.value, 0).getDate();
  const monthEnd = `${yearStr}-${monthStr}-${String(lastDayVal).padStart(2, '0')}`;

  filteredCustomers.value.forEach((cust) => {
    // Filter att for this customer in month
    const attInMonth = attendanceList.value.filter(
      (a) =>
        a.customer_id === cust.id && a.business_date >= monthStart && a.business_date <= monthEnd,
    );

    const daysAttended = attInMonth.length;
    let mealCount = 0;
    let attendanceCharged = 0;

    attInMonth.forEach((a) => {
      mealCount += a.attended_shifts.length;
      attendanceCharged += Number(a.rate_applied);
    });

    // Baki transactions in month
    const bakiInMonth = bakiTransactions.value.filter(
      (b) =>
        b.customer_id === cust.id && b.business_date >= monthStart && b.business_date <= monthEnd,
    );
    const extrasCharged = bakiInMonth.reduce((sum, item) => sum + Number(item.amount), 0);

    // Collections in month
    const colInMonth = collectionsList.value.filter((col) => {
      if (col.customer_id !== cust.id) return false;
      const dateOnly = col.collected_at.split('T')[0] || '';
      return dateOnly >= monthStart && dateOnly <= monthEnd;
    });
    const totalPaid = colInMonth.reduce((sum, item) => sum + Number(item.amount), 0);

    summaries.push({
      customerId: cust.id,
      name: cust.full_name,
      dailyRate: cust.contract_daily_rate || 0,
      daysAttended,
      mealCount,
      attendanceCharged,
      extrasCharged,
      totalPaid,
      netBalance: cust.outstanding_balance,
    });
  });

  return summaries;
});

// Breakdown Dialog States
const showBreakdownDialog = ref(false);
const breakdownCustomer = ref<Customer | null>(null);
const loadingBreakdown = ref(false);
const breakdownAttendance = ref<AttendanceRecord[]>([]);
const breakdownBaki = ref<BakiItem[]>([]);
const breakdownCollections = ref<CollectionItem[]>([]);

async function viewBreakdown(customer: Customer) {
  breakdownCustomer.value = customer;
  showBreakdownDialog.value = true;
  await loadBreakdownData(customer.id);
}

async function viewBreakdownById(customerId: string) {
  const cust = customers.value.find((c) => c.id === customerId);
  if (cust) {
    await viewBreakdown(cust);
  }
}

async function loadBreakdownData(customerId: string) {
  const tenant = tenantStore.activeTenant;
  if (!tenant) return;
  loadingBreakdown.value = true;
  try {
    const [attRes, bakiRes, colRes] = await Promise.all([
      supabase
        .from('customer_daily_attendance')
        .select('*')
        .eq('tenant_id', tenant.id)
        .eq('customer_id', customerId)
        .order('business_date', { ascending: false }),
      supabase
        .from('baki_transactions')
        .select('*')
        .eq('tenant_id', tenant.id)
        .eq('customer_id', customerId)
        .order('business_date', { ascending: false }),
      supabase
        .from('customer_collections')
        .select('*')
        .eq('tenant_id', tenant.id)
        .eq('customer_id', customerId)
        .order('collected_at', { ascending: false }),
    ]);

    if (attRes.error) throw attRes.error;
    if (bakiRes.error) throw bakiRes.error;
    if (colRes.error) throw colRes.error;

    breakdownAttendance.value = attRes.data ?? [];
    breakdownBaki.value = bakiRes.data ?? [];
    breakdownCollections.value = colRes.data ?? [];
  } catch (err) {
    console.error('Failed to load breakdown details', err);
  } finally {
    loadingBreakdown.value = false;
  }
}

// Global Fetch
async function fetchData() {
  const tenant = tenantStore.activeTenant;
  if (!tenant) return;

  loading.value = true;
  try {
    // 1. Fetch active session
    await sessionStore.fetchActiveSession();

    // 2. Fetch active shifts
    const { data: shifts, error: shiftsErr } = await supabase
      .from('shifts')
      .select('name')
      .eq('tenant_id', tenant.id)
      .eq('is_active', true)
      .order('name');
    if (shiftsErr) throw shiftsErr;
    activeShifts.value = shifts ?? [];

    // 3. Fetch contract worker customers
    const { data: custData, error: custErr } = await supabase
      .from('customers')
      .select('*')
      .eq('tenant_id', tenant.id)
      .eq('category', 'contract_worker')
      .eq('is_active', true)
      .order('full_name', { ascending: true });
    if (custErr) throw custErr;
    customers.value = custData ?? [];

    // 4. Fetch attendance list based on view
    let attQuery = supabase
      .from('customer_daily_attendance')
      .select('*')
      .eq('tenant_id', tenant.id);
    let bakiQuery = supabase.from('baki_transactions').select('*').eq('tenant_id', tenant.id);
    let colQuery = supabase.from('customer_collections').select('*').eq('tenant_id', tenant.id);

    if (activeTab.value === 'daily') {
      attQuery = attQuery.eq('business_date', selectedDate.value);
    } else if (activeTab.value === 'weekly') {
      const dates = weekDays.value;
      if (dates.length === 7) {
        attQuery = attQuery
          .gte('business_date', dates[0]?.dateStr)
          .lte('business_date', dates[6]?.dateStr);
      }
    } else if (activeTab.value === 'monthly') {
      const yearStr = selectedYear.value;
      const monthStr = String(selectedMonth.value).padStart(2, '0');
      const start = `${yearStr}-${monthStr}-01`;
      const lastDayVal = new Date(selectedYear.value, selectedMonth.value, 0).getDate();
      const end = `${yearStr}-${monthStr}-${String(lastDayVal).padStart(2, '0')}`;

      attQuery = attQuery.gte('business_date', start).lte('business_date', end);
      bakiQuery = bakiQuery.gte('business_date', start).lte('business_date', end);
      colQuery = colQuery
        .gte('collected_at', `${start}T00:00:00Z`)
        .lte('collected_at', `${end}T23:59:59Z`);
    }

    const [attRes, bakiRes, colRes] = await Promise.all([attQuery, bakiQuery, colQuery]);
    if (attRes.error) throw attRes.error;
    attendanceList.value = attRes.data ?? [];

    if (activeTab.value === 'monthly') {
      if (bakiRes.error) throw bakiRes.error;
      if (colRes.error) throw colRes.error;
      bakiTransactions.value = bakiRes.data ?? [];
      collectionsList.value = colRes.data ?? [];
    }
  } catch (err) {
    void showApiError(err, t('attendance.errors.loadFailed'));
  } finally {
    loading.value = false;
  }
}

function onDateChange() {
  void fetchData();
}

function onMonthYearChange() {
  void fetchData();
}

watch(activeTab, () => {
  void fetchData();
});

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
</style>
