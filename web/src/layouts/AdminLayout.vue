<template>
  <q-layout view="hHh Lpr lFf" class="admin-layout">
    <!-- Header -->
    <q-header elevated class="bg-slate-950 border-bottom text-slate-800">
      <q-toolbar class="q-py-sm">
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          class="q-mr-sm text-slate-600"
          @click="toggleLeftDrawer"
        />

        <div class="row items-center q-gutter-sm">
          <q-icon name="admin_panel_settings" size="28px" class="text-amber-800" />
          <q-toolbar-title class="text-weight-bold text-slate-900">
            {{ $t('admin.layout.console') }}
          </q-toolbar-title>
          <q-badge color="amber" text-color="black" class="text-weight-bold uppercase">
            {{ $t('admin.layout.superadmin') }}
          </q-badge>
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

        <!-- View Workspaces Button -->
        <q-btn
          flat
          no-caps
          icon="launch"
          :label="$t('admin.layout.workspaceView')"
          color="amber-9"
          class="q-mr-md"
          @click="goToWorkspace"
        />

        <!-- User Profile Dropdown -->
        <div class="row items-center no-wrap">
          <q-btn-dropdown flat round dense class="user-dropdown-btn">
            <template #label>
              <q-avatar size="32px" class="user-avatar text-white">
                <img
                  v-if="tenantStore.userProfile?.avatar_url"
                  :src="tenantStore.userProfile.avatar_url"
                />
                <span v-else>{{ userInitials }}</span>
              </q-avatar>
            </template>

            <q-list style="min-width: 220px" class="bg-slate-950 text-slate-900 border-all q-py-sm">
              <div class="q-px-md q-py-sm">
                <div class="text-weight-bold text-amber-900">
                  {{ tenantStore.userProfile?.full_name || $t('admin.layout.adminUser') }}
                </div>
                <div class="text-caption text-slate-500">{{ tenantStore.user?.email }}</div>
                <div class="q-mt-xs">
                  <q-badge color="amber" class="text-black text-weight-bold">{{
                    $t('admin.layout.superadmin')
                  }}</q-badge>
                </div>
              </div>

              <q-separator class="q-my-sm" />

              <q-item clickable v-close-popup @click="handleSignOut" class="text-negative">
                <q-item-section avatar>
                  <q-icon name="logout" size="20px" color="negative" />
                </q-item-section>
                <q-item-section>{{ $t('admin.layout.signOut') }}</q-item-section>
              </q-item>
            </q-list>
          </q-btn-dropdown>
        </div>
      </q-toolbar>
    </q-header>

    <!-- Sidebar Drawer -->
    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      bordered
      class="bg-slate-950 text-slate-900 border-right"
      :width="260"
    >
      <div class="drawer-content flex flex-col justify-between">
        <div>
          <!-- Brand Logo/Header -->
          <div class="q-pa-md brand-section border-bottom flex items-center">
            <q-icon name="shield" size="28px" class="text-amber-800 q-mr-sm" />
            <div>
              <div class="text-weight-bold text-slate-900 text-subtitle1 leading-tight">
                {{ $t('admin.layout.globalControl') }}
              </div>
              <div class="text-xs text-slate-500">{{ $t('admin.layout.platformAdmin') }}</div>
            </div>
          </div>

          <!-- Navigation Links -->
          <q-list class="q-px-sm q-py-md">
            <q-item
              clickable
              exact
              to="/admin/dashboard"
              class="nav-link-item q-mb-sm"
              active-class="nav-active-item"
            >
              <q-item-section avatar>
                <q-icon name="dashboard" size="22px" />
              </q-item-section>
              <q-item-section>{{ $t('admin.layout.dashboard') }}</q-item-section>
            </q-item>

            <q-item
              clickable
              to="/admin/tenants"
              class="nav-link-item q-mb-sm"
              active-class="nav-active-item"
            >
              <q-item-section avatar>
                <q-icon name="business" size="22px" />
              </q-item-section>
              <q-item-section>{{ $t('admin.layout.tenants') }}</q-item-section>
            </q-item>

            <q-item
              clickable
              to="/admin/billing"
              class="nav-link-item q-mb-sm"
              active-class="nav-active-item"
            >
              <q-item-section avatar>
                <q-icon name="credit_card" size="22px" />
              </q-item-section>
              <q-item-section>{{ $t('admin.layout.billing') }}</q-item-section>
            </q-item>
          </q-list>
        </div>

        <!-- Footer / Version -->
        <div class="q-pa-md text-center text-xs text-slate-400 border-top">
          {{ $t('admin.layout.version') }}
        </div>
      </div>
    </q-drawer>

    <!-- Page Container -->
    <q-page-container class="bg-slate-900 text-slate-800 min-h-screen">
      <router-view v-slot="{ Component }">
        <transition name="fade-slide" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useTenantStore } from '../stores/tenant';
import { useLocale } from '../composables/useLocale';

const router = useRouter();
const tenantStore = useTenantStore();
const leftDrawerOpen = ref(true);
const { locale, toggleOptions } = useLocale();

const toggleLeftDrawer = () => {
  leftDrawerOpen.value = !leftDrawerOpen.value;
};

const getInitials = (name: string) => {
  if (!name) return 'AD';
  return name
    .split(' ')
    .map((word) => word[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();
};

const userInitials = computed(() => {
  const profileName = tenantStore.userProfile?.full_name || tenantStore.user?.email || '';
  return getInitials(profileName);
});

const goToWorkspace = async () => {
  if (tenantStore.myTenants.length > 0 && tenantStore.myTenants[0]?.tenants) {
    await router.push(`/${tenantStore.myTenants[0]?.tenants?.slug}/dashboard`);
  } else {
    await router.push('/');
  }
};

const handleSignOut = async () => {
  await tenantStore.logout();
  await router.push('/auth/login');
};
</script>

<style scoped lang="scss">
.admin-layout {
  font-family: 'Outfit', 'Inter', sans-serif;
  background-color: #f8fafc;
}

.bg-slate-900 {
  background-color: #f8fafc !important;
}

.bg-slate-950 {
  background-color: #ffffff !important;
}

.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.border-top {
  border-top: 1px solid rgba(0, 0, 0, 0.06);
}

.border-right {
  border-right: 1px solid rgba(0, 0, 0, 0.06);
}

.border-all {
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.user-avatar {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  font-weight: 700;
  border: 1px solid rgba(255, 255, 255, 0.2);
  cursor: pointer;
}

.nav-link-item {
  border-radius: 12px;
  color: #475569;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
    color: #0f172a;
  }
}

.nav-active-item {
  background: rgba(245, 158, 11, 0.08) !important;
  color: #b45309 !important;
  border-left: 3px solid #f59e0b;
  font-weight: 600;
}

.drawer-content {
  height: 100%;
}

.brand-section {
  height: 64px;
}

/* Transitions */
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.3s ease;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
