<template>
  <q-dialog v-model="isOpen" persistent>
    <q-card
      flat
      bordered
      class="q-dialog-plugin text-dark bg-white"
      style="width: 480px; max-width: 90vw"
    >
      <!-- Header -->
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div class="column">
          <div class="text-subtitle1 text-weight-bold">
            {{ $t('customers.attendance.dialog.title') }}
          </div>
          <div class="text-caption text-grey-7">
            {{ customer.full_name }} · {{ customer.phone || 'No Phone' }}
          </div>
        </div>
        <q-space />
        <q-btn
          flat
          round
          dense
          icon="close"
          v-close-popup
          class="cursor-pointer"
          style="min-width: 48px; min-height: 48px"
          :disable="saving"
        />
      </q-card-section>

      <!-- Content -->
      <q-card-section class="q-py-md q-px-md">
        <q-form @submit.prevent="onSubmit" class="q-gutter-y-md">
          <!-- Date Field (Editable Date Picker) -->
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
              {{ $t('customers.attendance.dialog.selectDate') }}
            </label>
            <q-input
              v-model="form.date"
              dense
              outlined
              bg-color="white"
              mask="XXXX-XX-XX"
              :rules="[(val) => !!val || 'Date is required']"
              :disable="saving"
            >
              <template v-slot:append>
                <q-icon name="event" class="cursor-pointer">
                  <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                    <q-date v-model="form.date" mask="YYYY-MM-DD">
                      <div class="row items-center justify-end">
                        <q-btn v-close-popup label="Close" color="primary" flat />
                      </div>
                    </q-date>
                  </q-popup-proxy>
                </q-icon>
              </template>
            </q-input>
          </div>

          <!-- Existing Addons/Extras banner -->
          <div
            v-if="existingExtras.length > 0"
            class="q-mt-sm bg-amber-1 q-pa-sm rounded-borders border-all"
            style="border-color: rgba(245, 158, 11, 0.2)"
          >
            <div class="text-caption text-weight-bold text-amber-9 row items-center">
              <q-icon name="warning" class="q-mr-xs" size="14px" />
              Existing Add-ons for Today:
            </div>
            <div class="q-mt-xs">
              <div
                v-for="item in existingExtras"
                :key="item.id"
                class="text-caption text-grey-9 q-ml-sm"
              >
                • {{ item.items_description }} (৳{{ item.amount }})
              </div>
            </div>
          </div>

          <!-- Shift Selection (btn-toggle) -->
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
              {{ $t('customers.attendance.dialog.selectShift') }} *
            </label>
            <div v-if="shiftOptions.length > 0">
              <q-btn-toggle
                v-model="form.shift"
                spread
                no-caps
                toggle-color="primary"
                toggle-text-color="white"
                color="grey-2"
                text-color="grey-8"
                class="full-width"
                style="min-height: 48px"
                :options="shiftOptions"
                :disable="saving"
              />
              <div
                v-if="form.shift && attendedShifts.includes(form.shift)"
                class="text-caption text-negative q-mt-sm text-weight-bold"
              >
                Already Present for {{ form.shift }} - Duplicate entry blocked.
              </div>
              <div
                v-else-if="allShiftsMarked"
                class="text-caption text-negative q-mt-sm text-weight-bold"
              >
                {{ $t('customers.attendance.dialog.allShiftsMarked') }}
              </div>
            </div>
            <div v-else class="text-caption text-negative text-weight-bold">
              {{ $t('customers.attendance.dialog.noShifts') }}
            </div>
          </div>

          <!-- Extras Toggle -->
          <div class="row items-center justify-between q-py-xs border-top q-mt-md">
            <span class="text-subtitle2 text-weight-medium text-grey-9">
              {{ $t('customers.attendance.dialog.addExtras') }}
            </span>
            <q-toggle
              v-model="form.addExtras"
              :disable="
                saving || allShiftsMarked || !!(form.shift && attendedShifts.includes(form.shift))
              "
              color="primary"
              style="min-height: 48px"
            />
          </div>

          <!-- Extras Section (v-if) -->
          <q-slide-transition>
            <div
              v-if="form.addExtras"
              class="q-gutter-y-sm bg-grey-1 q-pa-md rounded-borders border-all"
            >
              <!-- Extras Description (Rich Text Editor) -->
              <div>
                <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
                  {{ $t('customers.attendance.dialog.note') }} *
                </label>
                <q-editor
                  v-model="form.extrasNote"
                  min-height="6rem"
                  :disable="saving"
                  dense
                  class="bg-white text-dark"
                />
                <div
                  v-if="form.addExtras && !isNoteValid"
                  class="text-caption text-negative q-mt-xs"
                >
                  {{ $t('customers.attendance.dialog.noteRequired') }}
                </div>
              </div>

              <!-- Extras Amount -->
              <q-input
                v-model.number="form.extrasAmount"
                :label="$t('customers.attendance.dialog.amount') + ' *'"
                dense
                outlined
                bg-color="white"
                type="number"
                prefix="৳"
                :rules="[
                  (val) =>
                    !form.addExtras ||
                    (val !== null && val !== undefined) ||
                    $t('customers.attendance.dialog.amountRequired'),
                  (val) =>
                    !form.addExtras || val > 0 || $t('customers.attendance.dialog.amountMin'),
                ]"
                :disable="saving"
              />
            </div>
          </q-slide-transition>

          <!-- Footer Actions -->
          <div class="row justify-end q-gutter-x-sm q-mt-lg border-top q-pt-md">
            <q-btn
              flat
              dense
              no-caps
              :label="$t('customers.attendance.dialog.cancelBtn')"
              v-close-popup
              class="cursor-pointer q-px-md text-grey-7"
              style="min-height: 48px; min-width: 80px"
              :disable="saving"
            />
            <q-btn
              unelevated
              dense
              no-caps
              type="submit"
              color="primary"
              :label="$t('customers.attendance.dialog.saveBtn')"
              :loading="saving"
              :disable="isSaveDisabled"
              class="cursor-pointer q-px-md font-bold"
              style="min-height: 48px; min-width: 120px"
            />
          </div>
        </q-form>
      </q-card-section>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import type { Customer, DailyAttendance } from '../../stores/customers';
import { useCustomersStore } from '../../stores/customers';
import { useFeedback } from '../../composables/useFeedback';

interface Shift {
  name: string;
}

const props = defineProps<{
  modelValue: boolean;
  customer: Customer;
  activeShifts: Shift[];
  attendanceToday: DailyAttendance[];
  businessDate: string;
  sessionId: string;
  deviceToken?: string | null;
  staffId?: string | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved'): void;
}>();

const { t } = useI18n();
const customersStore = useCustomersStore();
const feedback = useFeedback();

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const saving = ref(false);
const form = ref({
  date: '',
  shift: '',
  addExtras: false,
  extrasNote: '',
  extrasAmount: 0,
});

const attendedShifts = computed(() => {
  const dateStr = form.value.date;
  const record = props.attendanceToday.find(
    (a) => a.customer_id === props.customer.id && a.business_date === dateStr,
  );
  return record ? record.attended_shifts : [];
});

const availableShifts = computed(() => {
  if (props.customer.contract_shifts && props.customer.contract_shifts.length > 0) {
    const contractedLower = props.customer.contract_shifts.map((s) => s.toLowerCase().trim());
    return props.activeShifts.filter((s) => contractedLower.includes(s.name.toLowerCase().trim()));
  }
  return props.activeShifts;
});

const shiftOptions = computed(() => {
  return availableShifts.value.map((s) => {
    const present = attendedShifts.value.includes(s.name);
    return {
      label: present ? `${s.name} (${t('customers.attendance.present') || 'Present'})` : s.name,
      value: s.name,
    };
  });
});

const allShiftsMarked = computed(() => {
  if (availableShifts.value.length === 0) return false;
  return availableShifts.value.every((s) => attendedShifts.value.includes(s.name));
});

const existingExtras = computed(() => {
  return customersStore.sessionBakiTransactions.filter((b) => b.customer_id === props.customer.id);
});

const isSaveDisabled = computed(() => {
  if (!form.value.shift) return true;
  return attendedShifts.value.includes(form.value.shift) || saving.value;
});

watch(
  isOpen,
  (newVal) => {
    if (newVal) {
      const localDate =
        props.businessDate ||
        (() => {
          const now = new Date();
          const year = now.getFullYear();
          const month = String(now.getMonth() + 1).padStart(2, '0');
          const day = String(now.getDate()).padStart(2, '0');
          return `${year}-${month}-${day}`;
        })();

      form.value = {
        date: localDate,
        shift: '',
        addExtras: false,
        extrasNote: '',
        extrasAmount: props.customer.contract_daily_rate || 0,
      };

      // Prefill first available non-attended shift
      const firstAvailable = availableShifts.value.find(
        (s) => !attendedShifts.value.includes(s.name),
      );
      if (firstAvailable) {
        form.value.shift = firstAvailable.name;
      } else if (availableShifts.value.length > 0) {
        form.value.shift = availableShifts.value[0]?.name || '';
      }
    }
  },
  { immediate: true },
);

const isNoteValid = computed(() => {
  if (!form.value.addExtras) return true;
  const cleanText = (form.value.extrasNote || '').replace(/<[^>]*>/g, '').trim();
  return cleanText.length > 0;
});

async function onSubmit() {
  if (!form.value.shift || isSaveDisabled.value) return;
  if (form.value.addExtras && !isNoteValid.value) return;

  saving.value = true;
  try {
    // 1. Toggle Attendance
    await customersStore.toggleAttendance({
      customerId: props.customer.id,
      sessionId: props.sessionId,
      shiftName: form.value.shift,
      businessDate: form.value.date,
      deviceToken: props.deviceToken,
      staffId: props.staffId,
    });

    // 2. If extras enabled, record baki transaction
    if (form.value.addExtras && form.value.extrasNote.trim() && form.value.extrasAmount > 0) {
      await customersStore.recordBaki({
        customerId: props.customer.id,
        sessionId: props.sessionId,
        itemsDescription: form.value.extrasNote.trim(),
        amount: form.value.extrasAmount,
        deviceToken: props.deviceToken,
        staffId: props.staffId,
      });
    }

    feedback.showSuccess(t('customers.attendance.dialog.success'));
    emit('saved');
    isOpen.value = false;
  } catch (err) {
    void feedback.showApiError(err, t('customers.attendance.errors.toggleFailed'));
  } finally {
    saving.value = false;
  }
}
</script>

<style scoped>
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.08);
}
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}
.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.08);
}
</style>
