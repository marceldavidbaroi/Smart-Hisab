# Smart-Hisab — Simplified Auth & App Flow (v2)

> This document outlines the primary Email & Password sign-in system with Email Confirmation (Resend/SMTP), replacing OAuth dependencies.

---

## 1. Auth Method: Email & Password (with Email Confirmation)

Authentication is built directly on Supabase Auth using standard Email & Password. On signup, a confirmation link is delivered via Resend/SMTP to verify user ownership without external OAuth setup friction.

| User Type | Auth Method | What They See |
|---|---|---|
| **Owner** | Email/Password (Confirmed) | Full access — all tabs, settings, staff/customer management |
| **Manager** | Email/Password (Confirmed) + Join Code | Management access — day control, reports, counter mode (no tenant/billing settings) |
| **Counter Staff** | 4-digit PIN on shared device | Counter mode only — meal toggle, baki collection. **No email account needed.** |

---

## 2. User Flows

### Flow A: Multi-Canteen Login Flow Architecture

```
                       ┌─────────────────────────┐
                       │   User Signs In / App   │
                       │       Launches          │
                       └────────────┬────────────┘
                                    │
                       Fetch user tenant memberships
                                    │
            ┌───────────────────────┼───────────────────────┐
            ▼                       ▼                       ▼
      [0 Canteens]            [1 Canteen]             [2+ Canteens]
            │                       │                       │
            ▼                       ▼                       ▼
 ┌─────────────────────┐  ┌───────────────────┐  ┌─────────────────────┐
 │  Onboarding Choice  │  │  Auto-select &    │  │    Select Canteen   │
 │   Screen (Create    │  │   Go Straight to  │  │   Screen (List with │
 │  Canteen / Join as  │  │   Home Dashboard  │  │ OWNER / MANAGER badge│
 │      Manager)       │  └───────────────────┘  │      per item)      │
 └─────────────────────┘                         └──────────┬──────────┘
                                                            │ Tap Canteen
                                                            ▼
                                                 ┌─────────────────────┐
                                                 │    Home Dashboard   │
                                                 └─────────────────────┘
```

### Flow B: New User / No Canteen (0 Canteens)

```
1. Login (Email/Password or Google Sign-In)
2. System detects NO tenant for the user (0 tenant memberships)
3. Directs user to Onboarding Choice screen with options:
   ┌──────────────────────────────────────────┐
   │                                          │
   │  🏪  "Create Canteen" (Owner Flow)       │
   │                                          │
   │  🔗  "Join as Manager" (I have a code)   │
   │                                          │
   └──────────────────────────────────────────┘
4. Tap "Create Canteen" → Enter name → Active tenant set → Navigates to Canteen Homepage
5. Tap "Join as Manager" → Enter join code → Active tenant set → Navigates to Canteen Homepage
```

### Flow C: Existing User with Canteens (1 Canteen vs 2+ Canteens)

```
Single Canteen (1 Canteen):
1. Sign In
2. System detects 1 tenant membership
3. Auto-selects the canteen & navigates straight to Canteen Homepage

Multiple Canteens (2+ Canteens - Owner or Manager):
1. Sign In
2. System detects 2+ tenant memberships → Select Canteen screen (`SelectCanteenScreen`)
3. View list of all canteens belonging to user, displaying each canteen name with user's role (OWNER or MANAGER) badge
4. Tap desired canteen → Active tenant context set → Navigates to selected Canteen Homepage
5. Switch canteens anytime via Settings → "Switch Canteen" (returns to Select Canteen screen)
```

### Flow C: Counter Staff (No App Download Needed)

```
Owner's Phone:
  1. Staff tab → "Add Staff"
  2. Enter: Name, Role (Cashier/Cook/etc.), 4-digit PIN
  3. Staff is created. Done.

At the Counter Device (already signed in under Owner or Manager's Google):
  4. App is in Counter Mode
  5. Staff sees avatar grid → taps their name → enters 4-digit PIN
  6. They're clocked in. Can log meals, collect baki.
  7. "Lock" button → returns to PIN gate (for next staff or break)
```

### Flow D: Logout & Cache Invalidation

```
1. User taps "Logout" (from Profile / Settings)
2. Confirmation bottom sheet appears → User confirms logout
3. Supabase Auth session terminated (`auth.signOut()`)
4. Local state & cache fully purged:
   - Clear active tenant context & local storage
   - Reset Riverpod state/notifiers to initial state
   - Invalidate any stored user session tokens
5. App redirects to Auth / Landing screen (`/login`)
6. On subsequent logins, system starts fresh and follows the exact same tenant evaluation flow (Flow A / Flow B / Flow C).
```

**Counter staff never need:**
- A Google account
- Their own phone
- To download the app

They only exist as entries in the staff list with a name + PIN.

---

## 3. Unified Layout — No More `/(main)` vs `/(terminal)`

### Old Architecture (Removed)
```
/(auth)  → checks isTerminalDevice
             ├── true  → /(terminal)   ← Separate layout, separate components
             └── false → /(main)       ← Separate layout, separate components
```

### New Architecture
```
/(auth)  → Google Sign-In
             │
             └── /(app)  ← Single layout for everyone
                   │
                   ├── Role = Owner   → All tabs visible + settings
                   ├── Role = Manager → All tabs visible (no tenant settings)
                   └── Counter Mode   → Simplified tabs (any role can toggle)
```

### Tab Structure

**Normal Mode** (Owner / Manager):
```
[Home]  [Customers]  [Staff]  [Settings]
```

**Counter Mode** (toggled on):
```
┌─ Staff PIN Gate ─────────────────────┐
│  Select your name → Enter 4-digit PIN │
└──────────────────────────────────────┘
         ↓ (after PIN verified)
[Home]  [Customers]  [Staff]
 └─ simplified views, no settings tab
 └─ header shows: staff name + "Lock" button
```

### How Counter Mode Works

```
Any logged-in user (Owner or Manager) can toggle Counter Mode:

  Home screen → "Start Counter Mode" button
       │
       ▼
  Staff PIN Gate appears (who is at the counter?)
       │
       ▼
  Counter Mode active:
    • Tabs shrink to Home / Customers / Staff
    • Settings tab hidden
    • Header shows active staff name + Lock button
    • Customer list shows quick meal toggle + baki collection
    • All transactions stamped with active staff_id
       │
  "Lock" button → clears staff session → back to PIN gate
  "Exit Counter Mode" → requires owner/manager biometric or PIN → back to Normal Mode
```

---

## 4. Multi-Tenant Support

A single Google account can be associated with **multiple canteens**:

```
┌─────────────────────────────┐
│  Active: Rahim's Canteen ✓  │  ← Owner (full access)
│  ABC Factory Mess           │  ← Manager (invited)
└─────────────────────────────┘
```

### Roles Per Tenant

> Full permission matrix in [tier_and_roles.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/tier_and_roles.md).

| Role | Create Canteen | Manage Staff/Customers | Open/Close Day | Counter Mode | Invite Others | Tenant Settings | Reports & Financials | Salary Payouts |
|---|---|---|---|---|---|---|---|---|
| **Owner** | ✅ | ✅ | ✅ | ✅ | ✅ Managers | ✅ | ✅ | ✅ |
| **Manager** | ✅ (own canteen) | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| **Counter Staff** | ❌ | ❌ | ❌ | ✅ (PIN only) | ❌ | ❌ | ❌ | ❌ |

---

## 5. Backend Changes Required

### Tables to Remove
| Table | Reason |
|---|---|
| `devices` | No device pairing. Auth is Google-based. |

### Tables to Add/Modify

#### `tenant_members` (New — replaces device pairing)
```sql
CREATE TABLE tenant_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  user_id     UUID NOT NULL REFERENCES auth.users(id),
  role        TEXT NOT NULL CHECK (role IN ('owner', 'manager')),
  invited_at  TIMESTAMPTZ DEFAULT now(),
  joined_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, user_id)
);
```

#### `tenant_invites` (New — for join codes)
```sql
CREATE TABLE tenant_invites (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  code        TEXT NOT NULL UNIQUE,           -- 6-digit code
  role        TEXT NOT NULL DEFAULT 'manager', -- role to assign on join
  created_by  UUID NOT NULL REFERENCES auth.users(id),
  expires_at  TIMESTAMPTZ NOT NULL,           -- 24 hour expiry
  used_by     UUID REFERENCES auth.users(id), -- NULL until used
  used_at     TIMESTAMPTZ
);
```

### RPCs to Remove
| RPC | Reason |
|---|---|
| `verify_pairing_code` | Replaced by simpler `join_tenant_by_code` |

### RPCs to Add
```sql
-- Owner generates invite code
CREATE FUNCTION generate_invite_code(p_tenant_id UUID, p_role TEXT DEFAULT 'manager')
RETURNS TEXT AS $$
  -- Generates 6-digit code, inserts into tenant_invites, returns code
$$;

-- Manager joins with code
CREATE FUNCTION join_tenant_by_code(p_code TEXT)
RETURNS JSON AS $$
  -- Validates code, checks expiry, creates tenant_member, returns tenant info
$$;
```

### Auth Store Changes
```
Remove:
  - isTerminalDevice flag
  - deviceToken
  - pairWithPin()
  - STORAGE_TERMINAL_KEY (terminal pairing persistence)

Keep:
  - Google Sign-In (loginWithGoogle)
  - activeStaff (for counter mode PIN sessions)
  - setStaffSession / clearStaffSession

Add:
  - counterMode: boolean (is counter mode active?)
  - toggleCounterMode()
  - joinTenantByCode(code: string)
```

---

## 6. App Route Structure (New)

```
/app
├── (auth)/
│   ├── login.tsx              ← Google Sign-In only
│   └── _layout.tsx
├── onboarding-choice.tsx       ← "Create Canteen" or "Join Canteen"
├── create-tenant.tsx           ← Canteen name input
├── join-tenant.tsx             ← Enter 6-digit code
├── (app)/                      ← Single unified layout
│   ├── _layout.tsx            ← Tabs + counter mode toggle + role gating
│   ├── index.tsx              ← Home (day status, stats, "Start Counter" button)
│   ├── customers.tsx          ← Customer list (adapts in counter mode)
│   ├── staff.tsx              ← Staff list + management
│   └── settings.tsx           ← Owner/Manager settings (hidden in counter mode)
├── meal-attendance/            ← Shared screens
├── meal-configs/
├── shifts/
└── staff/
```

---

## 7. Summary: Before vs After

| Aspect | Before (Legacy) | After (v2) |
|---|---|---|
| **Auth methods** | Google + email/password + device PIN pairing | Google only |
| **Web dashboard needed** | Yes (for device pairing) | No |
| **Layouts** | 2 separate (`/(main)` + `/(terminal)`) | 1 unified (`/(app)`) |
| **Counter device setup** | Generate PIN on web → enter on device → pair | Sign in with Google → toggle Counter Mode |
| **Staff auth** | 4-digit PIN (required for every action) | 4-digit PIN (session-based, for accountability) |
| **Multi-tenant** | Supported but complex | Supported — simple tenant switcher |
| **Adding a manager** | Not supported without web | "Invite Manager" → 6-digit code → join |
| **Steps to first use** | ~7 steps (including web) | 3 steps (download → Google → create) |
