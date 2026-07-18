<template>
  <q-layout view="hHh Lpr lFf" class="workspace-layout">
    <!-- Header -->
    <q-header bordered class="bg-white border-bottom text-dark">
      <q-toolbar dense class="q-py-xs">
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          class="q-mr-sm text-grey-7 cursor-pointer"
          @click="toggleLeftDrawer"
        />

        <div class="row items-center no-wrap">
          <img
            src="~@/assets/brand-mark.png"
            alt="Smart Hisab"
            class="header-brand-mark q-mr-sm shrink-0"
          />
          <div class="column">
            <div class="text-weight-bold text-dark text-sm ellipsis" style="max-width: 40vw">
              {{ tenantStore.activeTenant?.name }}
            </div>
            <div
              class="text-caption text-grey-7 row items-center no-wrap gt-xs"
              style="font-size: 11px"
            >
              <span class="text-grey-5">{{ $t('layouts.workspace.poweredBy') }}</span>
              <span class="text-weight-bold text-primary q-ml-xs">Smart Hisab</span>
            </div>
          </div>
        </div>

        <q-space />

        <LocaleSwitcher class="q-mr-sm" />
      </q-toolbar>
    </q-header>

    <!-- Sidebar Navigation Drawer -->
    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      :mini="miniState"
      :width="260"
      :breakpoint="600"
      bordered
      class="bg-white text-dark border-right"
      @mouseover="onMouseOver"
      @mouseleave="onMouseOut"
    >
      <div class="column fit no-wrap">
        <!-- Workspace Title / Header / Tenant Selector -->
        <div
          class="brand-section border-bottom flex items-center q-px-sm full-width shrink-0"
          :class="miniState ? 'justify-center' : 'justify-start'"
        >
          <!-- Tenant Selector Dropdown (Shown ONLY if user has multiple tenants) -->
          <q-btn-dropdown
            v-if="tenantStore.myTenants && tenantStore.myTenants.length > 1"
            flat
            no-caps
            dense
            no-caret
            align="left"
            class="full-width tenant-sidebar-btn"
            content-class="tenant-dropdown-menu"
          >
            <template #label>
              <div class="row items-center no-wrap text-left full-width">
                <q-icon
                  name="workspaces"
                  size="20px"
                  class="text-primary"
                  :class="{ 'q-mr-sm': !miniState }"
                />
                <div v-if="!miniState" class="col text-ellipsis overflow-hidden">
                  <div class="text-weight-bold text-dark text-xs leading-none">
                    {{ tenantStore.activeTenant?.name || 'Workspace' }}
                  </div>
                  <div class="text-xxs text-grey-7 leading-none q-mt-xs">
                    {{ tenantStore.activeRole || 'Member' }}
                  </div>
                </div>
                <q-icon
                  v-if="!miniState"
                  name="arrow_drop_down"
                  size="16px"
                  class="text-grey-7 q-ml-xs"
                />
              </div>
            </template>

            <!-- Dropdown List of Tenants -->
            <q-list class="q-py-xs bg-white text-dark border-all">
              <q-item-label header class="text-grey-7 text-xs font-semibold q-pb-xs">
                {{ $t('layouts.workspace.switchWorkspace') }}
              </q-item-label>

              <q-item
                v-for="membership in tenantStore.myTenants"
                :key="membership.id"
                clickable
                v-close-popup
                :active="membership.tenants?.id === tenantStore.activeTenant?.id"
                active-class="active-tenant-item"
                class="q-py-sm tenant-select-item"
                @click="switchWorkspace(membership.tenants?.slug)"
              >
                <q-item-section avatar>
                  <q-avatar size="28px" class="tenant-avatar-small">
                    {{ getInitials(membership.tenants?.name || '') }}
                  </q-avatar>
                </q-item-section>
                <q-item-section>
                  <q-item-label class="text-weight-bold text-xs">
                    {{ membership.tenants?.name }}
                  </q-item-label>
                  <q-item-label caption class="text-grey-6" style="font-size: 10px">
                    {{ membership.tenant_roles?.name || 'Member' }}
                  </q-item-label>
                </q-item-section>
                <q-item-section side v-if="membership.tenants?.id === tenantStore.activeTenant?.id">
                  <q-icon name="check" color="primary" size="16px" />
                </q-item-section>
              </q-item>
            </q-list>
          </q-btn-dropdown>

          <!-- Otherwise, show a static tenant brand header (Single Tenant case) -->
          <div v-else class="row items-center no-wrap q-pl-xs">
            <q-icon
              name="workspaces"
              size="20px"
              class="text-primary"
              :class="{ 'q-mr-sm': !miniState }"
            />
            <div v-if="!miniState" class="q-ml-xs">
              <div class="text-weight-bold text-dark text-xs leading-tight">
                {{ tenantStore.activeTenant?.name || 'Workspace' }}
              </div>
              <div class="text-xxs text-grey-7 leading-none">
                {{ tenantStore.activeTenant?.slug }}
              </div>
            </div>
          </div>
        </div>

        <!-- User Profile Info -->
        <div class="border-bottom q-py-xs bg-white full-width shrink-0">
          <q-item
            clickable
            class="q-px-sm full-width"
            :to="`/${tenantStore.activeTenant?.slug}/settings`"
          >
            <q-item-section avatar>
              <q-avatar size="28px" class="user-avatar text-white">
                <img
                  v-if="tenantStore.userProfile?.avatar_url"
                  :src="tenantStore.userProfile.avatar_url"
                />
                <span v-else>{{ userInitials }}</span>
              </q-avatar>
              <q-tooltip
                v-if="miniState"
                anchor="center right"
                self="center left"
                :offset="[10, 10]"
              >
                {{ tenantStore.userProfile?.full_name || 'User Profile' }} ({{
                  tenantStore.user?.email
                }})
              </q-tooltip>
            </q-item-section>
            <q-item-section v-if="!miniState">
              <q-item-label class="text-weight-bold text-xs text-dark leading-tight">
                {{ tenantStore.userProfile?.full_name || 'User Profile' }}
              </q-item-label>
              <q-item-label
                caption
                class="text-caption text-grey-7 leading-none q-mt-xs"
                style="font-size: 10px"
              >
                {{ tenantStore.user?.email }}
              </q-item-label>
            </q-item-section>
          </q-item>
        </div>

        <!-- Scrollable grouped nav -->
        <q-scroll-area class="col full-width">
          <q-list class="q-px-sm q-pt-sm q-pb-md full-width">
            <template v-for="(group, groupIndex) in navGroups" :key="group.id">
              <q-separator
                v-if="groupIndex > 0"
                class="q-my-sm"
                :class="miniState ? 'q-mx-xs' : 'q-mx-sm'"
              />
              <q-item-label
                v-if="group.label && !miniState"
                header
                class="nav-group-label text-grey-6 text-weight-bold"
              >
                {{ group.label }}
              </q-item-label>

              <q-item
                v-for="item in group.items"
                :key="item.toName"
                clickable
                exact
                :to="{
                  name: item.toName,
                  params: { tenantSlug: tenantStore.activeTenant?.slug },
                }"
                class="nav-link-item q-mb-xs"
                active-class="nav-active-item"
              >
                <q-item-section avatar>
                  <q-icon :name="item.icon" size="22px" />
                </q-item-section>
                <q-item-section v-if="!miniState">{{ item.label }}</q-item-section>
                <q-tooltip
                  v-if="miniState"
                  anchor="center right"
                  self="center left"
                  :offset="[10, 10]"
                >
                  {{ item.label }}
                </q-tooltip>
              </q-item>
            </template>
          </q-list>
        </q-scroll-area>

        <!-- Sign Out pinned to drawer bottom -->
        <div class="border-top q-py-sm bg-white full-width shrink-0">
          <q-item
            clickable
            class="q-px-sm text-negative full-width sign-out-item"
            @click="handleSignOut"
          >
            <q-item-section avatar>
              <q-icon name="logout" size="20px" color="negative" />
              <q-tooltip
                v-if="miniState"
                anchor="center right"
                self="center left"
                :offset="[10, 10]"
              >
                {{ $t('layouts.workspace.signOut') }}
              </q-tooltip>
            </q-item-section>
            <q-item-section v-if="!miniState">
              <q-item-label class="text-xs text-weight-bold">{{
                $t('layouts.workspace.signOut')
              }}</q-item-label>
            </q-item-section>
          </q-item>
        </div>
      </div>
    </q-drawer>

    <!-- Page Container -->
    <q-page-container class="bg-grey-2 text-dark min-h-screen">
      <ActiveSessionBanner />
      <router-view v-slot="{ Component }">
        <transition name="fade-slide" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </q-page-container>

    <!-- Create Workspace Dialog -->
    <q-dialog v-model="showCreateWorkspaceDialog" persistent>
      <q-card
        style="width: 450px; max-width: 90vw; border-radius: 16px"
        class="q-pa-md bg-white text-dark"
      >
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-bold text-dark">
            {{ $t('layouts.workspace.createNewWorkspace') }}
          </div>
          <q-space />
          <q-btn
            icon="close"
            flat
            round
            dense
            v-close-popup
            class="cursor-pointer text-grey-7"
            :disable="createLoading"
          />
        </q-card-section>

        <q-card-section class="q-pt-md">
          <q-banner
            v-if="createErrorMsg"
            class="bg-red-9 text-white rounded-borders q-mb-md text-sm"
          >
            <template #avatar>
              <q-icon name="warning" color="white" />
            </template>
            {{ createErrorMsg }}
          </q-banner>

          <q-form @submit.prevent="handleCreateWorkspace" class="q-gutter-y-md">
            <div>
              <label class="text-grey-7 font-semibold q-mb-xs block text-xs">{{
                $t('layouts.workspace.workspaceName')
              }}</label>
              <q-input
                v-model="newWorkspaceName"
                type="text"
                filled
                placeholder="Acme Corp"
                color="primary"
                class="custom-input"
                :rules="[(val) => !!val || $t('layouts.workspace.workspaceNameRequired')]"
                hide-bottom-space
                @update:model-value="autoGenerateSlug"
              />
            </div>

            <div>
              <label class="text-grey-7 font-semibold q-mb-xs block text-xs">{{
                $t('layouts.workspace.workspaceSlug')
              }}</label>
              <q-input
                v-model="newWorkspaceSlug"
                type="text"
                filled
                placeholder="acme-corp"
                color="primary"
                class="custom-input"
                :rules="[
                  (val) => !!val || $t('layouts.workspace.workspaceSlugRequired'),
                  (val) => /^[a-z0-9-]+$/.test(val) || $t('layouts.workspace.workspaceSlugInvalid'),
                ]"
                hide-bottom-space
                prefix="app.domain.com/"
              />
            </div>

            <div class="row justify-end q-mt-lg q-gutter-sm">
              <q-btn
                flat
                :label="$t('common.cancel')"
                v-close-popup
                :disable="createLoading"
                class="cursor-pointer text-grey-7"
              />
              <q-btn
                type="submit"
                color="primary"
                :label="$t('layouts.workspace.createWorkspace')"
                :loading="createLoading"
                class="q-px-md cursor-pointer btn-gradient text-weight-bold"
              />
            </div>
          </q-form>
        </q-card-section>
      </q-card>
    </q-dialog>
  </q-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useQuasar } from 'quasar';
import { useTenantStore } from '../stores/tenant';
import { useSessionStore } from '../stores/session';
import { createTenant } from '../services/multiTenant';
import ActiveSessionBanner from '../components/sessions/ActiveSessionBanner.vue';
import LocaleSwitcher from '../components/LocaleSwitcher.vue';
import { useI18n } from 'vue-i18n';

const router = useRouter();
const $q = useQuasar();
const tenantStore = useTenantStore();
const sessionStore = useSessionStore();
const { t } = useI18n();

const leftDrawerOpen = ref(false);
const isPinned = ref(false);
const miniState = ref(true);

const loadActiveSession = async () => {
  if (tenantStore.isFeatureEnabled('shift-sessions')) {
    try {
      await sessionStore.fetchActiveSession();
    } catch (err) {
      console.error('Failed to load active session:', err);
    }
  } else {
    sessionStore.clearSession();
  }
};

onMounted(() => {
  void loadActiveSession();
});

watch(
  () => tenantStore.activeTenant?.id,
  () => {
    void loadActiveSession();
  },
);

const showCreateWorkspaceDialog = ref(false);
const newWorkspaceName = ref('');
const newWorkspaceSlug = ref('');
const createLoading = ref(false);
const createErrorMsg = ref('');

const autoGenerateSlug = (val: string | number | null) => {
  const strVal = String(val || '');
  newWorkspaceSlug.value = strVal
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
};

const handleCreateWorkspace = async () => {
  createLoading.value = true;
  createErrorMsg.value = '';
  try {
    await createTenant(newWorkspaceName.value, newWorkspaceSlug.value);
    await tenantStore.loadUserProfileAndTenants();
    await tenantStore.setActiveTenantBySlug(newWorkspaceSlug.value);
    showCreateWorkspaceDialog.value = false;
    newWorkspaceName.value = '';
    newWorkspaceSlug.value = '';
    await router.push(`/${newWorkspaceSlug.value}/dashboard`);
  } catch (err) {
    const error = err as Error;
    createErrorMsg.value = error.message || 'Failed to create workspace. Slug might be taken.';
  } finally {
    createLoading.value = false;
  }
};

interface NavItem {
  label: string;
  icon: string;
  toName: string;
  requiredFeature?: string;
  requiredPermission?: string;
  requiredModulePermission?: { module: string; permission: string };
}

interface NavGroup {
  id: string;
  label?: string;
  items: NavItem[];
}

const isNavItemVisible = (item: NavItem): boolean => {
  if (item.requiredFeature && !tenantStore.isFeatureEnabled(item.requiredFeature)) {
    return false;
  }
  if (item.requiredPermission && !tenantStore.hasPermission(item.requiredPermission, 'read')) {
    return false;
  }
  if (
    item.requiredModulePermission &&
    !tenantStore.hasModulePermission(
      item.requiredModulePermission.module,
      item.requiredModulePermission.permission,
    )
  ) {
    return false;
  }
  return true;
};

const navGroups = computed<NavGroup[]>(() => {
  const groups: NavGroup[] = [
    {
      id: 'home',
      items: [
        {
          label: t('nav.dashboard'),
          icon: 'dashboard',
          toName: 'workspace-dashboard',
        },
      ],
    },
    {
      id: 'operations',
      label: t('nav.groups.operations'),
      items: [
        {
          label: t('customers.nav.label'),
          icon: 'face',
          toName: 'workspace-customers',
          requiredFeature: 'meal-management',
          requiredModulePermission: {
            module: 'meal_management',
            permission: 'customer_read',
          },
        },
        {
          label: t('nav.sessions'),
          icon: 'point_of_sale',
          toName: 'workspace-sessions',
          requiredFeature: 'shift-sessions',
          requiredModulePermission: {
            module: 'operational_shifts',
            permission: 'sessions_read',
          },
        },
      ],
    },
    {
      id: 'finance',
      label: t('nav.groups.finance'),
      items: [
        {
          label: t('nav.ledger'),
          icon: 'account_balance_wallet',
          toName: 'workspace-ledger',
          requiredFeature: 'financial-ledger',
          requiredModulePermission: {
            module: 'financial_ledger',
            permission: 'ledger_read',
          },
        },
        {
          label: t('nav.finance'),
          icon: 'assessment',
          toName: 'workspace-finance',
          requiredFeature: 'financial-ledger',
          requiredModulePermission: {
            module: 'financial_ledger',
            permission: 'dashboard_read',
          },
        },
      ],
    },
    {
      id: 'manage',
      label: t('nav.groups.manage'),
      items: [
        {
          label: t('nav.members'),
          icon: 'people',
          toName: 'workspace-members',
          requiredPermission: 'members',
        },
        {
          label: t('nav.shiftsConfig'),
          icon: 'schedule',
          toName: 'workspace-shifts',
          requiredFeature: 'shift-sessions',
          requiredModulePermission: {
            module: 'operational_shifts',
            permission: 'shifts_config_read',
          },
        },
        {
          label: t('nav.settings'),
          icon: 'settings',
          toName: 'workspace-settings',
          requiredPermission: 'settings',
        },
      ],
    },
  ];

  return groups
    .map((group) => ({
      ...group,
      items: group.items.filter(isNavItemVisible),
    }))
    .filter((group) => group.items.length > 0);
});

const toggleLeftDrawer = () => {
  if ($q.screen.gt.xs) {
    isPinned.value = !isPinned.value;
    miniState.value = !isPinned.value;
  } else {
    leftDrawerOpen.value = !leftDrawerOpen.value;
    miniState.value = false;
  }
};

const onMouseOver = () => {
  if ($q.screen.gt.xs && !isPinned.value) {
    miniState.value = false;
  }
};

const onMouseOut = () => {
  if ($q.screen.gt.xs && !isPinned.value) {
    miniState.value = true;
  }
};

const getInitials = (name: string) => {
  if (!name) return 'WS';
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

const switchWorkspace = async (slug?: string) => {
  if (!slug) return;
  await router.push(`/${slug}/dashboard`);
};

const handleSignOut = async () => {
  await tenantStore.logout();
  await router.push('/auth/login');
};
</script>

<style scoped lang="scss">
.workspace-layout {
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

.tenant-dropdown-btn {
  padding: 2px 8px;
  border-radius: 8px;
  border: 1px solid #cbd5e1;
  background: #f8fafc;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
    border-color: #94a3b8;
  }
}

.tenant-sidebar-btn {
  width: 100%;
  border-radius: 8px;
  padding: 4px;

  &:hover {
    background: rgba(0, 0, 0, 0.03);
  }
}

.user-avatar {
  background: linear-gradient(135deg, #0e4a47 0%, #2ec4b6 100%);
  font-weight: 700;
  border: 1px solid rgba(255, 255, 255, 0.2);
  cursor: pointer;
}

.tenant-avatar {
  background: linear-gradient(135deg, #0e4a47 0%, #2ec4b6 100%);
  font-weight: 700;
  border: 1.5px solid rgba(255, 255, 255, 0.2);
}

.tenant-avatar-small {
  background: linear-gradient(135deg, #0e4a47 0%, #2ec4b6 100%);
  color: white;
  font-weight: 700;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.header-brand-mark {
  width: 36px;
  height: 36px;
  object-fit: contain;
  border-radius: 8px;
}

.active-tenant-item {
  background: rgba(14, 74, 71, 0.08) !important;
  color: #0e4a47 !important;
}

.nav-active-item {
  background: rgba(14, 74, 71, 0.08) !important;
  color: #0e4a47 !important;
  border-left: 3px solid #0e4a47;
  font-weight: 600;
}

.tenant-dropdown-menu {
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08);
  border-radius: 12px;
  overflow: hidden;
}

.tenant-select-item {
  border-radius: 8px;
  margin: 4px 8px;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
  }
}

.nav-link-item {
  border-radius: 12px;
  color: #475569;
  transition: all 0.2s ease;

  &:hover {
    background: #f1f5f9;
    color: #1a2223;
  }
}

.brand-section {
  height: 64px;
}

.nav-group-label {
  font-size: 10px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  padding: 4px 12px 6px;
  line-height: 1.2;
}

.sign-out-item {
  min-height: 48px;
  border-radius: 12px;
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
  color: #1a2223 !important;

  &:hover {
    border-color: #94a3b8;
  }
}
</style>
