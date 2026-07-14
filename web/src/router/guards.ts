import type { Router, NavigationGuardNext } from 'vue-router';
import type { Pinia } from 'pinia';
import { useTenantStore } from '../stores/tenant';
import { Notify } from 'quasar';

export function setupRouteGuards(router: Router, pinia: Pinia) {
  router.beforeEach(async (to, from, next) => {
    const tenantStore = useTenantStore(pinia);

    // 1. Device-Level Kiosk Lock Check
    const deviceToken = localStorage.getItem('device_token');
    const isCounterLoginRoute = to.name === 'counter-login';
    // If a device token exists, force to counter-login (unless they have a valid staff session which we can check later)
    if (deviceToken && !isCounterLoginRoute) {
      next({ name: 'counter-login' });
      return;
    }

    // 2. Ensure the store is initialized with auth state
    if (!tenantStore.initialized) {
      await tenantStore.initializeStore();
    }

    const isAuthenticated = !!tenantStore.user;
    const isAuthRoute =
      to.path.startsWith('/auth') || to.name === 'tenant-login' || to.name === 'admin-login';
    const isAdminRoute = to.path.startsWith('/admin');
    const tenantSlug = to.params.tenantSlug as string | undefined;

    // 2. Unauthenticated user flow
    if (!isAuthenticated) {
      if (isAuthRoute) {
        next();
      } else {
        // Redirect to login, preserving target path in redirect query
        next({
          name: 'login',
          query: { redirect: to.fullPath },
        });
      }
      return;
    }

    // 3. Authenticated user flow: prevent accessing auth routes directly
    if (isAuthRoute) {
      if (to.name === 'no-tenant' || to.name === 'pending-access') {
        const allowSelfService = import.meta.env.ALLOW_SELF_SERVICE_TENANTS !== 'false';

        if (tenantStore.myTenants.length === 0 && !tenantStore.isSuperadmin) {
          if (to.name === 'no-tenant' && !allowSelfService) {
            next({ name: 'pending-access' });
          } else if (to.name === 'pending-access' && allowSelfService) {
            next({ name: 'no-tenant' });
          } else {
            next();
          }
        } else {
          // Otherwise send them to their dashboard
          redirectDefault(tenantStore, next);
        }
      } else {
        redirectDefault(tenantStore, next);
      }
      return;
    }

    // 4. Authenticated but has no tenants and is not superadmin
    // They must be forced to the no-tenant or pending-access page
    if (
      tenantStore.myTenants.length === 0 &&
      !tenantStore.isSuperadmin &&
      to.name !== 'no-tenant' &&
      to.name !== 'pending-access' &&
      !to.path.startsWith('/forbidden')
    ) {
      const allowSelfService = import.meta.env.ALLOW_SELF_SERVICE_TENANTS !== 'false';
      if (allowSelfService) {
        next({ name: 'no-tenant' });
      } else {
        next({ name: 'pending-access' });
      }
      return;
    }

    // 5. Admin access check
    if (isAdminRoute) {
      if (tenantStore.isSuperadmin) {
        next();
      } else {
        next({ name: 'error-403' });
      }
      return;
    }

    // 6. Tenant workspace access check
    if (tenantSlug) {
      try {
        await tenantStore.setActiveTenantBySlug(tenantSlug);

        // Check feature requirements
        const requiredFeature = to.meta.requiredFeature as string | undefined;
        if (requiredFeature && !tenantStore.isFeatureEnabled(requiredFeature)) {
          Notify.create({
            type: 'warning',
            message: `The "${requiredFeature.toUpperCase()}" module is not enabled for this workspace.`,
            position: 'top',
            timeout: 3000,
          });
          next({ name: 'workspace-dashboard', params: { tenantSlug } });
          return;
        }

        // Check permission requirements
        const requiredPermission = to.meta.requiredPermission as string | undefined;
        if (requiredPermission && !tenantStore.hasPermission(requiredPermission, 'read')) {
          Notify.create({
            type: 'negative',
            message: `You do not have permission to access the "${requiredPermission}" module.`,
            position: 'top',
            timeout: 3000,
          });
          next({ name: 'workspace-dashboard', params: { tenantSlug } });
          return;
        }

        next();
      } catch (err) {
        const error = err as Error;
        console.error(`Access verification failed for tenant slug: ${tenantSlug}`, error.message);
        next({ name: 'error-403' });
      }
      return;
    }

    // 7. Handle root '/' path or general pages
    if (to.path === '/') {
      redirectDefault(tenantStore, next);
      return;
    }

    next();
  });
}

function redirectDefault(
  tenantStore: ReturnType<typeof useTenantStore>,
  next: NavigationGuardNext,
) {
  // Always favor workspace redirect first (even for superadmins)
  if (tenantStore.myTenants.length > 0) {
    const firstSlug = tenantStore.myTenants[0]?.tenants?.slug;
    if (firstSlug) {
      next({ name: 'workspace-dashboard', params: { tenantSlug: firstSlug } });
      return;
    }
  }

  // Fallback behavior if they have no workspaces
  const allowSelfService = import.meta.env.ALLOW_SELF_SERVICE_TENANTS !== 'false';
  next(allowSelfService ? { name: 'no-tenant' } : { name: 'pending-access' });
}
