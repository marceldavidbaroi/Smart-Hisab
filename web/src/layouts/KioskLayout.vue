<template>
  <q-layout view="hHh lpR fFf" class="bg-grey-10 text-white overflow-hidden select-none">
    <!-- Header/Kiosk Status Bar -->
    <q-header elevated class="bg-grey-9 text-white bordered-bottom">
      <q-toolbar class="q-px-md" style="min-height: 56px">
        <q-icon name="devices" size="24px" class="q-mr-sm text-primary" />
        <div>
          <div class="text-subtitle2 text-weight-bold leading-none">
            {{ tenantName || 'Smart Hisab' }}
          </div>
          <div class="text-caption text-grey-5 leading-none">
            Terminal: {{ deviceName || 'Kiosk' }}
          </div>
        </div>

        <q-space />

        <!-- Status Indicators -->
        <div class="row items-center q-gutter-x-md">
          <!-- Connection Status -->
          <q-badge
            :color="isOnline ? 'positive' : 'negative'"
            class="q-py-xs q-px-sm text-weight-medium rounded-borders"
            style="min-height: 24px"
          >
            <q-icon :name="isOnline ? 'wifi' : 'wifi_off'" size="14px" class="q-mr-xs" />
            <span class="gt-xs">{{ isOnline ? 'Online' : 'Offline' }}</span>
          </q-badge>

          <!-- Active Staff Member -->
          <div v-if="kioskStore.isStaffAuthenticated" class="row items-center q-gutter-x-sm">
            <q-avatar size="28px" color="primary" text-color="white" class="text-weight-bold">
              {{ currentStaffName.charAt(0).toUpperCase() }}
            </q-avatar>
            <div class="column gt-xs">
              <span class="text-caption text-weight-medium text-white leading-none">
                {{ currentStaffName }}
              </span>
              <span class="text-caption text-grey-5 leading-none" style="font-size: 0.75rem">
                {{ currentStaffRole }}
              </span>
            </div>
            <q-btn
              flat
              dense
              round
              color="red-4"
              icon="logout"
              size="sm"
              class="cursor-pointer"
              @click="handleLogout"
            >
              <q-tooltip class="bg-red text-white">Clock Out</q-tooltip>
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
      Network connection lost. Offline operations enabled (Read Only).
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
.bordered-bottom {
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

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
