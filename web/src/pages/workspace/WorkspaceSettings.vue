<template>
  <q-page class="q-pa-lg">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-850">Workspace Settings</h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          Configure branding, preferences, and details for your organization.
        </p>
      </div>
    </div>

    <!-- Tabs selection -->
    <q-tabs
      v-model="activeTab"
      class="text-grey-7 q-mb-lg border-bottom"
      active-color="primary"
      indicator-color="primary"
      align="left"
      narrow-indicator
      dense
    >
      <q-tab name="general" label="General Settings" icon="settings" class="q-py-sm" />
      <q-tab name="kiosk" label="Kiosk Terminals" icon="devices" class="q-py-sm" />
    </q-tabs>

    <!-- Error Banner -->
    <q-banner v-if="errorMsg" class="bg-red-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="warning" color="white" />
      </template>
      {{ errorMsg }}
    </q-banner>

    <!-- Success Banner -->
    <q-banner v-if="successMsg" class="bg-green-9 text-white rounded-borders q-mb-lg text-sm">
      <template #avatar>
        <q-icon name="check_circle" color="white" />
      </template>
      {{ successMsg }}
    </q-banner>

    <q-tab-panels v-model="activeTab" animated class="bg-transparent">
      <!-- General Settings Panel -->
      <q-tab-panel name="general" class="q-pa-none">
        <div class="row q-col-gutter-lg">
          <!-- Settings Form -->
          <div class="col-12 col-md-8">
            <q-card class="glass-card">
              <q-card-section class="q-py-md border-bottom">
                <div class="text-h6 text-bold text-slate-800">Branding & Appearance</div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <q-form @submit.prevent="saveSettings" class="q-gutter-y-md">
                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                      >Workspace Name (Read-Only)</label
                    >
                    <q-input v-model="workspaceName" filled disable class="custom-input" />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                      >Workspace Slug (Read-Only)</label
                    >
                    <q-input v-model="workspaceSlug" filled disable class="custom-input" />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                      >Branding Logo URL</label
                    >
                    <q-input
                      v-model="logoUrl"
                      type="url"
                      filled
                      placeholder="https://example.com/logo.png"
                      color="primary"
                      class="custom-input"
                      :disable="!canEdit"
                    />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                      >Theme Theme Color Hex</label
                    >
                    <q-input
                      v-model="themeColor"
                      filled
                      placeholder="#6366f1"
                      color="primary"
                      class="custom-input"
                      :disable="!canEdit"
                      :rules="[
                        (val) => !val || /^#[0-9A-F]{6}$/i.test(val) || 'Must be a valid hex color',
                      ]"
                      hide-bottom-space
                    >
                      <template #append>
                        <q-icon name="colorize" class="cursor-pointer">
                          <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                            <q-color v-model="themeColor" />
                          </q-popup-proxy>
                        </q-icon>
                      </template>
                    </q-input>
                  </div>

                  <div class="q-mt-xl" v-if="canEdit">
                    <q-btn
                      type="submit"
                      color="primary"
                      label="Save Changes"
                      class="q-px-lg rounded-btn btn-gradient text-weight-bold"
                      :loading="saving"
                    />
                  </div>
                </q-form>
              </q-card-section>
            </q-card>
          </div>

          <!-- Settings Overview/Help -->
          <div class="col-12 col-md-4">
            <q-card class="glass-card full-height">
              <q-card-section class="q-py-md border-bottom row items-center">
                <q-icon name="shield" size="24px" class="text-amber-800 q-mr-sm" />
                <div class="text-h6 text-bold text-slate-800">Access Scopes</div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <div class="text-subtitle2 q-mb-sm text-amber-9">Editing Privileges</div>
                <p class="text-sm text-slate-500 q-mb-lg">
                  Branding settings are only configurable by users with the
                  <span class="text-slate-800 text-weight-bold">Owner</span> or
                  <span class="text-slate-800 text-weight-bold">Admin</span> role. Normal members
                  can only view settings.
                </p>

                <div class="text-subtitle2 q-mb-sm text-indigo-8">Subscription Plan</div>
                <p class="text-sm text-slate-500">
                  Feature flags and subscription tiers are platform-level policies that can only be
                  altered by a platform superadmin in the superadmin portal.
                </p>
              </q-card-section>
            </q-card>
          </div>

          <!-- Danger Zone -->
          <div class="col-12 q-mt-lg" v-if="isOwner">
            <q-card class="glass-card border-danger">
              <q-card-section class="q-py-md border-bottom bg-red-50 text-red-900 row items-center">
                <q-icon name="warning" size="24px" class="q-mr-sm text-red-9" />
                <div class="text-h6 text-bold text-red-9">Danger Zone</div>
              </q-card-section>

              <q-card-section class="q-pa-md bg-white">
                <div class="row items-center justify-between no-wrap q-col-gutter-md">
                  <div class="col-12 col-sm-8">
                    <div class="text-subtitle2 text-bold text-slate-900">Delete Workspace</div>
                    <p class="text-sm text-slate-500 q-mb-none q-mt-xs">
                      Permanently delete this workspace and all associated data, including members,
                      settings, devices, shifts, and ledgers. This action is irreversible.
                    </p>
                  </div>
                  <div class="col-12 col-sm-4 text-right">
                    <q-btn
                      color="negative"
                      unelevated
                      label="Delete Workspace"
                      class="rounded-btn text-weight-bold cursor-pointer"
                      @click="showDeleteConfirm = true"
                    />
                  </div>
                </div>
              </q-card-section>
            </q-card>
          </div>
        </div>
      </q-tab-panel>

      <!-- Kiosk Terminals Panel -->
      <q-tab-panel name="kiosk" class="q-pa-none">
        <div class="row q-col-gutter-lg">
          <!-- Left Side: Paired Devices List -->
          <div class="col-12 col-md-8">
            <q-card class="glass-card">
              <q-card-section class="q-py-md border-bottom text-slate-800">
                <div class="text-h6 text-bold">Paired Terminal Devices</div>
              </q-card-section>

              <q-card-section class="q-pa-none">
                <q-table
                  :rows="pairedDevices"
                  :columns="deviceColumns"
                  row-key="id"
                  flat
                  bordered
                  dense
                  :loading="loadingDevices"
                  class="no-border text-slate-800"
                  :rows-per-page-options="[5, 10, 20]"
                >
                  <template #body-cell-status="props">
                    <q-td :props="props">
                      <q-badge
                        color="positive"
                        label="Active"
                        class="q-py-xs q-px-sm text-weight-bold"
                      />
                    </q-td>
                  </template>
                  <template #body-cell-paired_at="props">
                    <q-td :props="props">
                      {{ new Date(props.value).toLocaleString() }}
                    </q-td>
                  </template>
                  <template #body-cell-last_active_at="props">
                    <q-td :props="props">
                      {{ new Date(props.value).toLocaleString() }}
                    </q-td>
                  </template>
                  <template #body-cell-actions="props">
                    <q-td :props="props" align="right">
                      <q-btn
                        dense
                        color="red-5"
                        icon="link_off"
                        label="Disconnect"
                        class="q-px-sm rounded-btn text-weight-bold cursor-pointer"
                        size="sm"
                        unelevated
                        @click="confirmDisconnectDevice(props.row)"
                      />
                    </q-td>
                  </template>
                  <template #no-data>
                    <div class="full-width column flex-center text-slate-500 q-pa-xl text-center">
                      <q-icon name="devices_other" size="48px" class="q-mb-sm text-slate-400" />
                      <div class="text-subtitle1 text-weight-medium">
                        No Terminal Devices Paired
                      </div>
                      <p class="text-sm text-slate-400 q-mt-xs q-mb-none">
                        Generate a pairing code on the right to pair a kiosk terminal device.
                      </p>
                    </div>
                  </template>
                </q-table>
              </q-card-section>
            </q-card>
          </div>

          <!-- Right Side: Pairing Code Generator -->
          <div class="col-12 col-md-4">
            <q-card class="glass-card text-slate-800">
              <q-card-section class="q-py-md border-bottom">
                <div class="text-h6 text-bold">Generate Pairing Code</div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <div
                  v-if="activePairingCode"
                  class="column items-center text-center q-pa-md bg-indigo-50 border-indigo-100 rounded-borders border-all"
                >
                  <q-icon name="vpn_key" size="36px" color="primary" class="q-mb-sm" />
                  <div class="text-caption text-indigo-7 text-weight-bold">
                    ACTIVE PAIRING CODE FOR:
                  </div>
                  <div class="text-subtitle1 text-slate-900 text-weight-bold q-mb-md">
                    {{ activePairingDeviceName }}
                  </div>

                  <div
                    class="text-h4 text-primary text-weight-bolder tracking-widest q-mb-md font-mono select-all"
                  >
                    {{ activePairingCode.slice(0, 3) }} {{ activePairingCode.slice(3) }}
                  </div>

                  <div class="text-caption text-slate-500 q-mb-md">
                    Expires:
                    {{
                      activePairingExpires
                        ? new Date(activePairingExpires).toLocaleTimeString()
                        : 'N/A'
                    }}
                  </div>

                  <q-btn
                    color="red-5"
                    unelevated
                    label="Revoke Code"
                    icon="cancel"
                    class="full-width rounded-btn text-weight-bold cursor-pointer"
                    @click="handleRevokePairingCode"
                  />
                </div>

                <q-form v-else @submit.prevent="handleGeneratePairingCode" class="q-gutter-y-md">
                  <p class="text-sm text-slate-500 q-mb-none">
                    Generate a temporary 6-digit code to pair a kiosk counter device (valid for 30
                    minutes).
                  </p>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                      >Device Name / Label</label
                    >
                    <q-input
                      v-model="deviceNameInput"
                      filled
                      placeholder="e.g. Counter Tablet 1"
                      color="primary"
                      class="custom-input"
                      :rules="[(val) => !!val || 'Device name is required']"
                      hide-bottom-space
                    />
                  </div>

                  <q-btn
                    type="submit"
                    color="primary"
                    label="Generate Code"
                    icon="key"
                    class="full-width rounded-btn btn-gradient text-weight-bold cursor-pointer"
                    :loading="generatingCode"
                  />
                </q-form>
              </q-card-section>
            </q-card>
          </div>
        </div>
      </q-tab-panel>
    </q-tab-panels>

    <!-- Delete Confirmation Dialog -->
    <q-dialog v-model="showDeleteConfirm" persistent>
      <q-card
        style="width: 450px; max-width: 90vw; border-radius: 16px"
        class="q-pa-md bg-white text-slate-900"
      >
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-red-9">Delete Workspace</div>
          <q-space />
          <q-btn
            icon="close"
            flat
            round
            dense
            v-close-popup
            class="cursor-pointer text-slate-500"
            :disable="deleting"
          />
        </q-card-section>

        <q-card-section class="q-pt-md">
          <p class="text-sm text-slate-600 q-mb-md">
            This will permanently delete
            <span class="text-weight-bold text-slate-900">{{ workspaceName }}</span
            >. Please type the workspace slug
            <span class="text-weight-bold text-red-9 select-all font-mono">{{
              workspaceSlug
            }}</span>
            to confirm.
          </p>

          <q-input
            v-model="deleteConfirmSlug"
            type="text"
            filled
            placeholder="Type slug to confirm"
            color="negative"
            class="custom-input q-mb-md"
            hide-bottom-space
            :disable="deleting"
          />

          <div class="row justify-end q-gutter-sm">
            <q-btn
              flat
              label="Cancel"
              v-close-popup
              :disable="deleting"
              class="cursor-pointer text-slate-500"
            />
            <q-btn
              color="negative"
              label="Permanently Delete"
              :loading="deleting"
              :disabled="deleteConfirmSlug !== workspaceSlug"
              class="q-px-md cursor-pointer text-weight-bold rounded-btn"
              @click="handleDeleteWorkspace"
            />
          </div>
        </q-card-section>
      </q-card>
    </q-dialog>

    <!-- Disconnect Device Confirmation Dialog -->
    <q-dialog v-model="confirmDisconnect" persistent>
      <q-card
        style="width: 400px; max-width: 90vw; border-radius: 16px"
        class="q-pa-md bg-white text-slate-900"
      >
        <q-card-section class="column items-center text-center q-pt-md">
          <q-avatar size="48px" color="red-1" text-color="red-5" class="q-mb-md">
            <q-icon name="link_off" size="28px" />
          </q-avatar>
          <div class="text-h6 text-bold text-slate-800">Disconnect Terminal?</div>
          <p class="text-sm text-slate-500 q-mt-sm">
            Are you sure you want to disconnect
            <span class="text-weight-bold text-slate-900">{{
              deviceToDisconnect?.device_name
            }}</span
            >? It will immediately block access and logout the terminal.
          </p>
        </q-card-section>

        <q-card-actions align="right" class="q-gutter-sm">
          <q-btn
            flat
            label="Cancel"
            color="slate-500"
            v-close-popup
            class="cursor-pointer animate-fade"
          />
          <q-btn
            color="red"
            label="Disconnect"
            class="q-px-md text-weight-bold rounded-btn cursor-pointer"
            v-close-popup
            @click="deviceToDisconnect && handleDisconnectDevice(deviceToDisconnect.id)"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useQuasar } from 'quasar';
import { useTenantStore } from '../../stores/tenant';
import { updateTenantSettings, deleteTenant } from '../../services/multiTenant';
import { generatePairingCode } from '../../services/staff';
import { supabase } from '../../boot/supabase';

const router = useRouter();
const tenantStore = useTenantStore();
const $q = useQuasar();

const activeTab = ref('general');

const workspaceName = ref('');
const workspaceSlug = ref('');
const logoUrl = ref('');
const themeColor = ref('');

const saving = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

const showDeleteConfirm = ref(false);
const deleteConfirmSlug = ref('');
const deleting = ref(false);

interface PairedDevice {
  id: string;
  device_name: string;
  paired_at: string;
  last_active_at: string;
}

interface DeviceColumn {
  name: string;
  label: string;
  field: string | ((row: PairedDevice) => unknown);
  align?: 'left' | 'right' | 'center';
  sortable?: boolean;
}

// Kiosk Terminals tab state
const pairedDevices = ref<PairedDevice[]>([]);
const loadingDevices = ref(false);
const deviceNameInput = ref('Counter Tablet');
const activePairingCode = ref('');
const activePairingExpires = ref<string | null>(null);
const activePairingDeviceName = ref('');
const generatingCode = ref(false);

const confirmDisconnect = ref(false);
const deviceToDisconnect = ref<PairedDevice | null>(null);

const deviceColumns: DeviceColumn[] = [
  {
    name: 'device_name',
    label: 'Device Name',
    field: 'device_name',
    align: 'left',
    sortable: true,
  },
  { name: 'status', label: 'Status', field: 'status', align: 'left' },
  { name: 'paired_at', label: 'Paired At', field: 'paired_at', align: 'left', sortable: true },
  {
    name: 'last_active_at',
    label: 'Last Active',
    field: 'last_active_at',
    align: 'left',
    sortable: true,
  },
  { name: 'actions', label: 'Actions', field: 'actions', align: 'right' },
];

const isOwner = computed(() => {
  return tenantStore.activeRole === 'Owner' || tenantStore.isSuperadmin;
});

const canEdit = computed(() => {
  return (
    tenantStore.activeRole === 'Owner' ||
    tenantStore.activeRole === 'Admin' ||
    tenantStore.isSuperadmin
  );
});

const loadTenantSettingsData = () => {
  if (!tenantStore.activeTenant) return;
  workspaceName.value = tenantStore.activeTenant.name;
  workspaceSlug.value = tenantStore.activeTenant.slug;
  logoUrl.value = tenantStore.activeSettings?.logo_url || '';
  themeColor.value = tenantStore.activeSettings?.theme_color || '';
};

const saveSettings = async () => {
  if (!tenantStore.activeTenant) return;
  saving.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const updated = await updateTenantSettings(tenantStore.activeTenant.id, {
      logo_url: logoUrl.value || null,
      theme_color: themeColor.value || null,
    });

    // Refresh settings in store
    tenantStore.activeSettings = updated;
    successMsg.value = 'Workspace settings updated successfully!';
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to update settings.';
  } finally {
    saving.value = false;
  }
};

const handleDeleteWorkspace = async () => {
  if (!tenantStore.activeTenant) return;
  deleting.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const deletedId = tenantStore.activeTenant.id;
    await deleteTenant(deletedId);

    // Refresh store profile & membership list
    await tenantStore.loadUserProfileAndTenants();

    showDeleteConfirm.value = false;
    deleteConfirmSlug.value = '';

    // Check if there are other tenants available
    if (tenantStore.myTenants.length > 0) {
      const nextTenant = tenantStore.myTenants[0];
      const nextSlug = nextTenant?.tenants?.slug;
      if (nextSlug) {
        await tenantStore.setActiveTenantBySlug(nextSlug);
        await router.push(`/${nextSlug}/dashboard`);
        return;
      }
    }

    // No other workspaces left, redirect to no-tenant
    await router.push('/auth/no-tenant');
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to delete workspace.';
  } finally {
    deleting.value = false;
  }
};

// Kiosk methods
const loadPairedDevices = async () => {
  if (!tenantStore.activeTenant) return;
  loadingDevices.value = true;
  try {
    const { data, error } = await supabase
      .from('paired_devices')
      .select('id, device_name, paired_at, last_active_at')
      .eq('tenant_id', tenantStore.activeTenant.id)
      .order('paired_at', { ascending: false });

    if (error) throw error;
    pairedDevices.value = data || [];
  } catch (err) {
    console.error('Error loading paired devices:', err);
  } finally {
    loadingDevices.value = false;
  }
};

const loadActivePairingCodes = async () => {
  if (!tenantStore.activeTenant) return;
  try {
    const { data, error } = await supabase
      .from('device_pairings')
      .select('pairing_code, device_name, expires_at')
      .eq('tenant_id', tenantStore.activeTenant.id)
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (!error && data && data.length > 0) {
      const first = data[0];
      if (first) {
        activePairingCode.value = first.pairing_code;
        activePairingDeviceName.value = first.device_name;
        activePairingExpires.value = first.expires_at;
      }
    } else {
      activePairingCode.value = '';
      activePairingDeviceName.value = '';
      activePairingExpires.value = null;
    }
  } catch (err) {
    console.error('Error loading active pairing codes:', err);
  }
};

const handleGeneratePairingCode = async () => {
  if (!tenantStore.activeTenant) return;
  generatingCode.value = true;
  try {
    const code = await generatePairingCode(tenantStore.activeTenant.id, deviceNameInput.value);
    activePairingCode.value = code;
    activePairingDeviceName.value = deviceNameInput.value;

    // Set expires time to 30 mins from now
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 30);
    activePairingExpires.value = expires.toISOString();

    $q.notify({
      type: 'positive',
      message: 'Pairing code generated successfully!',
      position: 'top',
    });
  } catch (err) {
    const error = err as Error;
    $q.notify({
      type: 'negative',
      message: error.message || 'Failed to generate pairing code.',
      position: 'top',
    });
  } finally {
    generatingCode.value = false;
  }
};

const handleRevokePairingCode = async () => {
  if (!tenantStore.activeTenant) return;
  try {
    const { error } = await supabase
      .from('device_pairings')
      .delete()
      .eq('tenant_id', tenantStore.activeTenant.id)
      .eq('pairing_code', activePairingCode.value);

    if (error) throw error;

    activePairingCode.value = '';
    activePairingDeviceName.value = '';
    activePairingExpires.value = null;

    $q.notify({
      type: 'info',
      message: 'Pairing code revoked.',
      position: 'top',
    });
  } catch (err) {
    const error = err as Error;
    $q.notify({
      type: 'negative',
      message: error.message || 'Failed to revoke pairing code.',
      position: 'top',
    });
  }
};

const confirmDisconnectDevice = (device: PairedDevice) => {
  deviceToDisconnect.value = device;
  confirmDisconnect.value = true;
};

const handleDisconnectDevice = async (deviceId: string) => {
  try {
    const { error } = await supabase.from('paired_devices').delete().eq('id', deviceId);

    if (error) throw error;

    $q.notify({
      type: 'positive',
      message: 'Terminal device disconnected successfully.',
      position: 'top',
    });

    await loadPairedDevices();
  } catch (err) {
    const error = err as Error;
    $q.notify({
      type: 'negative',
      message: error.message || 'Failed to disconnect device.',
      position: 'top',
    });
  }
};

watch(activeTab, (newTab) => {
  if (newTab === 'kiosk') {
    void loadPairedDevices();
    void loadActivePairingCodes();
  }
});

onMounted(() => {
  loadTenantSettingsData();
  void loadPairedDevices();
  void loadActivePairingCodes();
});
</script>

<style scoped lang="scss">
.glass-card {
  background: #ffffff;
  border: 1px solid rgba(0, 0, 0, 0.06);
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
}

.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.rounded-btn {
  border-radius: 12px;
}

.btn-gradient {
  background: linear-gradient(135deg, #6366f1 0%, #06b6d4 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.15);
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
}

.border-danger {
  border: 1px solid rgba(239, 68, 68, 0.3) !important;
}
</style>
