import type { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  // 1. Authentication Route Group
  {
    path: '/auth',
    component: () => import('@/layouts/AuthLayout.vue'),
    children: [
      {
        path: 'login',
        name: 'login',
        component: () => import('@/pages/auth/LoginPage.vue'),
      },
      {
        path: 'signup',
        redirect: { name: 'login' },
      },
      {
        path: 'no-tenant',
        name: 'no-tenant',
        component: () => import('@/pages/auth/NoTenantPage.vue'),
      },
      {
        path: 'pending-access',
        name: 'pending-access',
        component: () => import('@/pages/auth/PendingAccessPage.vue'),
      },
      {
        path: 'pair-device',
        name: 'pair-device',
        component: () => import('@/pages/auth/PairDevicePage.vue'),
      },
      {
        path: 'counter-login',
        name: 'counter-login',
        component: () => import('@/pages/auth/CounterLoginPage.vue'),
      },
    ],
  },
  {
    path: '/admin/auth/login',
    component: () => import('@/layouts/AuthLayout.vue'),
    children: [
      {
        path: '',
        name: 'admin-login',
        component: () => import('@/pages/auth/LoginPage.vue'),
      },
    ],
  },
  {
    path: '/:tenantSlug/login',
    component: () => import('@/layouts/AuthLayout.vue'),
    beforeEnter: (to) => {
      const slug = to.params.tenantSlug;
      const reserved = new Set(['auth', 'admin', 'kiosk', 'forbidden', 'error']);
      if (typeof slug === 'string' && reserved.has(slug)) {
        return slug === 'admin' ? { name: 'admin-login' } : { name: 'login' };
      }
      return true;
    },
    children: [
      {
        path: '',
        name: 'tenant-login',
        component: () => import('@/pages/auth/LoginPage.vue'),
      },
    ],
  },

  // 2. Superadmin Platform Control Group
  {
    path: '/admin',
    component: () => import('@/layouts/AdminLayout.vue'),
    children: [
      {
        path: 'dashboard',
        name: 'admin-dashboard',
        component: () => import('@/pages/admin/AdminDashboard.vue'),
      },
      {
        path: 'tenants',
        name: 'admin-tenants',
        component: () => import('@/pages/admin/AdminTenants.vue'),
      },
      {
        path: 'billing',
        name: 'admin-billing',
        component: () => import('@/pages/admin/AdminBilling.vue'),
      },
    ],
  },

  // 3. Tenant Workspaces Group
  {
    path: '/:tenantSlug',
    component: () => import('@/layouts/WorkspaceLayout.vue'),
    children: [
      {
        path: 'dashboard',
        name: 'workspace-dashboard',
        component: () => import('@/pages/workspace/WorkspaceDashboard.vue'),
      },
      {
        path: 'members',
        name: 'workspace-members',
        component: () => import('@/pages/workspace/WorkspaceMembers.vue'),
        meta: { requiredPermission: 'members' },
      },
      {
        path: 'settings',
        name: 'workspace-settings',
        component: () => import('@/pages/workspace/WorkspaceSettings.vue'),
        meta: { requiredPermission: 'settings' },
      },
      {
        path: 'counter/dashboard',
        name: 'counter-dashboard',
        component: () => import('@/pages/workspace/CounterDashboard.vue'),
      },
      {
        path: 'shifts',
        name: 'workspace-shifts',
        component: () => import('@/pages/workspace/WorkspaceShifts.vue'),
        meta: {
          requiredFeature: 'shift-sessions',
          requiredModulePermission: {
            module: 'operational_shifts',
            permission: 'shifts_config_read',
          },
        },
      },
      {
        path: 'sessions',
        name: 'workspace-sessions',
        component: () => import('@/pages/workspace/WorkspaceSessions.vue'),
        meta: {
          requiredFeature: 'shift-sessions',
          requiredModulePermission: {
            module: 'operational_shifts',
            permission: 'sessions_read',
          },
        },
      },
      {
        path: 'ledger',
        name: 'workspace-ledger',
        component: () => import('@/pages/workspace/WorkspaceLedger.vue'),
        meta: {
          requiredFeature: 'financial-ledger',
          requiredModulePermission: {
            module: 'financial_ledger',
            permission: 'ledger_read',
          },
        },
      },
      {
        path: 'finance',
        name: 'workspace-finance',
        component: () => import('@/pages/workspace/WorkspaceFinanceDashboard.vue'),
        meta: {
          requiredFeature: 'financial-ledger',
          requiredModulePermission: {
            module: 'financial_ledger',
            permission: 'dashboard_read',
          },
        },
      },
      {
        path: 'customers',
        name: 'workspace-customers',
        component: () => import('@/pages/workspace/WorkspaceCustomers.vue'),
        meta: {
          requiredFeature: 'meal-management',
          requiredModulePermission: {
            module: 'meal_management',
            permission: 'customer_read',
          },
        },
      },
      {
        path: 'customers/:customerId',
        name: 'workspace-customer-detail',
        component: () => import('@/pages/workspace/WorkspaceCustomerDetail.vue'),
        meta: {
          requiredFeature: 'meal-management',
          requiredModulePermission: {
            module: 'meal_management',
            permission: 'statement_read',
          },
        },
      },
    ],
  },

  // 4. Kiosk Terminal Routes
  {
    path: '/kiosk',
    component: () => import('@/layouts/KioskLayout.vue'),
    children: [
      {
        path: '',
        redirect: '/kiosk/login',
      },
      {
        path: 'pair',
        name: 'kiosk-pair',
        component: () => import('@/pages/kiosk/PairDevice.vue'),
      },
      {
        path: 'login',
        name: 'kiosk-login',
        component: () => import('@/pages/kiosk/PINLogin.vue'),
        meta: { requiresPairing: true },
      },
      {
        path: 'workspace',
        name: 'kiosk-workspace',
        component: () => import('@/pages/kiosk/StaffWorkspace.vue'),
        meta: { requiresPairing: true, requiresStaffAuth: true },
      },
      {
        path: 'customers',
        name: 'kiosk-customers',
        component: () => import('@/pages/kiosk/KioskCustomers.vue'),
        meta: { requiresPairing: true, requiresStaffAuth: true },
      },
      {
        path: 'attendance',
        name: 'kiosk-attendance',
        component: () => import('@/pages/kiosk/KioskAttendance.vue'),
        meta: { requiresPairing: true, requiresStaffAuth: true },
      },
      {
        path: 'baki',
        name: 'kiosk-baki',
        component: () => import('@/pages/kiosk/KioskBaki.vue'),
        meta: { requiresPairing: true, requiresStaffAuth: true },
      },
      {
        path: 'baki-payment',
        name: 'kiosk-baki-payment',
        component: () => import('@/pages/kiosk/KioskBakiPayment.vue'),
        meta: { requiresPairing: true, requiresStaffAuth: true },
      },
      {
        path: 'advance-payment',
        name: 'kiosk-advance-payment',
        component: () => import('@/pages/kiosk/KioskAdvancePayment.vue'),
        meta: {
          requiresPairing: true,
          requiresStaffAuth: true,
          requiredFeature: 'meal-management',
        },
      },
    ],
  },

  // 5. Fallback / Global Error Routes
  {
    path: '/forbidden',
    name: 'error-403',
    component: () => import('@/pages/ErrorForbidden.vue'),
  },

  // Catch-all route to display 404 error
  {
    path: '/:catchAll(.*)*',
    component: () => import('@/pages/ErrorNotFound.vue'),
  },
];

export default routes;
