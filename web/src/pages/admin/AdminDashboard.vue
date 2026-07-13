<template>
  <q-page class="q-pa-md q-pa-sm-lg">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-lg q-mb-sm-xl">
      <div>
        <h1 class="text-h5 text-sm-h4 text-weight-bold q-my-none text-amber-10">
          Platform Admin Dashboard
        </h1>
        <p class="text-grey-7 text-subtitle2 q-mt-xs q-mb-none">
          Global analytics and metrics for the SaaS platform.
        </p>
      </div>
      <div>
        <q-btn
          flat
          round
          dense
          icon="refresh"
          color="amber-10"
          class="cursor-pointer"
          @click="loadPlatformStats"
          :loading="loading"
        />
      </div>
    </div>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-negative text-white rounded-borders q-mb-lg text-subtitle2">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <!-- Metrics row -->
    <div class="row q-col-gutter-sm q-col-gutter-sm-md q-mb-lg">
      <!-- Tenants Card -->
      <div class="col-12 col-sm-4">
        <q-card flat bordered class="bg-white text-center q-pa-md metric-card-amber">
          <q-card-section>
            <q-icon name="business" size="48px" color="amber" class="q-mb-xs" />
            <div class="text-grey-7 text-xs text-weight-bold uppercase tracking-wider">
              Total Tenants
            </div>
            <div class="text-h3 text-grey-9 text-weight-bold q-mt-sm">{{ tenantCount }}</div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Users Card -->
      <div class="col-12 col-sm-4">
        <q-card flat bordered class="bg-white text-center q-pa-md metric-card-primary">
          <q-card-section>
            <q-icon name="people" size="48px" color="primary" class="q-mb-xs" />
            <div class="text-grey-7 text-xs text-weight-bold uppercase tracking-wider">
              Platform Users
            </div>
            <div class="text-h3 text-grey-9 text-weight-bold q-mt-sm">{{ userCount }}</div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Active Billing Card -->
      <div class="col-12 col-sm-4">
        <q-card flat bordered class="bg-white text-center q-pa-md metric-card-secondary">
          <q-card-section>
            <q-icon name="credit_card" size="48px" color="secondary" class="q-mb-xs" />
            <div class="text-grey-7 text-xs text-weight-bold uppercase tracking-wider">
              Paid Subscriptions
            </div>
            <div class="text-h3 text-grey-9 text-weight-bold q-mt-sm">{{ activePaidCount }}</div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- Quick Actions Panel -->
    <div class="row q-col-gutter-sm q-col-gutter-sm-md">
      <div class="col-12">
        <q-card flat bordered class="bg-white">
          <q-card-section class="row items-center border-bottom q-py-sm q-px-md">
            <q-icon name="bolt" size="24px" color="amber" class="q-mr-sm" />
            <div class="text-subtitle1 text-weight-bold text-grey-9">
              Quick Administrative Tools
            </div>
          </q-card-section>

          <q-card-section class="q-py-md q-py-sm-lg">
            <div class="row q-col-gutter-md">
              <div class="col-12 col-sm-6 col-md-4">
                <q-btn
                  unelevated
                  color="amber"
                  text-color="black"
                  class="full-width text-weight-bold cursor-pointer action-btn"
                  style="border-radius: 8px"
                  icon="add_business"
                  label="Provision New Tenant"
                  to="/admin/tenants"
                />
              </div>
              <div class="col-12 col-sm-6 col-md-4">
                <q-btn
                  outline
                  color="amber-10"
                  class="full-width text-weight-bold cursor-pointer action-btn"
                  style="border-radius: 8px"
                  icon="tune"
                  label="Manage Subscriptions"
                  to="/admin/billing"
                />
              </div>
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

const tenantCount = ref(0);
const userCount = ref(0);
const activePaidCount = ref(0);
const loading = ref(false);
const errorMsg = ref('');

const loadPlatformStats = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    // 1. Fetch total tenants count
    const { count: tc, error: te } = await supabase
      .from('tenants')
      .select('*', { count: 'exact', head: true });

    if (te) throw te;
    tenantCount.value = tc || 0;

    // 2. Fetch total user profiles count
    const { count: uc, error: ue } = await supabase
      .from('user_profiles')
      .select('*', { count: 'exact', head: true });

    if (ue) throw ue;
    userCount.value = uc || 0;

    // 3. Fetch paid subscriptions count
    const { count: pc, error: pe } = await supabase
      .from('tenant_billing')
      .select('*', { count: 'exact', head: true })
      .neq('subscription_tier', 'free');

    if (pe) throw pe;
    activePaidCount.value = pc || 0;
  } catch (err) {
    const error = err as Error;
    errorMsg.value =
      error.message || 'Failed to fetch global metrics. Ensure you are signed in as a Superadmin.';
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  void loadPlatformStats();
});
</script>

<style scoped lang="scss">
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.metric-card-amber {
  border-top: 3px solid var(--q-amber);
}

.metric-card-primary {
  border-top: 3px solid var(--q-primary);
}

.metric-card-secondary {
  border-top: 3px solid var(--q-secondary);
}

.tracking-wider {
  letter-spacing: 0.05em;
}

.action-btn {
  height: 48px;
}

@media (max-width: 599.98px) {
  .action-btn {
    min-height: 48px;
  }
}
</style>
