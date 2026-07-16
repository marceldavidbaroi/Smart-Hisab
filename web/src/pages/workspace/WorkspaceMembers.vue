<template>
  <q-page class="q-pa-lg">
    <!-- Header Title Section -->
    <div class="row items-center justify-between q-mb-lg">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-800">Members & Kiosks</h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          Manage your organization team, kiosk staff profiles, and terminal device pairings.
        </p>
      </div>
      <div>
        <q-btn
          v-if="canManage && tab === 'team'"
          color="primary"
          icon="person_add"
          label="Invite Member"
          class="rounded-btn q-px-md cursor-pointer"
          @click="showInviteDialog = true"
        />
        <div v-else-if="canManage && tab === 'kiosk'" class="row q-gutter-x-sm no-wrap">
          <q-btn
            outline
            color="secondary"
            icon="devices"
            label="Pair New Device"
            class="rounded-btn q-px-md cursor-pointer"
            @click="showPairingDialog = true"
          />
          <q-btn
            color="primary"
            icon="add"
            label="Add Kiosk Staff"
            class="rounded-btn q-px-md cursor-pointer"
            @click="openAddStaff"
          />
        </div>
      </div>
    </div>

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

    <!-- Navigation Tabs -->
    <q-tabs
      v-model="tab"
      dense
      class="text-grey-7 q-mb-lg"
      active-color="primary"
      indicator-color="primary"
      align="left"
      narrow-indicator
    >
      <q-tab name="team" label="Team Members" class="cursor-pointer" />
      <q-tab name="kiosk" label="Kiosks & Staff" class="cursor-pointer" />
    </q-tabs>

    <q-tab-panels v-model="tab" animated class="bg-transparent">
      <!-- Tab 1: Team Members -->
      <q-tab-panel name="team" class="q-pa-none q-gutter-y-lg">
        <!-- Members List Table -->
        <q-card class="glass-card">
          <q-card-section class="q-py-md border-bottom row items-center justify-between">
            <div class="text-h6 text-bold text-slate-800">Team Members</div>
            <q-btn
              flat
              round
              dense
              icon="refresh"
              color="grey-7"
              @click="loadMembers"
              :loading="loadingMembers"
            />
          </q-card-section>

          <q-table
            :rows="members"
            :columns="columns"
            row-key="id"
            flat
            binary-state-sort
            class="bg-transparent border-none text-slate-800"
            :loading="loadingMembers"
            no-data-label="No members found in this workspace"
            dense
          >
            <!-- Custom Avatar and Profile Slot -->
            <template #body-cell-user="props">
              <q-td :props="props">
                <div class="row items-center no-wrap">
                  <q-avatar size="32px" class="q-mr-sm member-table-avatar">
                    <img
                      v-if="props.row.user_profile?.avatar_url"
                      :src="props.row.user_profile.avatar_url"
                    />
                    <span v-else>{{
                      getInitials(props.row.user_profile?.full_name || 'Member')
                    }}</span>
                  </q-avatar>
                  <div>
                    <div class="text-weight-bold">
                      {{ props.row.user_profile?.full_name || 'Unregistered User' }}
                    </div>
                    <div class="text-caption text-grey-6 font-mono">{{ props.row.user_id }}</div>
                  </div>
                </div>
              </q-td>
            </template>

            <!-- Custom Role Slot -->
            <template #body-cell-role="props">
              <q-td :props="props">
                <q-badge outline color="primary" class="q-py-xs q-px-sm font-semibold">
                  {{ props.row.tenant_roles?.name || 'Member' }}
                </q-badge>
              </q-td>
            </template>

            <!-- Custom Status Slot -->
            <template #body-cell-status="props">
              <q-td :props="props">
                <q-badge
                  :color="props.row.status === 'active' ? 'positive' : 'negative'"
                  class="text-weight-bold text-white uppercase"
                >
                  {{ props.row.status }}
                </q-badge>
              </q-td>
            </template>

            <!-- Custom Actions Slot -->
            <template #body-cell-actions="props">
              <q-td :props="props" class="text-right">
                <q-btn
                  v-if="
                    canManage &&
                    props.row.user_id !== tenantStore.user?.id &&
                    props.row.tenant_roles?.name !== 'Owner'
                  "
                  flat
                  round
                  dense
                  icon="delete"
                  color="negative"
                  @click="confirmRemove(props.row)"
                >
                  <q-tooltip>Remove Member</q-tooltip>
                </q-btn>
                <span v-else class="text-caption text-grey-5">N/A</span>
              </q-td>
            </template>
          </q-table>
        </q-card>
      </q-tab-panel>

      <!-- Tab 2: Kiosks & Staff -->
      <q-tab-panel name="kiosk" class="q-pa-none">
        <q-card class="glass-card">
          <q-card-section class="q-py-md border-bottom row items-center justify-between">
            <div class="text-h6 text-bold text-slate-800">Kiosk Staff Profiles</div>
            <q-btn
              flat
              round
              dense
              icon="refresh"
              color="grey-7"
              @click="loadStaff"
              :loading="loadingStaff"
            />
          </q-card-section>

          <q-table
            :rows="staff"
            :columns="staffColumns"
            row-key="id"
            flat
            binary-state-sort
            class="bg-transparent border-none text-slate-800"
            :loading="loadingStaff"
            no-data-label="No kiosk staff profiles configured yet."
            dense
          >
            <!-- Custom Terminal Login allowed toggle -->
            <template #body-cell-allow_terminal_login="props">
              <q-td :props="props">
                <q-toggle
                  v-model="props.row.allow_terminal_login"
                  :disable="!canManage"
                  color="primary"
                  @update:model-value="toggleTerminalLogin(props.row)"
                />
              </q-td>
            </template>

            <!-- Custom Active toggle -->
            <template #body-cell-is_active="props">
              <q-td :props="props">
                <q-toggle
                  v-model="props.row.is_active"
                  :disable="!canManage"
                  color="positive"
                  @update:model-value="toggleStaffActive(props.row)"
                />
              </q-td>
            </template>

            <!-- Custom Actions Slot -->
            <template #body-cell-actions="props">
              <q-td :props="props" class="text-right">
                <div class="row justify-end q-gutter-x-sm no-wrap">
                  <q-btn
                    v-if="canManage && props.row.allow_terminal_login"
                    flat
                    round
                    dense
                    icon="vpn_key"
                    color="secondary"
                    @click="handleResetStaffPin(props.row)"
                  >
                    <q-tooltip>Reset 4-Digit PIN</q-tooltip>
                  </q-btn>
                  <q-btn
                    v-if="canManage"
                    flat
                    round
                    dense
                    icon="edit"
                    color="primary"
                    @click="openEditStaff(props.row)"
                  >
                    <q-tooltip>Edit Profile</q-tooltip>
                  </q-btn>
                </div>
              </q-td>
            </template>
          </q-table>
        </q-card>
      </q-tab-panel>
    </q-tab-panels>

    <!-- 2. Invite Member Dialog -->
    <q-dialog v-model="showInviteDialog" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md dialog-card">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-slate-800">Invite New Member</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="handleInvite" class="q-gutter-y-md q-mt-md">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Email Address</label
              >
              <q-input
                v-model="inviteEmail"
                type="email"
                filled
                placeholder="collaborator@company.com"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || 'Email is required']"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Role Assignment</label
              >
              <q-select
                v-model="inviteRole"
                :options="rolesOptions"
                filled
                color="primary"
                class="custom-input"
                emit-value
                map-options
              />
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pt-md">
            <q-btn flat label="Cancel" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              color="primary"
              label="Send Invitation"
              class="q-px-md rounded-btn btn-gradient text-weight-bold"
              :loading="submittingInvite"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- 3. Confirm Remove Member Dialog -->
    <q-dialog v-model="showConfirmRemove" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md">
        <q-card-section class="row items-center">
          <q-avatar icon="warning" color="red-9" text-color="white" class="q-mr-md" />
          <span class="text-h6 text-bold text-slate-800">Remove Team Member?</span>
        </q-card-section>

        <q-card-section class="q-py-md text-slate-600">
          Are you sure you want to remove
          <span class="text-weight-bold text-slate-800">{{
            selectedMember?.user_profile?.full_name || 'this member'
          }}</span>
          from this workspace? This action will immediately revoke their access to all tenant-scoped
          resources.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" v-close-popup color="grey-7" />
          <q-btn
            flat
            label="Confirm Remove"
            color="negative"
            @click="handleRemove"
            :loading="removingMember"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- 4. Add/Edit Staff Dialog -->
    <q-dialog v-model="showStaffDialog" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md dialog-card">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-slate-800">
            {{ isEditingStaff ? 'Edit Kiosk Staff Profile' : 'Add Kiosk Staff Profile' }}
          </div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="handleStaffSubmit" class="q-gutter-y-md q-mt-md">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Full Name</label
              >
              <q-input
                v-model="staffName"
                type="text"
                filled
                placeholder="e.g. John Doe"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || 'Full name is required']"
                hide-bottom-space
              />
            </div>

            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Phone Number</label
              >
              <q-input
                v-model="staffPhone"
                type="tel"
                filled
                placeholder="e.g. +88017XXXXXXXX"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || 'Phone number is required']"
                hide-bottom-space
              />
            </div>

            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
                >Role / Job Title</label
              >
              <q-input
                v-model="staffRole"
                type="text"
                filled
                placeholder="e.g. Cook, Cashier, Server"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || 'Role is required']"
                hide-bottom-space
              />
            </div>

            <div class="row items-center justify-between q-mt-md">
              <div class="col-8">
                <div class="text-weight-medium text-slate-800 text-sm">Allow Terminal Login</div>
                <div class="text-caption text-grey-6">
                  Allow this profile to authenticate on paired kiosk devices via 4-digit PIN.
                </div>
              </div>
              <q-toggle v-model="staffAllowTerminalLogin" color="primary" />
            </div>

            <div v-if="isEditingStaff" class="row items-center justify-between q-mt-md">
              <div class="col-8">
                <div class="text-weight-medium text-slate-800 text-sm">Active Profile</div>
                <div class="text-caption text-grey-6">
                  Enable or temporarily disable this staff member.
                </div>
              </div>
              <q-toggle v-model="staffIsActive" color="positive" />
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pt-md">
            <q-btn flat label="Cancel" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              color="primary"
              label="Save Profile"
              class="q-px-md rounded-btn btn-gradient text-weight-bold"
              :loading="submittingStaff"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- 5. Temporary PIN Display Dialog -->
    <q-dialog v-model="showTempPinDialog" persistent>
      <q-card
        class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md"
        style="width: 100%; max-width: 400px"
      >
        <q-card-section class="text-center q-pt-md">
          <q-icon name="vpn_key" size="48px" color="warning" class="q-mb-md" />
          <div class="text-h6 text-bold text-slate-800">Temporary PIN Code</div>
          <p class="text-slate-500 text-sm q-mt-sm">
            Hand over this temporary PIN code to the staff member.
          </p>
        </q-card-section>

        <q-card-section class="text-center q-py-md">
          <div
            class="text-h3 text-bold text-primary font-mono tracking-widest bg-grey-2 q-pa-md rounded-borders inline-block"
          >
            {{ tempPinCode }}
          </div>
          <div class="text-caption text-red-9 text-weight-bold q-mt-md">
            Warning: This code will not be shown again. The staff member will be forced to change it
            on their first login.
          </div>
        </q-card-section>

        <q-card-actions align="center">
          <q-btn
            unelevated
            color="primary"
            label="Got It"
            v-close-popup
            class="q-px-lg rounded-btn text-weight-bold"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- 6. Device Pairing Dialog -->
    <q-dialog v-model="showPairingDialog" persistent>
      <q-card class="bg-slate-950 text-slate-800 border-all rounded-borders q-pa-md dialog-card">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-slate-800">Pair Terminal Device</div>
          <q-space />
          <q-btn
            icon="close"
            flat
            round
            dense
            v-close-popup
            color="grey-7"
            @click="closePairingDialog"
          />
        </q-card-section>

        <q-card-section class="q-pt-md">
          <p class="text-slate-600 text-sm">
            Enter a descriptive name for the device (e.g. Counter Tablet A) and generate a 6-digit
            verification code.
          </p>

          <div v-if="!pairingCode" class="q-mb-md">
            <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs"
              >Device Name</label
            >
            <q-input
              v-model="pairingDeviceName"
              type="text"
              filled
              placeholder="e.g. Counter Kiosk 1"
              color="primary"
              class="custom-input"
              hide-bottom-space
            />
            <q-btn
              color="primary"
              label="Generate Code"
              class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
              :loading="generatingPairing"
              @click="handleGeneratePairingCode"
            />
          </div>

          <div v-else class="text-center q-py-lg">
            <div class="text-h6 text-slate-500 q-mb-xs">
              Verification Code for {{ pairingDeviceName }}
            </div>
            <div
              class="text-h3 text-bold text-primary font-mono tracking-widest bg-grey-2 q-pa-md rounded-borders inline-block q-my-md"
            >
              {{ formatPairingCode(pairingCode) }}
            </div>
            <div class="text-caption text-grey-6 text-weight-medium">
              Enter this code on the target device's Pairing Screen.<br />
              This code is valid for 30 minutes.
            </div>
          </div>
        </q-card-section>

        <q-card-actions align="right" class="q-px-md q-pb-md">
          <q-btn flat label="Close" v-close-popup color="grey-7" @click="closePairingDialog" />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useTenantStore } from '../../stores/tenant';
import {
  getTenantMembers,
  getTenantRoles,
  inviteUser,
  removeMember,
} from '../../services/multiTenant';
import {
  getStaffMembers,
  createStaffMember,
  updateStaffMember,
  resetStaffPin,
  generatePairingCode,
} from '../../services/staff';
import type { StaffMember } from '../../services/staff';

export interface MemberWithProfile {
  id: string;
  status: string;
  joined_at: string;
  user_id: string;
  tenant_roles: {
    id: string;
    name: string;
    description: string | null;
  } | null;
  user_profile: {
    id: string;
    full_name: string;
    avatar_url: string | null;
  } | null;
}

const tenantStore = useTenantStore();

// Tab state
const tab = ref('team');

// Team Members state
const members = ref<MemberWithProfile[]>([]);
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const roles = ref<any[]>([]);
const loadingMembers = ref(false);

const errorMsg = ref('');
const successMsg = ref('');

const showInviteDialog = ref(false);
const inviteEmail = ref('');
const inviteRole = ref('');
const submittingInvite = ref(false);

const showConfirmRemove = ref(false);
const selectedMember = ref<MemberWithProfile | null>(null);
const removingMember = ref(false);

// Kiosk Kiosk & Staff state
const staff = ref<StaffMember[]>([]);
const loadingStaff = ref(false);
const submittingStaff = ref(false);

const showStaffDialog = ref(false);
const isEditingStaff = ref(false);
const selectedStaffId = ref('');
const staffName = ref('');
const staffRole = ref('');
const staffPhone = ref('');
const staffAllowTerminalLogin = ref(false);
const staffIsActive = ref(true);

const showTempPinDialog = ref(false);
const tempPinCode = ref('');

const showPairingDialog = ref(false);
const pairingDeviceName = ref('Counter Tablet');
const pairingCode = ref('');
const generatingPairing = ref(false);

const columns = [
  {
    name: 'user',
    align: 'left' as const,
    label: 'Name / ID',
    field: 'user_profile',
    sortable: true,
  },
  { name: 'role', align: 'left' as const, label: 'Role', field: 'tenant_roles', sortable: true },
  { name: 'status', align: 'left' as const, label: 'Status', field: 'status', sortable: true },
  { name: 'actions', align: 'right' as const, label: 'Actions', field: 'actions' },
];

const staffColumns = [
  {
    name: 'full_name',
    align: 'left' as const,
    label: 'Full Name',
    field: 'full_name',
    sortable: true,
  },
  {
    name: 'role',
    align: 'left' as const,
    label: 'Role / Job Title',
    field: 'role',
    sortable: true,
  },
  { name: 'phone', align: 'left' as const, label: 'Phone Number', field: 'phone', sortable: true },
  {
    name: 'allow_terminal_login',
    align: 'center' as const,
    label: 'Terminal Access',
    field: 'allow_terminal_login',
  },
  { name: 'is_active', align: 'center' as const, label: 'Active', field: 'is_active' },
  { name: 'actions', align: 'right' as const, label: 'Actions', field: 'actions' },
];

const canManage = computed(() => {
  return (
    tenantStore.activeRole === 'Owner' ||
    tenantStore.activeRole === 'Admin' ||
    tenantStore.isSuperadmin
  );
});

const rolesOptions = computed(() => {
  return roles.value.map((r) => ({
    label: `${r.name} - ${r.description || ''}`,
    value: r.id,
  }));
});

const getInitials = (name: string) => {
  if (!name) return 'MB';
  return name
    .split(' ')
    .map((word) => word[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();
};

const loadMembers = async () => {
  if (!tenantStore.activeTenant) return;
  loadingMembers.value = true;
  errorMsg.value = '';
  try {
    const list = await getTenantMembers(tenantStore.activeTenant.id);
    members.value = (list || []) as unknown as MemberWithProfile[];
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to load workspace members.';
  } finally {
    loadingMembers.value = false;
  }
};

const loadRoles = async () => {
  if (!tenantStore.activeTenant) return;
  try {
    const list = await getTenantRoles(tenantStore.activeTenant.id);
    roles.value = list || [];
    if (list && list.length > 0) {
      const memberRole = list.find((r) => r.name === 'Member') || list[0];
      inviteRole.value = memberRole.id;
    }
  } catch (err) {
    console.error('Failed to load roles:', err);
  }
};

const handleInvite = async () => {
  if (!tenantStore.activeTenant) return;
  submittingInvite.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    await inviteUser(tenantStore.activeTenant.id, inviteEmail.value, inviteRole.value);
    successMsg.value = `Successfully invited ${inviteEmail.value} to this workspace!`;
    showInviteDialog.value = false;
    inviteEmail.value = '';
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to send invitation.';
  } finally {
    submittingInvite.value = false;
  }
};

const confirmRemove = (member: MemberWithProfile) => {
  selectedMember.value = member;
  showConfirmRemove.value = true;
};

const handleRemove = async () => {
  if (!tenantStore.activeTenant || !selectedMember.value) return;
  removingMember.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    await removeMember(tenantStore.activeTenant.id, selectedMember.value.user_id);
    successMsg.value = `Successfully removed ${selectedMember.value.user_profile?.full_name || 'member'} from this workspace.`;
    showConfirmRemove.value = false;
    selectedMember.value = null;
    await loadMembers();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to remove member.';
    showConfirmRemove.value = false;
  } finally {
    removingMember.value = false;
  }
};

// Kiosk & Staff Management methods
const loadStaff = async () => {
  if (!tenantStore.activeTenant) return;
  loadingStaff.value = true;
  try {
    const data = await getStaffMembers(tenantStore.activeTenant.id);
    staff.value = data || [];
  } catch (err) {
    const error = err as Error;
    console.error('Failed to load staff profiles:', error.message);
  } finally {
    loadingStaff.value = false;
  }
};

const openAddStaff = () => {
  isEditingStaff.value = false;
  selectedStaffId.value = '';
  staffName.value = '';
  staffRole.value = '';
  staffPhone.value = '';
  staffAllowTerminalLogin.value = false;
  staffIsActive.value = true;
  showStaffDialog.value = true;
};

const openEditStaff = (staffMember: StaffMember) => {
  isEditingStaff.value = true;
  selectedStaffId.value = staffMember.id;
  staffName.value = staffMember.full_name;
  staffRole.value = staffMember.role;
  staffPhone.value = staffMember.phone;
  staffAllowTerminalLogin.value = staffMember.allow_terminal_login;
  staffIsActive.value = staffMember.is_active;
  showStaffDialog.value = true;
};

const handleStaffSubmit = async () => {
  if (!tenantStore.activeTenant) return;
  submittingStaff.value = true;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    if (isEditingStaff.value) {
      await updateStaffMember(selectedStaffId.value, {
        full_name: staffName.value,
        role: staffRole.value,
        phone: staffPhone.value,
        allow_terminal_login: staffAllowTerminalLogin.value,
        is_active: staffIsActive.value,
      });
      successMsg.value = `Successfully updated staff member ${staffName.value}.`;
      showStaffDialog.value = false;
    } else {
      const newStaff = await createStaffMember({
        tenant_id: tenantStore.activeTenant.id,
        full_name: staffName.value,
        role: staffRole.value,
        phone: staffPhone.value,
        allow_terminal_login: staffAllowTerminalLogin.value,
      });
      successMsg.value = `Successfully added staff member ${staffName.value}.`;
      showStaffDialog.value = false;

      if (staffAllowTerminalLogin.value) {
        const pin = await resetStaffPin(newStaff.id);
        tempPinCode.value = pin;
        showTempPinDialog.value = true;
      }
    }
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to save staff member.';
  } finally {
    submittingStaff.value = false;
  }
};

const handleResetStaffPin = async (staffMember: StaffMember) => {
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const pin = await resetStaffPin(staffMember.id);
    tempPinCode.value = pin;
    showTempPinDialog.value = true;
    successMsg.value = `PIN reset successfully for ${staffMember.full_name}.`;
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to reset staff PIN.';
  }
};

const toggleTerminalLogin = async (staffMember: StaffMember) => {
  try {
    await updateStaffMember(staffMember.id, {
      allow_terminal_login: staffMember.allow_terminal_login,
    });
    successMsg.value = `Updated terminal access for ${staffMember.full_name}.`;
    if (staffMember.allow_terminal_login && !staffMember.temp_pin && !staffMember.hashed_pin) {
      const pin = await resetStaffPin(staffMember.id);
      tempPinCode.value = pin;
      showTempPinDialog.value = true;
    }
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to update terminal access.';
    staffMember.allow_terminal_login = !staffMember.allow_terminal_login;
  }
};

const toggleStaffActive = async (staffMember: StaffMember) => {
  try {
    await updateStaffMember(staffMember.id, {
      is_active: staffMember.is_active,
    });
    successMsg.value = `Updated active status for ${staffMember.full_name}.`;
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to update active status.';
    staffMember.is_active = !staffMember.is_active;
  }
};

const handleGeneratePairingCode = async () => {
  if (!tenantStore.activeTenant) return;
  generatingPairing.value = true;
  errorMsg.value = '';
  try {
    const code = await generatePairingCode(tenantStore.activeTenant.id, pairingDeviceName.value);
    pairingCode.value = code;
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || 'Failed to generate pairing code.';
  } finally {
    generatingPairing.value = false;
  }
};

const formatPairingCode = (code: string) => {
  if (!code) return '';
  if (code.length === 6) {
    return `${code.slice(0, 3)} ${code.slice(3)}`;
  }
  return code;
};

const closePairingDialog = () => {
  showPairingDialog.value = false;
  pairingCode.value = '';
  pairingDeviceName.value = 'Counter Tablet';
};

onMounted(() => {
  void loadMembers();
  void loadRoles();
  void loadStaff();
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

.member-table-avatar {
  background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%);
  color: white;
  font-weight: 700;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.dialog-card {
  width: 100%;
  max-width: 500px;
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

.bg-slate-950 {
  background-color: #ffffff !important;
}

.cursor-pointer {
  cursor: pointer;
}
</style>
