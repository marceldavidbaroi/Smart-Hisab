<template>
  <q-page class="q-pa-lg">
    <div class="row items-center justify-between q-mb-xl">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-850">
          {{ $t('workspace.dashboard.title') }}
        </h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          {{ $t('workspace.dashboard.subtitle') }}
          <span class="text-primary text-weight-bold">{{ tenantStore.activeTenant?.name }}</span>
        </p>
      </div>
      <div class="row items-center q-gutter-sm">
        <q-btn
          v-if="tenantStore.isFeatureEnabled('meal-management')"
          color="primary"
          icon="restaurant_menu"
          :label="$t('nav.mealConfigs')"
          unelevated
          dense
          class="q-px-md cursor-pointer text-weight-bold"
          style="border-radius: 8px; min-height: 40px"
          :to="{
            name: 'workspace-meal-configs',
            params: { tenantSlug: tenantStore.activeTenant?.slug },
          }"
        />
        <q-chip outline color="primary" class="q-px-md font-semibold">
          {{ $t('workspace.dashboard.role') }}: {{ tenantStore.activeRole || 'Member' }}
        </q-chip>
      </div>
    </div>

    <!-- Quick Actions Card Section -->
    <div class="q-mb-lg">
      <q-card class="glass-card">
        <q-card-section class="card-gradient-header row items-center q-py-sm">
          <q-icon name="bolt" size="22px" class="text-amber-7 q-mr-sm" />
          <div class="text-subtitle1 text-bold text-slate-800">
            {{ $t('workspace.dashboard.quickActions') }}
          </div>
        </q-card-section>

        <q-card-section class="q-py-md">
          <div class="row q-col-gutter-md">
            <div
              v-if="tenantStore.isFeatureEnabled('meal-management')"
              class="col-12 col-sm-6 col-md-3"
            >
              <q-btn
                flat
                bordered
                no-caps
                align="left"
                class="full-width quick-action-btn bg-white text-dark"
                :to="{
                  name: 'workspace-meal-configs',
                  params: { tenantSlug: tenantStore.activeTenant?.slug },
                }"
              >
                <div class="row items-center no-wrap full-width q-pa-xs">
                  <q-avatar size="36px" color="teal-1" text-color="teal-9" class="q-mr-md">
                    <q-icon name="restaurant_menu" size="20px" />
                  </q-avatar>
                  <div class="column">
                    <div class="text-weight-bold text-slate-800 text-subtitle2">
                      {{ $t('nav.mealConfigs') }}
                    </div>
                    <div class="text-caption text-grey-6" style="font-size: 11px">
                      Configure rates & notes
                    </div>
                  </div>
                </div>
              </q-btn>
            </div>

            <div
              v-if="tenantStore.isFeatureEnabled('meal-management')"
              class="col-12 col-sm-6 col-md-3"
            >
              <q-btn
                flat
                bordered
                no-caps
                align="left"
                class="full-width quick-action-btn bg-white text-dark"
                :to="{
                  name: 'workspace-customers',
                  params: { tenantSlug: tenantStore.activeTenant?.slug },
                }"
              >
                <div class="row items-center no-wrap full-width q-pa-xs">
                  <q-avatar size="36px" color="blue-1" text-color="blue-9" class="q-mr-md">
                    <q-icon name="face" size="20px" />
                  </q-avatar>
                  <div class="column">
                    <div class="text-weight-bold text-slate-800 text-subtitle2">
                      {{ $t('customers.nav.label') }}
                    </div>
                    <div class="text-caption text-grey-6" style="font-size: 11px">
                      Manage registered customers
                    </div>
                  </div>
                </div>
              </q-btn>
            </div>

            <div
              v-if="tenantStore.isFeatureEnabled('shift-sessions')"
              class="col-12 col-sm-6 col-md-3"
            >
              <q-btn
                flat
                bordered
                no-caps
                align="left"
                class="full-width quick-action-btn bg-white text-dark"
                :to="{
                  name: 'workspace-shifts',
                  params: { tenantSlug: tenantStore.activeTenant?.slug },
                }"
              >
                <div class="row items-center no-wrap full-width q-pa-xs">
                  <q-avatar size="36px" color="purple-1" text-color="purple-9" class="q-mr-md">
                    <q-icon name="schedule" size="20px" />
                  </q-avatar>
                  <div class="column">
                    <div class="text-weight-bold text-slate-800 text-subtitle2">
                      {{ $t('nav.shiftsConfig') }}
                    </div>
                    <div class="text-caption text-grey-6" style="font-size: 11px">
                      Operating shift windows
                    </div>
                  </div>
                </div>
              </q-btn>
            </div>

            <div
              v-if="tenantStore.isFeatureEnabled('financial-ledger')"
              class="col-12 col-sm-6 col-md-3"
            >
              <q-btn
                flat
                bordered
                no-caps
                align="left"
                class="full-width quick-action-btn bg-white text-dark"
                :to="{
                  name: 'workspace-ledger',
                  params: { tenantSlug: tenantStore.activeTenant?.slug },
                }"
              >
                <div class="row items-center no-wrap full-width q-pa-xs">
                  <q-avatar size="36px" color="amber-1" text-color="amber-9" class="q-mr-md">
                    <q-icon name="account_balance_wallet" size="20px" />
                  </q-avatar>
                  <div class="column">
                    <div class="text-weight-bold text-slate-800 text-subtitle2">
                      {{ $t('nav.ledger') }}
                    </div>
                    <div class="text-caption text-grey-6" style="font-size: 11px">
                      Cashbook transactions
                    </div>
                  </div>
                </div>
              </q-btn>
            </div>
          </div>
        </q-card-section>
      </q-card>
    </div>

    <!-- Cards Grid -->
    <div class="row q-col-gutter-lg">
      <!-- Tenant Overview Card -->
      <div class="col-12 col-md-6">
        <q-card class="glass-card full-height">
          <q-card-section class="card-gradient-header row items-center q-pb-md">
            <q-icon name="info" size="24px" class="text-primary q-mr-sm" />
            <div class="text-h6 text-bold text-slate-800">
              {{ $t('workspace.dashboard.profileCardTitle') }}
            </div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <div class="row q-col-gutter-y-md">
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">
                  {{ $t('workspace.dashboard.workspaceName') }}:
                </div>
                <div class="col-8 text-weight-medium text-slate-800">
                  {{ tenantStore.activeTenant?.name }}
                </div>
              </div>
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">
                  {{ $t('workspace.dashboard.routingSlug') }}:
                </div>
                <div class="col-8">
                  <q-badge
                    color="teal-1"
                    text-color="teal-9"
                    class="text-sm font-mono q-py-xs q-px-sm"
                  >
                    {{ tenantStore.activeTenant?.slug }}
                  </q-badge>
                </div>
              </div>
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">
                  {{ $t('workspace.dashboard.tenantId') }}:
                </div>
                <div class="col-8 text-caption font-mono text-slate-500 ellipsis">
                  {{ tenantStore.activeTenant?.id }}
                </div>
              </div>
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">
                  {{ $t('workspace.dashboard.status') }}:
                </div>
                <div class="col-8">
                  <q-badge
                    :color="tenantStore.activeTenant?.status === 'active' ? 'green-2' : 'orange-2'"
                    :class="
                      tenantStore.activeTenant?.status === 'active'
                        ? 'text-green-9'
                        : 'text-orange-9'
                    "
                    class="text-weight-bold uppercase"
                  >
                    {{ tenantStore.activeTenant?.status }}
                  </q-badge>
                </div>
              </div>
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Feature Flags & Capabilities Card -->
      <div class="col-12 col-md-6">
        <q-card class="glass-card full-height">
          <q-card-section class="card-gradient-header row items-center q-pb-md">
            <q-icon name="stars" size="24px" class="text-purple-6 q-mr-sm" />
            <div class="text-h6 text-bold text-slate-800">
              {{ $t('workspace.dashboard.featuresCardTitle') }}
            </div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <div v-if="hasFeatures" class="row q-col-gutter-sm">
              <div
                v-for="(enabled, feature) in enabledFeatures"
                :key="feature"
                class="col-6 col-sm-4"
              >
                <div
                  class="feature-pill flex items-center justify-between q-pa-sm"
                  :class="enabled ? 'feature-enabled' : 'feature-disabled'"
                >
                  <div class="flex items-center">
                    <q-icon
                      :name="enabled ? 'check_circle' : 'cancel'"
                      :color="enabled ? 'positive' : 'grey-5'"
                      size="18px"
                      class="q-mr-xs"
                    />
                    <span class="text-xs text-weight-bold uppercase font-mono text-slate-700">{{
                      feature
                    }}</span>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center q-py-lg text-slate-500">
              <q-icon name="extension" size="48px" class="q-mb-sm text-slate-400" />
              <div>{{ $t('workspace.dashboard.noFeatures') }}</div>
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
/* eslint-disable @typescript-eslint/no-explicit-any */
import { computed } from 'vue';
import { useTenantStore } from '../../stores/tenant';

const tenantStore = useTenantStore();

const VALID_FEATURES = [
  'shift-sessions',
  'financial-ledger',
  'meal-management',
  'procurement',
  'staff-payroll',
];

const enabledFeatures = computed<any>(() => {
  const rawFeatures = (tenantStore.activeSettings as any)?.enabled_features || {};
  const filtered: any = {};
  for (const key of VALID_FEATURES) {
    if (key in rawFeatures) {
      filtered[key] = rawFeatures[key];
    }
  }
  return filtered;
});

const hasFeatures = computed(() => {
  return Object.keys(enabledFeatures.value).length > 0;
});
</script>

<style scoped lang="scss">
.glass-card {
  background: #ffffff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
}

.card-gradient-header {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.bg-slate-950 {
  background-color: #f1f5f9 !important;
}

.feature-pill {
  border-radius: 8px;
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.feature-enabled {
  background: rgba(34, 197, 94, 0.08);
  border-color: rgba(34, 197, 94, 0.15);
}

.feature-disabled {
  background: rgba(0, 0, 0, 0.02);
  opacity: 0.6;
}

.quick-action-btn {
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.08);
  transition: all 0.2s ease;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 14px rgba(0, 0, 0, 0.06);
    border-color: rgba(14, 74, 71, 0.2);
  }
}
</style>
