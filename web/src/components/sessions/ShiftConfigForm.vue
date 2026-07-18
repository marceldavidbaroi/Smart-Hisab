<template>
  <q-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    persistent
  >
    <q-card
      class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md"
      style="width: 450px; max-width: 90vw"
    >
      <q-card-section class="row items-center q-pb-none">
        <div class="text-h6 text-weight-bold">
          {{ isEdit ? $t('sessions.shiftForm.editTitle') : $t('sessions.shiftForm.createTitle') }}
        </div>
        <q-space />
        <q-btn icon="close" flat round dense v-close-popup color="grey-7" :disable="saving" />
      </q-card-section>

      <q-form @submit.prevent="handleSubmit" class="q-gutter-y-md q-mt-sm">
        <q-card-section class="q-py-none">
          <div class="q-mb-md">
            <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
              $t('sessions.shiftForm.shiftName')
            }}</label>
            <q-input
              v-model="form.name"
              type="text"
              filled
              dense
              :placeholder="$t('sessions.shiftForm.namePlaceholder')"
              color="primary"
              class="custom-input"
              :rules="[(val) => !!val || $t('sessions.shiftForm.nameRequired')]"
              hide-bottom-space
            />
          </div>

          <div class="q-mb-md row q-col-gutter-sm">
            <div class="col-6">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('sessions.shiftForm.startTime')
              }}</label>
              <q-input
                v-model="form.start_time"
                filled
                dense
                color="primary"
                class="custom-input"
                mask="##:## AA"
                placeholder="05:00 AM"
                :rules="[(val) => !!val || $t('sessions.shiftForm.startTimeRequired'), time12hRule]"
                hide-bottom-space
              >
                <template v-slot:append>
                  <q-icon name="access_time" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-time
                        :model-value="to24h(form.start_time)"
                        @update:model-value="(v) => (form.start_time = to12h(v))"
                      >
                        <div class="row items-center justify-end">
                          <q-btn
                            v-close-popup
                            :label="$t('sessions.shiftForm.closeBtn')"
                            color="primary"
                            flat
                          />
                        </div>
                      </q-time>
                    </q-popup-proxy>
                  </q-icon>
                </template>
              </q-input>
            </div>
            <div class="col-6">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('sessions.shiftForm.endTime')
              }}</label>
              <q-input
                v-model="form.end_time"
                filled
                dense
                color="primary"
                class="custom-input"
                mask="##:## AA"
                placeholder="05:00 PM"
                :rules="[(val) => !!val || $t('sessions.shiftForm.endTimeRequired'), time12hRule]"
                hide-bottom-space
              >
                <template v-slot:append>
                  <q-icon name="access_time" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-time
                        :model-value="to24h(form.end_time)"
                        @update:model-value="(v) => (form.end_time = to12h(v))"
                      >
                        <div class="row items-center justify-end">
                          <q-btn
                            v-close-popup
                            :label="$t('sessions.shiftForm.closeBtn')"
                            color="primary"
                            flat
                          />
                        </div>
                      </q-time>
                    </q-popup-proxy>
                  </q-icon>
                </template>
              </q-input>
            </div>
          </div>

          <div class="row items-center justify-between q-mt-md">
            <div class="col-8">
              <div class="text-subtitle2 text-weight-medium text-slate-800">
                {{ $t('sessions.shiftForm.activeStatus') }}
              </div>
              <div class="text-caption text-grey-6">
                {{ $t('sessions.shiftForm.activeStatusDesc') }}
              </div>
            </div>
            <q-toggle v-model="form.is_active" color="primary" />
          </div>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn
            flat
            :label="$t('sessions.shiftForm.cancelBtn')"
            v-close-popup
            color="grey-7"
            :disable="saving"
          />
          <q-btn
            type="submit"
            :label="isEdit ? $t('sessions.shiftForm.saveBtn') : $t('sessions.shiftForm.createBtn')"
            color="primary"
            class="q-px-md text-weight-bold"
            unelevated
            dense
            :loading="saving"
            style="min-height: 40px"
          />
        </q-card-actions>
      </q-form>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';

interface Shift {
  id?: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
}

const props = defineProps<{
  modelValue: boolean;
  isEdit: boolean;
  initialData?: Shift | null;
  saving: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'submit', data: Shift): void;
}>();

const TIME12H_RE = /^(0[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$/i;

const form = ref<Shift>({
  name: '',
  start_time: '08:00 AM',
  end_time: '04:00 PM',
  is_active: true,
});

function to12h(time24: string | null | undefined): string {
  if (!time24) return '';
  const [hRaw = '0', mRaw = '00'] = time24.split(':');
  let hours = parseInt(hRaw, 10);
  if (Number.isNaN(hours)) return '';
  const minutes = (mRaw || '00').slice(0, 2).padStart(2, '0');
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  hours = hours ? hours : 12;
  return `${String(hours).padStart(2, '0')}:${minutes} ${ampm}`;
}

function to24h(time12: string | null | undefined): string {
  if (!time12) return '';
  const match = time12.trim().match(TIME12H_RE);
  if (!match) {
    // Already 24h from picker / DB (HH:mm[:ss])
    const [h = '', m = '00'] = time12.split(':');
    if (/^\d{1,2}$/.test(h) && /^\d{2}/.test(m)) {
      return `${h.padStart(2, '0')}:${m.slice(0, 2)}`;
    }
    return '';
  }
  let hours = parseInt(match[1]!, 10);
  const minutes = match[2]!;
  const ampm = match[3]!.toUpperCase();
  if (ampm === 'AM') {
    hours = hours === 12 ? 0 : hours;
  } else {
    hours = hours === 12 ? 12 : hours + 12;
  }
  return `${String(hours).padStart(2, '0')}:${minutes}`;
}

function time12hRule(val: string) {
  if (!val?.trim()) return true;
  return TIME12H_RE.test(val.trim()) || 'Use format 05:00 AM';
}

watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      if (props.initialData) {
        form.value = {
          ...props.initialData,
          start_time: to12h(props.initialData.start_time),
          end_time: to12h(props.initialData.end_time),
        };
      } else {
        form.value = {
          name: '',
          start_time: '08:00 AM',
          end_time: '04:00 PM',
          is_active: true,
        };
      }
    }
  },
);

function handleSubmit() {
  emit('submit', {
    ...form.value,
    start_time: to24h(form.value.start_time),
    end_time: to24h(form.value.end_time),
  });
}
</script>

<style scoped>
.dialog-card {
  border-radius: 12px;
}
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
