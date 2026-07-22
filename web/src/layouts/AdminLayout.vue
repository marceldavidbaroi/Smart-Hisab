<template>
  <q-layout view="hHh Lpr lFf" class="admin-layout">
    <q-header bordered class="bg-white text-dark border-bottom">
      <q-toolbar dense class="q-px-sm">
        <q-btn
          flat
          round
          icon="menu"
          aria-label="Menu"
          class="menu-btn text-grey-7 cursor-pointer q-mr-xs"
          @click="toggleLeftDrawer"
        />

        <div class="row items-center no-wrap col overflow-hidden">
          <img
            src="~@/assets/brand-mark.png"
            alt="Smart Hisab"
            class="header-brand-mark shrink-0 q-mr-sm"
          />
          <div class="column overflow-hidden min-width-0">
            <div class="text-weight-bold text-dark text-body2 ellipsis">
              <span class="lt-sm">{{ $t('admin.layout.platformAdmin') }}</span>
              <span class="gt-xs">{{ $t('admin.layout.console') }}</span>
            </div>
            <div class="text-caption text-grey-7 gt-xs" style="font-size: 11px; line-height: 1.2">
              {{ $t('admin.layout.globalControl') }}
            </div>
          </div>
          <q-badge
            color="secondary"
            text-color="dark"
            class="q-ml-sm text-weight-bold gt-sm shrink-0"
          >
            {{ $t('admin.layout.superadmin') }}
          </q-badge>
        </div>

        <q-space />

        <LocaleSwitcher class="q-mr-xs" />

        <q-btn-dropdown flat round class="user-menu-btn cursor-pointer">
          <template #label>
            <q-avatar size="36px" class="user-avatar text-white">
              <img
                v-if="tenantStore.userProfile?.avatar_url"
                :src="tenantStore.userProfile.avatar_url"
              />
              <span v-else>{{ userInitials }}</span>
            </q-avatar>
          </template>

          <q-list class="user-menu-list bg-white text-dark q-py-sm">
            <div class="q-px-md q-py-sm">
              <div class="text-weight-bold text-dark">
                {{ tenantStore.userProfile?.full_name || $t('admin.layout.adminUser') }}
              </div>
              <div class="text-caption text-grey-7 ellipsis">{{ tenantStore.user?.email }}</div>
              <q-badge color="secondary" text-color="dark" class="q-mt-xs text-weight-bold">
                {{ $t('admin.layout.superadmin') }}
              </q-badge>
            </div>

            <q-separator class="q-my-sm" />

            <q-item clickable v-close-popup class="text-negative" @click="handleSignOut">
              <q-item-section avatar>
                <q-icon name="logout" size="20px" color="negative" />
              </q-item-section>
              <q-item-section>{{ $t('admin.layout.signOut') }}</q-item-section>
            </q-item>
          </q-list>
        </q-btn-dropdown>
      </q-toolbar>
    </q-header>

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
        <div
          class="brand-section border-bottom row items-center q-px-sm full-width shrink-0"
          :class="miniState ? 'justify-center' : 'justify-start'"
        >
          <img
            src="../assets/brand-mark.png"
            alt="Smart Hisab"
            class="header-brand-mark shrink-0"
            :class="{ 'q-mr-sm': !miniState }"
          />
          <div v-if="!miniState" class="overflow-hidden min-width-0">
            <div class="text-weight-bold text-dark text-body2 ellipsis leading-tight">
              {{ $t('admin.layout.globalControl') }}
            </div>
            <div class="text-caption text-grey-7">{{ $t('admin.layout.platformAdmin') }}</div>
          </div>
        </div>

        <div class="border-bottom q-py-xs bg-white full-width shrink-0">
          <q-item class="q-px-sm full-width" dense>
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
                {{ tenantStore.userProfile?.full_name || $t('admin.layout.adminUser') }}
              </q-tooltip>
            </q-item-section>
            <q-item-section v-if="!miniState">
              <q-item-label class="text-weight-bold text-dark text-caption ellipsis">
                {{ tenantStore.userProfile?.full_name || $t('admin.layout.adminUser') }}
              </q-item-label>
              <q-item-label caption class="text-grey-7 ellipsis" style="font-size: 10px">
                {{ tenantStore.user?.email }}
              </q-item-label>
            </q-item-section>
          </q-item>
        </div>

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
                :key="item.to"
                clickable
                exact
                :to="item.to"
                class="nav-link-item q-mb-xs cursor-pointer"
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

        <div class="border-top q-py-sm bg-white full-width shrink-0">
          <q-item
            clickable
            class="q-px-sm text-negative full-width sign-out-item cursor-pointer"
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
                {{ $t('admin.layout.signOut') }}
              </q-tooltip>
            </q-item-section>
            <q-item-section v-if="!miniState">
              <q-item-label class="text-caption text-weight-bold">
                {{ $t('admin.layout.signOut') }}
              </q-item-label>
            </q-item-section>
          </q-item>
        </div>
      </div>
    </q-drawer>

    <q-page-container>
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
import { useQuasar } from 'quasar';
import { useTenantStore } from '../stores/tenant';
import { useI18n } from 'vue-i18n';
import LocaleSwitcher from '../components/LocaleSwitcher.vue';

const router = useRouter();
const $q = useQuasar();
const tenantStore = useTenantStore();
const { t } = useI18n();

const leftDrawerOpen = ref(false);
const isPinned = ref(false);
const miniState = ref(true);

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

const navGroups = computed(() => [
  {
    id: 'console',
    items: [
      {
        label: t('admin.layout.dashboard'),
        icon: 'dashboard',
        to: '/admin/dashboard',
      },
    ],
  },
  {
    id: 'management',
    label: t('admin.layout.platformAdmin'),
    items: [
      {
        label: t('admin.layout.tenants'),
        icon: 'business',
        to: '/admin/tenants',
      },
      {
        label: t('admin.layout.billing'),
        icon: 'credit_card',
        to: '/admin/billing',
      },
    ],
  },
]);

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

const handleSignOut = async () => {
  await tenantStore.logout();
  await router.push('/admin/auth/login');
};
</script>

<style scoped lang="scss">
.admin-layout {
  font-family: 'Outfit', 'Inter', sans-serif;
  background-color: var(--brand-surface);
}

.border-bottom {
  border-bottom: 1px solid rgba(14, 74, 71, 0.08);
}

.border-top {
  border-top: 1px solid rgba(14, 74, 71, 0.08);
}

.border-right {
  border-right: 1px solid rgba(14, 74, 71, 0.08);
}

.menu-btn,
.user-menu-btn {
  min-width: 44px;
  min-height: 44px;
}

.header-brand-mark {
  width: 32px;
  height: 32px;
  object-fit: contain;
  border-radius: var(--radius-md);
}

.user-avatar {
  background: linear-gradient(135deg, var(--brand-primary) 0%, var(--brand-accent) 100%);
  font-weight: 700;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.user-menu-list {
  min-width: 220px;
  max-width: min(280px, 90vw);
  border: 1px solid rgba(14, 74, 71, 0.1);
  border-radius: var(--radius-lg);
}

.brand-section {
  height: 56px;
}

.nav-group-label {
  font-size: 10px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.nav-link-item {
  border-radius: var(--radius-lg);
  color: #475569;
  min-height: 44px;
  transition:
    background-color 0.15s ease,
    color 0.15s ease;

  &:hover {
    background: var(--brand-soft);
    color: var(--brand-dark);
  }
}

.nav-active-item {
  background: rgba(14, 74, 71, 0.08) !important;
  color: var(--brand-primary) !important;
  border-left: 3px solid var(--brand-primary);
  font-weight: 600;
}

.sign-out-item {
  min-height: 48px;
  border-radius: var(--radius-lg);
}

.min-width-0 {
  min-width: 0;
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.25s ease;
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
