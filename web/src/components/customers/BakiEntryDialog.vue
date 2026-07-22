<template>
  <q-dialog v-model="isOpen" persistent @hide="onDialogHide">
    <q-card flat bordered class="q-dialog-plugin" style="width: 500px; max-width: 95vw">
      <!-- Header -->
      <q-card-section class="row items-center border-bottom q-py-sm">
        <div>
          <div class="text-subtitle1 text-weight-bold">
            {{ $t('customers.baki.dialog.title') }}
          </div>
          <div class="text-caption text-grey-7">
            {{ customer.full_name }} {{ customer.phone ? `(${customer.phone})` : '' }}
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
          :disable="saving"
        />
      </q-card-section>

      <!-- Form Section -->
      <q-card-section class="q-py-md q-px-md max-height-dialog-scroll">
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

          <!-- Shift Selection -->
          <div>
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">
              {{ $t('customers.baki.dialog.shift') }} *
            </label>
            <q-btn-toggle
              v-model="form.shift"
              spread
              no-caps
              toggle-color="primary"
              toggle-text-color="white"
              text-color="grey-7"
              bg-color="grey-2"
              unelevated
              :options="shiftOptions"
              :disable="saving"
              style="min-height: 40px"
            />
          </div>

          <q-separator />

          <!-- Dynamic Line Items -->
          <div>
            <div class="row justify-between items-center q-mb-sm">
              <label class="text-caption text-grey-7 text-weight-medium">
                {{ $t('customers.baki.itemsDescription') }} & {{ $t('customers.baki.amount') }} *
              </label>
              <q-btn
                flat
                dense
                no-caps
                color="primary"
                icon="add"
                :label="$t('customers.baki.dialog.addRow')"
                class="cursor-pointer font-medium"
                :disable="saving"
                @click="addRow"
              />
            </div>

            <div class="q-gutter-y-sm">
              <div
                v-for="(line, index) in form.lines"
                :key="index"
                class="row q-col-gutter-sm items-start"
              >
                <!-- Note Input -->
                <div class="col">
                  <q-input
                    v-model="line.note"
                    dense
                    outlined
                    bg-color="white"
                    :placeholder="$t('customers.baki.dialog.note')"
                    :rules="[(val) => !!val || $t('customers.baki.dialog.noteRequired')]"
                    :disable="saving"
                    hide-bottom-space
                  />
                </div>

                <!-- Amount Input -->
                <div class="col-4">
                  <q-input
                    v-model.number="line.amount"
                    dense
                    outlined
                    bg-color="white"
                    type="number"
                    prefix="৳"
                    :placeholder="$t('customers.baki.dialog.amount')"
                    :rules="[
                      (val) =>
                        (val !== null && val !== undefined) ||
                        $t('customers.baki.dialog.amountRequired'),
                      (val) => val > 0 || $t('customers.baki.dialog.amountMin'),
                    ]"
                    :disable="saving"
                    hide-bottom-space
                  />
                </div>

                <!-- Remove Row Button -->
                <div class="col-auto self-center">
                  <q-btn
                    flat
                    round
                    dense
                    color="negative"
                    icon="delete"
                    class="cursor-pointer"
                    :disable="saving || form.lines.length <= 1"
                    style="min-width: 40px; min-height: 40px"
                    @click="removeRow(index)"
                  />
                </div>
              </div>
            </div>
          </div>

          <q-separator />

          <!-- Total Calculation -->
          <div
            class="row justify-between items-center bg-grey-1 q-pa-sm rounded-borders border-all"
          >
            <span class="text-subtitle2 text-weight-bold text-grey-8">
              {{ $t('customers.baki.dialog.total') }}:
            </span>
            <span class="text-h6 text-weight-bold text-primary font-mono">
              ৳{{ formatMoneyDisplay(totalAmount) }}
            </span>
          </div>

          <!-- Action Footer -->
          <div class="row justify-end q-gutter-x-sm q-mt-lg">
            <q-btn
              flat
              dense
              no-caps
              :label="$t('customers.baki.dialog.cancelBtn')"
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
              :label="$t('customers.baki.dialog.saveBtn')"
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
import type { Customer } from '../../stores/customers';
import { formatMoney } from '../../utils/format';

import { useCustomersStore } from '../../stores/customers';
import { useFeedback } from '../../composables/useFeedback';

interface BakiLine {
  note: string;
  amount: number | null;
}

const props = defineProps<{
  modelValue: boolean;
  customer: Customer;
  sessionId: string;
  businessDate: string;
  sessionShiftName?: string | null;
  deviceToken?: string | null;
  staffId?: string | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'saved', newBalance: number): void;
}>();

const { t, locale } = useI18n();
const customersStore = useCustomersStore();
const feedback = useFeedback();

const saving = ref(false);

const form = ref({
  date: '',
  shift: '',
  lines: [] as BakiLine[],
});

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});

const shiftOptions = computed(() => [
  { label: t('customers.baki.dialog.shifts.breakfast'), value: 'breakfast' },
  { label: t('customers.baki.dialog.shifts.lunch'), value: 'lunch' },
  { label: t('customers.baki.dialog.shifts.afternoon_snacks'), value: 'afternoon_snacks' },
  { label: t('customers.baki.dialog.shifts.dinner'), value: 'dinner' },
]);

const totalAmount = computed(() => {
  return form.value.lines.reduce((sum, line) => sum + (line.amount || 0), 0);
});

const isSaveDisabled = computed(() => {
  if (!form.value.shift || !form.value.date) return true;
  if (form.value.lines.length === 0) return true;
  return form.value.lines.some(
    (line) => !line.note.trim() || line.amount === null || line.amount <= 0,
  );
});

function addRow() {
  form.value.lines.push({ note: '', amount: null });
}

function removeRow(index: number) {
  if (form.value.lines.length > 1) {
    form.value.lines.splice(index, 1);
  }
}

function formatMoneyDisplay(val: number): string {
  return formatMoney(val, locale.value === 'bn' ? 'bn' : 'en');
}

function resetForm() {
  const d = new Date();
  const todayStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  form.value.date = todayStr;
  // Try to default to sessionShiftName if valid shift options value contains it
  const validShifts = ['breakfast', 'lunch', 'afternoon_snacks', 'dinner'];
  const proposedShift = props.sessionShiftName?.toLowerCase() || '';
  form.value.shift = validShifts.includes(proposedShift) ? proposedShift : 'lunch';
  form.value.lines = [{ note: '', amount: null }];
  saving.value = false;
}

watch(
  isOpen,
  (newVal) => {
    if (newVal) {
      resetForm();
    }
  },
  { immediate: true },
);

function onDialogHide() {
  resetForm();
}

async function onSubmit() {
  if (isSaveDisabled.value) return;

  saving.value = true;
  try {
    const shiftLabel = t(`customers.baki.dialog.shifts.${form.value.shift}`);
    const joinedNotes = form.value.lines.map((line) => `${line.note} (৳${line.amount})`).join('; ');
    const itemsDescription = `${shiftLabel} — ${joinedNotes}`;

    const newBalance = await customersStore.recordBaki({
      customerId: props.customer.id,
      sessionId: props.sessionId,
      itemsDescription,
      amount: totalAmount.value,
      deviceToken: props.deviceToken,
      staffId: props.staffId,
      businessDate: form.value.date,
    });

    feedback.showSuccess(t('customers.baki.dialog.success'));
    emit('saved', newBalance);
    isOpen.value = false;
  } catch (err) {
    void feedback.showApiError(err);
  } finally {
    saving.value = false;
  }
}

defineExpose({
  form,
  resetForm,
  saving,
  onSubmit,
});
</script>

<style scoped>
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
.max-height-dialog-scroll {
  max-height: 70vh;
  overflow-y: auto;
}
.font-medium {
  font-weight: 500;
}
</style>
