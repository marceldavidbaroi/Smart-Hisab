<template>
  <q-page class="q-pa-md q-pa-sm-lg">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-lg q-mb-sm-xl">
      <div>
        <h1 class="text-h5 text-sm-h4 text-weight-bold q-my-none text-amber-10">
          Tenants Management
        </h1>
        <p class="text-grey-7 text-subtitle2 q-mt-xs q-mb-none">
          View all tenants on the platform and provision new ones.
        </p>
      </div>
      <div>
        <q-btn
          unelevated
          color="amber"
          text-color="black"
          icon="add"
          label="Provision Tenant"
          class="text-weight-bold cursor-pointer action-btn"
          style="border-radius: 8px"
          @click="showCreateDialog = true"
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

    <!-- Success Banner -->
    <q-banner
      v-if="successMsg"
      class="bg-positive text-white rounded-borders q-mb-lg text-subtitle2"
    >
      <template #avatar>
        <q-icon name="check_circle" color="white" />
      </template>
      {{ successMsg }}
    </q-banner>

    <!-- Tenants Table -->
    <q-card flat bordered class="bg-white">
      <q-card-section class="row items-center justify-between border-bottom q-py-sm q-px-md">
        <div class="text-subtitle1 text-weight-bold text-grey-9">Platform Tenants</div>
        <q-btn
          flat
          round
          dense
          icon="refresh"
          color="grey-7"
          class="cursor-pointer"
          @click="loadTenants"
          :loading="loading"
        />
      </q-card-section>

      <q-table
        :rows="tenants"
        :columns="columns"
        row-key="id"
        flat
        dense
        binary-state-sort
        class="bg-white text-grey-9"
        :loading="loading"
        no-data-label="No tenants found on this platform"
      >
        <!-- Status Slot -->
        <template #body-cell-status="props">
          <q-td :props="props">
            <q-badge
              :color="props.row.status === 'active' ? 'positive' : 'warning'"
              class="text-weight-bold text-uppercase"
              outline
            >
              {{ props.row.status }}
            </q-badge>
          </q-td>
        </template>

        <!-- Actions Slot -->
        <template #body-cell-actions="props">
          <q-td :props="props" class="text-right">
            <q-btn
              flat
              round
              dense
              icon="open_in_new"
              color="amber-10"
              class="cursor-pointer action-btn-sm"
              @click="visitTenantWorkspace(props.row.slug)"
            >
              <q-tooltip>Go to Workspace</q-tooltip>
            </q-btn>
          </q-td>
        </template>
      </q-table>
    </q-card>

    <!-- Provision Tenant Dialog -->
    <q-dialog v-model="showCreateDialog" persistent>
      <q-card class="bg-white text-grey-9 q-pa-md" style="width: 100%; max-width: 500px">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold text-amber-10">Provision Workspace Tenant</div>
          <q-space />
          <q-btn
            icon="close"
            flat
            round
            dense
            v-close-popup
            color="grey-6"
            class="cursor-pointer"
          />
        </q-card-section>

        <q-form @submit.prevent="handleCreateTenant" class="q-gutter-y-md q-mt-md">
          <q-card-section class="q-py-none q-gutter-y-md">
            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                >Organization Name</label
              >
              <q-input
                v-model="name"
                type="text"
                outlined
                dense
                placeholder="Enterprise Inc."
                color="amber-10"
                :rules="[(val) => !!val || 'Name is required']"
                hide-bottom-space
                @update:model-value="autoGenerateSlug"
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                >URL Slug</label
              >
              <q-input
                v-model="slug"
                type="text"
                outlined
                dense
                placeholder="enterprise-inc"
                color="amber-10"
                :rules="[
                  (val) => !!val || 'Slug is required',
                  (val) =>
                    /^[a-z0-9-]+$/.test(val) ||
                    'Slug must only contain lowercase letters, numbers, and dashes',
                ]"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                >Owner Email Address</label
              >
              <q-input
                v-model="ownerEmail"
                type="email"
                outlined
                dense
                placeholder="owner@enterprise.com"
                color="amber-10"
                :rules="[(val) => !!val || 'Owner email is required']"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                >Parent Tenant (Optional)</label
              >
              <q-select
                v-model="parentId"
                :options="parentTenantOptions"
                outlined
                dense
                color="amber-10"
                emit-value
                map-options
                clearable
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                >Subscription Tier</label
              >
              <q-select
                v-model="subscriptionTier"
                :options="['free', 'pro', 'enterprise']"
                outlined
                dense
                color="amber-10"
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption"
                >Feature Modules</label
              >
              <div class="row q-col-gutter-sm q-mt-xs">
                <div class="col-6">
                  <q-checkbox v-model="features.crm" label="CRM Module" color="amber-10" dense />
                </div>
                <div class="col-6">
                  <q-checkbox
                    v-model="features.invoicing"
                    label="Invoicing Module"
                    color="amber-10"
                    dense
                  />
                </div>
                <div class="col-6">
                  <q-checkbox v-model="features.chat" label="Chat Module" color="amber-10" dense />
                </div>
              </div>
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pt-md">
            <q-btn flat label="Cancel" v-close-popup color="grey-7" class="cursor-pointer" />
            <q-btn
              type="submit"
              unelevated
              color="amber"
              text-color="black"
              label="Provision Tenant"
              class="text-weight-bold cursor-pointer"
              :loading="submitting"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '../../boot/supabase';
import { adminCreateTenant } from '../../services/multiTenant';
import type { Tenant } from '../../services/multiTenant';

const router = useRouter();

const tenants = ref<Tenant[]>([]);
const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const showCreateDialog = ref(false);
const name = ref('');
const slug = ref('');
const ownerEmail = ref('');
const parentId = ref<string | null>(null);
const subscriptionTier = ref('free');
const features = ref({
  crm: true,
  invoicing: false,
  chat: false,
});
const submitting = ref(false);

const parentTenantOptions = computed(() => {
  return tenants.value.map((t) => ({
    label: t.name,
    value: t.id,
  }));
});

const getParentName = (parentUuid: string | null | undefined) => {
  if (!parentUuid) return 'None';
  const parent = tenants.value.find((t) => t.id === parentUuid);
  return parent ? parent.name : 'Unknown';
};

const columns = [
  { name: 'name', align: 'left' as const, label: 'Tenant Name', field: 'name', sortable: true },
  { name: 'slug', align: 'left' as const, label: 'Slug', field: 'slug', sortable: true },
  {
    name: 'parent',
    align: 'left' as const,
    label: 'Parent Tenant',
    field: (row: Tenant) => getParentName(row.parent_id),
    sortable: true,
  },
  { name: 'status', align: 'left' as const, label: 'Status', field: 'status', sortable: true },
  { name: 'id', align: 'left' as const, label: 'Tenant ID', field: 'id', sortable: true },
  { name: 'actions', align: 'right' as const, label: 'Actions', field: 'actions' },
];

const autoGenerateSlug = (val: string | number | null) => {
  const strVal = String(val || '');
  slug.value = strVal
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
};

const loadTenants = async () => {
  loading.value = true;
  errorMsg.value = '';
  try {
    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    tenants.value = (data || []) as Tenant[];
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to load platform tenants.';
  } finally {
    loading.value = false;
  }
};

const handleCreateTenant = async () => {
  submitting.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const createParams: Parameters<typeof adminCreateTenant>[0] = {
      name: name.value,
      slug: slug.value,
      ownerEmail: ownerEmail.value,
      enabledFeatures: features.value,
      subscriptionTier: subscriptionTier.value,
    };
    if (parentId.value) {
      createParams.parentId = parentId.value;
    }

    await adminCreateTenant(createParams);

    successMsg.value = `Successfully provisioned tenant '${name.value}' with owner email '${ownerEmail.value}'!`;
    showCreateDialog.value = false;

    // Reset form
    name.value = '';
    slug.value = '';
    ownerEmail.value = '';
    parentId.value = null;
    subscriptionTier.value = 'free';
    features.value = { crm: true, invoicing: false, chat: false };

    await loadTenants();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to provision tenant.';
  } finally {
    submitting.value = false;
  }
};

const visitTenantWorkspace = (slugStr: string) => {
  void router.push(`/${slugStr}/dashboard`);
};

onMounted(() => {
  void loadTenants();
});
</script>

<style scoped lang="scss">
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.block {
  display: block;
}

.action-btn {
  height: 40px;
}

@media (max-width: 599.98px) {
  .action-btn {
    min-height: 48px;
    min-width: 48px;
  }

  .action-btn-sm {
    min-height: 48px;
    min-width: 48px;
  }
}
</style>
