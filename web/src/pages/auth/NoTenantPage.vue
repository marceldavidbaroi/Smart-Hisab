<template>
  <div class="no-tenant-container">
    <div class="text-h5 text-bold text-slate-800 q-mb-md text-center">Create Your Workspace</div>
    <p class="text-slate-500 q-mb-lg text-sm text-center">
      You are not a member of any workspace yet. Create one to get started.
    </p>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-red-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <q-form @submit.prevent="handleCreateTenant" class="q-gutter-y-md">
      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
          >Workspace Name</label
        >
        <q-input
          v-model="name"
          type="text"
          filled
          placeholder="Acme Corp"
          color="primary"
          class="custom-input"
          :rules="[(val) => !!val || 'Workspace name is required']"
          hide-bottom-space
          @update:model-value="autoGenerateSlug"
        />
      </div>

      <div>
        <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
          >Workspace Slug (URL)</label
        >
        <q-input
          v-model="slug"
          type="text"
          filled
          placeholder="acme-corp"
          color="primary"
          class="custom-input"
          :rules="[
            (val) => !!val || 'Workspace slug is required',
            (val) =>
              /^[a-z0-9-]+$/.test(val) ||
              'Slug must only contain lowercase letters, numbers, and dashes',
          ]"
          hide-bottom-space
          prefix="app.domain.com/"
        />
      </div>

      <q-btn
        type="submit"
        color="primary"
        class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
        label="Create Workspace"
        :loading="loading"
      />
    </q-form>

    <div class="q-mt-xl text-center">
      <q-btn flat color="grey-7" icon="logout" label="Sign Out" @click="handleSignOut" size="sm" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { createTenant } from '../../services/multiTenant';
import { useTenantStore } from '../../stores/tenant';

const router = useRouter();
const tenantStore = useTenantStore();

onMounted(async () => {
  if (tenantStore.isSuperadmin) {
    await router.push('/admin/dashboard');
    return;
  }
  const allowSelfService = import.meta.env.ALLOW_SELF_SERVICE_TENANTS !== 'false';
  if (!allowSelfService) {
    await router.push('/auth/pending-access');
  }
});

const name = ref('');
const slug = ref('');
const loading = ref(false);
const errorMsg = ref('');

const autoGenerateSlug = (val: string | number | null) => {
  const strVal = String(val || '');
  slug.value = strVal
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
};

const handleCreateTenant = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    // 1. Create tenant RPC
    await createTenant(name.value, slug.value);

    // 2. Refresh store memberships
    await tenantStore.loadUserProfileAndTenants();

    // 3. Set active tenant
    await tenantStore.setActiveTenantBySlug(slug.value);

    // 4. Redirect to the workspace dashboard
    await router.push(`/${slug.value}/dashboard`);
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to create workspace. Slug might be taken.';
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
.no-tenant-container {
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
