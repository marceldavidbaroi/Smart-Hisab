<template>
  <q-layout view="hHh lpR fFf" class="bg-grey-2 text-dark select-none kiosk-layout">
    <!-- Header/Kiosk Status Bar — phone-app first -->
    <q-header bordered class="bg-white text-dark">
      <q-toolbar class="kiosk-toolbar q-px-sm q-px-md-md">
        <!-- Logo and Workspace name -->
        <div class="kiosk-toolbar__brand row items-center no-wrap col-grow">
          <img
            src="../assets/brand-mark.png"
            alt="Smart Hisab"
            class="q-mr-sm shrink-0"
            style="height: 24px; object-fit: contain"
          />
          <div class="text-subtitle2 text-weight-bold text-dark ellipsis">
            {{ tenantName || 'Smart Hisab' }}
          </div>
        </div>

        <div class="kiosk-toolbar__actions row items-center no-wrap">
          <!-- Connection Status Icon (only if offline, visible on header for quick attention) -->
          <q-icon
            v-if="!isOnline"
            name="wifi_off"
            color="negative"
            size="20px"
            class="shrink-0 q-mr-sm"
          >
            <q-tooltip class="bg-negative text-white">{{ $t('layouts.kiosk.offline') }}</q-tooltip>
          </q-icon>

          <LocaleSwitcher class="q-mr-sm" />

          <!-- User Profile Icon with Dropdown Menu -->
          <q-avatar
            size="32px"
            color="teal-1"
            text-color="primary"
            class="cursor-pointer text-weight-bold border-primary"
          >
            <template v-if="kioskStore.isStaffAuthenticated">
              {{ currentStaffName.charAt(0).toUpperCase() }}
            </template>
            <template v-else>
              <q-icon name="person" size="20px" />
            </template>

            <q-menu
              anchor="bottom right"
              self="top right"
              class="q-pa-md kiosk-profile-menu"
              style="min-width: 260px; border-radius: 16px"
            >
              <div class="column q-gutter-y-sm">
                <!-- Header/Tenant details -->
                <div class="text-caption text-grey-6 text-weight-medium q-mb-xs">
                  {{ $t('layouts.kiosk.terminal') }} Details
                </div>

                <div class="row items-center no-wrap q-py-xs">
                  <q-icon name="business" size="20px" color="grey-6" class="q-mr-sm shrink-0" />
                  <div class="column ellipsis">
                    <span class="text-caption text-grey-5 line-height-1">Workspace</span>
                    <span class="text-subtitle2 text-weight-bold text-dark ellipsis">{{
                      tenantName || 'Smart Hisab'
                    }}</span>
                  </div>
                </div>

                <div class="row items-center no-wrap q-py-xs">
                  <q-icon name="devices" size="20px" color="grey-6" class="q-mr-sm shrink-0" />
                  <div class="column ellipsis">
                    <span class="text-caption text-grey-5 line-height-1">Device</span>
                    <span class="text-subtitle2 text-weight-bold text-dark ellipsis">{{
                      deviceName || 'Kiosk'
                    }}</span>
                  </div>
                </div>

                <div class="row items-center no-wrap q-py-xs">
                  <q-icon
                    :name="isOnline ? 'wifi' : 'wifi_off'"
                    size="20px"
                    :color="isOnline ? 'positive' : 'negative'"
                    class="q-mr-sm shrink-0"
                  />
                  <div class="column">
                    <span class="text-caption text-grey-5 line-height-1">Status</span>
                    <span
                      class="text-subtitle2 text-weight-bold"
                      :class="isOnline ? 'text-positive' : 'text-negative'"
                    >
                      {{ isOnline ? $t('layouts.kiosk.online') : $t('layouts.kiosk.offline') }}
                    </span>
                  </div>
                </div>

                <!-- Staff Info and Logout -->
                <template v-if="kioskStore.isStaffAuthenticated">
                  <q-separator class="q-my-xs" />
                  <div class="row items-center no-wrap q-py-xs">
                    <q-avatar
                      size="32px"
                      color="primary"
                      text-color="white"
                      class="text-weight-bold q-mr-sm shrink-0"
                    >
                      {{ currentStaffName.charAt(0).toUpperCase() }}
                    </q-avatar>
                    <div class="column ellipsis">
                      <span class="text-subtitle2 text-weight-bold text-dark ellipsis">{{
                        currentStaffName
                      }}</span>
                      <span class="text-caption text-grey-5 capitalize ellipsis">{{
                        currentStaffRole
                      }}</span>
                    </div>
                  </div>

                  <q-btn
                    outline
                    color="red-5"
                    icon="logout"
                    :label="$t('layouts.kiosk.clockOut')"
                    class="full-width q-py-xs text-weight-bold cursor-pointer rounded-borders q-mt-xs"
                    style="min-height: 40px"
                    @click="handleLogout"
                  />
                </template>
              </div>
            </q-menu>
          </q-avatar>
        </div>
      </q-toolbar>
    </q-header>

    <!-- Offline Banner Notification -->
    <div
      v-if="!isOnline"
      class="bg-orange-9 text-white text-center q-py-xs text-caption text-weight-bold full-width"
    >
      {{ $t('layouts.kiosk.offlineBanner') }}
    </div>

    <!-- Main Container -->
    <q-page-container>
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useKioskStore } from '../stores/kiosk';
import LocaleSwitcher from '../components/LocaleSwitcher.vue';

const router = useRouter();
const kioskStore = useKioskStore();

const isOnline = computed(() => kioskStore.isOnline);

const tenantName = computed(() => kioskStore.tenantName);
const deviceName = computed(() => kioskStore.deviceName);
const currentStaffName = computed(() => kioskStore.currentStaff?.fullName || '');
const currentStaffRole = computed(() => kioskStore.currentStaff?.role || '');

const handleLogout = () => {
  kioskStore.logoutStaff();
  void router.push({ name: 'kiosk-login' });
};
</script>

<script lang="ts">
export default {
  name: 'KioskLayout',
};
</script>

<style scoped lang="scss">
.kiosk-toolbar {
  min-height: 56px;
  flex-wrap: nowrap;
  gap: 4px;
}

.kiosk-toolbar__brand {
  min-width: 0; /* allow ellipsis inside flex */
  overflow: hidden;
  padding-right: 4px;
}

.kiosk-toolbar__actions {
  flex-shrink: 0;
}

.kiosk-brand-mark {
  width: 36px;
  height: 36px;
  object-fit: contain;
  border-radius: 8px;
}

.shrink-0 {
  flex-shrink: 0;
}

.col-grow {
  flex: 1 1 auto;
}

/* Route transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
