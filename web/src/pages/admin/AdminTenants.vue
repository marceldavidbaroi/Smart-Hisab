<template>
  <q-page class="q-pa-md q-pa-sm-lg">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-lg q-mb-sm-xl">
      <div>
        <h1 class="text-h5 text-sm-h4 text-weight-bold q-my-none text-amber-10">
          {{ $t('admin.tenants.title') }}
        </h1>
        <p class="text-grey-7 text-subtitle2 q-mt-xs q-mb-none">
          {{ $t('admin.tenants.subtitle') }}
        </p>
      </div>
      <div>
        <q-btn
          unelevated
          color="amber"
          text-color="black"
          icon="add"
          :label="$t('admin.tenants.provisionBtn')"
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
        <div class="text-subtitle1 text-weight-bold text-grey-9">
          {{ $t('admin.tenants.cardTitle') }}
        </div>
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
        :no-data-label="$t('admin.tenants.noTenants')"
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
          <q-td :props="props" class="text-right q-gutter-x-xs">
            <q-btn
              flat
              round
              dense
              icon="open_in_new"
              color="amber-10"
              class="cursor-pointer action-btn-sm"
              @click="visitTenantWorkspace(props.row.slug)"
            >
              <q-tooltip>{{ $t('admin.tenants.tooltipWorkspace') }}</q-tooltip>
            </q-btn>

            <q-btn
              flat
              round
              dense
              :icon="props.row.status === 'active' ? 'block' : 'check_circle'"
              :color="props.row.status === 'active' ? 'warning' : 'positive'"
              class="cursor-pointer action-btn-sm"
              @click="handleToggleStatus(props.row)"
            >
              <q-tooltip>{{
                props.row.status === 'active' ? 'Suspend Tenant' : 'Activate Tenant'
              }}</q-tooltip>
            </q-btn>

            <q-btn
              flat
              round
              dense
              icon="delete"
              color="negative"
              class="cursor-pointer action-btn-sm"
              @click="handleDeleteTenant(props.row)"
            >
              <q-tooltip>Delete Tenant</q-tooltip>
            </q-btn>
          </q-td>
        </template>
      </q-table>
    </q-card>

    <!-- Provision Tenant Dialog -->
    <q-dialog v-model="showCreateDialog" persistent>
      <q-card class="bg-white text-grey-9 q-pa-md" style="width: 100%; max-width: 500px">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold text-amber-10">
            {{ $t('admin.tenants.dialog.title') }}
          </div>
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
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption">{{
                $t('admin.tenants.dialog.orgName')
              }}</label>
              <q-input
                v-model="name"
                type="text"
                outlined
                dense
                placeholder="Enterprise Inc."
                color="amber-10"
                :rules="[(val) => !!val || $t('admin.tenants.dialog.orgNameReq')]"
                hide-bottom-space
                @update:model-value="autoGenerateSlug"
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption">{{
                $t('admin.tenants.dialog.slug')
              }}</label>
              <q-input
                v-model="slug"
                type="text"
                outlined
                dense
                placeholder="enterprise-inc"
                color="amber-10"
                :rules="[
                  (val) => !!val || $t('admin.tenants.dialog.slugReq'),
                  (val) => /^[a-z0-9-]+$/.test(val) || $t('admin.tenants.dialog.slugInvalid'),
                ]"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption">{{
                $t('admin.tenants.dialog.ownerEmail')
              }}</label>
              <q-input
                v-model="ownerEmail"
                type="email"
                outlined
                dense
                placeholder="owner@enterprise.com"
                color="amber-10"
                :rules="[(val) => !!val || $t('admin.tenants.dialog.ownerEmailReq')]"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption">{{
                $t('admin.tenants.dialog.parent')
              }}</label>
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
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption">{{
                $t('admin.tenants.dialog.tier')
              }}</label>
              <q-select
                v-model="subscriptionTier"
                :options="['free', 'pro', 'enterprise']"
                outlined
                dense
                color="amber-10"
              />
            </div>

            <div class="q-mt-md">
              <label class="input-label text-grey-7 text-weight-bold q-mb-xs block text-caption">{{
                $t('admin.tenants.dialog.features')
              }}</label>
              <div class="row q-col-gutter-sm q-mt-xs">
                <div class="col-12">
                  <q-checkbox
                    v-model="features['shift-sessions']"
                    label="Operational Shifts & Sessions"
                    color="amber-10"
                    dense
                  />
                </div>
                <div class="col-12">
                  <q-checkbox
                    v-model="features['financial-ledger']"
                    label="Transaction Ledger"
                    color="amber-10"
                    dense
                  />
                </div>
                <div class="col-12">
                  <q-checkbox
                    v-model="features['meal-management']"
                    label="Meal & Customer Management"
                    color="amber-10"
                    dense
                  />
                </div>
                <div class="col-12">
                  <q-checkbox
                    v-model="features['procurement']"
                    label="Procurement & Supplier Management"
                    color="amber-10"
                    dense
                  />
                </div>
                <div class="col-12">
                  <q-checkbox
                    v-model="features['staff-payroll']"
                    label="Staff Attendance & Payroll"
                    color="amber-10"
                    dense
                  />
                </div>
              </div>
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pt-md">
            <q-btn
              flat
              :label="$t('kioskUI.workspace.clockOutDialog.cancelBtn')"
              v-close-popup
              color="grey-7"
              class="cursor-pointer"
            />
            <q-btn
              type="submit"
              unelevated
              color="amber"
              text-color="black"
              :label="$t('admin.tenants.provisionBtn')"
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
import { useQuasar } from 'quasar';
import { supabase } from '../../boot/supabase';
import { adminCreateTenant, deleteTenant } from '../../services/multiTenant';
import type { Tenant } from '../../services/multiTenant';
import { useI18n } from 'vue-i18n';
import { showSuccess, showError } from '../../composables/useFeedback';
import { useTenantStore } from '../../stores/tenant';

const router = useRouter();
const $q = useQuasar();
const { t } = useI18n();
const tenantStore = useTenantStore();

const tenants = ref<(Tenant & { owner?: string })[]>([]);
const loading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const showCreateDialog = ref(false);
const name = ref('');
const slug = ref('');
const ownerEmail = ref('');
const parentId = ref<string | null>(null);
const subscriptionTier = ref('free');
const features = ref<Record<string, boolean>>({
  'shift-sessions': true,
  'financial-ledger': true,
  'meal-management': true,
  procurement: true,
  'staff-payroll': true,
});
const submitting = ref(false);

const parentTenantOptions = computed(() => {
  return tenants.value.map((t) => ({
    label: t.name,
    value: t.id,
  }));
});

const getParentName = (parentUuid: string | null | undefined) => {
  if (!parentUuid) return t('admin.tenants.dialog.none');
  const parent = tenants.value.find((t) => t.id === parentUuid);
  return parent ? parent.name : 'Unknown';
};

const columns = computed(() => [
  {
    name: 'name',
    align: 'left' as const,
    label: t('admin.tenants.cols.name'),
    field: 'name',
    sortable: true,
  },
  {
    name: 'slug',
    align: 'left' as const,
    label: t('admin.tenants.cols.slug'),
    field: 'slug',
    sortable: true,
  },
  {
    name: 'owner',
    align: 'left' as const,
    label: 'Owner / Creator',
    field: 'owner',
    sortable: true,
  },
  {
    name: 'parent',
    align: 'left' as const,
    label: t('admin.tenants.cols.parent'),
    field: (row: Tenant) => getParentName(row.parent_id),
    sortable: true,
  },
  {
    name: 'status',
    align: 'left' as const,
    label: t('admin.tenants.cols.status'),
    field: 'status',
    sortable: true,
  },
  {
    name: 'id',
    align: 'left' as const,
    label: t('admin.tenants.cols.id'),
    field: 'id',
    sortable: true,
  },
  {
    name: 'actions',
    align: 'right' as const,
    label: t('admin.tenants.cols.actions'),
    field: 'actions',
  },
]);

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
    const { data: tenantsData, error: tenantsError } = await supabase
      .from('tenants')
      .select('*')
      .order('created_at', { ascending: false });

    if (tenantsError) throw tenantsError;

    // Fetch members who are owners (Owner role UUID)
    const { data: membersData, error: membersError } = await supabase
      .from('tenant_members')
      .select('tenant_id, user_id, user_profiles(full_name)')
      .eq('role_id', '00000000-0000-0000-0000-000000000001');

    if (membersError) throw membersError;

    // Fetch invitations that are for owners
    const { data: invitesData, error: invitesError } = await supabase
      .from('tenant_invitations')
      .select('tenant_id, email')
      .eq('role_id', '00000000-0000-0000-0000-000000000001');

    if (invitesError) throw invitesError;

    tenants.value = (tenantsData || []).map((t) => {
      const activeOwner = membersData?.find((m) => m.tenant_id === t.id);
      const pendingOwner = invitesData?.find((i) => i.tenant_id === t.id);

      let ownerText = 'No Owner';
      if (activeOwner && activeOwner.user_profiles) {
        ownerText = (activeOwner.user_profiles as unknown as { full_name: string }).full_name;
      } else if (pendingOwner) {
        ownerText = `${pendingOwner.email} (Pending)`;
      }

      return {
        ...t,
        owner: ownerText,
      };
    });
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

    successMsg.value = t('admin.tenants.messages.success', {
      name: name.value,
      email: ownerEmail.value,
    });
    showCreateDialog.value = false;

    // Reset form
    name.value = '';
    slug.value = '';
    ownerEmail.value = '';
    parentId.value = null;
    subscriptionTier.value = 'free';
    features.value = {
      'shift-sessions': true,
      'financial-ledger': true,
      'meal-management': true,
      procurement: true,
      'staff-payroll': true,
    };

    await loadTenants();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to provision tenant.';
  } finally {
    submitting.value = false;
  }
};

const handleToggleStatus = async (tenantRow: Tenant) => {
  const newStatus = tenantRow.status === 'active' ? 'suspended' : 'active';
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const { error } = await supabase
      .from('tenants')
      .update({ status: newStatus })
      .eq('id', tenantRow.id);

    if (error) throw error;
    showSuccess(`Successfully updated tenant status to ${newStatus}.`);
    await loadTenants();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to update tenant status.';
  }
};

const handleDeleteTenant = (tenantRow: Tenant) => {
  $q.dialog({
    title: 'Confirm Tenant Deletion',
    message: `Are you sure you want to permanently delete the tenant "${tenantRow.name}"? This will permanently delete all related workspaces, settings, members, ledger, and customer records. This action cannot be undone.`,
    cancel: true,
    persistent: true,
    ok: {
      color: 'negative',
      label: 'Delete Permanently',
      unelevated: true,
    },
  }).onOk(() => {
    void (async () => {
      errorMsg.value = '';
      successMsg.value = '';
      loading.value = true;
      try {
        await deleteTenant(tenantRow.id);
        showSuccess(`Successfully deleted tenant "${tenantRow.name}".`);
        await loadTenants();
      } catch (err) {
        const error = err as Error;
        void showError(error.message || 'Failed to delete tenant.');
      } finally {
        loading.value = false;
      }
    })();
  });
};

const visitTenantWorkspace = (slugStr: string) => {
  // Leave platform console mode so / and auth redirects stay in workspace scope
  tenantStore.setAdminSession(false);
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
