<template>
  <q-page class="q-pa-lg">
    <!-- Header Title Section -->
    <div class="row items-center justify-between q-mb-lg">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-800">
          {{ $t('workspace.members.title') }}
        </h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          {{ $t('workspace.members.subtitle') }}
        </p>
      </div>
      <div>
        <q-btn
          v-if="canManage && tab === 'team'"
          color="primary"
          icon="person_add"
          :label="$t('workspace.members.inviteMemberBtn')"
          class="rounded-btn q-px-md cursor-pointer"
          @click="showInviteDialog = true"
        />
        <div v-else-if="canManage && tab === 'kiosk'" class="row q-gutter-x-sm no-wrap">
          <q-btn
            outline
            color="secondary"
            icon="devices"
            :label="$t('workspace.members.pairDeviceBtn')"
            class="rounded-btn q-px-md cursor-pointer"
            @click="showPairingDialog = true"
          />
          <q-btn
            color="primary"
            icon="add"
            :label="$t('workspace.members.addStaffBtn')"
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
      <q-tab name="team" :label="$t('workspace.members.tabs.team')" class="cursor-pointer" />
      <q-tab name="kiosk" :label="$t('workspace.members.tabs.kiosk')" class="cursor-pointer" />
      <q-tab
        name="staff-roles"
        :label="$t('workspace.members.tabs.roles')"
        class="cursor-pointer"
        v-if="tenantStore.isFeatureEnabled('shift-sessions')"
      />
    </q-tabs>

    <q-tab-panels v-model="tab" animated class="bg-transparent">
      <!-- Tab 1: Team Members -->
      <q-tab-panel name="team" class="q-pa-none q-gutter-y-lg">
        <!-- Members List Table -->
        <q-card class="glass-card">
          <q-card-section class="q-py-md border-bottom row items-center justify-between">
            <div class="text-h6 text-bold text-slate-800">
              {{ $t('workspace.members.teamTable.title') }}
            </div>
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
            :no-data-label="$t('workspace.members.teamTable.noData')"
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
                      {{
                        props.row.user_profile?.full_name ||
                        $t('workspace.members.teamTable.unregistered')
                      }}
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
                  <q-tooltip>{{ $t('workspace.members.teamTable.removeTooltip') }}</q-tooltip>
                </q-btn>
                <span v-else class="text-caption text-grey-5">{{
                  $t('workspace.members.teamTable.na')
                }}</span>
              </q-td>
            </template>
          </q-table>
        </q-card>
      </q-tab-panel>

      <!-- Tab 2: Kiosks & Staff -->
      <q-tab-panel name="kiosk" class="q-pa-none">
        <q-card class="glass-card">
          <q-card-section class="q-py-md border-bottom row items-center justify-between">
            <div class="text-h6 text-bold text-slate-800">
              {{ $t('workspace.members.kioskTable.title') }}
            </div>
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
            :no-data-label="$t('workspace.members.kioskTable.noData')"
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
                    <q-tooltip>{{ $t('workspace.members.kioskTable.resetPinTooltip') }}</q-tooltip>
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
                    <q-tooltip>{{
                      $t('workspace.members.kioskTable.editProfileTooltip')
                    }}</q-tooltip>
                  </q-btn>
                </div>
              </q-td>
            </template>
          </q-table>
        </q-card>
      </q-tab-panel>

      <!-- Tab 3: Staff Roles -->
      <q-tab-panel
        name="staff-roles"
        class="q-pa-none q-gutter-y-lg"
        v-if="tenantStore.isFeatureEnabled('shift-sessions')"
      >
        <q-card class="glass-card border-all bg-white text-dark">
          <q-card-section class="q-py-md border-bottom row items-center justify-between">
            <div>
              <div class="text-h6 text-bold text-slate-800">
                {{ $t('workspace.members.rolesTable.title') }}
              </div>
              <div class="text-caption text-grey-6">
                {{ $t('workspace.members.rolesTable.subtitle') }}
              </div>
            </div>
            <q-btn
              color="primary"
              icon="add"
              :label="$t('workspace.members.rolesTable.createBtn')"
              unelevated
              dense
              class="q-px-sm rounded-btn"
              style="min-height: 40px"
              @click="openCreateRoleDialog"
            />
          </q-card-section>

          <q-table
            :rows="staffRoles"
            :columns="roleColumns"
            row-key="id"
            flat
            binary-state-sort
            class="bg-transparent border-none text-slate-800"
            :loading="loadingRoles"
            :no-data-label="$t('workspace.members.rolesTable.noData')"
            dense
          >
            <!-- Custom System Role badge -->
            <template #body-cell-is_system_role="props">
              <q-td :props="props">
                <q-badge
                  :color="props.value ? 'primary' : 'warning'"
                  class="text-weight-bold uppercase q-py-xs q-px-sm"
                >
                  {{
                    props.value
                      ? $t('workspace.members.rolesTable.system')
                      : $t('workspace.members.rolesTable.custom')
                  }}
                </q-badge>
              </q-td>
            </template>

            <!-- Actions -->
            <template #body-cell-actions="props">
              <q-td :props="props" class="q-gutter-x-sm">
                <q-btn
                  flat
                  dense
                  color="primary"
                  icon="edit"
                  :label="$t('common.edit')"
                  class="text-weight-bold"
                  @click="openEditRoleDialog(props.row)"
                />
                <q-btn
                  flat
                  dense
                  color="negative"
                  icon="delete"
                  :label="$t('common.delete')"
                  class="text-weight-bold"
                  v-if="!props.row.is_system_role"
                  @click="confirmDeleteRole(props.row)"
                />
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
          <div class="text-h6 text-bold text-slate-800">
            {{ $t('workspace.members.inviteDialog.title') }}
          </div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="handleInvite" class="q-gutter-y-md q-mt-md">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                $t('workspace.members.inviteDialog.emailLabel')
              }}</label>
              <q-input
                v-model="inviteEmail"
                type="email"
                filled
                :placeholder="$t('workspace.members.inviteDialog.emailPlaceholder')"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || $t('workspace.members.inviteDialog.emailRequired')]"
                hide-bottom-space
              />
            </div>

            <div>
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                $t('workspace.members.inviteDialog.roleLabel')
              }}</label>
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
            <q-btn flat :label="$t('common.cancel')" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              color="primary"
              :label="$t('workspace.members.inviteDialog.sendBtn')"
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
          <span class="text-h6 text-bold text-slate-800">{{
            $t('workspace.members.removeDialog.title')
          }}</span>
        </q-card-section>

        <q-card-section class="q-py-md text-slate-600">
          {{
            $t('workspace.members.removeDialog.message', {
              name: selectedMember?.user_profile?.full_name || '',
            })
          }}
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat :label="$t('common.cancel')" v-close-popup color="grey-7" />
          <q-btn
            flat
            :label="$t('workspace.members.removeDialog.confirmBtn')"
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
            {{
              isEditingStaff
                ? $t('workspace.members.staffDialog.editTitle')
                : $t('workspace.members.staffDialog.addTitle')
            }}
          </div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup color="grey-7" />
        </q-card-section>

        <q-form @submit.prevent="handleStaffSubmit" class="q-gutter-y-md q-mt-md">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                $t('workspace.members.staffDialog.fullName')
              }}</label>
              <q-input
                v-model="staffName"
                type="text"
                filled
                :placeholder="$t('workspace.members.staffDialog.fullNamePlaceholder')"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || $t('workspace.members.staffDialog.fullNameRequired')]"
                hide-bottom-space
              />
            </div>

            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                $t('workspace.members.staffDialog.phone')
              }}</label>
              <q-input
                v-model="staffPhone"
                type="tel"
                filled
                :placeholder="$t('workspace.members.staffDialog.phonePlaceholder')"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || $t('workspace.members.staffDialog.phoneRequired')]"
                hide-bottom-space
              />
            </div>

            <div class="q-mb-md">
              <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                $t('workspace.members.staffDialog.roleLabel')
              }}</label>
              <q-select
                v-model="staffRole"
                :options="roleOptions"
                emit-value
                map-options
                filled
                dense
                :placeholder="$t('workspace.members.staffDialog.rolePlaceholder')"
                color="primary"
                class="custom-input"
                :rules="[
                  (val: string) => !!val || $t('workspace.members.staffDialog.roleRequired'),
                ]"
                hide-bottom-space
                v-if="tenantStore.isFeatureEnabled('shift-sessions')"
              />
              <q-input
                v-else
                v-model="staffRole"
                type="text"
                filled
                :placeholder="$t('workspace.members.staffDialog.roleInputPlaceholder')"
                color="primary"
                class="custom-input"
                :rules="[
                  (val: string) => !!val || $t('workspace.members.staffDialog.roleRequired'),
                ]"
                hide-bottom-space
              />
            </div>

            <div class="row items-center justify-between q-mt-md">
              <div class="col-8">
                <div class="text-weight-medium text-slate-800 text-sm">
                  {{ $t('workspace.members.staffDialog.allowTerminal') }}
                </div>
                <div class="text-caption text-grey-6">
                  {{ $t('workspace.members.staffDialog.allowTerminalDesc') }}
                </div>
              </div>
              <q-toggle v-model="staffAllowTerminalLogin" color="primary" />
            </div>

            <div v-if="isEditingStaff" class="row items-center justify-between q-mt-md">
              <div class="col-8">
                <div class="text-weight-medium text-slate-800 text-sm">
                  {{ $t('workspace.members.staffDialog.activeProfile') }}
                </div>
                <div class="text-caption text-grey-6">
                  {{ $t('workspace.members.staffDialog.activeProfileDesc') }}
                </div>
              </div>
              <q-toggle v-model="staffIsActive" color="positive" />
            </div>
          </q-card-section>

          <q-card-actions align="right" class="q-px-md q-pt-md">
            <q-btn flat :label="$t('common.cancel')" v-close-popup color="grey-7" />
            <q-btn
              type="submit"
              color="primary"
              :label="$t('workspace.members.staffDialog.saveBtn')"
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
          <div class="text-h6 text-bold text-slate-800">
            {{ $t('workspace.members.tempPinDialog.title') }}
          </div>
          <p class="text-slate-500 text-sm q-mt-sm">
            {{ $t('workspace.members.tempPinDialog.subtitle') }}
          </p>
        </q-card-section>

        <q-card-section class="text-center q-py-md">
          <div
            class="text-h3 text-bold text-primary font-mono tracking-widest bg-grey-2 q-pa-md rounded-borders inline-block"
          >
            {{ tempPinCode }}
          </div>
          <div class="text-caption text-red-9 text-weight-bold q-mt-md">
            {{ $t('workspace.members.tempPinDialog.warning') }}
          </div>
        </q-card-section>

        <q-card-actions align="center">
          <q-btn
            unelevated
            color="primary"
            :label="$t('workspace.members.tempPinDialog.gotItBtn')"
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
          <div class="text-h6 text-bold text-slate-800">
            {{ $t('workspace.members.pairDialog.title') }}
          </div>
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
            {{ $t('workspace.members.pairDialog.subtitle') }}
          </p>

          <div v-if="!pairingCode" class="q-mb-md">
            <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
              $t('workspace.members.pairDialog.deviceName')
            }}</label>
            <q-input
              v-model="pairingDeviceName"
              type="text"
              filled
              :placeholder="$t('workspace.members.pairDialog.deviceNamePlaceholder')"
              color="primary"
              class="custom-input"
              hide-bottom-space
            />
            <q-btn
              color="primary"
              :label="$t('workspace.members.pairDialog.generateBtn')"
              class="full-width q-py-sm rounded-btn btn-gradient q-mt-lg text-weight-bold"
              :loading="generatingPairing"
              @click="handleGeneratePairingCode"
            />
          </div>

          <div v-else class="text-center q-py-lg">
            <div class="text-h6 text-slate-500 q-mb-xs">
              {{
                $t('workspace.members.pairDialog.verificationTitle', { device: pairingDeviceName })
              }}
            </div>
            <div
              class="text-h3 text-bold text-primary font-mono tracking-widest bg-grey-2 q-pa-md rounded-borders inline-block q-my-md"
            >
              {{ formatPairingCode(pairingCode) }}
            </div>
            <div class="text-caption text-grey-6 text-weight-medium">
              {{ $t('workspace.members.pairDialog.verificationDesc') }}
            </div>
          </div>
        </q-card-section>

        <q-card-actions align="right" class="q-px-md q-pb-md">
          <q-btn
            flat
            :label="$t('common.close')"
            v-close-popup
            color="grey-7"
            @click="closePairingDialog"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Staff Role Dialog -->
    <q-dialog v-model="showRoleDialog" persistent>
      <q-card
        class="bg-white text-dark border-all rounded-borders dialog-card q-pa-md"
        style="width: 500px; max-width: 90vw"
      >
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold">
            {{
              isEditingRole
                ? $t('workspace.members.roleDialog.editTitle')
                : $t('workspace.members.roleDialog.addTitle')
            }}
          </div>
          <q-space />
          <q-btn
            icon="close"
            flat
            round
            dense
            v-close-popup
            color="grey-7"
            :disable="submittingRole"
          />
        </q-card-section>

        <q-form @submit.prevent="handleRoleSubmit" class="q-gutter-y-md q-mt-sm">
          <q-card-section class="q-py-none">
            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('workspace.members.roleDialog.roleName')
              }}</label>
              <q-input
                v-model="roleForm.name"
                type="text"
                filled
                dense
                placeholder="e.g. Lead Chef, Assistant"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || $t('workspace.members.roleDialog.roleNameRequired')]"
                hide-bottom-space
                :disabled="roleForm.is_system_role"
              />
            </div>

            <div class="q-mb-md">
              <label class="block text-caption text-grey-7 text-weight-medium q-mb-xs">{{
                $t('workspace.members.roleDialog.description')
              }}</label>
              <q-input
                v-model="roleForm.description"
                type="textarea"
                filled
                color="primary"
                class="custom-input"
                rows="2"
                :placeholder="$t('workspace.members.roleDialog.descriptionPlaceholder')"
                :disabled="roleForm.is_system_role"
              />
            </div>

            <!-- Permission toggles -->
            <div class="text-subtitle2 text-weight-bold text-slate-800 q-mb-sm">
              {{ $t('workspace.members.roleDialog.capabilities') }}
            </div>

            <q-list bordered separator class="rounded-borders q-pa-sm">
              <div
                class="text-caption text-grey-6 text-weight-medium q-px-sm q-py-xs uppercase bg-grey-2"
              >
                {{ $t('workspace.members.roleDialog.sections.sessions') }}
              </div>
              <q-item tag="label" v-ripple dense>
                <q-item-section>
                  <q-item-label class="text-sm">{{
                    $t('workspace.members.roleDialog.perms.openSession')
                  }}</q-item-label>
                  <q-item-label caption>{{
                    $t('workspace.members.roleDialog.perms.openSessionDesc')
                  }}</q-item-label>
                </q-item-section>
                <q-item-section side>
                  <q-toggle
                    v-model="roleForm.permissions.modules.operational_shifts.sessions_open"
                    color="primary"
                  />
                </q-item-section>
              </q-item>

              <q-item tag="label" v-ripple dense>
                <q-item-section>
                  <q-item-label class="text-sm">{{
                    $t('workspace.members.roleDialog.perms.closeSession')
                  }}</q-item-label>
                  <q-item-label caption>{{
                    $t('workspace.members.roleDialog.perms.closeSessionDesc')
                  }}</q-item-label>
                </q-item-section>
                <q-item-section side>
                  <q-toggle
                    v-model="roleForm.permissions.modules.operational_shifts.sessions_close"
                    color="primary"
                  />
                </q-item-section>
              </q-item>

              <div
                class="text-caption text-grey-6 text-weight-medium q-px-sm q-py-xs uppercase bg-grey-2 q-mt-sm"
              >
                {{ $t('workspace.members.roleDialog.sections.kioskMutating') }}
              </div>
              <q-item tag="label" v-ripple dense>
                <q-item-section>
                  <q-item-label class="text-sm">{{
                    $t('workspace.members.roleDialog.perms.posSales')
                  }}</q-item-label>
                  <q-item-label caption>{{
                    $t('workspace.members.roleDialog.perms.posSalesDesc')
                  }}</q-item-label>
                </q-item-section>
                <q-item-section side>
                  <q-toggle v-model="roleForm.permissions.modules.kiosk.log_pos" color="primary" />
                </q-item-section>
              </q-item>

              <q-item tag="label" v-ripple dense>
                <q-item-section>
                  <q-item-label class="text-sm">{{
                    $t('workspace.members.roleDialog.perms.bazaarExp')
                  }}</q-item-label>
                  <q-item-label caption>{{
                    $t('workspace.members.roleDialog.perms.bazaarExpDesc')
                  }}</q-item-label>
                </q-item-section>
                <q-item-section side>
                  <q-toggle
                    v-model="roleForm.permissions.modules.kiosk.log_expense"
                    color="primary"
                  />
                </q-item-section>
              </q-item>

              <q-item tag="label" v-ripple dense>
                <q-item-section>
                  <q-item-label class="text-sm">{{
                    $t('workspace.members.roleDialog.perms.salaryAdvance')
                  }}</q-item-label>
                  <q-item-label caption>{{
                    $t('workspace.members.roleDialog.perms.salaryAdvanceDesc')
                  }}</q-item-label>
                </q-item-section>
                <q-item-section side>
                  <q-toggle
                    v-model="roleForm.permissions.modules.kiosk.log_advance"
                    color="primary"
                  />
                </q-item-section>
              </q-item>
            </q-list>
          </q-card-section>

          <q-card-actions align="right">
            <q-btn
              flat
              :label="$t('common.cancel')"
              v-close-popup
              color="grey-7"
              :disable="submittingRole"
            />
            <q-btn
              type="submit"
              :label="
                isEditingRole
                  ? $t('workspace.members.roleDialog.saveBtn')
                  : $t('workspace.members.roleDialog.createBtn')
              "
              color="primary"
              class="q-px-md text-weight-bold"
              unelevated
              dense
              :loading="submittingRole"
              style="min-height: 40px"
            />
          </q-card-actions>
        </q-form>
      </q-card>
    </q-dialog>

    <!-- Confirm Delete Role Dialog -->
    <q-dialog v-model="showConfirmDeleteRole" persistent>
      <q-card class="bg-white text-dark border-all rounded-borders q-pa-md">
        <q-card-section class="row items-center">
          <q-avatar icon="delete" color="red-1" text-color="red-9" class="q-mr-md" />
          <span class="text-h6 text-weight-bold">{{
            $t('workspace.members.deleteRoleDialog.title')
          }}</span>
        </q-card-section>

        <q-card-section class="q-py-md text-grey-7">
          {{ $t('workspace.members.deleteRoleDialog.message', { name: roleToDelete?.name || '' }) }}
        </q-card-section>

        <q-card-actions align="right">
          <q-btn
            flat
            :label="$t('common.cancel')"
            v-close-popup
            color="grey-7"
            :disable="deletingRole"
          />
          <q-btn
            flat
            :label="$t('common.delete')"
            color="red-5"
            @click="handleDeleteRole"
            :loading="deletingRole"
            class="text-weight-bold"
          />
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
import { supabase } from '../../boot/supabase';
import { showSuccess, showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const tenantStore = useTenantStore();
const { t } = useI18n();

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

const columns = computed(() => [
  {
    name: 'user',
    align: 'left' as const,
    label: t('workspace.members.teamTable.cols.nameId'),
    field: 'user_profile',
    sortable: true,
  },
  {
    name: 'role',
    align: 'left' as const,
    label: t('workspace.members.teamTable.cols.role'),
    field: 'tenant_roles',
    sortable: true,
  },
  {
    name: 'status',
    align: 'left' as const,
    label: t('workspace.members.teamTable.cols.status'),
    field: 'status',
    sortable: true,
  },
  {
    name: 'actions',
    align: 'right' as const,
    label: t('workspace.members.teamTable.cols.actions'),
    field: 'actions',
  },
]);

const staffColumns = computed(() => [
  {
    name: 'full_name',
    align: 'left' as const,
    label: t('workspace.members.kioskTable.cols.name'),
    field: 'full_name',
    sortable: true,
  },
  {
    name: 'role',
    align: 'left' as const,
    label: t('workspace.members.kioskTable.cols.role'),
    field: 'role',
    sortable: true,
  },
  {
    name: 'phone',
    align: 'left' as const,
    label: t('workspace.members.kioskTable.cols.phone'),
    field: 'phone',
    sortable: true,
  },
  {
    name: 'allow_terminal_login',
    align: 'center' as const,
    label: t('workspace.members.kioskTable.cols.terminalAccess'),
    field: 'allow_terminal_login',
  },
  {
    name: 'is_active',
    align: 'center' as const,
    label: t('workspace.members.kioskTable.cols.active'),
    field: 'is_active',
  },
  {
    name: 'actions',
    align: 'right' as const,
    label: t('workspace.members.kioskTable.cols.actions'),
    field: 'actions',
  },
]);

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
    errorMsg.value = error.message || t('workspace.members.messages.loadMembersFailed');
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
    successMsg.value = t('workspace.members.messages.inviteSuccess', { email: inviteEmail.value });
    showInviteDialog.value = false;
    inviteEmail.value = '';
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('workspace.members.messages.inviteFailed');
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
    successMsg.value = t('workspace.members.messages.removeSuccess', {
      name: selectedMember.value.user_profile?.full_name || '',
    });
    showConfirmRemove.value = false;
    selectedMember.value = null;
    await loadMembers();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('workspace.members.messages.removeFailed');
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
      successMsg.value = t('workspace.members.messages.updateStaffSuccess', {
        name: staffName.value,
      });
      showStaffDialog.value = false;
    } else {
      const newStaff = await createStaffMember({
        tenant_id: tenantStore.activeTenant.id,
        full_name: staffName.value,
        role: staffRole.value,
        phone: staffPhone.value,
        allow_terminal_login: staffAllowTerminalLogin.value,
      });
      successMsg.value = t('workspace.members.messages.createStaffSuccess', {
        name: staffName.value,
      });
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
    errorMsg.value = error.message || t('workspace.members.messages.saveStaffFailed');
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
    successMsg.value = t('workspace.members.messages.resetPinSuccess', {
      name: staffMember.full_name,
    });
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('workspace.members.messages.resetPinFailed');
  }
};

const toggleTerminalLogin = async (staffMember: StaffMember) => {
  try {
    await updateStaffMember(staffMember.id, {
      allow_terminal_login: staffMember.allow_terminal_login,
    });
    successMsg.value = t('workspace.members.messages.terminalAccessSuccess', {
      name: staffMember.full_name,
    });
    if (staffMember.allow_terminal_login && !staffMember.temp_pin && !staffMember.hashed_pin) {
      const pin = await resetStaffPin(staffMember.id);
      tempPinCode.value = pin;
      showTempPinDialog.value = true;
    }
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('workspace.members.messages.terminalAccessFailed');
    staffMember.allow_terminal_login = !staffMember.allow_terminal_login;
  }
};

const toggleStaffActive = async (staffMember: StaffMember) => {
  try {
    await updateStaffMember(staffMember.id, {
      is_active: staffMember.is_active,
    });
    successMsg.value = t('workspace.members.messages.statusSuccess', {
      name: staffMember.full_name,
    });
    await loadStaff();
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('workspace.members.messages.statusFailed');
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
    errorMsg.value = error.message || t('workspace.members.messages.pairingCodeFailed');
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

// Staff Roles Admin UI states & actions
interface StaffRole {
  id: string;
  name: string;
  description: string | null;
  permissions: Record<string, unknown> | null;
  is_system_role: boolean;
}

interface RoleFormState {
  id: string;
  name: string;
  description: string;
  is_system_role: boolean;
  permissions: {
    modules: {
      operational_shifts: {
        sessions_open: boolean;
        sessions_close: boolean;
        sessions_reopen: boolean;
      };
      kiosk: {
        log_pos: boolean;
        log_expense: boolean;
        log_advance: boolean;
        view_active_session: boolean;
      };
    };
  };
}

const staffRoles = ref<StaffRole[]>([]);
const loadingRoles = ref(false);
const showRoleDialog = ref(false);
const isEditingRole = ref(false);
const submittingRole = ref(false);

const roleForm = ref<RoleFormState>({
  id: '',
  name: '',
  description: '',
  is_system_role: false,
  permissions: {
    modules: {
      operational_shifts: {
        sessions_open: false,
        sessions_close: false,
        sessions_reopen: false,
      },
      kiosk: {
        log_pos: true,
        log_expense: true,
        log_advance: false,
        view_active_session: true,
      },
    },
  },
});

const roleColumns = computed(() => [
  {
    name: 'name',
    align: 'left' as const,
    label: t('workspace.members.rolesTable.cols.name'),
    field: 'name',
    sortable: true,
  },
  {
    name: 'description',
    align: 'left' as const,
    label: t('workspace.members.rolesTable.cols.description'),
    field: 'description',
  },
  {
    name: 'is_system_role',
    align: 'center' as const,
    label: t('workspace.members.rolesTable.cols.type'),
    field: 'is_system_role',
    sortable: true,
  },
  {
    name: 'actions',
    align: 'center' as const,
    label: t('workspace.members.rolesTable.cols.actions'),
    field: 'id',
  },
]);

const roleOptions = computed(() => {
  return staffRoles.value.map((r) => ({
    label: r.name,
    value: r.name,
  }));
});

const loadStaffRoles = async () => {
  if (!tenantStore.activeTenant) return;
  loadingRoles.value = true;
  try {
    const { data, error } = await supabase
      .from('staff_roles')
      .select('*')
      .or(`tenant_id.eq.${tenantStore.activeTenant.id},tenant_id.is.null`)
      .order('name');
    if (error) throw error;
    staffRoles.value = (data || []) as StaffRole[];
  } catch (err: unknown) {
    const error = err as Error;
    console.error('Failed to load staff roles:', error.message);
  } finally {
    loadingRoles.value = false;
  }
};

function openCreateRoleDialog() {
  isEditingRole.value = false;
  roleForm.value = {
    id: '',
    name: '',
    description: '',
    is_system_role: false,
    permissions: {
      modules: {
        operational_shifts: {
          sessions_open: false,
          sessions_close: false,
          sessions_reopen: false,
        },
        kiosk: {
          log_pos: true,
          log_expense: true,
          log_advance: false,
          view_active_session: true,
        },
      },
    },
  };
  showRoleDialog.value = true;
}

function openEditRoleDialog(role: StaffRole) {
  isEditingRole.value = true;
  const basePerm = {
    modules: {
      operational_shifts: {
        sessions_open: false,
        sessions_close: false,
        sessions_reopen: false,
      },
      kiosk: {
        log_pos: true,
        log_expense: true,
        log_advance: false,
        view_active_session: true,
      },
    },
  };
  const rolePerm = role.permissions as {
    modules?: {
      operational_shifts?: Record<string, boolean>;
      kiosk?: Record<string, boolean>;
    };
  } | null;
  const permissions = {
    modules: {
      operational_shifts: {
        ...basePerm.modules.operational_shifts,
        ...(rolePerm?.modules?.operational_shifts || {}),
      },
      kiosk: {
        ...basePerm.modules.kiosk,
        ...(rolePerm?.modules?.kiosk || {}),
      },
    },
  };
  roleForm.value = {
    id: role.id,
    name: role.name,
    description: role.description || '',
    is_system_role: role.is_system_role,
    permissions,
  };
  showRoleDialog.value = true;
}

async function handleRoleSubmit() {
  if (!tenantStore.activeTenant) return;
  submittingRole.value = true;
  try {
    if (isEditingRole.value && roleForm.value.id) {
      const { error } = await supabase
        .from('staff_roles')
        .update({
          name: roleForm.value.name,
          description: roleForm.value.description || null,
          permissions: roleForm.value.permissions,
        })
        .eq('id', roleForm.value.id);
      if (error) throw error;
      showSuccess(t('workspace.members.messages.saveRoleSuccess'));
    } else {
      const { error } = await supabase.from('staff_roles').insert({
        tenant_id: tenantStore.activeTenant.id,
        name: roleForm.value.name,
        description: roleForm.value.description || null,
        permissions: roleForm.value.permissions,
        is_system_role: false,
      });
      if (error) throw error;
      showSuccess(t('workspace.members.messages.createRoleSuccess'));
    }
    showRoleDialog.value = false;
    await loadStaffRoles();
  } catch (err: unknown) {
    await showApiError(err, t('workspace.members.messages.saveRoleFailed'));
  } finally {
    submittingRole.value = false;
  }
}

const showConfirmDeleteRole = ref(false);
const deletingRole = ref(false);
const roleToDelete = ref<StaffRole | null>(null);

function confirmDeleteRole(role: StaffRole) {
  roleToDelete.value = role;
  showConfirmDeleteRole.value = true;
}

async function handleDeleteRole() {
  if (!roleToDelete.value) return;
  deletingRole.value = true;
  try {
    const { error } = await supabase.from('staff_roles').delete().eq('id', roleToDelete.value.id);
    if (error) throw error;
    showSuccess(t('workspace.members.messages.deleteRoleSuccess'));
    showConfirmDeleteRole.value = false;
    roleToDelete.value = null;
    await loadStaffRoles();
  } catch (err: unknown) {
    await showApiError(err, t('workspace.members.messages.deleteRoleFailed'));
  } finally {
    deletingRole.value = false;
  }
}

onMounted(() => {
  void loadMembers();
  void loadRoles();
  void loadStaff();
  void loadStaffRoles();
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
