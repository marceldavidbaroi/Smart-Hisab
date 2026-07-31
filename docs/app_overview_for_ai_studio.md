# Smart-Hisab — Full Context Prompt for Google AI Studio

> **Purpose:** Paste this entire document into Google AI Studio as a **System Instruction** or **Initial Context Prompt**. Then ask it to generate dummy React Native / Expo TSX screens you can preview in your `playground.tsx`. This prompt gives the AI full context about what exists, why it's built this way, and asks it to suggest simpler, Bangladesh-optimized flows.

---

## 1. What Smart-Hisab Is

Smart-Hisab is a **canteen / mess management + POS (Point of Sale)** system built for small-to-medium canteens, corporate mess halls, and hostel kitchens in **Bangladesh**. The typical user is a canteen owner ("malik") or a counter cashier ("staff") who manages daily meals on credit ("baki") and collects payments later.

### The Core Problem It Solves
In Bangladesh, canteens commonly run a **credit-based meal system** (known as "baki khata" / "hisab khata"):
- Workers eat daily meals on credit.
- The canteen owner tracks who ate and how much they owe in a paper notebook.
- At week-end or month-end, workers pay their accumulated debt.
- Cash drawer reconciliation is done manually, leading to shortages and disputes.

**Smart-Hisab digitizes this entire flow** — meal attendance → debt tracking → cash collection → daily cash drawer reconciliation.

---

## 2. Backend System (Supabase / Postgres)

### Tech Stack
- **Backend:** Supabase (hosted Postgres + Auth + Realtime + Edge Functions + RPC)
- **Mobile App:** React Native / Expo (TypeScript), NativeWind (TailwindCSS), Expo Router (file-based routing)
- **Web Dashboard:** Quasar Framework v2 (Vue 3) — **LEGACY, OUT OF SCOPE.** Ignore for all suggestions. The mobile app is the only active product.
- **State Management:** Zustand (mobile), React Query / TanStack Query (caching)

### Database Schema Architecture

Everything operates on a strict **multi-tenant boundary** rooted in operational time windows:

**Hierarchy:** `Tenant` → `BusinessDay` → `Shift`

#### Core Entities
| Entity Group | Tables | Purpose |
|---|---|---|
| **Identity & Devices** | `tenants`, `users`, `devices` | Multi-tenant isolation. Devices are kiosk/POS terminals paired to a tenant. |
| **Staff & Payroll** | `staff_roles`, `staff`, `staff_attendance`, `salary_payouts` | Counter workers authenticate via 4-digit PIN (not full login). |
| **Customers & Ledger** | `customers`, `customer_wallets`, `wallet_entries` | Immutable append-only ledger tracking customer debt (meal charges) and payments. |
| **Operations** | `shifts` (Breakfast/Lunch/Dinner), `meal_configs` (base rates per shift), `meal_attendance` | Records who ate what meal, auto-charges wallet. |
| **Cashbook** | `business_days` (opening/closing cash), `day_entries` (cash inflow/outflow ledger), `day_notes` | Daily cash drawer reconciliation system. |

#### Core Design Principles
1. **Operational Window Isolation:** Every transaction is stamped with `shift_id` + `business_day_id`, solving the midnight shift rollover problem.
2. **Dual-Ledger Accounting:**
   - `WalletEntry` → tracks **customer debt** (who owes what)
   - `DayEntry` → tracks **company cash flow** (actual money in the drawer)
3. **Derived State (No Static Balances):** Customer balance and company cash position are calculated dynamically from immutable ledger entries — no stale `outstanding_balance` columns.

---

## 3. Authentication Flow — Why Two Separate Auth Paradigms

The app has **two completely different user types** that need different authentication experiences:

### Auth Type 1: Manager / Owner Login (`/(auth)` → `/(main)`)
- **Who:** The canteen owner or manager who configures the system.
- **How:** Standard email/password or Google OAuth via Supabase Auth.
- **What they see:** Full management dashboard — business day control, staff management, customer management, meal config, shift setup, cashbook analytics, profile settings.
- **Device:** Their personal phone.

### Auth Type 2: Terminal / POS Device Login (`/(auth)` → `/(terminal)`)
- **Who:** A **shared device** (dedicated Android tablet/phone) sitting at the canteen counter.
- **How:** The owner "pairs" the device using a one-time **6-digit PIN code** generated from the Web Dashboard. This calls a Supabase RPC `verify_pairing_code` which returns a `device_token` and binds the device to the tenant.
- **After pairing:** The device is permanently associated with the tenant. Individual counter **staff members** then authenticate using a quick **4-digit PIN** (not full email/password) to "clock in" to the terminal. This PIN gate (`TerminalStaffLogin` component) ensures every action (meal logging, payment collection) is attributed to a specific staff member.
- **What they see:** Simplified POS interface — customer meal toggle, baki (debt) collection, staff list. No configuration screens.
- **Security:** A "Lock" button in the terminal header clears the staff session (requiring PIN re-entry) without unpairing the device.

### Why Two Layouts?
```
/(auth)/login  →  checks isTerminalDevice
                    ├── true  →  /(terminal)  [POS mode: tabs = Home, Customer, Staff, Device Info]
                    └── false →  /(main)      [Manager mode: tabs = Home, Operation, Settings, Profile]
```

The **terminal layout** is designed for **speed and simplicity** — a cashier standing at the counter needs to log 50+ meals in 15 minutes during lunch rush. They don't need settings, analytics, or configuration. The **main layout** is for the owner sitting in their office reviewing the day's numbers.

---

## 4. Current App Structure (Expo Router File-Based Routing)

### `/(main)` — Manager Dashboard (4 tabs)
| Tab | File | Features |
|---|---|---|
| **Home** | `index.tsx` | Business Day status banner, Open/Close day modal, quick stats |
| **Operation** | `operation.tsx` | Access to Meal Configs, Shifts, Staff, Customer management |
| **Settings** | `settings.tsx` | App preferences, dark mode, notification settings |
| **Profile** | `profile.tsx` | Account info, tenant selector, logout |

### `/(terminal)` — POS Terminal (4 tabs)
| Tab | File | Features |
|---|---|---|
| **Home** | `index.tsx` | Running Business Day status, minimal controls |
| **Customer** | `customer.tsx` | Swipeable customer cards, meal attendance toggle, baki collection bottom sheet, customer statement view |
| **Staff** | `staff.tsx` | Staff list, first-time PIN setup, PIN verification |
| **Device Info** | `device-info.tsx` | Terminal connection status, sync info |

### Gate Guards (Before Terminal Tabs Render)
1. **`TerminalStaffLogin`** — If no `activeStaff` session, shows a full-screen PIN entry. Staff must authenticate before accessing any terminal feature.
2. **`BusinessDayGateGuard`** — If no Business Day is open, blocks access and shows a prompt to open the day (with `opening_cash` input).

---

## 5. Main Operational Workflows

### Daily Flow (This is what happens every day in a Bangladesh canteen):

```
Morning 6:00 AM
  └─ Manager/Head Cashier opens Business Day
     └─ Enters opening_cash (physical cash counted from drawer)
     └─ System marks day as "open"

Breakfast 7:00–9:00 AM / Lunch 12:00–2:00 PM / Dinner 7:00–9:00 PM
  └─ Counter staff logs into terminal via 4-digit PIN
  └─ As customers eat:
     └─ Staff taps customer → toggles "Meal Attended"
     └─ System creates MealAttendance record
     └─ System auto-creates WalletEntry (type: meal_charge)
     └─ Customer's dynamically-calculated debt increases

  └─ When a customer pays cash to reduce their baki:
     └─ Staff taps "Record Baki" → enters amount → confirms with PIN
     └─ Ledger Action 1: WalletEntry (type: payment) → reduces customer debt
     └─ Ledger Action 2: DayEntry (type: inflow) → increases expected drawer cash

Night 10:00 PM
  └─ Manager closes Business Day
     └─ System calculates: expected_cash = opening_cash + inflows - outflows
     └─ Manager enters actual closing_cash (physical count)
     └─ System calculates variance (shortage/overage)
     └─ Day is locked — no backdated transactions allowed
```

---

## 6. What I Want You (Google AI Studio) To Do

### Primary Request: Generate Dummy React Native UI
Generate complete, self-contained **React Native / Expo TSX components** with **hardcoded mock data** (no real API calls) that I can paste into my `playground.tsx` file and instantly preview on my Android device.

### Design Constraints
- **Tech:** React Native + Expo + NativeWind (TailwindCSS classes via `className`)
- **Typography:** Canteen/POS-optimized — main titles ≥16px bold, labels ≥12px. **No micro-fonts.**
- **Touch targets:** Minimum 48px hitbox for all interactive elements (this is used at arm's length).
- **Dialogs/Modals:** Use **Bottom Slide Sheets** with `rounded-t-3xl` top corners, **NO close X button** (dismiss via backdrop tap or action buttons), **blur backdrop**.
- **Loading:** Skeleton loaders, not spinners.
- **Lists:** Pull-to-refresh (`RefreshControl`), swipeable row actions for Edit/Delete.
- **Empty states:** Hide header action buttons when list is empty; show primary CTA inside the empty state card instead.
- **Max 400 lines per component file.**

### Screens I Want Dummy UI For
1. **Terminal Home** — Shows running business day status, active shift indicator, quick meal count summary, prominent "Lock Terminal" button.
2. **Customer List (Terminal POS)** — Fast-scrolling customer cards with meal attendance toggle and swipe-to-collect-baki. Search bar with debounce.
3. **Baki Collection Bottom Sheet** — Amount input (with Bangladeshi ৳ symbol), PIN confirmation, success animation.
4. **Business Day Open/Close Modal** — Bottom sheet with opening_cash or closing_cash number input, expected vs actual comparison on close.
5. **Staff PIN Login Screen** — Full-screen staff avatar grid, tap to select, 4-digit PIN pad, subtle animations.
6. **Manager Dashboard Home** — Day summary cards (total meals served, cash collected, outstanding baki), business day status banner.

---

## 7. Suggest Improvements — Make It Simpler for Bangladesh

> **Important context:** The Web Dashboard (Quasar/Vue) is legacy and frozen. All future development is mobile-only. You are free to suggest changes to the backend (Supabase, Postgres schema, Edge Functions) and the mobile frontend (React Native/Expo). Nothing is sacred — challenge every design decision.

Given the Bangladesh canteen context, please suggest concrete improvements across these areas:

### 7A. App Architecture & Layout Simplification

1. **Can the two layouts (Main vs Terminal) be merged into one?** Maintaining `/(main)` and `/(terminal)` as completely separate route groups means duplicated components, separate layouts, and two mental models. Is there a smarter pattern? Ideas to evaluate:
   - A **single layout with role-based feature gating** (owner sees all tabs, staff sees only POS tabs)
   - A **"mode switch"** toggle in settings (Owner Mode ↔ Counter Mode) on the same device
   - A **progressive disclosure** approach where the same Home screen adapts based on role
   - Which approach results in the least code, best UX, and easiest maintenance?

2. **Is the device-pairing flow too enterprise for a small canteen?** Right now the owner must: go to web dashboard → generate 6-digit PIN → enter on the Android device → pair. For a Bangladesh canteen owner who may not even have a laptop, is there a simpler onboarding? Ideas:
   - QR code scan from owner's phone to pair a second device
   - Just login with the same account on two devices, with one marked as "counter mode"
   - Skip device pairing entirely — any logged-in user with "staff" role auto-enters terminal mode

### 7B. Backend Schema Simplification

3. **Is the Business Day → Shift hierarchy too complex?** Most Bangladesh canteens have 3 fixed meals (sokaler nashta, dupur er khabar, rater khabar). Questions:
   - Can we eliminate configurable shifts and hardcode 3 meal periods?
   - Or keep shifts but make them auto-detected based on time-of-day (7-10 AM = Breakfast, 12-3 PM = Lunch, 7-10 PM = Dinner)?
   - Does the `shift_id` stamp on every transaction actually provide value, or is `business_day_id` + timestamp sufficient?

4. **Is the dual-ledger (WalletEntry + DayEntry) overkill?** For a 50-customer canteen:
   - Would a **single unified `transactions` table** with a `type` enum (meal_charge, payment, expense, salary_payout) be cleaner?
   - Can the cashbook (cash drawer tracking) be derived from the same table using filtered aggregation?
   - What are the accounting integrity trade-offs?

5. **Should Supabase remain the backend, or would something simpler work?** Evaluate:
   - **Keep Supabase** — mature, Postgres RLS for multi-tenancy, real-time subscriptions, auth built-in
   - **Firebase/Firestore** — better offline-first story, easier for mobile-only apps, but weaker for relational accounting data
   - **SQLite local-first (PowerSync / ElectricSQL)** — data lives on device, syncs to cloud. Perfect for Bangladesh's unreliable internet. But adds sync complexity.
   - **Supabase + local SQLite hybrid** — use Supabase as the cloud backend but cache/queue transactions locally in SQLite for offline resilience
   - Which gives the best balance of simplicity, offline support, and accounting integrity?

### 7C. UX Flow Simplification

6. **PIN authentication friction** — In rush hour with 50+ people in line:
   - Requiring staff PIN for every baki collection or meal toggle is too slow
   - Should we use a **session-based model** (staff PINs in once, session lasts until manual lock or 30-min timeout)?
   - Or **biometric fallback** (fingerprint to confirm sensitive actions like payment collection, skip for meal toggles)?
   - For meal attendance specifically — should it be **PIN-free** (just tap the customer) since it only affects the customer's wallet, not cash?

7. **Meal attendance is too many taps** — Current flow: open customer tab → find customer → tap → toggle meal. For 50 customers eating lunch:
   - Should there be a **"Bulk Meal" mode** where the screen shows all customers as a checklist and you tick everyone who ate?
   - Or a **"Default All Present"** mode where everyone is marked as having eaten, and you only un-toggle the ones who didn't show up (common in hostel mess)?
   - Or **NFC/QR scan** — each customer has a card/QR, staff just scans them as they walk through the line?

8. **Bangla language / localization** — For Bangladesh canteen staff who may not be fluent in English:
   - Should the UI default to **Bangla labels** with English fallback?
   - Display Bangla numerals (১২৩) vs English numerals (123) — which is more practical for accounting?
   - Should customer names support Bangla Unicode input natively?

### 7D. Bangladesh-Specific Technical Challenges

9. **Offline-first architecture** — Internet in Bangladesh (especially in factory/hostel areas) is unreliable:
   - Should all transactions be queued locally in SQLite/MMKV and synced when connectivity returns?
   - How does this affect the immutable ledger integrity? (conflict resolution for dual-device edits)
   - Should the app work 100% offline for days and only sync for reporting/backup?

10. **Mobile money integration** — bKash and Nagad dominate Bangladesh payments:
    - Should the baki collection flow include payment method selection (Cash / bKash / Nagad)?
    - Can we integrate bKash merchant API for direct QR-based payment within the app?
    - Or is it simpler to just record "bKash received" as a payment method tag without API integration?

11. **Low-end device optimization** — Many Bangladesh canteen counter devices are budget Android phones (2-3GB RAM):
    - Should we minimize animations and heavy components?
    - Use FlatList virtualization aggressively for customer lists?
    - Consider a lighter state management approach than Zustand + React Query?

12. **Multi-device sync for small teams** — A canteen may have the owner's personal phone + 1 counter tablet:
    - Do we need Supabase Realtime subscriptions so the owner sees live updates on their phone as the cashier logs meals?
    - Or is pull-to-refresh sufficient for a small operation?

---

## 8. Full System Rethink — If You Were Building This From Scratch

Ignore everything above for a moment. If you were designing a **canteen baki management app for Bangladesh from zero**, knowing:
- Users: Small canteen owners (50-200 customers), 1-3 staff
- Environment: Budget Android phones, unreliable internet, Bangla-speaking users
- Core need: Track "who ate" and "who owes how much" daily, collect cash, reconcile at end of day
- Secondary need: Owner sees reports/summaries on their phone

**Propose the simplest possible architecture:**
1. What's the minimum database schema? (Forget multi-tenant enterprise patterns)
2. What's the minimum number of screens?
3. What's the ideal auth flow for a canteen owner who has never used a SaaS app?
4. Should it even be a React Native app, or would a simpler PWA / Flutter / native Kotlin app be better?
5. What's the MVP feature set vs what's over-engineering?

---

## 9. How to Respond

When generating UI code:
1. **Output complete TSX files** — I will directly paste them into `playground.tsx`.
2. **Use mock data arrays** at the top of each file (e.g., `const MOCK_CUSTOMERS = [...]`).
3. **Include all imports** — assume standard Expo/NativeWind setup.
4. **One screen per response** unless I ask for multiple.
5. For improvement suggestions, provide **concrete alternatives** with pros/cons tables, not just abstract advice.
6. **Ignore the web dashboard entirely** — it's legacy. All suggestions should be mobile-app-only.
7. When suggesting backend changes, show the proposed Postgres schema or table structure.
8. When suggesting flow changes, show a simple flow diagram (ASCII or mermaid).
