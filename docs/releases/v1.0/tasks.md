# Smart-Hisab v1.0.0 — Release Checklist & Remaining Tasks

> **Goal (Easy English)**:  
> This checklist tracks what is already completed and what needs to be done to officially release **v1.0.0 (Free Tier)** for solo canteen owners.

---

## 1. Feature Status Overview

| Feature / Area | Status | Easy Explanation |
|---|:---:|---|
| **Auth & Canteen Onboarding** | ✅ Done | Email/password login, create canteen, join canteen with 6-digit code. |
| **Customer Directory & Wallets** | ✅ Done | Add customers, meal attendance toggle, baki collection, balance guard, voiding entries, statement history. |
| **Staff Management (Tab 4)** | ✅ Done | Add/edit staff with Daily/Monthly wage types, Advance vs Regular salary payouts, balance settlement, and ledger history. |
| **Invite Manager (Tab 5)** | ✅ Done | Owner can generate a 6-digit code valid for 24h to invite a manager. |
| **Settings & Profile** | ✅ Done | Shifts & meal rates config, canteen profile & manager invites. |
| **Cashbook & Bazar Hub (Tab 3)** | ✅ Done | Clean separation of Canteen Wallet Cashflow (Cash Drawer, bKash, Bank) vs Bazar & Vendor Baki (Accounts Payable). |
| **Canteen Wallets / Accounts** | ✅ Done | Multi-channel business money accounts (Cash Drawer, bKash, Bank, Safe) backend migration & UI selectors integrated across cashbook and payroll. |
| **Home Dashboard (Tab 1)** | ✅ Done | Zero-Friction Owner Command Hub (Direct modal triggers, live drawer cash pulse, active shift ribbon, yesterday's recap, live activity audit feed). |
| **Linter & Code Cleanup** | ✅ Done | `flutter analyze` passes with 0 issues & 0 warnings. |
| **Release Build Testing** | ⏳ Pending | Android APK/AppBundle verification & permissions check. |

---

## 2. Remaining Tasks Breakdown for v1.0 Release

### Task 1: Staff Advance (অগ্রিম) & Regular Salary Payouts with Canteen Wallet Integration
- **Status**: ✅ Completed
- **Implemented Capabilities**:
  1. **Backend & DB Schema**:
     - `salary_payouts` table now stores `payout_type` (`regular_salary`, `advance`), `payout_month`, and `account_id` ([`20260831000000_staff_advance_and_payout_types.sql`](file:///Users/daviditc/Documents/personal_projects/smart-hisab/supabase/migrations/20260831000000_staff_advance_and_payout_types.sql)).
     - RPC `record_salary_payout_v2` automatically draws funds from the chosen Canteen Wallet (`cash_drawer`, `mobile_money`, `bank`, `safe`) and records day outflows.
  2. **Mobile UI (`RecordSalaryPayoutBottomSheet`)**:
     - Dual-mode selector: **"Regular Salary"** vs **"Advance (অগ্রিম)"**.
     - **"Paid From"** Canteen Wallet channel selector (Cash Drawer, bKash, Bank, Safe).
     - Automated calculation: Displays `Base Wage / Salary` − `Prior Advances` = `Net Due to Settle` / `Staff Owes`.
  3. **Visual Indicators & Ledger (`StaffDetailScreen` & `StaffScreen`)**:
     - Advance badges (`Adv: ৳...`), Net Due badges, and Owes Canteen indicators.
     - Distinct ledger tags `[ADVANCE (অগ্রিম)]` and `[SALARY]`.

### Task 2: Cashbook & Bazar Separation (Tab 3 UX Streamlining)
- **Status**: 🟡 In Progress
- **Implemented & Remaining Capabilities**:
  1. **Segmented Sub-view inside Tab 3 (`💵 Cashbook` vs `🛒 Bazar & Baki`)**:
     - Cashbook view tracks physical liquid cashflow (Inflow, Outflow, Net Balance, Shift Reconciliation).
     - Bazar & Baki view acts as the morning grocery hub (Checklists, Wholesaler Baki Ledger, Expense categorization).
  2. **Bazar Hub (`bazar_hub_view.dart`)**:
     - Top KPI cards: Today's Cash Bazar (আজকের নগদ বাজার), Today's New Credit Baki (আজকের নতুন বাকি), Total Vendor Payable (মহাজনদের মোট দেনা).
     - Active Bazar Fard (বাজারের ফর্দ): Quick grocery checklist with fast post-bazar price reconciliation.
     - Direct shortcuts to **Vendors & Suppliers** and **New Bazar Note**.
  3. **Expense Bottom Sheet (`add_expense_bottom_sheet.dart`)**:
     - Dual-mode toggle: `[ 💵 নগদ (Cash) ]` vs `[ 📝 বাকি (Vendor Baki) ]`.
     - Smart routing: Cash expenses deduct from selected Canteen Wallet (Cash Drawer, bKash, Bank); Baki expenses link to a vendor profile without falsely draining today's cash drawer.

### Task 3: Vendor Khata & Baki Settlement Integration
- **Status**: ✅ Completed
- **Implemented Capabilities**:
  1. **Vendors Directory (`vendors_screen.dart`)**:
     - Total Accounts Payable KPI header (মোট বকেয়া পাওনা).
     - Supplier list with contact number, outstanding balance, and Swipe-to-Pay row action.
  2. **Vendor Detail & Ledger Passbook (`vendor_detail_screen.dart`)**:
     - Full transaction ledger passbook showing chronological `[BAKI PURCHASE / বাকি ক্রয়]` (+৳) vs `[PAYMENT PAID / পরিশোধ]` (−৳) with memo notes and staff signatures.
     - Direct One-Tap Call button (`tel:` launcher).
     - Direct Quick Action buttons: `[ 📝 Add Baki (বাকি ক্রয়) ]` and `[ 💳 Pay Due (পরিশোধ) ]`.
  3. **Pay Vendor Sheet & Multi-Wallet Integration (`record_vendor_payment_bottom_sheet.dart`)**:
     - Settle supplier debt drawing funds from **Cash Drawer**, **bKash**, or **Bank Account**.
     - RPC `record_vendor_payment_v2` automatically reduces vendor debt and records a physical wallet outflow.
  4. **Add Vendor Baki Sheet (`add_vendor_baki_bottom_sheet.dart`)**:
     - Record raw grocery / fuel credit purchases linked to the vendor (`record_expense_v2`) without touching cash drawer.

### Task 4: Zero-Friction Owner Home Dashboard Redesign & Direct Wiring
- **Status**: ✅ Completed
- **Goal**: Transform Tab 1 from an unwired placeholder into a counter-first daily command center for the solo canteen owner, adhering to the 3-second rule.
- **Specification & Architecture**:
  1. **Dynamic Lifecycle States (Morning $\rightarrow$ Active $\rightarrow$ Night)**:
     - **State A (Morning / Day Closed)**: Prominent "Start Business Day" card with opening cash prompt + **"Yesterday's Recap"** card (Meals count, Cash Inflows, Variance status `✅ Balanced` / `⚠️ Variance`) + Total Baki overview.
     - **State B (Active Day Pulse)**: Active shift ribbon (e.g. `🍽️ Lunch • ৳80/meal`) + Live Drawer Cash pulse ($\text{Opening Cash} + \text{Inflows} - \text{Outflows}$) + 3 KPI tiles (Meals, Inflow, Outflow) + `[ 🔒 End Day & Reconcile ]` button.
     - **State C (Closed Day Summary)**: Complete cash reconciliation breakdown (Expected vs Actual Cash + Variance indicator).
  2. **Direct-Trigger Action Station (Zero Redirection)**:
     - `[ 🛒 Add Expense ]` $\rightarrow$ Directly triggers `AddExpenseBottomSheet` on Home (no tab switching).
     - `[ 💵 Collect Baki ]` $\rightarrow$ Triggers `QuickCustomerPickerBottomSheet` $\rightarrow$ `CollectBakiBottomSheet`.
     - `[ 📝 Day Note / Bazar ]` $\rightarrow$ Directly triggers `AddDayNoteBottomSheet` on Home.
     - `[ 🍽️ Mark Meals ]` $\rightarrow$ Fast navigation to Customers tab with active shift focused.
  3. **Live Activity Stream / Audit Feed**:
     - Shows the latest 3–5 day transactions (cash inflows, market expenses, meal entries) for instant cashier verification.
  4. **Dual-Layer Data Wiring**:
     - Wire `businessDayNotifierProvider` to compute real-time inflows/outflows from `day_entries`, fetch `lastClosedDay`, and cache to Hive.
     - Split into modular widgets under `features/home/widgets/` to strictly comply with the `< 400 lines` rule.

### Task 5: End-to-End Flow Verification (Manual Checklist)
Run through these 5 real-life canteen workflows to verify:

1. **Daily Business Day Cycle**:
   - Tap **"Start Business Day"** on Home with opening cash (e.g. ৳5,000).
   - Verify Home updates to **"Day Open"** and displays active shift & drawer pulse.
   - Tap **"Close Business Day"**, enter closing cash, check variance calculations.
2. **Direct Home Quick Actions**:
   - Tap **"Add Expense"** directly on Home $\rightarrow$ record market expense (৳1,200).
   - Verify drawer cash on Home decreases by ৳1,200 and activity feed shows the new entry immediately.
   - Tap **"Collect Baki"** on Home $\rightarrow$ pick customer $\rightarrow$ collect ৳500 $\rightarrow$ verify Home updates instantly.
3. **Cashbook & Market Expenses**:
   - Add a cash grocery expense (e.g. ৳1,200 vegetables from market).
   - Add a vendor credit purchase (e.g. ৳3,600 rice from Rahim Store on Baki).
   - Verify cash drawer only reduced by ৳1,200, while Rahim Store's balance increased by ৳3,600.
   - Settle ৳2,000 to Rahim Store from Cash Drawer; verify both cash drawer and vendor balance update properly.
4. **Staff Payroll & Advances**:
   - Add staff member (e.g. Karim - Cook - ৳8,000/mo).
   - Record salary payout (৳4,000 cash).
   - Verify staff detail shows payout history and paid amount.
5. **Manager Invite Flow**:
   - In Settings → Invite Manager, tap "Generate Code".
   - Confirm 6-digit code displays with countdown timer.

---

### Task 6: Android Release Build Verification
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


