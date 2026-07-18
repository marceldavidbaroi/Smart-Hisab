<template>
  <q-page class="q-pa-md q-pa-sm-lg">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-lg q-mb-sm-xl">
      <div>
        <h1 class="text-h5 text-sm-h4 text-weight-bold q-my-none text-amber-10">
          {{ $t('admin.billing.title') }}
        </h1>
        <p class="text-grey-7 text-subtitle2 q-mt-xs q-mb-none">
          {{ $t('admin.billing.subtitle') }}
        </p>
      </div>
    </div>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-negative text-white rounded-borders q-mb-lg text-subtitle2">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <!-- Success Banner -->
    <q-banner
      v-if="successMsg"
      class="bg-positive text-white rounded-borders q-mb-lg text-subtitle2"
    >
      <template #avatar>
        <q-icon name="check_circle" color="white" />
      </template>
      {{ successMsg }}
    </q-banner>

    <div class="row q-col-gutter-sm q-col-gutter-sm-md">
      <!-- Tenant Selector & Billing Editor -->
      <div class="col-12 col-md-6">
        <q-card flat bordered class="bg-white">
          <q-card-section class="q-py-sm q-px-md border-bottom">
            <div class="text-subtitle1 text-weight-bold text-grey-9">
              {{ $t('admin.billing.controlCard') }}
            </div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <q-form @submit.prevent="updateBillingPolicy" class="q-gutter-y-md">
              <div>
                <label
                  class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                  >{{ $t('admin.billing.selectTenant') }}</label
                >
                <q-select
                  v-model="selectedTenantId"
                  :options="tenantOptions"
                  outlined
                  dense
                  color="amber-10"
                  emit-value
                  map-options
                  @update:model-value="onTenantSelected"
                />
              </div>

              <div v-if="selectedTenantId" class="q-gutter-y-md">
                <div>
                  <label
                    class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                    >{{ $t('admin.billing.planTier') }}</label
                  >
                  <q-select
                    v-model="billingTier"
                    :options="['free', 'pro', 'enterprise']"
                    outlined
                    dense
                    color="amber-10"
                  />
                </div>

                <div>
                  <label
                    class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                    >{{ $t('admin.billing.paymentStatus') }}</label
                  >
                  <q-select
                    v-model="billingStatus"
                    :options="['active', 'past_due', 'canceled']"
                    outlined
                    dense
                    color="amber-10"
                  />
                </div>

                <q-btn
                  type="submit"
                  unelevated
                  color="amber"
                  text-color="black"
                  :label="$t('admin.billing.updateBtn')"
                  class="text-weight-bold cursor-pointer action-btn q-mt-sm"
                  :loading="submittingBilling"
                />
              </div>
            </q-form>
          </q-card-section>
        </q-card>
      </div>

      <!-- Feature Toggles Editor -->
      <div class="col-12 col-md-6">
        <q-card flat bordered class="bg-white">
          <q-card-section class="q-py-sm q-px-md border-bottom">
            <div class="text-subtitle1 text-weight-bold text-grey-9">
              {{ $t('admin.billing.featuresCard') }}
            </div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <div v-if="selectedTenantId" class="q-gutter-y-md">
              <p class="text-caption text-grey-6 q-mb-xs">
                {{ $t('admin.billing.featuresDesc') }}
              </p>

              <div class="q-gutter-y-xs">
                <q-checkbox
                  v-model="featureShiftSessions"
                  label="Operational Shifts & Sessions"
                  color="amber-10"
                  dense
                  class="block q-py-xs"
                />
                <q-checkbox
                  v-model="featureFinancialLedger"
                  label="Transaction Ledger"
                  color="amber-10"
                  dense
                  class="block q-py-xs"
                />
                <q-checkbox
                  v-model="featureMealManagement"
                  label="Meal & Customer Management"
                  color="amber-10"
                  dense
                  class="block q-py-xs"
                />
                <q-checkbox
                  v-model="featureProcurement"
                  label="Procurement & Supplier Management"
                  color="amber-10"
                  dense
                  class="block q-py-xs"
                />
                <q-checkbox
                  v-model="featureStaffPayroll"
                  label="Staff Attendance & Payroll"
                  color="amber-10"
                  dense
                  class="block q-py-xs"
                />
              </div>

              <q-btn
                unelevated
                color="amber"
                text-color="black"
                :label="$t('admin.billing.saveBtn')"
                class="text-weight-bold cursor-pointer action-btn q-mt-sm"
                @click="updateFeaturesPolicy"
                :loading="submittingFeatures"
              />
            </div>
            <div v-else class="text-center q-py-xl text-grey-6 text-weight-medium">
              {{ $t('admin.billing.noTenantSelected') }}
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from '../../boot/supabase';
import { adminUpdateBilling, adminToggleTenantFeatures } from '../../services/multiTenant';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

interface SimpleTenant {
  id: string;
  name: string;
  slug: string;
}

const tenants = ref<SimpleTenant[]>([]);
const selectedTenantId = ref<string | null>(null);

const billingTier = ref('free');
const billingStatus = ref('active');
const submittingBilling = ref(false);

const featureShiftSessions = ref(true);
const featureFinancialLedger = ref(true);
const featureMealManagement = ref(true);
const featureProcurement = ref(true);
const featureStaffPayroll = ref(true);
const submittingFeatures = ref(false);

const errorMsg = ref('');
const successMsg = ref('');
const tenantOptions = ref<{ label: string; value: string }[]>([]);

const loadTenants = async () => {
  try {
    const { data, error } = await supabase.from('tenants').select('id, name, slug');
    if (error) throw error;
    tenants.value = data || [];
    tenantOptions.value = tenants.value.map((t) => ({
      label: `${t.name} (${t.slug})`,
      value: t.id,
    }));
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to load workspaces.';
  }
};

const onTenantSelected = async (tenantId: string) => {
  if (!tenantId) return;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    // 1. Fetch current billing tier
    const { data: billing, error: billingErr } = await supabase
      .from('tenant_billing')
      .select('*')
      .eq('tenant_id', tenantId)
      .single();

    if (!billingErr && billing) {
      billingTier.value = billing.subscription_tier;
      billingStatus.value = billing.status;
    } else {
      billingTier.value = 'free';
      billingStatus.value = 'active';
    }

    // 2. Fetch current settings features
    const { data: settings, error: settingsErr } = await supabase
      .from('tenant_settings')
      .select('enabled_features')
      .eq('tenant_id', tenantId)
      .single();

    if (!settingsErr && settings) {
      const f = settings.enabled_features as Record<string, boolean>;
      featureShiftSessions.value = f?.['shift-sessions'] !== false;
      featureFinancialLedger.value = f?.['financial-ledger'] !== false;
      featureMealManagement.value = f?.['meal-management'] !== false;
      featureProcurement.value = f?.['procurement'] !== false;
      featureStaffPayroll.value = f?.['staff-payroll'] !== false;
    } else {
      featureShiftSessions.value = true;
      featureFinancialLedger.value = true;
      featureMealManagement.value = true;
      featureProcurement.value = true;
      featureStaffPayroll.value = true;
    }
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('admin.billing.messages.loadFailed');
  }
};

const updateBillingPolicy = async () => {
  if (!selectedTenantId.value) return;
  submittingBilling.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    await adminUpdateBilling(selectedTenantId.value, billingTier.value, billingStatus.value);
    successMsg.value = t('admin.billing.messages.billingSuccess');
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('admin.billing.messages.overrideFailed');
  } finally {
    submittingBilling.value = false;
  }
};

const updateFeaturesPolicy = async () => {
  if (!selectedTenantId.value) return;
  submittingFeatures.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const activeFeatures = {
      'shift-sessions': featureShiftSessions.value,
      'financial-ledger': featureFinancialLedger.value,
      'meal-management': featureMealManagement.value,
      procurement: featureProcurement.value,
      'staff-payroll': featureStaffPayroll.value,
    };
    await adminToggleTenantFeatures(selectedTenantId.value, activeFeatures);
    successMsg.value = t('admin.billing.messages.featuresSuccess');
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('admin.billing.messages.toggleFailed');
  } finally {
    submittingFeatures.value = false;
  }
};

onMounted(() => {
  void loadTenants();
});
</script>

<style scoped lang="scss">
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.block {
  display: block;
}

.action-btn {
  height: 40px;
}

@media (max-width: 599.98px) {
  .action-btn {
    min-height: 48px;
    min-width: 48px;
  }
}
</style>
