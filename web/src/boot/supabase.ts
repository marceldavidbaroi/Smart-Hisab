import { defineBoot } from '#q-app';
import { createClient } from '@supabase/supabase-js';

// Retrieve keys from defineEnv or fallback to import.meta.env
const supabaseUrl = process.env.SUPABASE_URL || import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY || '';

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

export default defineBoot(({ app }) => {
  // Listen for auth changes to handle redirects or sync states
  supabase.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') {
      console.log('[supabase boot] user signed out');
    }
  });

  // Expose $supabase to Vue templates and options API
  app.config.globalProperties.$supabase = supabase;
});
