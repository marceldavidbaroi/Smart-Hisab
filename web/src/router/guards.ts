import type { Router, RouteLocationRaw, RouteLocationNormalized } from 'vue-router';
import type { Pinia } from 'pinia';
import { useTenantStore } from '../stores/tenant';
import { useKioskStore } from '../stores/kiosk';
import { Notify } from 'quasar';

function noTenantTarget(isSuperadmin = false): RouteLocationRaw {
  const allowSelfService = import.meta.env.ALLOW_SELF_SERVICE_TENANTS !== 'false';
  return { name: allowSelfService || isSuperadmin ? 'no-tenant' : 'pending-access' };
}

function firstWorkspaceSlug(tenantStore: ReturnType<typeof useTenantStore>): string | null {
  for (const membership of tenantStore.myTenants) {
    const tenants = membership.tenants as unknown;
    // Supabase may return object OR array for nested FK selects
    if (Array.isArray(tenants)) {
      const slug = (tenants[0] as { slug?: string } | undefined)?.slug;
      if (slug) return slug;
    } else if (tenants && typeof tenants === 'object') {
      const slug = (tenants as { slug?: string }).slug;
      if (slug) return slug;
    }
  }
  return null;
}

/** Prefer active admin console; otherwise workspace; else no-tenant gate. */
function redirectTenantScope(tenantStore: ReturnType<typeof useTenantStore>): RouteLocationRaw {
  if (tenantStore.isSuperadmin && tenantStore.isAdminSession) {
    return { name: 'admin-dashboard' };
  }
  const slug = firstWorkspaceSlug(tenantStore);
  if (slug) {
    return { name: 'workspace-dashboard', params: { tenantSlug: slug } };
  }
  return noTenantTarget(tenantStore.isSuperadmin);
}

function isInAdminScope(tenantStore: ReturnType<typeof useTenantStore>): boolean {
  return tenantStore.isSuperadmin && tenantStore.isAdminSession;
}

/** Platform admin login scope: always admin portal (never workspace). */
function redirectAdminScope(
  tenantStore: ReturnType<typeof useTenantStore>,
  to: RouteLocationNormalized,
): RouteLocationRaw | true {
  if (!tenantStore.hasUserProfile) {
    return { name: 'error-403' };
  }
  if (!tenantStore.isSuperadmin) {
    // Stay on /admin/auth/login so the page can show Access Denied after a fresh login.
    return true;
  }
  tenantStore.setAdminSession(true);
  const deepLink = redirectFromQuery(to);
  if (isSafeAdminDeepLink(deepLink)) {
    return deepLink;
  }
  return { name: 'admin-dashboard' };
}

function isAdminLoginRoute(to: RouteLocationNormalized) {
  return to.name === 'admin-login' || to.query.scope === 'admin';
}

/** Safe post-login deep link from `?redirect=` (same-origin path only). */
function redirectFromQuery(to: RouteLocationNormalized): string | null {
  const raw = to.query.redirect;
  if (typeof raw !== 'string' || !raw.startsWith('/') || raw.startsWith('//')) {
    return null;
  }
  return raw;
}

function isSafeAdminDeepLink(path: string | null): path is string {
  return !!path && path.startsWith('/admin') && !path.startsWith('/admin/auth');
}

function isSafeWorkspaceDeepLink(path: string | null): path is string {
  return !!path && path.startsWith('/') && !path.startsWith('/admin');
}

export function setupRouteGuards(router: Router, pinia: Pinia) {
  router.beforeEach(async (to) => {
    const tenantStore = useTenantStore(pinia);
    const kioskStore = useKioskStore(pinia);

    const isPaired = kioskStore.isDevicePaired;

    // 1. Kiosk-Specific Route Guards
    if (to.path.startsWith('/kiosk')) {
      if (to.meta.requiresPairing && !isPaired) {
        return { name: 'kiosk-pair' };
      }
      if (to.name === 'kiosk-pair' && isPaired) {
        return { name: 'kiosk-login' };
      }
      if (to.meta.requiresStaffAuth && !kioskStore.isStaffAuthenticated) {
        return { name: 'kiosk-login' };
      }
      return true;
    }

    // 2. Device-Level Kiosk Lock (paired devices stay in kiosk UI)
    if (isPaired) {
      return {
        name: kioskStore.isStaffAuthenticated ? 'kiosk-workspace' : 'kiosk-login',
      };
    }

    // 3. Ensure the store is initialized with auth state
    if (!tenantStore.initialized) {
      await tenantStore.initializeStore();
    }

    const isAuthenticated = !!tenantStore.user;
    const isAuthRoute =
      to.path.startsWith('/auth') || to.name === 'tenant-login' || to.name === 'admin-login';
    const isAdminRoute = to.path.startsWith('/admin');
    const tenantSlug = to.params.tenantSlug as string | undefined;
    const isNoTenantGate = to.name === 'no-tenant' || to.name === 'pending-access';
    const isForbiddenRoute = to.name === 'error-403' || to.path.startsWith('/forbidden');

    // 4. Unauthenticated user flow
    if (!isAuthenticated) {
      if (isAuthRoute) return true;
      if (isAdminRoute) {
        return { name: 'admin-login', query: { redirect: to.fullPath } };
      }
      return { name: 'login', query: { redirect: to.fullPath } };
    }

    // 4b. Authenticated but no user_profiles row — block platform/workspace (not login form itself)
    if (!tenantStore.hasUserProfile && !isForbiddenRoute) {
      if (
        to.name === 'login' ||
        to.name === 'admin-login' ||
        to.name === 'tenant-login' ||
        to.name === 'signup'
      ) {
        return true;
      }
      return { name: 'error-403' };
    }

    // 5. Authenticated user on auth routes — honor login scope
    if (isAuthRoute) {
      if (isNoTenantGate) {
        if (firstWorkspaceSlug(tenantStore)) {
          return redirectTenantScope(tenantStore);
        }
        const allowSelfService = import.meta.env.ALLOW_SELF_SERVICE_TENANTS !== 'false';
        if (to.name === 'no-tenant' && !allowSelfService && !tenantStore.isSuperadmin) {
          return { name: 'pending-access' };
        }
        if (to.name === 'pending-access' && (allowSelfService || tenantStore.isSuperadmin)) {
          return { name: 'no-tenant' };
        }
        return true;
      }

      // /admin/auth/login (or ?scope=admin) → platform scope BEFORE deep-link
      if (isAdminLoginRoute(to)) {
        return redirectAdminScope(tenantStore, to);
      }

      // Admin scope sticky: never follow workspace deep-links while in platform mode
      if (isInAdminScope(tenantStore)) {
        return { name: 'admin-dashboard' };
      }

      // Workspace login deep-link (never into /admin without admin scope)
      const deepLink = redirectFromQuery(to);
      if (isSafeWorkspaceDeepLink(deepLink)) {
        return deepLink;
      }

      // /auth/login, /:slug/login → tenant/workspace scope
      return redirectTenantScope(tenantStore);
    }

    // 6. Authenticated, no usable workspace, not superadmin → force gate page
    if (
      !firstWorkspaceSlug(tenantStore) &&
      !tenantStore.isSuperadmin &&
      !isNoTenantGate &&
      !isForbiddenRoute
    ) {
      return noTenantTarget();
    }

    // 7. Admin access check (/admin/auth/login already handled above as auth route)
    if (isAdminRoute) {
      if (!tenantStore.isSuperadmin) {
        return { name: 'error-403' };
      }
      // Tenant scope sticky: require explicit admin login to enter platform mode
      if (!tenantStore.isAdminSession) {
        return { name: 'admin-login', query: { redirect: to.fullPath } };
      }
      return true;
    }

    // 8. Tenant workspace access check
    if (tenantSlug) {
      // Admin scope sticky: stay in platform console unless explicitly switched
      if (isInAdminScope(tenantStore)) {
        return { name: 'admin-dashboard' };
      }

      try {
        await tenantStore.setActiveTenantBySlug(tenantSlug);

        const requiredFeature = to.meta.requiredFeature as string | undefined;
        if (requiredFeature && !tenantStore.isFeatureEnabled(requiredFeature)) {
          Notify.create({
            type: 'warning',
            message: `The "${requiredFeature.toUpperCase()}" module is not enabled for this workspace.`,
            position: 'top',
            timeout: 3000,
          });
          return { name: 'workspace-dashboard', params: { tenantSlug } };
        }

        const requiredPermission = to.meta.requiredPermission as string | undefined;
        if (requiredPermission && !tenantStore.hasPermission(requiredPermission, 'read')) {
          Notify.create({
            type: 'negative',
            message: `You do not have permission to access the "${requiredPermission}" module.`,
            position: 'top',
            timeout: 3000,
          });
          return { name: 'workspace-dashboard', params: { tenantSlug } };
        }

        const requiredModulePermission = to.meta.requiredModulePermission as
          | {
              module: string;
              permission: string;
            }
          | undefined;
        if (
          requiredModulePermission &&
          !tenantStore.hasModulePermission(
            requiredModulePermission.module,
            requiredModulePermission.permission,
          )
        ) {
          Notify.create({
            type: 'negative',
            message: `You do not have permission to access this page.`,
            position: 'top',
            timeout: 3000,
          });
          return { name: 'workspace-dashboard', params: { tenantSlug } };
        }

        return true;
      } catch (err) {
        const error = err as Error;
        console.error(`Access verification failed for tenant slug: ${tenantSlug}`, error.message);
        return { name: 'error-403' };
      }
    }

    // 9. Root `/` — default to tenant scope (not admin)
    if (to.path === '/') {
      return redirectTenantScope(tenantStore);
    }

    return true;
  });
}
