import { create } from 'zustand';

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
  setColorScheme: (colorScheme) => set({ colorScheme }),
  toggleColorScheme: () =>
    set((state) => ({
      colorScheme: state.colorScheme === 'light' ? 'dark' : 'light',
    })),
  setNotificationsEnabled: (notificationsEnabled) => set({ notificationsEnabled }),
  setActiveTab: (activeTab) => set({ activeTab }),
}));
