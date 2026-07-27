import { create } from 'zustand';

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  role: 'Owner' | 'Manager' | 'Cashier';
  storeName: string;
  avatarUrl?: string;
}

interface AuthState {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  setUser: (user: UserProfile | null) => void;
  loginWithGoogle: () => Promise<void>;
  pairWithPin: (pin: string) => Promise<void>;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null, // Default to null for login flow testing
  isAuthenticated: false,
  isLoading: false,
  setUser: (user) => set({ user, isAuthenticated: !!user }),
  loginWithGoogle: async () => {
    set({ isLoading: true });
    // Simulate authentication API call delay
    await new Promise((resolve) => setTimeout(resolve, 800));
    set({
      isLoading: false,
      isAuthenticated: true,
      user: {
        id: 'usr_google_01',
        name: 'Marcel David Baroi',
        email: 'david@smarthisab.com',
        role: 'Owner',
        storeName: 'Central Hisab Enterprise',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      },
    });
  },
  pairWithPin: async (pin: string) => {
    set({ isLoading: true });
    await new Promise((resolve) => setTimeout(resolve, 800));
    
    // Simple validation rule for demo
    if (pin === '123456' || pin === '654321' || pin.length === 6) {
      set({
        isLoading: false,
        isAuthenticated: true,
        user: {
          id: 'usr_terminal_02',
          name: 'POS Terminal #1',
          email: 'pos1@smarthisab.com',
          role: 'Cashier',
          storeName: 'Central Hisab Enterprise (Branch 1)',
          avatarUrl: undefined,
        },
      });
    } else {
      set({ isLoading: false });
      throw new Error('Invalid PIN code. Please check your web dashboard.');
    }
  },
  logout: () => set({ user: null, isAuthenticated: false }),
}));
