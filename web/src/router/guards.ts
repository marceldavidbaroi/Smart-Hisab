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

/** Normal / tenant login scope: workspace first; admin only as last-resort fallback. */
function redirectTenantScope(tenantStore: ReturnType<typeof useTenantStore>): RouteLocationRaw {
  const slug = firstWorkspaceSlug(tenantStore);
  if (slug) {
    return { name: 'workspace-dashboard', params: { tenantSlug: slug } };
  }
  return noTenantTarget(tenantStore.isSuperadmin);
}

/** Platform admin login scope: always admin portal (never workspace). */
function redirectAdminScope(
  tenantStore: ReturnType<typeof useTenantStore>,
): RouteLocationRaw | true {
  if (tenantStore.isSuperadmin) {
    tenantStore.setAdminSession(true);
    return { name: 'admin-dashboard' };
  }
  // Stay on /admin/auth/login so the page can show Access Denied.
  return true;
}

function isAdminLoginRoute(to: RouteLocationNormalized) {
  return to.name === 'admin-login' || to.query.scope === 'admin';
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

    // 4. Unauthenticated user flow
    if (!isAuthenticated) {
      if (isAuthRoute) return true;
      if (isAdminRoute) {
        return { name: 'admin-login', query: { redirect: to.fullPath } };
      }
      return { name: 'login', query: { redirect: to.fullPath } };
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

      // /admin/auth/login (or ?scope=admin) → platform scope only
      if (isAdminLoginRoute(to)) {
        return redirectAdminScope(tenantStore);
      }

      // /auth/login, /:slug/login → tenant/workspace scope
      return redirectTenantScope(tenantStore);
    }

    // 6. Authenticated, no usable workspace, not superadmin → force gate page
    if (
      !firstWorkspaceSlug(tenantStore) &&
      !tenantStore.isSuperadmin &&
      !isNoTenantGate &&
      !to.path.startsWith('/forbidden')
    ) {
      return noTenantTarget();
    }

    // 7. Admin access check
    if (isAdminRoute) {
      if (tenantStore.isSuperadmin && tenantStore.isAdminSession) return true;
      return { name: 'error-403' };
    }

    // 8. Tenant workspace access check
    if (tenantSlug) {
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
