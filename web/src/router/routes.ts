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
        name: 'signup',
        component: () => import('@/pages/auth/SignupPage.vue'),
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
        path: 'crm',
        name: 'workspace-crm',
        component: () => import('@/pages/workspace/CrmPage.vue'),
        meta: { requiredFeature: 'crm', requiredPermission: 'crm' },
      },
      {
        path: 'invoicing',
        name: 'workspace-invoicing',
        component: () => import('@/pages/workspace/InvoicingPage.vue'),
        meta: { requiredFeature: 'invoicing', requiredPermission: 'invoicing' },
      },
      {
        path: 'chat',
        name: 'workspace-chat',
        component: () => import('@/pages/workspace/ChatPage.vue'),
        meta: { requiredFeature: 'chat', requiredPermission: 'chat' },
      },
    ],
  },

  // 4. Fallback / Global Error Routes
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
