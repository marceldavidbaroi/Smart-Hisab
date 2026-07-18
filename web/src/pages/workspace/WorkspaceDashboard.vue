<template>
  <q-page class="q-pa-lg">
    <div class="row items-center justify-between q-mb-xl">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-850">{{ $t('workspace.dashboard.title') }}</h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          {{ $t('workspace.dashboard.subtitle') }}
          <span class="text-primary text-weight-bold">{{ tenantStore.activeTenant?.name }}</span>
        </p>
      </div>
      <div>
        <q-chip outline color="primary" class="q-px-md font-semibold">
          {{ $t('workspace.dashboard.role') }}: {{ tenantStore.activeRole || 'Member' }}
        </q-chip>
      </div>
    </div>

    <!-- Cards Grid -->
    <div class="row q-col-gutter-lg">
      <!-- Tenant Overview Card -->
      <div class="col-12 col-md-6">
        <q-card class="glass-card full-height">
          <q-card-section class="card-gradient-header row items-center q-pb-md">
            <q-icon name="info" size="24px" class="text-primary q-mr-sm" />
            <div class="text-h6 text-bold text-slate-800">{{ $t('workspace.dashboard.profileCardTitle') }}</div>
          </q-card-section>

          <q-card-section class="q-pt-md">
            <div class="row q-col-gutter-y-md">
               <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">{{ $t('workspace.dashboard.workspaceName') }}:</div>
                <div class="col-8 text-weight-medium text-slate-800">
                  {{ tenantStore.activeTenant?.name }}
                </div>
              </div>
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">{{ $t('workspace.dashboard.routingSlug') }}:</div>
                <div class="col-8">
                  <q-badge
                    color="indigo-1"
                    text-color="indigo-9"
                    class="text-sm font-mono q-py-xs q-px-sm"
                  >
                    {{ tenantStore.activeTenant?.slug }}
                  </q-badge>
                </div>
              </div>
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">{{ $t('workspace.dashboard.tenantId') }}:</div>
                <div class="col-8 text-caption font-mono text-slate-500 ellipsis">
                  {{ tenantStore.activeTenant?.id }}
                </div>
              </div>
              <div class="col-12 row items-center">
                <div class="col-4 text-slate-500 text-weight-bold">{{ $t('workspace.dashboard.status') }}:</div>
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
            <div class="text-h6 text-bold text-slate-800">{{ $t('workspace.dashboard.featuresCardTitle') }}</div>
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
</style>
