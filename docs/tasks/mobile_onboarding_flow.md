# Task: Complete Mobile Onboarding & Authentication Flow

## Objective
Implement the missing authentication and onboarding flow steps in the mobile application to match the documented `app_flow.md`. This includes user registration, tenant creation routing, and initial shift configuration.

## Missing Components

### 1. Registration Screen
- **Location:** `mobile/src/app/(auth)/register.tsx` [COMPLETED]
- **Requirements:**
  - UI Form with fields: Name, Email, Password, Confirm Password. [COMPLETED]
  - Allow toggling password and confirm password visibility. [COMPLETED]
  - Form validation: passwords match, min length, required fields. [COMPLETED]
  - Integrate with Supabase Auth for user sign-up. [COMPLETED]
  - On successful registration, redirect/switch to the Login screen. [COMPLETED]
- **Related Updates:**
  - Update `mobile/src/app/(auth)/login.tsx` to include a navigation link/button to the new registration screen ("Don't have an account? Create Account"). [COMPLETED]

### 2. Auto-Seeded Default Operational Shifts
- **Locations:** `supabase/migrations/20260728000002_auto_seed_default_shifts.sql`, `mobile/src/store/useTenantStore.ts` [COMPLETED]
- **Provisioned Slots:**
  1. **Morning Slot:** 06:30 AM – 11:00 AM (`06:30` - `11:00`)
  2. **Afternoon Slot:** 11:00 AM – 03:30 PM (`11:00` - `15:30`)
  3. **Evening Slot:** 03:30 PM – 07:30 PM (`15:30` - `19:30`)
  4. **Night Slot:** 07:30 PM – 11:30 PM (`19:30` - `23:30`)
- **Requirements:**
  - Automatically insert these 4 shifts into the `public.shifts` table upon tenant creation.
  - Backfill these 4 shifts for any pre-existing tenants without shifts.

### 3. Store Management for Shifts
- **Location:** `mobile/src/store/useShiftStore.ts` [COMPLETED]
- **Requirements:**
  - Implement Zustand store for shift state management (`shifts`, `isLoading`, `error`).
  - Support CRUD operations for custom shifts when accessed via settings.

### 4. Direct Routing to Dashboard
- **Locations:** `mobile/src/app/create-tenant.tsx`, `mobile/src/app/index.tsx` [COMPLETED]
- **Requirements:**
  - Redirect directly to `/(main)` upon workspace creation or login.
  - Remove mandatory intermediate shift creation step from onboarding flow.

### 5. Manager Day Tracking & Counter Cash Flow (Web & Terminal)
- **Locations:** `mobile/src/app/(main)/index.tsx`, `mobile/src/app/(terminal)/...`, `mobile/src/store/useBusinessDayStore.ts`
- **Requirements:**
  - When a Manager logs in or a Terminal device is operated, ensure a **Business Day** is running (active).
  - If no business day is active, prompt/enforce the user to **Start Day** with an input field for **Opening Counter Cash** (`opening_cash`) before permitting transactions.
  - Provide an **End Day** action for the Manager to close the active business day by entering **Closing Counter Cash** (`closing_cash`).
  - Provide a **Resume Day** option if a closed day needs to be reopened on the same calendar date.

## Execution Order
1. **Phase 1:** Build `register.tsx` and link it to `login.tsx`. [COMPLETED]
2. **Phase 2:** Create `useShiftStore.ts` for shift state management and Supabase API integration. [COMPLETED]
3. **Phase 3:** Auto-seed 4 default operational shifts in `create_tenant` RPC and `useTenantStore.ts`. [COMPLETED]
4. **Phase 4:** Update navigation in `create-tenant.tsx` and `index.tsx` to route directly from workspace creation to Main Dashboard (`/(main)`). [COMPLETED]
5. **Phase 5:** Integrate Manager Day Tracking flow with Opening & Closing Counter Cash inputs on the dashboard.

