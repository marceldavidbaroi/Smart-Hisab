import { create } from 'zustand';
import { Platform } from 'react-native';
import { supabase } from '@/lib/supabase';
import type { User as SupabaseUser } from '@supabase/supabase-js';
import { useTenantStore } from './useTenantStore';

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
  role?: 'owner' | 'manager' | string;
  storeName?: string;
  isTerminalDevice?: boolean;
  tenantId?: string;
}

export interface KioskStaffSession {
  id: string;
  fullName: string;
  role: string;
}

interface AuthState {
  user: User | null;
  supabaseUser: SupabaseUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  isTerminalDevice: boolean;
  deviceToken: string | null;
  activeStaff: KioskStaffSession | null;
  counterMode: boolean;
  initialize: () => Promise<void>;
  loginWithGoogle: () => Promise<void>;
  login: (email: string, password?: string) => Promise<void>;
  signUp: (email: string, password?: string, fullName?: string) => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  pairWithPin: (pin: string) => Promise<void>;
  setStaffSession: (staff: KioskStaffSession) => void;
  clearStaffSession: () => void;
  toggleCounterMode: (enabled?: boolean) => void;
  joinTenantByCode: (code: string) => Promise<{ tenant_id: string; name: string; role: string }>;
  logout: () => Promise<void>;
}

function mapSupabaseUser(sbUser: SupabaseUser): User {
  return {
    id: sbUser.id,
    name: sbUser.user_metadata?.full_name || sbUser.user_metadata?.name || sbUser.email?.split('@')[0] || 'User',
    email: sbUser.email || '',
    avatarUrl: sbUser.user_metadata?.avatar_url,
    role: sbUser.user_metadata?.role || 'owner',
    storeName: 'Smart-Hisab Canteen',
    isTerminalDevice: false,
  };
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  supabaseUser: null,
  isAuthenticated: false,
  isLoading: false,
  isTerminalDevice: false,
  deviceToken: null,
  activeStaff: null,
  counterMode: false,

  initialize: async () => {
    set({ isLoading: true });
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        set({
          supabaseUser: session.user,
          user: mapSupabaseUser(session.user),
          isAuthenticated: true,
          isTerminalDevice: false,
          deviceToken: null,
        });
      }

      supabase.auth.onAuthStateChange((_event, session) => {
        if (session?.user) {
          set({
            supabaseUser: session.user,
            user: mapSupabaseUser(session.user),
            isAuthenticated: true,
            isTerminalDevice: false,
            deviceToken: null,
          });
        } else {
          set({
            supabaseUser: null,
            user: null,
            isAuthenticated: false,
            isTerminalDevice: false,
            deviceToken: null,
            activeStaff: null,
            counterMode: false,
          });
        }
      });
    } catch (e) {
      console.error('Failed to initialize Supabase session', e);
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
            redirectTo: typeof window !== 'undefined' ? window.location.origin : undefined,
          },
        });
        if (error) throw error;
      } else if (GoogleSignin && process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID) {
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
        const WebBrowser = require('expo-web-browser');
        const AuthSession = require('expo-auth-session');
        const Constants = require('expo-constants').default;

        WebBrowser.maybeCompleteAuthSession();

        const isExpoGo = Constants?.executionEnvironment === 'storeClient';
        let redirectUrl = AuthSession.makeRedirectUri({ preferLocalhost: true });

        if (isExpoGo && Constants?.expoConfig?.hostUri) {
          redirectUrl = `exp://${Constants.expoConfig.hostUri}/--/`;
        }

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

  login: async (email: string, password?: string) => {
    set({ isLoading: true });
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password: password || '' });
      if (error) throw error;
      if (data.user) {
        set({ supabaseUser: data.user, user: mapSupabaseUser(data.user), isAuthenticated: true });
      }
    } finally {
      set({ isLoading: false });
    }
  },

  signUp: async (email: string, password?: string, fullName?: string) => {
    set({ isLoading: true });
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password: password || '',
        options: { data: { full_name: fullName || email.split('@')[0] } },
      });
      if (error) throw error;
      if (data.user) {
        set({ supabaseUser: data.user, user: mapSupabaseUser(data.user), isAuthenticated: true });
      }
    } finally {
      set({ isLoading: false });
    }
  },

  resetPassword: async (email: string) => {
    set({ isLoading: true });
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email);
      if (error) throw error;
    } finally {
      set({ isLoading: false });
    }
  },

  pairWithPin: async (pin: string) => {
    return get().joinTenantByCode(pin).then(() => {});
  },

  setStaffSession: (staff: KioskStaffSession) => {
    set({ activeStaff: staff });
  },

  clearStaffSession: () => {
    set({ activeStaff: null });
  },

  toggleCounterMode: (enabled?: boolean) => {
    const nextVal = enabled !== undefined ? enabled : !get().counterMode;
    set({ counterMode: nextVal });
    if (!nextVal) {
      set({ activeStaff: null });
    }
  },

  joinTenantByCode: async (code: string) => {
    set({ isLoading: true });
    try {
      const { data, error } = await supabase.rpc('join_tenant_by_code', { p_code: code.trim() });
      if (error) throw error;
      if (data && data.tenant_id) {
        useTenantStore.getState().setActiveTenant({
          id: data.tenant_id,
          name: data.name,
          slug: data.name.toLowerCase().replace(/\s+/g, '-'),
          status: 'active',
        });
        return data;
      }
      throw new Error('Could not join canteen with provided code');
    } finally {
      set({ isLoading: false });
    }
  },

  logout: async () => {
    set({ isLoading: true });
    try {
      if (Platform.OS !== 'web' && GoogleSignin) {
        await GoogleSignin.signOut().catch(() => {});
      }
      await supabase.auth.signOut();
      set({ user: null, supabaseUser: null, isAuthenticated: false, isTerminalDevice: false, deviceToken: null, activeStaff: null, counterMode: false });
    } finally {
      set({ isLoading: false });
    }
  },
}));
