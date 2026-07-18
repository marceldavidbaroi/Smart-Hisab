<template>
  <q-page class="q-pa-lg">
    <div class="row items-center justify-between q-mb-md">
      <div>
        <h1 class="text-h4 text-bold q-my-none text-slate-850">
          {{ $t('workspace.settings.title') }}
        </h1>
        <p class="text-slate-500 text-subtitle2 q-mt-xs q-mb-none">
          {{ $t('workspace.settings.subtitle') }}
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
      <q-tab
        name="general"
        :label="$t('workspace.settings.tabs.general')"
        icon="settings"
        class="q-py-sm"
      />
      <q-tab
        name="preferences"
        :label="$t('workspace.settings.tabs.preferences')"
        icon="tune"
        class="q-py-sm"
      />
      <q-tab
        name="kiosk"
        :label="$t('workspace.settings.tabs.kiosk')"
        icon="devices"
        class="q-py-sm"
      />
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
                <div class="text-h6 text-bold text-slate-800">
                  {{ $t('workspace.settings.branding.title') }}
                </div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <q-form @submit.prevent="saveSettings" class="q-gutter-y-md">
                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.branding.nameLabel')
                    }}</label>
                    <q-input v-model="workspaceName" filled disable class="custom-input" />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.branding.slugLabel')
                    }}</label>
                    <q-input v-model="workspaceSlug" filled disable class="custom-input" />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.branding.logoUrl')
                    }}</label>
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
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.branding.themeColor')
                    }}</label>
                    <q-input
                      v-model="themeColor"
                      filled
                      placeholder="#0e4a47"
                      color="primary"
                      class="custom-input"
                      :disable="!canEdit"
                      :rules="[
                        (val) =>
                          !val ||
                          /^#[0-9A-F]{6}$/i.test(val) ||
                          $t('workspace.settings.branding.themeColorInvalid'),
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
                      :label="$t('workspace.settings.branding.saveBtn')"
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
                <div class="text-h6 text-bold text-slate-800">
                  {{ $t('workspace.settings.accessScopes.title') }}
                </div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <div class="text-subtitle2 q-mb-sm text-amber-9">
                  {{ $t('workspace.settings.accessScopes.privilegesTitle') }}
                </div>
                <p class="text-sm text-slate-500 q-mb-lg">
                  {{ $t('workspace.settings.accessScopes.privilegesDesc') }}
                </p>

                <div class="text-subtitle2 q-mb-sm text-teal-8">
                  {{ $t('workspace.settings.accessScopes.planTitle') }}
                </div>
                <p class="text-sm text-slate-500">
                  {{ $t('workspace.settings.accessScopes.planDesc') }}
                </p>
              </q-card-section>
            </q-card>
          </div>

          <!-- Danger Zone -->
          <div class="col-12 q-mt-lg" v-if="isOwner">
            <q-card class="glass-card border-danger">
              <q-card-section class="q-py-md border-bottom bg-red-50 text-red-900 row items-center">
                <q-icon name="warning" size="24px" class="q-mr-sm text-red-9" />
                <div class="text-h6 text-bold text-red-9">
                  {{ $t('workspace.settings.dangerZone.title') }}
                </div>
              </q-card-section>

              <q-card-section class="q-pa-md bg-white">
                <div class="row items-center justify-between no-wrap q-col-gutter-md">
                  <div class="col-12 col-sm-8">
                    <div class="text-subtitle2 text-bold text-slate-900">
                      {{ $t('workspace.settings.dangerZone.deleteTitle') }}
                    </div>
                    <p class="text-sm text-slate-500 q-mb-none q-mt-xs">
                      {{ $t('workspace.settings.dangerZone.deleteDesc') }}
                    </p>
                  </div>
                  <div class="col-12 col-sm-4 text-right">
                    <q-btn
                      color="negative"
                      unelevated
                      :label="$t('workspace.settings.dangerZone.deleteBtn')"
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

      <!-- Workspace Preferences (localization) -->
      <q-tab-panel name="preferences" class="q-pa-none">
        <div class="row q-col-gutter-lg">
          <div class="col-12 col-md-8">
            <q-card class="glass-card">
              <q-card-section class="q-py-md border-bottom">
                <div class="text-h6 text-bold text-slate-800">
                  {{ $t('workspace.settings.localization.title') }}
                </div>
                <div class="text-caption text-grey-7 q-mt-xs">
                  {{ $t('workspace.settings.localization.subtitle') }}
                </div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <q-form @submit.prevent="savePreferences" class="q-gutter-y-md">
                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.localization.currency')
                    }}</label>
                    <q-select
                      v-model="prefCurrency"
                      :options="currencyOptions"
                      emit-value
                      map-options
                      filled
                      dense
                      class="custom-input"
                      :disable="!isOwner"
                    />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.localization.timezone')
                    }}</label>
                    <q-select
                      v-model="prefTimezone"
                      :options="timezoneOptions"
                      emit-value
                      map-options
                      filled
                      dense
                      class="custom-input"
                      :disable="!isOwner"
                    />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.localization.region')
                    }}</label>
                    <q-select
                      v-model="prefRegion"
                      :options="regionOptions"
                      emit-value
                      map-options
                      filled
                      dense
                      class="custom-input"
                      :disable="!isOwner"
                    />
                  </div>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.localization.dateFormat')
                    }}</label>
                    <q-select
                      v-model="prefDateFormat"
                      :options="dateFormatOptions"
                      emit-value
                      map-options
                      filled
                      dense
                      class="custom-input"
                      :disable="!isOwner"
                    />
                  </div>

                  <q-separator class="q-my-md" />

                  <div>
                    <div class="text-subtitle2 text-weight-bold text-slate-800 q-mb-xs">
                      {{ $t('workspace.settings.posEditWindow.title') }}
                    </div>
                    <div class="text-caption text-grey-7 q-mb-md">
                      {{ $t('workspace.settings.posEditWindow.subtitle') }}
                    </div>
                    <div class="row q-col-gutter-sm">
                      <div class="col-5">
                        <q-input
                          v-model.number="posEditValue"
                          type="number"
                          filled
                          dense
                          class="custom-input"
                          :label="$t('workspace.settings.posEditWindow.value')"
                          :disable="!isOwner"
                          :rules="[
                            (v) =>
                              (v !== null && v > 0) ||
                              $t('workspace.settings.posEditWindow.valueMin'),
                          ]"
                          hide-bottom-space
                        />
                      </div>
                      <div class="col-7">
                        <q-select
                          v-model="posEditUnit"
                          :options="posEditUnitOptions"
                          emit-value
                          map-options
                          filled
                          dense
                          class="custom-input"
                          :label="$t('workspace.settings.posEditWindow.unit')"
                          :disable="!isOwner"
                        />
                      </div>
                    </div>
                  </div>

                  <div class="q-mt-lg" v-if="isOwner">
                    <q-btn
                      type="submit"
                      color="primary"
                      :label="$t('workspace.settings.localization.saveBtn')"
                      class="q-px-lg rounded-btn btn-gradient text-weight-bold"
                      :loading="savingPreferences"
                    />
                  </div>
                  <p v-else class="text-caption text-grey-7 q-mb-none">
                    {{ $t('workspace.settings.localization.ownerOnly') }}
                  </p>
                </q-form>
              </q-card-section>
            </q-card>
          </div>

          <div class="col-12 col-md-4">
            <q-card class="glass-card full-height">
              <q-card-section class="q-py-md border-bottom row items-center">
                <q-icon name="info" size="24px" class="text-primary q-mr-sm" />
                <div class="text-h6 text-bold text-slate-800">
                  {{ $t('workspace.settings.localization.appliesTitle') }}
                </div>
              </q-card-section>
              <q-card-section class="q-pt-md">
                <p class="text-sm text-slate-500 q-mb-md">
                  {{ $t('workspace.settings.localization.appliesDesc') }}
                </p>
                <div class="text-caption text-grey-8">
                  {{ $t('workspace.settings.localization.preview') }}:
                  <span class="text-weight-medium text-slate-800">{{ preferencePreview }}</span>
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
                <div class="text-h6 text-bold">
                  {{ $t('workspace.settings.kioskDevices.title') }}
                </div>
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
                        :label="$t('workspace.settings.kioskDevices.statusActive')"
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
                      <div class="row q-gutter-xs justify-end no-wrap">
                        <q-btn
                          dense
                          color="primary"
                          outline
                          icon="qr_code_2"
                          :label="$t('workspace.settings.kioskDevices.repairBtn')"
                          class="q-px-sm rounded-btn text-weight-bold cursor-pointer"
                          style="min-height: 40px"
                          size="sm"
                          unelevated
                          @click="confirmRepairDevice(props.row)"
                        />
                        <q-btn
                          dense
                          color="red-5"
                          icon="link_off"
                          :label="$t('workspace.settings.kioskDevices.disconnectBtn')"
                          class="q-px-sm rounded-btn text-weight-bold cursor-pointer"
                          style="min-height: 40px"
                          size="sm"
                          unelevated
                          @click="confirmDisconnectDevice(props.row)"
                        />
                      </div>
                    </q-td>
                  </template>
                  <template #no-data>
                    <div class="full-width column flex-center text-slate-500 q-pa-xl text-center">
                      <q-icon name="devices_other" size="48px" class="q-mb-sm text-slate-400" />
                      <div class="text-subtitle1 text-weight-medium">
                        {{ $t('workspace.settings.kioskDevices.noDevicesTitle') }}
                      </div>
                      <p class="text-sm text-slate-400 q-mt-xs q-mb-none">
                        {{ $t('workspace.settings.kioskDevices.noDevicesDesc') }}
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
                <div class="text-h6 text-bold">
                  {{ $t('workspace.settings.generatePairing.title') }}
                </div>
              </q-card-section>

              <q-card-section class="q-pt-md">
                <div
                  v-if="activePairingCode"
                  class="column items-center text-center q-pa-md bg-teal-1 border-teal-100 rounded-borders border-all"
                >
                  <q-icon name="vpn_key" size="36px" color="primary" class="q-mb-sm" />
                  <div class="text-caption text-teal-7 text-weight-bold">
                    {{ $t('workspace.settings.generatePairing.activeTitle') }}
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
                    {{ $t('workspace.settings.generatePairing.expires') }}:
                    {{
                      activePairingExpires
                        ? new Date(activePairingExpires).toLocaleTimeString()
                        : 'N/A'
                    }}
                  </div>

                  <q-btn
                    color="red-5"
                    unelevated
                    :label="$t('workspace.settings.generatePairing.revokeBtn')"
                    icon="cancel"
                    class="full-width rounded-btn text-weight-bold cursor-pointer"
                    @click="handleRevokePairingCode"
                  />
                </div>

                <q-form v-else @submit.prevent="handleGeneratePairingCode" class="q-gutter-y-md">
                  <p class="text-sm text-slate-500 q-mb-none">
                    {{ $t('workspace.settings.generatePairing.desc') }}
                  </p>

                  <div>
                    <label class="input-label text-slate-600 font-semibold q-mb-xs block text-xs">{{
                      $t('workspace.settings.generatePairing.nameLabel')
                    }}</label>
                    <q-input
                      v-model="deviceNameInput"
                      filled
                      :placeholder="$t('workspace.settings.generatePairing.nameLabel')"
                      color="primary"
                      class="custom-input"
                      :rules="[
                        (val) => !!val || $t('workspace.settings.generatePairing.nameRequired'),
                      ]"
                      hide-bottom-space
                    />
                  </div>

                  <q-btn
                    type="submit"
                    color="primary"
                    :label="$t('workspace.settings.generatePairing.generateBtn')"
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
          <div class="text-h6 text-bold text-red-9">
            {{ $t('workspace.settings.deleteDialog.title') }}
          </div>
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
            {{
              $t('workspace.settings.deleteDialog.desc', {
                name: workspaceName,
                slug: workspaceSlug,
              })
            }}
          </p>

          <q-input
            v-model="deleteConfirmSlug"
            type="text"
            filled
            :placeholder="$t('workspace.settings.deleteDialog.placeholder')"
            color="negative"
            class="custom-input q-mb-md"
            hide-bottom-space
            :disable="deleting"
          />

          <div class="row justify-end q-gutter-sm">
            <q-btn
              flat
              :label="$t('workspace.settings.deleteDialog.cancelBtn')"
              v-close-popup
              :disable="deleting"
              class="cursor-pointer text-slate-500"
            />
            <q-btn
              color="negative"
              :label="$t('workspace.settings.deleteDialog.deleteBtn')"
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
          <div class="text-h6 text-bold text-slate-800">
            {{ $t('workspace.settings.disconnectDialog.title') }}
          </div>
          <p class="text-sm text-slate-500 q-mt-sm">
            {{
              $t('workspace.settings.disconnectDialog.desc', {
                name: deviceToDisconnect?.device_name || '',
              })
            }}
          </p>
        </q-card-section>

        <q-card-actions align="right" class="q-gutter-sm">
          <q-btn
            flat
            :label="$t('workspace.settings.disconnectDialog.cancelBtn')"
            color="slate-500"
            v-close-popup
            class="cursor-pointer animate-fade"
          />
          <q-btn
            color="red"
            :label="$t('workspace.settings.disconnectDialog.confirmBtn')"
            class="q-px-md text-weight-bold rounded-btn cursor-pointer"
            v-close-popup
            @click="deviceToDisconnect && handleDisconnectDevice(deviceToDisconnect.id)"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Re-pair Device Confirmation Dialog -->
    <q-dialog v-model="confirmRepair" persistent>
      <q-card
        style="width: 400px; max-width: 90vw; border-radius: 16px"
        class="q-pa-md bg-white text-slate-900"
      >
        <q-card-section class="column items-center text-center q-pt-md">
          <q-avatar size="48px" color="primary" text-color="white" class="q-mb-md">
            <q-icon name="qr_code_2" size="28px" />
          </q-avatar>
          <div class="text-h6 text-bold text-slate-800">
            {{ $t('workspace.settings.repairDialog.title') }}
          </div>
          <p class="text-sm text-slate-500 q-mt-sm">
            {{
              $t('workspace.settings.repairDialog.desc', {
                name: deviceToRepair?.device_name || '',
              })
            }}
          </p>
        </q-card-section>

        <q-card-actions align="right" class="q-gutter-sm">
          <q-btn
            flat
            :label="$t('workspace.settings.repairDialog.cancelBtn')"
            color="slate-500"
            v-close-popup
            class="cursor-pointer"
            :disable="repairingDevice"
          />
          <q-btn
            color="primary"
            :label="$t('workspace.settings.repairDialog.confirmBtn')"
            class="q-px-md text-weight-bold rounded-btn cursor-pointer"
            :loading="repairingDevice"
            @click="deviceToRepair && handleRepairDevice(deviceToRepair)"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useTenantStore } from '../../stores/tenant';
import { updateTenantSettings, deleteTenant } from '../../services/multiTenant';
import { generatePairingCode, prepareDeviceRepair } from '../../services/staff';
import { supabase } from '../../boot/supabase';
import { showSuccess, showInfo, showApiError } from '../../composables/useFeedback';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const tenantStore = useTenantStore();
const { t } = useI18n();

const activeTab = ref('general');

const workspaceName = ref('');
const workspaceSlug = ref('');
const logoUrl = ref('');
const themeColor = ref('');

const prefCurrency = ref('BDT');
const prefTimezone = ref('Asia/Dhaka');
const prefRegion = ref('BD');
const prefDateFormat = ref('DD/MM/YYYY');
const posEditValue = ref(24);
const posEditUnit = ref<'minutes' | 'hours' | 'days'>('hours');
const savingPreferences = ref(false);

const currencyOptions = [
  { label: 'Bangladeshi Taka (BDT)', value: 'BDT' },
  { label: 'US Dollar (USD)', value: 'USD' },
  { label: 'Euro (EUR)', value: 'EUR' },
  { label: 'Indian Rupee (INR)', value: 'INR' },
  { label: 'British Pound (GBP)', value: 'GBP' },
];

const timezoneOptions = [
  { label: 'Asia/Dhaka (Bangladesh)', value: 'Asia/Dhaka' },
  { label: 'Asia/Kolkata (India)', value: 'Asia/Kolkata' },
  { label: 'Asia/Dubai', value: 'Asia/Dubai' },
  { label: 'UTC', value: 'UTC' },
  { label: 'Europe/London', value: 'Europe/London' },
  { label: 'America/New_York', value: 'America/New_York' },
];

const regionOptions = [
  { label: 'Bangladesh (BD)', value: 'BD' },
  { label: 'India (IN)', value: 'IN' },
  { label: 'United Arab Emirates (AE)', value: 'AE' },
  { label: 'United Kingdom (GB)', value: 'GB' },
  { label: 'United States (US)', value: 'US' },
];

const dateFormatOptions = [
  { label: 'DD/MM/YYYY (31/12/2026)', value: 'DD/MM/YYYY' },
  { label: 'MM/DD/YYYY (12/31/2026)', value: 'MM/DD/YYYY' },
  { label: 'YYYY-MM-DD (2026-12-31)', value: 'YYYY-MM-DD' },
];

const posEditUnitOptions = computed(() => [
  { label: t('workspace.settings.posEditWindow.units.minutes'), value: 'minutes' },
  { label: t('workspace.settings.posEditWindow.units.hours'), value: 'hours' },
  { label: t('workspace.settings.posEditWindow.units.days'), value: 'days' },
]);

const preferencePreview = computed(() => {
  const sample = new Date(2026, 11, 31);
  let dateStr = '2026-12-31';
  if (prefDateFormat.value === 'DD/MM/YYYY') dateStr = '31/12/2026';
  else if (prefDateFormat.value === 'MM/DD/YYYY') dateStr = '12/31/2026';
  void sample;
  return `${prefCurrency.value} · ${prefTimezone.value} · ${prefRegion.value} · ${dateStr}`;
});

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
const confirmRepair = ref(false);
const deviceToRepair = ref<PairedDevice | null>(null);
const repairingDevice = ref(false);

const deviceColumns = computed<DeviceColumn[]>(() => [
  {
    name: 'device_name',
    label: t('workspace.settings.kioskDevices.cols.name'),
    field: 'device_name',
    align: 'left',
    sortable: true,
  },
  {
    name: 'status',
    label: t('workspace.settings.kioskDevices.cols.status'),
    field: 'status',
    align: 'left',
  },
  {
    name: 'paired_at',
    label: t('workspace.settings.kioskDevices.cols.pairedAt'),
    field: 'paired_at',
    align: 'left',
    sortable: true,
  },
  {
    name: 'last_active_at',
    label: t('workspace.settings.kioskDevices.cols.lastActive'),
    field: 'last_active_at',
    align: 'left',
    sortable: true,
  },
  {
    name: 'actions',
    label: t('workspace.settings.kioskDevices.cols.actions'),
    field: 'actions',
    align: 'right',
  },
]);

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

  const prefs = (tenantStore.activeSettings?.preferences || {}) as {
    localization?: {
      currency?: string;
      timezone?: string;
      region?: string;
      date_format?: string;
    };
    pos_edit_window?: {
      value?: number;
      unit?: string;
    };
  };
  const loc = prefs.localization || {};
  prefCurrency.value = loc.currency || 'BDT';
  prefTimezone.value = loc.timezone || 'Asia/Dhaka';
  prefRegion.value = loc.region || 'BD';
  prefDateFormat.value = loc.date_format || 'DD/MM/YYYY';
  const pew = prefs.pos_edit_window || {};
  posEditValue.value = Number(pew.value) > 0 ? Number(pew.value) : 24;
  posEditUnit.value =
    pew.unit === 'minutes' || pew.unit === 'days' || pew.unit === 'hours' ? pew.unit : 'hours';
};

const savePreferences = async () => {
  if (!tenantStore.activeTenant || !isOwner.value) return;
  savingPreferences.value = true;
  try {
    const existing =
      (tenantStore.activeSettings?.preferences as Record<string, unknown> | null) || {};
    const existingLoc = (existing.localization as Record<string, unknown> | undefined) || {};

    const updated = await updateTenantSettings(tenantStore.activeTenant.id, {
      preferences: {
        ...existing,
        localization: {
          ...existingLoc,
          currency: prefCurrency.value,
          timezone: prefTimezone.value,
          region: prefRegion.value,
          date_format: prefDateFormat.value,
        },
        pos_edit_window: {
          value: posEditValue.value,
          unit: posEditUnit.value,
        },
      },
    });

    tenantStore.activeSettings = updated;
    showSuccess(t('workspace.settings.messages.prefUpdated'));
  } catch (err) {
    await showApiError(err, t('workspace.settings.messages.prefFailed'));
  } finally {
    savingPreferences.value = false;
  }
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
    successMsg.value = t('workspace.settings.messages.settingsUpdated');
  } catch (err) {
    const error = err as Error;
    errorMsg.value = error.message || t('workspace.settings.messages.settingsFailed');
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
    errorMsg.value = error.message || t('workspace.settings.messages.deleteFailed');
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

    showSuccess(t('workspace.settings.messages.pairingSuccess'));
  } catch (err) {
    await showApiError(err, t('workspace.settings.messages.pairingFailed'));
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

    showInfo(t('workspace.settings.messages.revokeSuccess'));
  } catch (err) {
    await showApiError(err, t('workspace.settings.messages.revokeFailed'));
  }
};

const confirmDisconnectDevice = (device: PairedDevice) => {
  deviceToDisconnect.value = device;
  confirmDisconnect.value = true;
};

const confirmRepairDevice = (device: PairedDevice) => {
  deviceToRepair.value = device;
  confirmRepair.value = true;
};

const handleRepairDevice = async (device: PairedDevice) => {
  if (!tenantStore.activeTenant) return;
  repairingDevice.value = true;
  try {
    const code = await prepareDeviceRepair(tenantStore.activeTenant.id, device.id);
    activePairingCode.value = code;
    activePairingDeviceName.value = device.device_name;
    deviceNameInput.value = device.device_name;

    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 30);
    activePairingExpires.value = expires.toISOString();

    confirmRepair.value = false;
    deviceToRepair.value = null;

    await loadPairedDevices();
    showSuccess(t('workspace.settings.messages.repairSuccess'));
  } catch (err) {
    await showApiError(err, t('workspace.settings.messages.repairFailed'));
  } finally {
    repairingDevice.value = false;
  }
};

const handleDisconnectDevice = async (deviceId: string) => {
  try {
    const { error } = await supabase.from('paired_devices').delete().eq('id', deviceId);

    if (error) throw error;

    showSuccess(t('workspace.settings.messages.disconnectSuccess'));

    await loadPairedDevices();
  } catch (err) {
    await showApiError(err, t('workspace.settings.messages.disconnectFailed'));
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
  background: linear-gradient(135deg, #0e4a47 0%, #2ec4b6 100%) !important;
  color: white !important;
  box-shadow: 0 4px 12px rgba(14, 74, 71, 0.15);
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
