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
                mask="time"
                :rules="[(val) => !!val || $t('sessions.shiftForm.startTimeRequired')]"
                hide-bottom-space
              >
                <template v-slot:append>
                  <q-icon name="access_time" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-time v-model="form.start_time">
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
                mask="time"
                :rules="[(val) => !!val || $t('sessions.shiftForm.endTimeRequired')]"
                hide-bottom-space
              >
                <template v-slot:append>
                  <q-icon name="access_time" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-time v-model="form.end_time">
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

const form = ref<Shift>({
  name: '',
  start_time: '08:00',
  end_time: '16:00',
  is_active: true,
});

watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen) {
      if (props.initialData) {
        form.value = { ...props.initialData };
      } else {
        form.value = {
          name: '',
          start_time: '08:00',
          end_time: '16:00',
          is_active: true,
        };
      }
    }
  },
);

function handleSubmit() {
  emit('submit', form.value);
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
