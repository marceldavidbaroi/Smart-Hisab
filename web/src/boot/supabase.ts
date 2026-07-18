import { defineBoot } from '#q-app';
import { createClient } from '@supabase/supabase-js';
import { useTenantStore } from '../stores/tenant';

// Retrieve keys from import.meta.env (configured via defineEnv in quasar.config.ts)
const supabaseUrl = import.meta.env.SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.SUPABASE_ANON_KEY || '';

const defaultFetch: typeof fetch = globalThis.fetch.bind(globalThis);

// Multi-tenant header injection: adds x-selected-tenant-id from localstorage if present
const withSelectedTenantHeader = (init?: RequestInit): RequestInit | undefined => {
  const storageKey = 'workspace.selected.tenant.id';
  const selectedTenantId =
    typeof window !== 'undefined' ? window.localStorage.getItem(storageKey) : null;

  if (!selectedTenantId) {
    return init;
  }

  const nextInit = { ...init };
  const headers = new Headers(nextInit.headers);
  headers.set('x-selected-tenant-id', selectedTenantId);
  nextInit.headers = headers;
  return nextInit;
};

// Tracked fetch to inject tenant headers and handle 401/403 errors
const trackedFetch: typeof fetch = async (input, init) => {
  const modifiedInit = withSelectedTenantHeader(init);
  const response = await defaultFetch(input, modifiedInit);

  // Auto-refresh token logic or route redirect on 401 can be integrated here
  if (response.status === 401) {
    console.warn('[supabase] Unauthorized access (401)');
  } else if (response.status === 403) {
    console.warn('[supabase] Forbidden access (403)');
  }

  return response;
};

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  global: {
    fetch: trackedFetch,
  },
  auth: {
    detectSessionInUrl: true,
    flowType: 'pkce',
  },
});

export default defineBoot(({ app, router }) => {
  // Defer store work: awaiting Supabase inside onAuthStateChange can deadlock.
  supabase.auth.onAuthStateChange((event, session) => {
    void Promise.resolve().then(async () => {
      const tenantStore = useTenantStore();

      if (event === 'SIGNED_OUT') {
        tenantStore.clearStore();
        return;
      }

      // OAuth PKCE: session may arrive after first guard run.
      if (
        (event === 'SIGNED_IN' || event === 'INITIAL_SESSION' || event === 'TOKEN_REFRESHED') &&
        session?.user
      ) {
        const wasLoggedOut = !tenantStore.user;
        await tenantStore.syncFromUser(session.user);

        if (!wasLoggedOut || (event !== 'SIGNED_IN' && event !== 'INITIAL_SESSION')) {
          return;
        }

        const route = router.currentRoute.value;
        // Only nudge navigation when still parked on a pre-auth route.
        // Keep fullPath so `?redirect=` survives the auth-restore race.
        if (
          route.path === '/' ||
          route.name === 'login' ||
          route.name === 'signup' ||
          route.name === 'tenant-login' ||
          route.name === 'admin-login'
        ) {
          await router.replace(route.fullPath);
        }
      }
    });
  });

  app.config.globalProperties.$supabase = supabase;
});
