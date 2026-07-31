<template>
  <q-page class="q-pa-md bg-grey-1 text-dark">
    <!-- Header section -->
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h5 text-weight-bold text-slate-800 q-ma-none">
          {{ $t('workspace.mealConfigs.title') }}
        </h1>
        <p class="text-caption text-grey-6 q-ma-none q-mt-xs">
          {{ $t('workspace.mealConfigs.subtitle') }}
        </p>
      </div>
      <q-btn
        color="primary"
        icon="add"
        :label="$t('workspace.mealConfigs.createBtn')"
        unelevated
        dense
        class="q-px-sm rounded-btn cursor-pointer"
        style="min-height: 40px"
        @click="openCreateDialog"
      />
    </div>

    <!-- Meal Configs List / Grid -->
    <div v-if="loading" class="row justify-center q-py-xl">
      <q-spinner color="primary" size="36px" />
    </div>

    <div
      v-else-if="mealConfigs.length === 0"
      class="column items-center justify-center q-py-xl text-grey-6"
    >
      <q-icon name="restaurant_menu" size="48px" class="q-mb-sm text-grey-4" />
      <div class="text-subtitle2">{{ $t('workspace.mealConfigs.noConfigs') }}</div>
    </div>

    <div v-else class="row q-col-gutter-md">
      <div
        v-for="config in mealConfigs"
        :key="config.id"
        class="col-12 col-sm-6 col-md-4"
      >
        <q-card
          flat
          bordered
          class="q-pa-md bg-white border-all relative-position hover-card transition-all"
        >
          <div class="row items-start justify-between q-mb-xs">
            <div>
              <div class="text-caption text-grey-6 text-weight-bold uppercase" style="font-size: 11px">
                {{ $t('workspace.mealConfigs.rate') }}
              </div>
              <div class="text-h6 text-weight-bold text-primary">
                ৳{{ Number(config.rate).toFixed(2) }}
              </div>
            </div>
            <q-badge color="grey-3" text-color="grey-8" class="text-caption q-pa-xs">
              <q-icon name="event" size="14px" class="q-mr-xs" />
              {{ config.effective_from }}
            </q-badge>
          </div>

          <q-separator class="q-my-sm" inset />

          <div class="q-mb-md">
            <div class="text-caption text-grey-6 text-weight-medium q-mb-xs">
              {{ $t('workspace.mealConfigs.note') }}
            </div>
            <div class="text-body2 text-slate-800 break-words font-medium">
              {{ config.note || '-' }}
            </div>
          </div>

          <div class="row justify-end q-gutter-x-xs">
            <q-btn
              flat
              dense
              color="primary"
              icon="edit"
              :label="$t('common.edit')"
              class="text-weight-bold q-px-xs cursor-pointer"
              @click="openEditDialog(config)"
            />
            <q-btn
              flat
              dense
              color="negative"
              icon="delete"
              :label="$t('common.delete')"
              class="text-weight-bold q-px-xs cursor-pointer"
              @click="confirmDelete(config)"
            />
          </div>
        </q-card>
      </div>
    </div>

    <!-- Create / Edit Dialog -->
    <q-dialog v-model="showDialog" persistent>
      <q-card style="width: 450px; max-width: 90vw; border-radius: 12px" class="q-pa-sm">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-subtitle1 text-weight-bold text-slate-800">
            {{ isEdit ? $t('workspace.mealConfigs.editTitle') : $t('workspace.mealConfigs.createTitle') }}
          </div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup class="cursor-pointer text-grey-6" />
        </q-card-section>

        <q-form @submit.prevent="saveMealConfig">
          <q-card-section class="q-gutter-y-md">
            <div>
              <label class="text-caption text-weight-bold text-grey-7 block q-mb-xs">
                {{ $t('workspace.mealConfigs.rate') }} *
              </label>
              <q-input
                v-model.number="form.rate"
                type="number"
                step="0.01"
                min="0"
                dense
                outlined
                placeholder="0.00"
                prefix="৳"
                :rules="[(val) => val !== null && val !== '' && val >= 0 || 'Valid rate is required']"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="text-caption text-weight-bold text-grey-7 block q-mb-xs">
                {{ $t('workspace.mealConfigs.effectiveFrom') }} *
              </label>
              <q-input
                v-model="form.effective_from"
                type="date"
                dense
                outlined
                :rules="[(val) => !!val || 'Date is required']"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="text-caption text-weight-bold text-grey-7 block q-mb-xs">
                {{ $t('workspace.mealConfigs.note') }}
              </label>
              <q-input
                v-model="form.note"
                type="textarea"
                rows="3"
                dense
                outlined
                placeholder="e.g. Standard Lunch & Dinner Meal Rate"
                hide-bottom-space
              />
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pb-md">
            <q-btn
              flat
              dense
              :label="$t('common.cancel')"
              v-close-popup
              class="cursor-pointer text-grey-7 q-px-sm"
            />
            <q-btn
              type="submit"
              color="primary"
              dense
              unelevated
              :label="$t('common.save')"
              :loading="saving"
              class="cursor-pointer text-weight-bold q-px-md"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useQuasar } from 'quasar';
import { supabase } from '../../boot/supabase';
import { useTenantStore } from '../../stores/tenant';
import { showSuccess, showApiError, showInfo } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

interface MealConfig {
  id: string;
  tenant_id: string;
  rate: number;
  effective_from: string;
  note: string | null;
  created_at?: string;
}

const $q = useQuasar();
const tenantStore = useTenantStore();
const { t } = useI18n();

const mealConfigs = ref<MealConfig[]>([]);
const loading = ref(true);
const saving = ref(false);
const showDialog = ref(false);
const isEdit = ref(false);
const editingId = ref<string | null>(null);

const form = ref<{
  rate: number | null;
  effective_from: string;
  note: string;
}>({
  rate: null,
  effective_from: new Date().toISOString().substring(0, 10),
  note: '',
});

const fetchMealConfigs = async () => {
  if (!tenantStore.activeTenant?.id) return;
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('meal_configs')
      .select('*')
      .eq('tenant_id', tenantStore.activeTenant.id)
      .order('effective_from', { ascending: false });

    if (error) throw error;
    mealConfigs.value = (data || []) as MealConfig[];
  } catch (err) {
    showApiError(err, t('workspace.mealConfigs.failedLoad'));
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  void fetchMealConfigs();
});

const openCreateDialog = () => {
  isEdit.value = false;
  editingId.value = null;
  form.value = {
    rate: null,
    effective_from: new Date().toISOString().substring(0, 10),
    note: '',
  };
  showDialog.value = true;
};

const openEditDialog = (config: MealConfig) => {
  isEdit.value = true;
  editingId.value = config.id;
  form.value = {
    rate: config.rate,
    effective_from: config.effective_from,
    note: config.note || '',
  };
  showDialog.value = true;
};

const saveMealConfig = async () => {
  if (!tenantStore.activeTenant?.id || form.value.rate === null) return;
  saving.value = true;
  try {
    const payload = {
      tenant_id: tenantStore.activeTenant.id,
      rate: form.value.rate,
      effective_from: form.value.effective_from,
      note: form.value.note || null,
    };

    if (isEdit.value && editingId.value) {
      const { data, error } = await supabase
        .from('meal_configs')
        .update(payload)
        .eq('id', editingId.value)
        .select()
        .single();

      if (error) throw error;

      // Targeted Cache Mutation
      const idx = mealConfigs.value.findIndex((item) => item.id === editingId.value);
      if (idx !== -1 && data) {
        mealConfigs.value[idx] = data as MealConfig;
      }
      showSuccess(t('workspace.mealConfigs.updatedSuccess'));
    } else {
      const { data, error } = await supabase
        .from('meal_configs')
        .insert(payload)
        .select()
        .single();

      if (error) throw error;
      if (data) {
        mealConfigs.value.unshift(data as MealConfig);
      }
      showSuccess(t('workspace.mealConfigs.createdSuccess'));
    }

    showDialog.value = false;
  } catch (err) {
    showApiError(err, t('workspace.mealConfigs.failedSave'));
  } finally {
    saving.value = false;
  }
};

const confirmDelete = (config: MealConfig) => {
  $q.dialog({
    title: t('workspace.mealConfigs.deleteConfirmTitle'),
    message: t('workspace.mealConfigs.deleteConfirmMsg'),
    cancel: true,
    persistent: true,
  }).onOk(() => {
    void deleteMealConfig(config.id);
  });
};

const deleteMealConfig = async (id: string) => {
  try {
    const { error } = await supabase.from('meal_configs').delete().eq('id', id);
    if (error) throw error;

    // Targeted local mutation
    mealConfigs.value = mealConfigs.value.filter((item) => item.id !== id);
    showSuccess(t('workspace.mealConfigs.deletedSuccess'));
  } catch (err) {
    showApiError(err, t('workspace.mealConfigs.failedSave'));
  }
};
</script>

<style scoped>
.hover-card {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}
.hover-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.rounded-btn {
  border-radius: 8px;
}
</style>
