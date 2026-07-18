<template>
  <q-card flat bordered class="bg-white">
    <q-card-section class="q-py-md row justify-between items-center border-bottom">
      <div>
        <div class="text-subtitle1 text-weight-bold">{{ $t('customers.attendance.title') }}</div>
        <div class="text-caption text-grey-7">{{ $t('customers.attendance.subtitle') }}</div>
      </div>
    </q-card-section>

    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="32px" />
    </div>

    <div v-else-if="customers.length === 0" class="text-center text-grey-6 q-py-xl">
      {{ $t('customers.attendance.empty') }}
    </div>

    <q-list v-else separator class="q-px-none">
      <q-item v-for="worker in customers" :key="worker.id" class="q-py-md">
        <q-item-section>
          <q-item-label class="text-weight-bold text-dark">{{ worker.full_name }}</q-item-label>
          <q-item-label caption class="text-grey-6">
            {{ worker.factory_unit || '—' }} | {{ $t('customers.attendance.rateCharged') }}: ৳{{
              worker.contract_daily_rate
            }}
          </q-item-label>
        </q-item-section>

        <q-item-section side class="row no-wrap q-gutter-x-sm justify-end items-center">
          <q-btn
            v-for="shift in shiftNames"
            :key="shift"
            :label="shift"
            dense
            no-caps
            :color="isAttended(worker.id, shift) ? 'primary' : 'grey-2'"
            :text-color="isAttended(worker.id, shift) ? 'white' : 'dark'"
            :flat="!isAttended(worker.id, shift)"
            :unelevated="isAttended(worker.id, shift)"
            :disable="disabled || !isShiftAllowed(worker, shift)"
            class="attendance-toggle-btn cursor-pointer font-semibold"
            :aria-pressed="isAttended(worker.id, shift)"
            :aria-label="`Toggle ${shift} shift for ${worker.full_name}`"
            @click="onToggle(worker.id, shift)"
          >
            <q-icon v-if="isAttended(worker.id, shift)" name="check" size="14px" class="q-mr-xs" />
          </q-btn>
        </q-item-section>
      </q-item>
    </q-list>
  </q-card>
</template>

<script setup lang="ts">
import type { Customer, DailyAttendance } from '../../stores/customers';

const props = defineProps<{
  customers: Customer[];
  attendanceToday: DailyAttendance[];
  shiftNames: string[];
  loading?: boolean;
  disabled?: boolean;
}>();

const emit = defineEmits<{
  (e: 'toggle', params: { customerId: string; shiftName: string }): void;
}>();

function isAttended(customerId: string, shift: string): boolean {
  const record = props.attendanceToday.find((a) => a.customer_id === customerId);
  return record ? record.attended_shifts.includes(shift) : false;
}

function isShiftAllowed(worker: Customer, shift: string): boolean {
  if (!worker.contract_shifts) return true;
  return worker.contract_shifts.includes(shift);
}

function onToggle(customerId: string, shiftName: string) {
  emit('toggle', { customerId, shiftName });
}
</script>

<style scoped>
.attendance-toggle-btn {
  height: 48px;
  min-width: 80px;
  padding: 0 16px;
  border-radius: 8px;
}
</style>
