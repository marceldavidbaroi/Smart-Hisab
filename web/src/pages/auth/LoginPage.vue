<template>
  <div class="login-container">
    <div class="login-header q-mb-lg">
      <h2 class="text-h6 text-weight-bold text-dark q-my-none">{{ headline }}</h2>
      <p class="text-body2 text-grey-7 q-mt-xs q-mb-none">{{ subtitle }}</p>
    </div>

    <q-banner v-if="errorMsg" class="bg-negative text-white rounded-lg q-mb-md text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <q-btn
      unelevated
      no-caps
      class="full-width login-cta google-btn text-weight-bold"
      :loading="loading"
      @click="handleGoogleLogin"
    >
      <div class="row items-center no-wrap">
        <q-icon
          name="img:https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg"
          size="18px"
          class="q-mr-sm"
        />
        <span>{{ $t('auth.login.signInGoogle') }}</span>
      </div>
    </q-btn>

    <template v-if="showPairDevice">
      <div class="login-divider row items-center q-my-md">
        <q-separator class="col" />
        <span class="text-caption text-grey-6 q-px-sm text-weight-medium">{{
          $t('auth.login.orContinueWith')
        }}</span>
        <q-separator class="col" />
      </div>

      <q-btn
        outline
        no-caps
        color="primary"
        class="full-width login-cta text-weight-medium"
        :to="'/auth/pair-device'"
      >
        <div class="row items-center no-wrap">
          <q-icon name="devices" size="18px" class="q-mr-sm" />
          <span>{{ $t('auth.login.pairDevice') }}</span>
        </div>
      </q-btn>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { signInWithGoogle } from '../../services/multiTenant';
import { useTenantStore } from '../../stores/tenant';
import { useI18n } from 'vue-i18n';

const route = useRoute();
const tenantStore = useTenantStore();
const { t } = useI18n();

const loading = ref(false);
const errorMsg = ref('');

const isAdminLogin = computed(() => route.name === 'admin-login' || route.query.scope === 'admin');

const showPairDevice = computed(() => !isAdminLogin.value);

const headline = computed(() =>
  isAdminLogin.value ? t('auth.login.platformAdmin') : t('auth.login.welcomeBack'),
);

const subtitle = computed(() =>
  isAdminLogin.value ? t('auth.login.adminSubtitle') : t('auth.login.workspacesSubtitle'),
);

function isSafeAdminPath(path: string | undefined): path is string {
  return (
    typeof path === 'string' &&
    path.startsWith('/admin') &&
    !path.startsWith('//') &&
    !path.startsWith('/admin/auth')
  );
}

function isSafeWorkspacePath(path: string | undefined): path is string {
  return (
    typeof path === 'string' &&
    path.startsWith('/') &&
    !path.startsWith('//') &&
    !path.startsWith('/admin')
  );
}

const handleGoogleLogin = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    let redirectTo = window.location.origin;
    const redirectPath = route.query.redirect as string | undefined;
    const isExplicitAdminScope = isAdminLogin.value;

    if (isExplicitAdminScope) {
      tenantStore.setAdminSession(true);
      redirectTo += isSafeAdminPath(redirectPath) ? redirectPath : '/admin/dashboard';
    } else {
      tenantStore.setAdminSession(false);
      if (isSafeWorkspacePath(redirectPath)) {
        redirectTo += redirectPath;
      } else if (route.params.tenantSlug) {
        const tenantSlug = Array.isArray(route.params.tenantSlug)
          ? route.params.tenantSlug[0]
          : route.params.tenantSlug;
        redirectTo += `/${tenantSlug}/dashboard`;
      }
    }

    const { error } = await signInWithGoogle(redirectTo);
    if (error) {
      errorMsg.value = error.message;
    }
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped lang="scss">
.login-container {
  width: 100%;
}

.login-cta {
  min-height: 48px;
  border-radius: var(--radius-lg);
}

.google-btn {
  background: #ffffff !important;
  border: 1px solid rgba(14, 74, 71, 0.18) !important;
  color: var(--brand-dark) !important;
  transition:
    border-color 0.2s ease,
    background-color 0.2s ease,
    box-shadow 0.2s ease;

  &:hover {
    background: var(--brand-surface) !important;
    border-color: var(--brand-primary) !important;
    box-shadow: 0 2px 8px rgba(14, 74, 71, 0.08);
  }
}

.login-divider {
  .q-separator {
    opacity: 0.55;
  }
}
</style>
