<template>
  <div class="signup-container">
    <div class="text-h5 text-bold text-slate-800 q-mb-md">
      {{ $t('auth.signup.createAccount') }}
    </div>
    <p class="text-slate-500 q-mb-lg text-sm">{{ $t('auth.signup.subtitle') }}</p>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-red-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <!-- Success Message -->
    <div v-if="successMsg" class="text-center q-py-lg">
      <q-icon name="mark_email_read" size="72px" class="text-primary q-mb-md" />
      <div class="text-h6 text-slate-800 text-bold q-mb-sm">
        {{ $t('auth.signup.verifyEmailTitle') }}
      </div>
      <p
        class="text-slate-500 text-sm q-mb-lg"
        v-html="
          $t('auth.signup.verifyEmailText', {
            email: `<span class='text-slate-800 text-weight-bold'>${email}</span>`,
          })
        "
      ></p>
      <q-btn
        color="primary"
        outline
        class="full-width q-py-sm rounded-btn"
        :label="$t('auth.signup.backToLogin')"
        to="/auth/login"
      />
    </div>

    <q-form v-else @submit.prevent="handleSignup" class="q-gutter-y-md">
      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
          $t('auth.signup.fullNameLabel')
        }}</label>
        <q-input
          v-model="fullName"
          type="text"
          filled
          placeholder="Jane Doe"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || $t('auth.signup.fullNameRequired')]"
          hide-bottom-space
        />
      </div>

      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
          $t('auth.signup.emailLabel')
        }}</label>
        <q-input
          v-model="email"
          type="email"
          filled
          placeholder="name@company.com"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || $t('auth.signup.emailRequired')]"
          hide-bottom-space
        />
      </div>

      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
          $t('auth.signup.passwordLabel')
        }}</label>
        <q-input
          v-model="password"
          type="password"
          filled
          placeholder="••••••••"
          color="primary"
          class="custom-input"
          :rules="[
            (val) => !!val || $t('auth.signup.passwordRequired'),
            (val) => val.length >= 6 || $t('auth.signup.passwordMinLength'),
          ]"
          hide-bottom-space
        />
      </div>

      <q-btn
        type="submit"
        color="primary"
        class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
        :label="$t('auth.signup.register')"
        :loading="loading"
      />
    </q-form>

    <div v-if="!successMsg">
      <!-- Separator -->
      <div class="row items-center q-my-lg">
        <q-separator class="col" />
        <span class="text-slate-400 q-px-sm text-xs text-uppercase text-weight-bold">{{
          $t('auth.login.orContinueWith')
        }}</span>
        <q-separator class="col" />
      </div>

      <!-- Google Sign Up Button -->
      <q-btn
        outline
        no-caps
        class="full-width q-py-sm rounded-btn google-btn text-weight-bold"
        :loading="loading"
        @click="handleGoogleSignup"
      >
        <div class="row items-center no-wrap">
          <q-icon
            name="img:https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg"
            size="18px"
            class="q-mr-sm"
          />
          <span>{{ $t('auth.signup.signUpGoogle') }}</span>
        </div>
      </q-btn>
    </div>

    <div v-if="!successMsg" class="q-mt-xl text-center text-sm text-slate-500">
      {{ $t('auth.signup.alreadyHaveAccount') }}
      <router-link to="/auth/login" class="text-primary text-weight-bold hover-underline">
        {{ $t('auth.signup.signIn') }}
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRoute } from 'vue-router';
import { signUpWithEmail, signInWithGoogle } from '../../services/multiTenant';
import { useI18n } from 'vue-i18n';

const route = useRoute();
const { t } = useI18n();

const fullName = ref('');
const email = ref('');
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref(false);

const handleSignup = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    const { error } = await signUpWithEmail(email.value, password.value, fullName.value);
    if (error) {
      errorMsg.value = error.message;
      return;
    }
    successMsg.value = true;
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('feedback.somethingWentWrong');
  } finally {
    loading.value = false;
  }
};

const handleGoogleSignup = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    const redirectPath = route.query.redirect as string | undefined;
    const redirectTo = redirectPath ? window.location.origin + redirectPath : undefined;
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
.signup-container {
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
