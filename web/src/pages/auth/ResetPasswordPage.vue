<template>
  <div class="reset-password-container">
    <div class="reset-header q-mb-lg text-center">
      <h2 class="text-h6 text-weight-bold text-dark q-my-none">Set New Password</h2>
      <p class="text-body2 text-grey-7 q-mt-xs q-mb-none">
        Please enter and confirm your new account password below.
      </p>
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

    <q-form v-if="!successMsg" @submit.prevent="handleUpdatePassword" class="q-gutter-y-sm">
      <div>
        <span class="text-caption text-weight-medium text-grey-8">New Password</span>
        <q-input
          v-model="newPassword"
          dense
          outlined
          type="password"
          placeholder="At least 6 characters"
          :rules="[
            (val) => !!val || 'Password is required',
            (val) => val.length >= 6 || 'Minimum 6 characters required',
          ]"
        />
      </div>

      <div>
        <span class="text-caption text-weight-medium text-grey-8">Confirm Password</span>
        <q-input
          v-model="confirmPassword"
          dense
          outlined
          type="password"
          placeholder="Repeat new password"
          :rules="[
            (val) => !!val || 'Please confirm your password',
            (val) => val === newPassword || 'Passwords do not match',
          ]"
        />
      </div>

      <q-btn
        unelevated
        no-caps
        type="submit"
        color="primary"
        class="full-width reset-cta text-weight-bold q-mt-md"
        :loading="loading"
      >
        <span>Update Password</span>
      </q-btn>
    </q-form>

    <div v-else class="text-center q-mt-md">
      <q-btn
        unelevated
        no-caps
        color="primary"
        class="full-width reset-cta text-weight-bold"
        :to="'/auth/login'"
      >
        <span>Proceed to Sign In</span>
      </q-btn>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { supabase } from '../../boot/supabase';

const newPassword = ref('');
const confirmPassword = ref('');
const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const handleUpdatePassword = async () => {
  if (!newPassword.value || newPassword.value !== confirmPassword.value) {
    errorMsg.value = 'Passwords do not match.';
    return;
  }

  loading.value = true;
  errorMsg.value = '';
  successMsg.value = '';

  try {
    const { error } = await supabase.auth.updateUser({
      password: newPassword.value,
    });
    if (error) throw error;
    successMsg.value = 'Your password has been successfully updated! You can now log in using your email and password.';
  } catch (err: unknown) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to update password. Please try requesting a new reset link.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped lang="scss">
.reset-password-container {
  width: 100%;
}

.reset-cta {
  min-height: 48px;
  border-radius: var(--radius-lg);
}
</style>
