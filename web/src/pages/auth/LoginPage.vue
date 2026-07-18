<template>
  <div class="login-container">
    <div class="text-h5 text-bold text-slate-800 q-mb-md">
      <template v-if="route.name === 'admin-login'">{{ $t('auth.login.platformAdmin') }}</template>
      <template v-else-if="tenantName">{{ $t('auth.login.welcomeTo', { tenant: tenantName }) }}</template>
      <template v-else>{{ $t('auth.login.welcomeBack') }}</template>
    </div>
    <p class="text-slate-500 q-mb-lg text-sm">
      <template v-if="route.name === 'admin-login'">{{ $t('auth.login.adminSubtitle') }}</template>
      <template v-else-if="tenantName">{{ $t('auth.login.workspaceSubtitle') }}</template>
      <template v-else>{{ $t('auth.login.workspacesSubtitle') }}</template>
    </p>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-red-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <q-form @submit.prevent="handleLogin" class="q-gutter-y-md">
      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
          >{{ $t('auth.login.emailLabel') }}</label
        >
        <q-input
          v-model="email"
          type="email"
          filled
          placeholder="name@company.com"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || $t('auth.login.emailRequired')]"
          hide-bottom-space
        />
      </div>

      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
          >{{ $t('auth.login.passwordLabel') }}</label
        >
        <q-input
          v-model="password"
          type="password"
          filled
          placeholder="••••••••"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || $t('auth.login.passwordRequired')]"
          hide-bottom-space
        />
      </div>

      <q-btn
        type="submit"
        color="primary"
        class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
        :label="$t('auth.login.signIn')"
        :loading="loading"
      />
    </q-form>

    <!-- Separator -->
    <div class="row items-center q-my-lg">
      <q-separator class="col" />
      <span class="text-slate-400 q-px-sm text-xs text-uppercase text-weight-bold"
        >{{ $t('auth.login.orContinueWith') }}</span
      >
      <q-separator class="col" />
    </div>

    <!-- Google Login Button -->
    <q-btn
      outline
      no-caps
      class="full-width q-py-sm rounded-btn google-btn text-weight-bold"
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

    <!-- Pair Counter Device Button -->
    <q-btn
      outline
      no-caps
      class="full-width q-py-sm rounded-btn q-mt-md text-weight-bold"
      color="secondary"
      :to="'/auth/pair-device'"
    >
      <div class="row items-center no-wrap">
        <q-icon name="devices" size="18px" class="q-mr-sm" />
        <span>{{ $t('auth.login.pairDevice') }}</span>
      </div>
    </q-btn>

    <div class="q-mt-xl text-center text-sm text-slate-500">
      {{ $t('auth.login.noAccount') }}
      <router-link to="/auth/signup" class="text-primary text-weight-bold hover-underline">
        {{ $t('auth.login.signUp') }}
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { signInWithEmail, signInWithGoogle } from '../../services/multiTenant';
import { useTenantStore } from '../../stores/tenant';
import { supabase } from '../../boot/supabase';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const route = useRoute();
const tenantStore = useTenantStore();
const { t } = useI18n();

const email = ref('');
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');

const tenantName = ref<string | null>(null);
const resolvingTenant = ref(false);

const fetchTenantInfo = async () => {
  const slug = route.params.tenantSlug as string | undefined;
  if (!slug) {
    tenantName.value = null;
    return;
  }

  resolvingTenant.value = true;
  try {
    const { data, error } = await supabase.from('tenants').select('name').eq('slug', slug).single();

    if (error) {
      console.error('Error fetching tenant details:', error.message);
      tenantName.value = null;
    } else if (data) {
      tenantName.value = data.name;
    }
  } catch (err) {
    console.error('Failed to fetch tenant info:', err);
    tenantName.value = null;
  } finally {
    resolvingTenant.value = false;
  }
};

onMounted(fetchTenantInfo);
watch(() => route.params.tenantSlug, fetchTenantInfo);

const handleLogin = async () => {
  const targetRouteName = route.name;
  const targetQuery = { ...route.query };
  const targetParams = { ...route.params };

  loading.value = true;
  errorMsg.value = '';
  try {
    const { error } = await signInWithEmail(email.value, password.value);
    if (error) {
      errorMsg.value = error.message;
      return;
    }

    // Success, reinitialize the store to load profiles & memberships
    await tenantStore.initializeStore();

    // Check where to redirect
    // 1. Explicit redirect path in query parameter (e.g. redirect=/admin/dashboard)
    const redirectPath = targetQuery.redirect as string | undefined;
    if (redirectPath) {
      await router.push(redirectPath);
      return;
    }

    // 2. Logging in from Admin login URL or with scope=admin
    const isExplicitAdminScope = targetRouteName === 'admin-login' || targetQuery.scope === 'admin';
    if (isExplicitAdminScope) {
      if (tenantStore.isSuperadmin) {
        tenantStore.setAdminSession(true);
        await router.push('/admin/dashboard');
        return;
      } else {
        // Strict admin segregation: non-admins are rejected from /admin/auth/login
        errorMsg.value = t('auth.login.deniedSuperadmin');
        await tenantStore.logout();
        return;
      }
    } else {
      tenantStore.setAdminSession(false);
    }

    // 3. Logging in from a tenant-specific page
    const tenantSlug = targetParams.tenantSlug as string | undefined;
    if (tenantSlug) {
      // Check if user has access to this tenant
      if (tenantStore.hasTenantAccess(tenantSlug)) {
        await router.push(`/${tenantSlug}/dashboard`);
        return;
      } else {
        // Logged in but doesn't have access to this specific tenant
        errorMsg.value = t('auth.login.deniedWorkspace', { tenant: tenantName.value || tenantSlug });
        return;
      }
    }

    // 4. Default fallback redirection logic
    if (tenantStore.myTenants.length > 0 && tenantStore.myTenants[0]?.tenants) {
      // Go to first tenant workspace dashboard
      await router.push(`/${tenantStore.myTenants[0]?.tenants?.slug}/dashboard`);
    } else if (tenantStore.isSuperadmin && isExplicitAdminScope) {
      // If superadmin has no workspaces and logged in explicitly via admin scope, go to admin portal
      await router.push('/admin/dashboard');
    } else {
      // Regular user with no workspaces, or superadmin logging in via auth scope
      await router.push('/auth/no-tenant');
    }
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};

const handleGoogleLogin = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    let redirectTo = window.location.origin;

    // Determine the target URL after Google OAuth callback
    const redirectPath = route.query.redirect as string | undefined;
    if (redirectPath) {
      redirectTo += redirectPath;
    } else if (route.params.tenantSlug) {
      const tenantSlug = Array.isArray(route.params.tenantSlug)
        ? route.params.tenantSlug[0]
        : route.params.tenantSlug;
      redirectTo += `/${tenantSlug}/dashboard`;
    } else if (route.name === 'admin-login' || route.query.scope === 'admin') {
      tenantStore.setAdminSession(true);
      redirectTo += `/admin/dashboard`;
    } else {
      tenantStore.setAdminSession(false);
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

.input-label {
  display: block;
}

.block {
  display: block;
}

.rounded-btn {
  border-radius: 12px;
}

.btn-gradient {
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
  border: none;

  &:hover {
    filter: brightness(1.1);
  }
}

.google-btn {
  background: #ffffff !important;
  border: 1px solid #cbd5e1 !important;
  color: #0f172a !important;
  transition: all 0.2s ease-in-out;

  &:hover {
    background: #f8fafc !important;
    border-color: #94a3b8 !important;
  }
}

.hover-underline:hover {
  text-decoration: underline;
}

.custom-input :deep(.q-field__control) {
  border-radius: 12px;
  background: #ffffff !important;
  border: 1px solid #cbd5e1;
  color: #0f172a !important;

  &:hover {
    border-color: #94a3b8;
  }

  &.q-field__control--focused {
    border-color: #6366f1;
    box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15);
  }
}
</style>
