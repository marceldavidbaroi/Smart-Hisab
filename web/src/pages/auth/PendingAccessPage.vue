<template>
  <div class="pending-access-container text-center q-py-lg">
    <q-icon name="hourglass_empty" size="72px" class="text-warning q-mb-md animate-slow-spin" />

    <div class="text-h5 text-bold text-slate-800 q-mb-md">{{ $t('auth.pending.title') }}</div>

    <p class="text-slate-500 text-sm q-mb-xl">
      {{ $t('auth.pending.subtitle') }}
    </p>

    <q-btn
      color="primary"
      outline
      class="full-width q-py-sm rounded-btn q-mb-md"
      :label="$t('auth.pending.checkStatus')"
      :loading="loading"
      @click="handleRefresh"
    />

    <q-btn
      flat
      color="grey-7"
      icon="logout"
      :label="$t('auth.pending.signOut')"
      class="full-width rounded-btn text-weight-bold"
      @click="handleSignOut"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useTenantStore } from '../../stores/tenant';
import { Notify } from 'quasar';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const tenantStore = useTenantStore();
const { t } = useI18n();
const loading = ref(false);

const handleRefresh = async () => {
  loading.value = true;
  try {
    // Re-verify if any tenant membership was added
    await tenantStore.loadUserProfileAndTenants();

    if (tenantStore.myTenants.length > 0) {
      const firstSlug = tenantStore.myTenants[0]?.tenants?.slug;
      if (firstSlug) {
        Notify.create({
          type: 'positive',
          message: t('auth.pending.accessDetected'),
          position: 'top',
        });
        await router.push(`/${firstSlug}/dashboard`);
        return;
      }
    }

    Notify.create({
      type: 'info',
      message: t('auth.pending.stillAwaiting'),
      position: 'top',
      timeout: 2000,
    });
  } catch (err) {
    const error = err as Error;
    Notify.create({
      type: 'negative',
      message: error.message || t('auth.pending.failedRefresh'),
      position: 'top',
    });
  } finally {
    loading.value = false;
  }
};

const handleSignOut = async () => {
  await tenantStore.logout();
  await router.push('/auth/login');
};
</script>

<style scoped lang="scss">
.pending-access-container {
  width: 100%;
}

.rounded-btn {
  border-radius: 12px;
}

@keyframes slow-spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.animate-slow-spin {
  animation: slow-spin 8s linear infinite;
}
</style>
