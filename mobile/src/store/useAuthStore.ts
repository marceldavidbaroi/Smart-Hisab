import { create } from 'zustand';
import { Platform } from 'react-native';
import { supabase, safeStorage } from '@/lib/supabase';
import type { User as SupabaseUser } from '@supabase/supabase-js';
import { useTenantStore } from './useTenantStore';

const STORAGE_TERMINAL_KEY = 'smart_hisab_paired_terminal';

let GoogleSignin: any = null;
if (Platform.OS !== 'web') {
  try {
    GoogleSignin = require('@react-native-google-signin/google-signin').GoogleSignin;
    if (GoogleSignin && typeof GoogleSignin.configure === 'function') {
      GoogleSignin.configure({
        scopes: ['https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/userinfo.profile'],
        webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID || 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com',
        offlineAccess: true,
      });
    }
  } catch (err) {
    console.warn('[AuthStore] Native GoogleSignin module not available (running in Expo Go). Fallback enabled.');
  }
}

export interface User {
  id: string;
  name: string;
  email: string;
  avatarUrl?: string;
  role?: string;
  storeName?: string;
  isTerminalDevice?: boolean;
  tenantId?: string;
}


export interface KioskStaffSession {
  id: string;
  fullName: string;
  role: string;
  permissions?: Record<string, unknown>;
}

interface AuthState {
  user: User | null;
  supabaseUser: SupabaseUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  isTerminalDevice: boolean;
  deviceToken: string | null;
  activeStaff: KioskStaffSession | null;
  initialize: () => Promise<void>;
  login: (email: string, password?: string) => Promise<void>;
  signUp: (email: string, password?: string, fullName?: string) => Promise<void>;
  loginWithGoogle: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  pairWithPin: (pin: string) => Promise<void>;
  setStaffSession: (staff: KioskStaffSession) => Promise<void>;
  clearStaffSession: () => Promise<void>;
  logout: () => Promise<void>;
}

function mapSupabaseUser(sbUser: SupabaseUser): User {
  return {
    id: sbUser.id,
    name: sbUser.user_metadata?.full_name || sbUser.user_metadata?.name || sbUser.email?.split('@')[0] || 'User',
    email: sbUser.email || '',
    avatarUrl: sbUser.user_metadata?.avatar_url,
    role: 'Owner',
    storeName: 'Smart Hisab Store',
  };
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  supabaseUser: null,
  isAuthenticated: false,
  isLoading: false,
  isTerminalDevice: false,
  deviceToken: null,
  activeStaff: null,

  initialize: async () => {
    set({ isLoading: true });
    try {
      // 1. Check for persisted terminal device pairing first
      const storedTerminalJson = await safeStorage.getItem(STORAGE_TERMINAL_KEY);
      if (storedTerminalJson) {
        try {
          const storedData = JSON.parse(storedTerminalJson);
          if (storedData?.deviceToken && storedData?.user) {
            set({
              user: storedData.user,
              isAuthenticated: true,
              isTerminalDevice: true,
              deviceToken: storedData.deviceToken,
              activeStaff: storedData.activeStaff || null,
            });

            if (storedData.tenant) {
              useTenantStore.getState().setActiveTenant(storedData.tenant);
            }
            return;
          }
        } catch (e) {
          console.warn('[AuthStore] Failed to parse stored terminal payload:', e);
        }
      }

      // 2. Check standard Supabase session
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        set({
          supabaseUser: session.user,
          user: mapSupabaseUser(session.user),
          isAuthenticated: true,
          isTerminalDevice: false,
        });
      }

      supabase.auth.onAuthStateChange((_event, session) => {
        if (session?.user) {
          set({
            supabaseUser: session.user,
            user: mapSupabaseUser(session.user),
            isAuthenticated: true,
            isTerminalDevice: false,
          });
        } else {
          // Only clear if not in terminal device mode
          const currentStore = useAuthStore.getState();
          if (!currentStore.isTerminalDevice) {
            set({ supabaseUser: null, user: null, isAuthenticated: false, isTerminalDevice: false, activeStaff: null });
          }
        }
      });
    } catch (e) {
      console.error('Failed to initialize Supabase session', e);
    } finally {
      set({ isLoading: false });
    }
  },

  login: async (email: string, password?: string) => {
    set({ isLoading: true });
    try {
      if (!password) {
        throw new Error('Password is required');
      }
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;

      if (data.user) {
        set({
          supabaseUser: data.user,
          user: mapSupabaseUser(data.user),
          isAuthenticated: true,
        });
      }
    } catch (err: any) {
      set({ isLoading: false });
      throw err;
    } finally {
      set({ isLoading: false });
    }
  },

  signUp: async (email: string, password?: string, fullName?: string) => {
    set({ isLoading: true });
    try {
      if (!password) {
        throw new Error('Password is required');
      }
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName || email.split('@')[0],
          },
        },
      });

      if (error) throw error;

      if (data.user) {
        set({
          supabaseUser: data.user,
          user: mapSupabaseUser(data.user),
          isAuthenticated: true,
        });
      }
    } catch (err: any) {
      set({ isLoading: false });
      throw err;
    } finally {
      set({ isLoading: false });
    }
  },

  loginWithGoogle: async () => {
    set({ isLoading: true });
    try {
      if (Platform.OS === 'web') {
        const { error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: {
            redirectTo: window.location.origin,
          },
        });
        if (error) throw error;
      } else if (GoogleSignin) {
        // Native Google Sign-In (Development / Production Native Build)
        await GoogleSignin.hasPlayServices();
        const userInfo = await GoogleSignin.signIn();
        const idToken = userInfo.data?.idToken;

        if (!idToken) {
          throw new Error('No ID Token present in Google Sign-In response');
        }

        const { data, error } = await supabase.auth.signInWithIdToken({
          provider: 'google',
          token: idToken,
        });

        if (error) throw error;

        if (data.user) {
          set({
            supabaseUser: data.user,
            user: mapSupabaseUser(data.user),
            isAuthenticated: true,
          });
        }
      } else {
        // Fallback for Expo Go using WebBrowser OAuth
        const WebBrowser = require('expo-web-browser');
        const AuthSession = require('expo-auth-session');
        const Constants = require('expo-constants').default;

        WebBrowser.maybeCompleteAuthSession();

        // Detect if running in Expo Go sandbox vs Standalone / Dev Build
        const isExpoGo = Constants?.executionEnvironment === 'storeClient';
        
        let redirectUrl = AuthSession.makeRedirectUri({
          preferLocalhost: true,
        });

        // In Expo Go, force AuthSession proxy redirect URI or custom scheme
        if (isExpoGo && Constants?.expoConfig?.hostUri) {
          redirectUrl = `exp://${Constants.expoConfig.hostUri}/--/`;
        }

        console.log('[OAuth Debug] Generated Redirect URI:', redirectUrl);

        const { data, error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: {
            redirectTo: redirectUrl,
            skipBrowserRedirect: true,
          },
        });

        if (error) throw error;

        if (data?.url) {
          const res = await WebBrowser.openAuthSessionAsync(data.url, redirectUrl);
          if (res.type === 'success' && res.url) {
            // Extract tokens whether Supabase returned them in hash (#) or query params (?)
            const rawUrl = res.url;
            let access_token: string | null = null;
            let refresh_token: string | null = null;

            if (rawUrl.includes('#')) {
              const hashString = rawUrl.split('#')[1];
              const hashParams = new URLSearchParams(hashString);
              access_token = hashParams.get('access_token');
              refresh_token = hashParams.get('refresh_token');
            }

            if (!access_token || !refresh_token) {
              const urlObj = new URL(rawUrl.replace('#', '?'));
              access_token = access_token || urlObj.searchParams.get('access_token');
              refresh_token = refresh_token || urlObj.searchParams.get('refresh_token');
            }

            if (access_token && refresh_token) {
              const { data: sessionData, error: sessionErr } = await supabase.auth.setSession({
                access_token,
                refresh_token,
              });
              if (sessionErr) throw sessionErr;
              if (sessionData?.user) {
                set({
                  supabaseUser: sessionData.user,
                  user: mapSupabaseUser(sessionData.user),
                  isAuthenticated: true,
                });
              }
            }
          }
        }
      }
    } catch (err: any) {
      console.error('Google Sign-In error:', err);
      throw err;
    } finally {
      set({ isLoading: false });
    }
  },

  resetPassword: async (email: string) => {
    set({ isLoading: true });
    try {
      if (!email) throw new Error('Please enter your email address');
      const redirectUrl = Platform.OS === 'web' && typeof window !== 'undefined'
        ? `${window.location.origin}/auth/reset-password`
        : 'http://localhost:9000/auth/reset-password';
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: redirectUrl,
      });
      if (error) throw error;
    } finally {
      set({ isLoading: false });
    }
  },

  pairWithPin: async (pin: string) => {
    set({ isLoading: true });
    try {
      const cleanPin = pin.trim();

      // Attempt to pair with backend RPC
      const { data, error } = await supabase.rpc('verify_pairing_code', {
        p_code: cleanPin,
        p_device_name: Platform.OS === 'ios' ? 'iOS Terminal' : Platform.OS === 'android' ? 'Android Terminal' : 'Mobile Terminal',
      });

      if (error) {
        console.error('Supabase verify_pairing_code error:', error);
        throw error;
      }

      if (data && data.success) {
        const pairedUser: User = {
          id: data.device_token || 'usr_terminal_device',
          name: data.tenant_name ? `${data.tenant_name} Terminal` : 'POS Terminal Device',
          email: `${data.tenant_slug || 'terminal'}@terminal.smarthisab.com`,
          role: 'Terminal Device',
          storeName: data.tenant_name || 'Smart Hisab Store',
          isTerminalDevice: true,
          tenantId: data.tenant_id,
        };

        const activeTenantObj = {
          id: data.tenant_id,
          name: data.tenant_name,
          slug: data.tenant_slug || 'terminal',
          status: 'active',
        };

        const deviceTokenVal = data.device_token || 'device_token_' + Date.now();

        // Persist terminal pairing to async storage
        await safeStorage.setItem(
          STORAGE_TERMINAL_KEY,
          JSON.stringify({
            deviceToken: deviceTokenVal,
            user: pairedUser,
            tenant: activeTenantObj,
          })
        );

        set({
          isLoading: false,
          isAuthenticated: true,
          isTerminalDevice: true,
          deviceToken: deviceTokenVal,
          user: pairedUser,
          activeStaff: null,
        });

        useTenantStore.getState().setActiveTenant(activeTenantObj);
        return;
      }

      if (data && data.message) {
        throw new Error(data.message);
      }

      throw new Error('Invalid pairing code. Please generate a code from your Web Management Dashboard.');
    } catch (err: any) {
      console.warn('Pairing failed:', err?.message || err);

      // Demo PIN fallback if testing offline or demo code
      if (pin.trim() === '123456') {
        const currentActive = useTenantStore.getState().activeTenant;
        let fallbackTenant = currentActive;

        if (!fallbackTenant) {
          try {
            const { data: tData } = await supabase.from('tenants').select('id, name, slug, status').limit(1);
            if (tData && tData.length > 0) {
              fallbackTenant = tData[0] as any;
            }
          } catch (e) {
            console.warn('Failed to fetch fallback tenant:', e);
          }
        }

        const fallbackTenantId = fallbackTenant?.id || '00000000-0000-0000-0000-000000000001';

        const demoUser: User = {
          id: 'usr_terminal_02',
          name: 'Demo Terminal #1',
          email: 'pos1@smarthisab.com',
          role: 'Cashier',
          storeName: fallbackTenant?.name || 'Central Hisab Enterprise',
          isTerminalDevice: true,
          tenantId: fallbackTenantId,
        };

        const demoTenantObj = fallbackTenant || {
          id: fallbackTenantId,
          name: 'Demo Store',
          slug: 'demo-store',
          status: 'active',
        };

        await safeStorage.setItem(
          STORAGE_TERMINAL_KEY,
          JSON.stringify({
            deviceToken: 'demo_device_token',
            user: demoUser,
            tenant: demoTenantObj,
          })
        );

        set({
          isLoading: false,
          isAuthenticated: true,
          isTerminalDevice: true,
          deviceToken: 'demo_device_token',
          user: demoUser,
          activeStaff: null,
        });

        useTenantStore.getState().setActiveTenant(demoTenantObj);
        return;
      }

      throw new Error(err?.message || 'Pairing failed. Invalid or expired PIN code.');
    } finally {
      set({ isLoading: false });
    }
  },

  setStaffSession: async (staff: KioskStaffSession) => {
    const currentState = useAuthStore.getState();
    set({ activeStaff: staff });

    try {
      const storedTerminalJson = await safeStorage.getItem(STORAGE_TERMINAL_KEY);
      if (storedTerminalJson) {
        const storedData = JSON.parse(storedTerminalJson);
        storedData.activeStaff = staff;
        await safeStorage.setItem(STORAGE_TERMINAL_KEY, JSON.stringify(storedData));
      }
    } catch (e) {
      console.warn('[AuthStore] Failed to persist active staff session:', e);
    }
  },

  clearStaffSession: async () => {
    set({ activeStaff: null });
    try {
      const storedTerminalJson = await safeStorage.getItem(STORAGE_TERMINAL_KEY);
      if (storedTerminalJson) {
        const storedData = JSON.parse(storedTerminalJson);
        delete storedData.activeStaff;
        await safeStorage.setItem(STORAGE_TERMINAL_KEY, JSON.stringify(storedData));
      }
    } catch (e) {
      console.warn('[AuthStore] Failed to clear active staff session:', e);
    }
  },

  logout: async () => {
    set({ isLoading: true });
    try {
      await safeStorage.removeItem(STORAGE_TERMINAL_KEY);
      if (Platform.OS !== 'web' && GoogleSignin) {
        await GoogleSignin.signOut().catch(() => {});
      }
      await supabase.auth.signOut();
      set({ user: null, supabaseUser: null, isAuthenticated: false, isTerminalDevice: false, deviceToken: null, activeStaff: null });
    } finally {
      set({ isLoading: false });
    }
  },
}));
