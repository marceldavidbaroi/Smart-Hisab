import { create } from 'zustand';
import { colorScheme as nativewindColorScheme } from 'nativewind';

export type ColorScheme = 'light' | 'dark';

interface AppState {
  colorScheme: ColorScheme;
  notificationsEnabled: boolean;
  activeTab: string;
  setColorScheme: (scheme: ColorScheme) => void;
  toggleColorScheme: () => void;
  setNotificationsEnabled: (enabled: boolean) => void;
  setActiveTab: (tab: string) => void;
}

export const useAppStore = create<AppState>((set) => ({
  colorScheme: 'light',
  notificationsEnabled: true,
  activeTab: 'dashboard',
  setColorScheme: (colorScheme) => {
    nativewindColorScheme.set(colorScheme);
    set({ colorScheme });
  },
  toggleColorScheme: () =>
    set((state) => {
      const nextScheme = state.colorScheme === 'light' ? 'dark' : 'light';
      nativewindColorScheme.set(nextScheme);
      return { colorScheme: nextScheme };
    }),
  setNotificationsEnabled: (notificationsEnabled) => set({ notificationsEnabled }),
  setActiveTab: (activeTab) => set({ activeTab }),
}));

