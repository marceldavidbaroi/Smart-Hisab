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

    <q-banner v-if="successMsg" class="bg-positive text-white rounded-lg q-mb-md text-sm">
      <template #avatar>
        <q-icon name="check_circle" color="white" />
      </template>
      {{ successMsg }}
    </q-banner>

    <!-- Main Login View -->
    <template v-if="mode === 'login'">
      <q-form @submit.prevent="handleEmailLogin" class="q-gutter-y-sm">
        <q-input
          v-model="email"
          dense
          outlined
          type="email"
          label="Email Address"
          placeholder="name@example.com"
          :rules="[(val) => !!val || 'Email is required']"
        />

        <div>
          <div class="row items-center justify-between q-mb-xs">
            <span class="text-caption text-weight-medium text-grey-8">Password</span>
            <a
              href="#"
              class="text-caption text-primary text-weight-bold cursor-pointer"
              style="text-decoration: none"
              @click.prevent="switchToForgotPassword"
            >
              Forgot Password?
            </a>
          </div>
          <q-input
            v-model="password"
            dense
            outlined
            type="password"
            placeholder="••••••••"
            :rules="[(val) => !!val || 'Password is required']"
          />
        </div>

        <q-btn
          unelevated
          no-caps
          type="submit"
          color="primary"
          class="full-width login-cta text-weight-bold q-mt-md"
          :loading="loading"
        >
          <span>Sign In with Email</span>
        </q-btn>
      </q-form>

      <div class="login-divider row items-center q-my-md">
        <q-separator class="col" />
        <span class="text-caption text-grey-6 q-px-sm text-weight-medium">OR</span>
        <q-separator class="col" />
      </div>

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

      <div class="text-center q-mt-sm">
        <span class="text-caption text-grey-7">Don't have an account? </span>
        <router-link to="/auth/signup" class="text-caption text-primary text-weight-bold" style="text-decoration: none">
          Sign Up
        </router-link>
      </div>

      <template v-if="showPairDevice">
        <div class="q-mt-sm">
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
        </div>
      </template>
    </template>

    <!-- Forgot Password View -->
    <template v-else-if="mode === 'forgot_password'">
      <q-form @submit.prevent="handleForgotPassword" class="q-gutter-y-sm">
        <p class="text-caption text-grey-7 q-mb-sm">
          Enter your email address below (including social login users) to receive password reset instructions.
        </p>

        <q-input
          v-model="email"
          dense
          outlined
          type="email"
          label="Email Address"
          placeholder="name@example.com"
          :rules="[(val) => !!val || 'Email is required']"
        />

        <q-btn
          unelevated
          no-caps
          type="submit"
          color="primary"
          class="full-width login-cta text-weight-bold q-mt-md"
          :loading="loading"
        >
          <span>Send Reset Instructions</span>
        </q-btn>

        <q-btn
          flat
          no-caps
          color="grey-8"
          class="full-width q-mt-xs"
          @click="switchToLogin"
        >
          <q-icon name="arrow_back" size="18px" class="q-mr-xs" />
          <span>Back to Login</span>
        </q-btn>
      </q-form>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { signInWithGoogle, signInWithEmail, resetPasswordForEmail } from '../../services/multiTenant';
import { useTenantStore } from '../../stores/tenant';
import { useI18n } from 'vue-i18n';

const route = useRoute();
const router = useRouter();
const tenantStore = useTenantStore();
const { t } = useI18n();

const mode = ref<'login' | 'forgot_password'>('login');
const email = ref('');
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const isAdminLogin = computed(() => route.name === 'admin-login' || route.query.scope === 'admin');

const showPairDevice = computed(() => !isAdminLogin.value);

const headline = computed(() => {
  if (mode.value === 'forgot_password') return 'Reset Password';
  return isAdminLogin.value ? t('auth.login.platformAdmin') : t('auth.login.welcomeBack');
});

const subtitle = computed(() => {
  if (mode.value === 'forgot_password') return 'We will send a reset link to your email';
  return isAdminLogin.value ? t('auth.login.adminSubtitle') : t('auth.login.workspacesSubtitle');
});

function switchToForgotPassword() {
  errorMsg.value = '';
  successMsg.value = '';
  mode.value = 'forgot_password';
}

function switchToLogin() {
  errorMsg.value = '';
  successMsg.value = '';
  mode.value = 'login';
}

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

const handleEmailLogin = async () => {
  if (!email.value || !password.value) return;
  loading.value = true;
  errorMsg.value = '';
  successMsg.value = '';

  try {
    const { data, error } = await signInWithEmail(email.value, password.value);
    if (error) throw error;

    if (data.user) {
      const redirectPath = route.query.redirect as string | undefined;
      if (isAdminLogin.value) {
        tenantStore.setAdminSession(true);
        await router.push(isSafeAdminPath(redirectPath) ? redirectPath : '/admin/dashboard');
      } else {
        tenantStore.setAdminSession(false);
        if (isSafeWorkspacePath(redirectPath)) {
          await router.push(redirectPath);
        } else if (route.params.tenantSlug) {
          const tenantSlug = Array.isArray(route.params.tenantSlug)
            ? route.params.tenantSlug[0]
            : route.params.tenantSlug;
          await router.push(`/${tenantSlug}/dashboard`);
        } else {
          await router.push('/auth/no-tenant');
        }
      }
    }
  } catch (err: unknown) {
    const error = err as Error;
    errorMsg.value = error.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};

const handleForgotPassword = async () => {
  if (!email.value) return;
  loading.value = true;
  errorMsg.value = '';
  successMsg.value = '';

  try {
    const { error } = await resetPasswordForEmail(email.value);
    if (error) throw error;
    successMsg.value = 'Password reset instructions have been sent to your email.';
  } catch (err: unknown) {
    const error = err as Error;
    errorMsg.value = error.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};

const handleGoogleLogin = async () => {
  loading.value = true;
  errorMsg.value = '';
  successMsg.value = '';
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
