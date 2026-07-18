<template>
  <q-page class="flex flex-center q-pa-md">
    <div class="text-center">
      <div class="q-mb-md">
        <q-icon name="gpp_bad" size="96px" class="text-red-7" />
      </div>
      <h1 class="text-h3 text-bold q-mb-xs text-slate-850">403</h1>
      <h2 class="text-h5 text-slate-500 q-mb-lg">{{ $t('errors.forbiddenTitle') }}</h2>
      <p class="text-body1 text-slate-500 max-w-md q-mx-auto q-mb-xl">
        {{ $t('errors.forbiddenText') }}
      </p>

      <div class="row justify-center q-gutter-md">
        <q-btn
          unelevated
          color="primary"
          :label="$t('errors.backSafety')"
          class="q-px-lg rounded-btn"
          @click="goBack"
        />
        <q-btn
          outline
          color="primary"
          :label="$t('errors.signInDifferent')"
          class="q-px-lg rounded-btn"
          @click="signOutAndLogin"
        />
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';
import { useTenantStore } from '../stores/tenant';

const router = useRouter();
const tenantStore = useTenantStore();

const goBack = async () => {
  if (tenantStore.myTenants.length > 0 && tenantStore.myTenants[0]?.tenants) {
    await router.push(`/${tenantStore.myTenants[0]?.tenants?.slug}/dashboard`);
  } else if (tenantStore.isSuperadmin && tenantStore.isAdminSession) {
    await router.push('/admin/dashboard');
  } else {
    await router.push('/');
  }
};

const signOutAndLogin = async () => {
  await tenantStore.logout();
  await router.push('/auth/login');
};
</script>

<style scoped>
.max-w-md {
  max-width: 450px;
}
.rounded-btn {
  border-radius: 12px;
}
</style>
