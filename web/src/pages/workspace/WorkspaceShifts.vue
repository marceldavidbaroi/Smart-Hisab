<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
          {{ $t('workspace.shifts.title') }}
        </h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('workspace.shifts.subtitle') }}
        </p>
      </div>
      <q-btn
        color="primary"
        icon="add"
        :label="$t('workspace.shifts.createBtn')"
        unelevated
        dense
        class="q-px-sm rounded-btn"
        style="min-height: 40px"
        @click="openCreateDialog"
      />
    </div>

    <!-- Shifts list -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="36px" />
    </div>

    <div
      v-else-if="shifts.length === 0"
      class="column items-center justify-center q-py-xl text-grey-6"
    >
      <q-icon name="schedule" size="48px" class="q-mb-sm text-grey-4" />
      <div>{{ $t('workspace.shifts.noShifts') }}</div>
    </div>

    <div v-else class="row q-col-gutter-md">
      <div v-for="shift in shifts" :key="shift.id" class="col-12 col-sm-6 col-md-4">
        <q-card
          flat
          bordered
          class="q-pa-md bg-white border-all relative-position hover-card transition-all"
        >
          <div class="row items-center justify-between q-mb-sm">
            <div class="text-subtitle1 text-weight-bold text-slate-800">{{ shift.name }}</div>
            <q-badge
              :color="shift.is_active ? 'positive' : 'grey-7'"
              class="text-weight-bold uppercase q-py-xs q-px-sm"
            >
              {{
                shift.is_active ? $t('workspace.shifts.active') : $t('workspace.shifts.inactive')
              }}
            </q-badge>
          </div>

          <div class="row items-center q-gutter-x-sm text-subtitle2 text-slate-700 q-mb-md">
            <q-icon name="alarm" size="18px" color="primary" />
            <span class="font-mono">{{ formatTime12h(shift.start_time) }}</span>
            <span class="text-grey-5">{{ $t('workspace.shifts.to') }}</span>
            <span class="font-mono">{{ formatTime12h(shift.end_time) }}</span>
          </div>

          <div class="row justify-end q-gutter-x-sm">
            <q-btn
              flat
              dense
              color="primary"
              icon="edit"
              :label="$t('common.edit')"
              class="text-weight-bold q-px-xs"
              @click="openEditDialog(shift)"
            />
          </div>
        </q-card>
      </div>
    </div>

    <!-- Shift Config Form Dialog -->
    <ShiftConfigForm
      v-model="showForm"
      :is-edit="isEdit"
      :initial-data="editingShift"
      :saving="saving"
      @submit="handleFormSubmit"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from '../../boot/supabase';
import { useTenantStore } from '../../stores/tenant';
import { showSuccess, showApiError } from '../../composables/useFeedback';
import ShiftConfigForm from '../../components/sessions/ShiftConfigForm.vue';
import { useI18n } from 'vue-i18n';

const tenantStore = useTenantStore();
const { t } = useI18n();

interface Shift {
  id?: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
}

const shifts = ref<Shift[]>([]);
const loading = ref(false);
const showForm = ref(false);
const isEdit = ref(false);
const editingShift = ref<Shift | null>(null);
const saving = ref(false);

async function loadShifts() {
  const tenantId = tenantStore.activeTenant?.id;
  if (!tenantId) return;
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('shifts')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('name');
    if (error) throw error;
    shifts.value = (data || []) as Shift[];
  } catch (err: unknown) {
    await showApiError(err, t('workspace.shifts.failedLoad'));
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  void loadShifts();
});

function openCreateDialog() {
  isEdit.value = false;
  editingShift.value = null;
  showForm.value = true;
}

function openEditDialog(shift: Shift) {
  isEdit.value = true;
  editingShift.value = shift;
  showForm.value = true;
}

async function handleFormSubmit(formData: Shift) {
  const tenantId = tenantStore.activeTenant?.id;
  if (!tenantId) return;
  saving.value = true;
  try {
    if (isEdit.value && formData.id) {
      // Update
      const { error } = await supabase
        .from('shifts')
        .update({
          name: formData.name,
          start_time: formData.start_time,
          end_time: formData.end_time,
          is_active: formData.is_active,
        })
        .eq('id', formData.id);
      if (error) throw error;
      showSuccess(t('workspace.shifts.updatedSuccess'));
    } else {
      // Create
      const { error } = await supabase.from('shifts').insert({
        tenant_id: tenantId,
        name: formData.name,
        start_time: formData.start_time,
        end_time: formData.end_time,
        is_active: formData.is_active,
      });
      if (error) throw error;
      showSuccess(t('workspace.shifts.createdSuccess'));
    }
    showForm.value = false;
    await loadShifts();
  } catch (err: unknown) {
    await showApiError(err, t('workspace.shifts.failedSave'));
  } finally {
    saving.value = false;
  }
}

function formatTime12h(timeStr: string) {
  if (!timeStr) return '';
  const parts = timeStr.split(':');
  if (parts.length < 2) return timeStr;
  let hours = parseInt(parts[0] || '0', 10);
  const minutes = parts[1] || '00';
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  hours = hours ? hours : 12;
  return `${hours}:${minutes} ${ampm}`;
}
</script>

<style scoped>
.rounded-btn {
  border-radius: 8px;
}
.hover-card:hover {
  border-color: var(--q-primary);
  background: rgba(99, 102, 241, 0.02);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03);
}
.transition-all {
  transition: all 0.2s ease;
}
.border-all {
  border: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
