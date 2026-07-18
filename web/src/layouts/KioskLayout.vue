<template>
  <q-layout view="hHh lpR fFf" class="bg-grey-2 text-dark overflow-hidden select-none">
    <!-- Header/Kiosk Status Bar -->
    <q-header bordered class="bg-white text-dark">
      <q-toolbar class="q-px-md" style="min-height: 56px">
        <q-icon name="devices" size="24px" class="text-primary q-mr-sm" />
        <div>
          <div class="text-subtitle2 text-weight-bold leading-none text-dark">
            {{ tenantName || 'Smart Hisab' }}
          </div>
          <div class="text-caption text-grey-7 leading-none">
            {{ $t('layouts.kiosk.terminal') }}: {{ deviceName || 'Kiosk' }}
          </div>
        </div>

        <q-space />

        <!-- Language Switcher Toggle -->
        <q-btn-toggle
          v-model="locale"
          toggle-color="primary"
          color="indigo-1"
          text-color="primary"
          toggle-text-color="white"
          flat
          dense
          unelevated
          class="q-mr-sm text-xs text-weight-bold"
          style="
            font-size: 11px;
            height: 32px;
            border-radius: 8px;
            padding: 2px;
            border: 1.5px solid var(--q-primary);
          "
          :options="toggleOptions"
        />

        <!-- Status Indicators -->
        <div class="row items-center q-gutter-x-md">
          <!-- Connection Status -->
          <q-badge
            :color="isOnline ? 'positive' : 'negative'"
            class="q-py-xs q-px-sm text-weight-medium rounded-borders"
            style="min-height: 24px"
          >
            <q-icon :name="isOnline ? 'wifi' : 'wifi_off'" size="14px" class="q-mr-xs" />
            <span class="gt-xs">{{
              isOnline ? $t('layouts.kiosk.online') : $t('layouts.kiosk.offline')
            }}</span>
          </q-badge>

          <!-- Active Staff Member -->
          <div v-if="kioskStore.isStaffAuthenticated" class="row items-center q-gutter-x-sm">
            <q-avatar size="28px" color="primary" text-color="white" class="text-weight-bold">
              {{ currentStaffName.charAt(0).toUpperCase() }}
            </q-avatar>
            <div class="column gt-xs">
              <span class="text-caption text-weight-medium text-dark leading-none">
                {{ currentStaffName }}
              </span>
              <span class="text-caption text-grey-7 leading-none" style="font-size: 0.75rem">
                {{ currentStaffRole }}
              </span>
            </div>
            <q-btn
              flat
              dense
              round
              color="red-5"
              icon="logout"
              size="sm"
              class="cursor-pointer"
              @click="handleLogout"
            >
              <q-tooltip class="bg-red text-white">{{ $t('layouts.kiosk.clockOut') }}</q-tooltip>
            </q-btn>
          </div>
        </div>
      </q-toolbar>
    </q-header>

    <!-- Offline Banner Notification -->
    <div
      v-if="!isOnline"
      class="bg-orange-9 text-white text-center q-py-xs text-caption text-weight-bold full-width z-max"
      style="position: absolute; top: 56px; left: 0"
    >
      {{ $t('layouts.kiosk.offlineBanner') }}
    </div>

    <!-- Main Container -->
    <q-page-container :class="{ 'pt-banner': !isOnline }">
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
import { useLocale } from '../composables/useLocale';

const router = useRouter();
const kioskStore = useKioskStore();
const { locale, toggleOptions } = useLocale();

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
.leading-none {
  line-height: 1.25;
}

.pt-banner {
  padding-top: 80px !important;
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
