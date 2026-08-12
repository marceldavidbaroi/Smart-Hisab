# Authentication & Logout Flow

> Technical documentation for session management, logout workflow, local cache invalidation, and reactive routing in Smart-Hisab.

---

## Architecture Overview

Authentication in Smart-Hisab is managed centrally via `AuthNotifier` (`lib/core/auth/auth_notifier.dart`) using Supabase Auth and Riverpod state management.

```mermaid
graph TD
    A[User Taps Sign Out] --> B[Modal Bottom Sheet Confirmation]
    B -- Cancel --> C[Dismiss Modal]
    B -- Confirm --> D[AuthNotifier.signOut]
    D --> E[Supabase client.auth.signOut]
    D --> F[Delete Hive Cache: active_tenant & active_user]
    D --> G[State = AuthStatus.unauthenticated]
    G --> H[AuthGuard Reactively Rebuilds]
    H --> I[Navigates to LoginScreen]
```

---

## 1. Logout Entrypoints

The Sign Out action is accessible across key screens in the application:

1. **`SettingsScreen`** (`lib/features/settings/settings_screen.dart`)
   - Prominent, danger-styled list tile at the bottom of settings.
2. **`MyProfileScreen`** (`lib/features/settings/my_profile_screen.dart`)
   - Dedicated "Sign Out" button at the bottom of the profile overview.
3. **`OnboardingChoiceScreen`** (`lib/features/auth/onboarding_choice_screen.dart`)
   - Header logout icon button for users in tenant setup state.

---

## 2. Modal Bottom Sheet Confirmation

All sign out actions trigger `CustomModalBottomSheet.show()` adhering strictly to project standards:
- **Rounded top corners**: `BorderRadius.vertical(top: Radius.circular(32))`
- **No close button**: Dismissible via backdrop tap or explicit action buttons (`Cancel` / `Sign Out`).
- **Destructive styling**: Primary action uses `AppColors.danger`.

---

## 3. Session & Cache Cleanup

When the user confirms sign out, `AuthNotifier.signOut()` executes:

1. **Supabase Auth Sign Out**: Invokes `SupabaseService.client.auth.signOut()` to invalidate backend refresh tokens.
2. **Offline Cache Purging**: Deletes Hive stored keys (`active_tenant` and `active_user`).
3. **State Mutation**: Resets `authState` to `AuthState(status: AuthStatus.unauthenticated)`.
4. **Reactive Routing**: `AuthGuard` in `main.dart` reacts to `AuthStatus.unauthenticated` and renders `LoginScreen`.
5. **User Feedback**: Displays a success snackbar toast via `NotificationService`.

---

## 4. Danger Zone: Profile & Canteen Data Deletion

In `MyProfileScreen` (`lib/features/settings/my_profile_screen.dart`), users can access the **Danger Zone** to permanently purge their account and canteen data:

```mermaid
graph TD
    A[User Taps Delete Profile & Canteen] --> B[Modal Bottom Sheet Confirmation]
    B -- Type DELETE & Confirm --> C[AuthNotifier.deleteAccount]
    C --> D[RPC public.delete_user_account]
    D --> E[Cascade Delete Tenants & User Profile]
    C --> F[Purge Hive Caches & Sign Out]
    F --> G[Navigate to AccountDeletedScreen]
    G -- Tap Back to Login --> H[LoginScreen]
```

### Security & Database Cascade
- **RPC `delete_user_account()`**: `SECURITY DEFINER` function that identifies the caller (`auth.uid()`), cascade deletes any owned `tenants` (and associated staff, customers, sales, cashbook, shifts, meal configs), removes memberships and `user_profiles`, and purges `auth.users`.
- **`AccountDeletedScreen`**: Displays permanent deletion confirmation and provides a "Back to Login" action button returning to `LoginScreen`.

---

## 5. Non-Recursive RLS Security

To prevent Postgres infinite recursion (`code: 42P17`) when querying `tenant_members`, a `SECURITY DEFINER` helper function `public.get_my_tenant_ids()` is used in RLS policies:

```sql
CREATE OR REPLACE FUNCTION public.get_my_tenant_ids()
RETURNS SETOF UUID AS $$
BEGIN
  RETURN QUERY SELECT tenant_id FROM public.tenant_members WHERE user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE POLICY tenant_members_select ON public.tenant_members FOR SELECT USING (
  user_id = auth.uid() OR tenant_id IN (SELECT public.get_my_tenant_ids())
);
```
