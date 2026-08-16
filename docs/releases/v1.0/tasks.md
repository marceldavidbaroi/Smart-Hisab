# Smart-Hisab v1.0.0 — Release Checklist & Remaining Tasks

> **Goal (Easy English)**:  
> This checklist tracks what is already completed and what needs to be done to officially release **v1.0.0 (Free Tier)** for solo canteen owners.

---

## 1. Feature Status Overview

| Feature / Area | Status | Easy Explanation |
|---|:---:|---|
| **Auth & Canteen Onboarding** | ✅ Done | Email/password login, create canteen, join canteen with 6-digit code. |
| **Customer Directory & Wallets** | ✅ Done | Add customers, meal attendance toggle, baki collection, balance guard, voiding entries, statement history. |
| **Staff Management (Tab 4)** | ✅ Done | Add/edit staff, track monthly payroll, record salary payouts (cash, bank, mobile money). |
| **Invite Manager (Tab 5)** | ✅ Done | Owner can generate a 6-digit code valid for 24h to invite a manager. |
| **Settings & Vendors** | ✅ Done | Shifts & meal rates config, vendor directory & vendor payments, canteen profile. |
| **Canteen Wallets / Accounts** | 🟡 In Progress | Multi-channel business money accounts (Cash Drawer, bKash, Bank, Safe) backend migration created; UI selectors pending. |
| **Home Dashboard Quick Actions** | ✅ Done | Quick action buttons wired to directly switch tabs to Customers & Cashbook. |
| **Linter & Code Cleanup** | ✅ Done | `flutter analyze` passes with 0 issues & 0 warnings. |
| **Release Build Testing** | ⏳ Pending | Android APK/AppBundle verification & permissions check. |

---

## 2. Remaining Tasks Breakdown for v1.0 Release

### Task 1: Canteen Wallets & Multi-Channel Payment Source
- **Goal**: Enable canteen owners to spend money (Bazar, Staff salaries) from external channels (bKash, Bank, Safe, Vendor Credit) without breaking or subtracting from the physical active cash drawer.
- **Components**:
  1. ✅ Backend: `canteen_accounts` and `canteen_account_entries` tables, RLS policies, trigger-based balance sync, auto-seed defaults, and updated RPCs (`record_expense_v2`, `record_baki_payment_v2`, `record_salary_payout_v2`, `transfer_canteen_funds`, `calculate_expected_cash`).
  2. In `AddExpenseBottomSheet`: Add **"Paid From"** selector (Cash Drawer, bKash, Bank, Safe, or Pay Later on Vendor Baki).
  3. In `RecordSalaryPayoutBottomSheet`: Support selecting payment account source (Cash Drawer vs bKash/Bank).
  4. In `CollectBakiBottomSheet`: Support receiving into Cash Drawer or Mobile Money.

### Task 2: End-to-End Flow Verification (Manual Checklist)
Run through these 5 real-life canteen workflows to verify:

1. **Daily Business Day Cycle**:
   - Tap **"Start Business Day"** on Home with opening cash (e.g. ৳5,000).
   - Verify Home updates to **"Day Open"**.
   - Tap **"Close Business Day"**, enter closing cash, check variance calculations.
2. **Cashbook & Market Expenses**:
   - Add a bazar expense (e.g. ৳1,200 rice from Rahim Vendor).
   - Add a quick day note (e.g. "Buy 5kg onions tomorrow").
   - Verify day summary updates Inflows, Outflows, and Net balance.
3. **Staff Payroll**:
   - Add staff member (e.g. Karim - Cook - ৳8,000/mo).
   - Record salary payout (৳4,000 cash).
   - Verify staff detail shows payout history and paid amount.
4. **Manager Invite Flow**:
   - In Settings → Invite Manager, tap "Generate Code".
   - Confirm 6-digit code displays with countdown timer.

---

### Task 3: Android Release Build Verification
- **Command**:
  ```bash
  cd mobile
  flutter clean
  flutter pub get
  flutter build apk --release
  ```
- **Checklist**:
  - Verify app builds successfully without ProGuard or shrinker errors.
  - Verify Android internet permissions in `AndroidManifest.xml`.

---

## 3. What Belongs to Future Versions?

| Version | Included Features |
|---|---|
| **v1.5 (Pro Tier)** | Counter Mode (PIN-based rapid staff switching), Advanced Analytics & Monthly Reports (P&L breakdown across all wallets), SMS alerts. |
| **v2.0 (Business Tier)** | Multi-canteen switching per owner account, Bulk meal attendance mode, Printable PDF statement export. |
