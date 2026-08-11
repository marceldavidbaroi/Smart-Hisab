# Smart-Hisab — Screen Map v1.0 (Free Tier)

> **Release goal**: A solo canteen owner downloads the app and replaces their paper notebook **today**.
> **Design rule**: If any screen takes more than 3 taps to complete its primary action, redesign it.

---

## Tier Limits (v1.0)

| Limit | Value |
|---|---|
| Canteens | 1 |
| Customers | 50 |
| Staff | 3 |
| Managers | 1 |
| Counter Mode | ❌ Not available |
| Reports | Daily summary only |

---

## Active Roles

| Role | Auth Method | Layout |
|---|---|---|
| **Owner** | Google Sign-In | Full 5-tab layout, all actions |
| **Manager** | Google Sign-In + 6-digit join code | Same 5-tab layout, restricted Settings |

> Counter Staff does NOT exist in v1.0. No Counter Mode, no PIN login.

---

## Bottom Navigation (5 Tabs)

```
┌─────────┬────────────┬──────────┬─────────┬──────────┐
│  🏠     │  👥        │  💰      │  👷     │  ⚙️      │
│  Home   │  Customers │  Cashbook│  Staff  │  Settings│
└─────────┴────────────┴──────────┴─────────┴──────────┘
```

| Tab | Primary Purpose | Usage Frequency |
|---|---|---|
| **Home** | Day status dashboard + quick actions | Every app open |
| **Customers** | Meal attendance + baki collection + profiles | 50+ times/day during meals |
| **Cashbook** | Expenses, day entries, market costs, day notes | 5–15 times/day |
| **Staff** | Staff profiles + salary payouts | Weekly |
| **Settings** | Canteen config, shifts, meal rates, vendors, invite | Setup + occasional |

---

## Tab 1: 🏠 Home

### State A: No Day Open

```
┌──────────────────────────────────────┐
│  Smart-Hisab          [canteen name] │
├──────────────────────────────────────┤
│  ☀️  Good Morning, [Owner Name]      │
│  ┌──────────────────────────────┐    │
│  │  📅  Start Today's Day       │    │
│  │  Tap to open business day    │    │
│  └──────────────────────────────┘    │
│  Yesterday's Summary (if exists):    │
│  ┌──────────────────────────────┐    │
│  │ Meals: 45  │ Cash: ৳12,000  │    │
│  │ Baki Collected: ৳8,000      │    │
│  │ Variance: ৳0 ✅              │    │
│  └──────────────────────────────┘    │
│  Total Baki Outstanding: ৳45,000    │
└──────────────────────────────────────┘
```

**RPCs used**:
- `get_active_business_day(tenant_id)` → determines which state to show
- `calculate_expected_cash(yesterday_day_id)` + direct query on `day_entries` → yesterday's summary card
- `start_business_day(tenant_id, null, opening_cash)` → on "Start Today's Day" confirm

---

### State B: Day is Open

```
┌──────────────────────────────────────┐
│  📅 Today — [date]        🟢 Open   │
│  Opening Cash: ৳5,000               │
│  ┌────────┬────────┬────────┐        │
│  │ Meals  │ Cash   │  Baki  │        │
│  │  32    │ ৳8,200 │ ৳6,000 │        │
│  └────────┴────────┴────────┘        │
│  Quick Actions:                      │
│  ┌──────────────┬──────────────┐     │
│  │ 🍽️ Mark      │ 💵 Collect   │     │
│  │    Meals     │    Baki      │     │
│  ├──────────────┼──────────────┤     │
│  │ 🛒 Add       │ 📝 Day       │     │
│  │    Expense   │    Notes     │     │
│  └──────────────┴──────────────┘     │
│  Total Baki Outstanding: ৳45,000    │
│  ┌──────────────────────────────┐    │
│  │  🔒  Close Today's Day       │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- `get_active_business_day(tenant_id)` → resolves current day
- `calculate_expected_cash(day_id)` → live stats
- `end_business_day(tenant_id, day_id, null, closing_cash, notes)` → on close confirm

> [!NOTE]
> In Counter Mode (v1.5+), the "Start Today's Day" and "Close Today's Day" buttons are **hidden**. Counter staff can only operate within an already-open day.

---

### State C: Day Closed

```
┌──────────────────────────────────────┐
│  📅 Today — [date]       🔴 Closed  │
│  Summary:                            │
│  ┌──────────────────────────────┐    │
│  │ Opening:  ৳5,000             │    │
│  │ + Inflows: ৳8,200            │    │
│  │ - Outflows: ৳3,500           │    │
│  │ = Expected: ৳9,700           │    │
│  │ Actual:    ৳9,500            │    │
│  │ Variance:  -৳200 ⚠️          │    │
│  └──────────────────────────────┘    │
│  [🔄 Reopen Today's Day]            │
└──────────────────────────────────────┘
```

**RPCs used**:
- `resume_business_day(tenant_id, day_id, null)` → on reopen ⚠️ *Not yet implemented in migration SQL*

---

## Tab 2: 👥 Customers

### Customer List

```
┌──────────────────────────────────────┐
│  Customers (32/50)     [+ Add]  [🔍]│
│  Active Shift: 🍽️ Lunch (৳80)       │
│  ┌──────────────────────────────┐    │
│  │ 👤 Rahim Mia         ৳2,400 │    │
│  │    ABC Factory    [🍽️ ✅]    │    │
│  ├──────────────────────────────┤    │
│  │ 👤 Karim Sheikh      ৳1,800 │    │
│  │    ABC Factory    [🍽️ ☐]    │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- `get_current_shift(tenant_id)` → shows active shift banner
- `record_meal_attendance(tenant_id, customer_id, null)` → on meal checkbox tap
- `record_baki_payment(tenant_id, customer_id, amount, null, notes)` → swipe left collect

**Bottom Sheets**: Add Customer (direct DB insert), Collect Baki (`record_baki_payment`)

---

### Customer Detail Page

```
┌──────────────────────────────────────┐
│  ← Customers     👤 Rahim Mia       │
│  ABC Factory  •  📞 01712345678      │
├──────────────────────────────────────┤
│  Balance                             │
│  ┌──────────────────────────────┐    │
│  │     ৳2,400                   │    │
│  │     Outstanding Baki         │    │
│  │     [💵 Collect Payment]     │    │
│  └──────────────────────────────┘    │
├──────────────────────────────────────┤
│  Transaction History                 │
│  ┌──────────────────────────────┐    │
│  │ Jul 31 • Lunch  🍽️ +৳80     │    │
│  │ Jul 31 • Dinner 🍽️ +৳80     │    │
│  │ Jul 30 • Payment 💵 -৳500   │    │
│  │ Jul 30 • Lunch  🍽️ +৳80     │    │
│  │ ... (infinite scroll)        │    │
│  └──────────────────────────────┘    │
│  [✏️ Edit Customer] (swipe action)   │
└──────────────────────────────────────┘
```

**RPCs used**:
- `get_customer_balance(tenant_id, customer_id)` → balance card ⚠️
- `get_customer_statement(tenant_id, customer_id, null, null)` → paginated statement list ⚠️
- `record_baki_payment(...)` → Collect Payment button

---

## Tab 3: 💰 Cashbook

```
┌──────────────────────────────────────┐
│  💰 Cashbook           📅 Today      │
│  ┌────────┬────────┬────────┐        │
│  │ Inflow │ Outflow│ Net    │        │
│  │ ৳8,200 │ ৳3,500 │ ৳4,700 │        │
│  └────────┴────────┴────────┘        │
│  [+ Expense] [+ Income] [+ Note]    │
├──────────────────────────────────────┤
│  Today's Entries:                    │
│  ┌──────────────────────────────┐    │
│  │ 💵 Customer Payment   +৳500 │    │
│  │ 🛒 Market Cost        -৳800 │    │
│  │    Rice (Rahim Vendor)       │    │
│  │ 💵 Customer Payment   +৳300 │    │
│  │ 🏠 Canteen Expense    -৳200 │    │
│  │    Gas cylinder              │    │
│  └──────────────────────────────┘    │
│  Day Notes:                          │
│  ┌──────────────────────────────┐    │
│  │ 📝 Buy 5kg onion tomorrow   │    │
│  │ ⚠️ Stove needs repair        │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- `calculate_expected_cash(day_id)` → live inflow/outflow stats
- `record_expense(tenant_id, category, amount, vendor_id, null, notes)` → Add Expense sheet
- `record_misc_income(tenant_id, amount, null, notes)` → Add Income sheet ⚠️
- Direct DB insert for `day_notes` → Add Day Note sheet

---

## Tab 4: 👷 Staff

### Staff List

```
┌──────────────────────────────────────┐
│  👷 Staff (2/3)          [+ Add]     │
│  ┌──────────────────────────────┐    │
│  │ 👤 Karim Sheikh              │    │
│  │   Cook  •  📞 01712345678    │    │
│  │   ← swipe: [💵 Pay] [✏️ Edit]│    │
│  ├──────────────────────────────┤    │
│  │ 👤 Alam Hossain              │    │
│  │   Cashier  •  📞 01898765432 │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

### Staff Detail

```
┌──────────────────────────────────────┐
│  ← Staff        👤 Karim Sheikh     │
│  Cook  •  📞 01712345678             │
├──────────────────────────────────────┤
│  Salary Summary                      │
│  ┌──────────────────────────────┐    │
│  │  Total Paid (This Month)     │    │
│  │         ৳8,000               │    │
│  │  [💵 Record Salary Payout]   │    │
│  └──────────────────────────────┘    │
├──────────────────────────────────────┤
│  Payout History                      │
│  ┌──────────────────────────────┐    │
│  │ Jul 15  💵 ৳4,000  Cash      │    │
│  │ Jul 1   💵 ৳4,000  Cash      │    │
│  │ ... (infinite scroll)        │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- Direct DB read for `staff_members` + `staff_wallets`
- `record_salary_payout(tenant_id, staff_id, amount, mode, notes)` → swipe left pay salary / detail button

---

## Tab 5: ⚙️ Settings

```
┌──────────────────────────────────────┐
│  ⚙️ Settings                         │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Canteen Profile           │ →  │
│  │ 🍽️ Shifts & Meal Rates       │ →  │
│  │ 🏪 Vendors                   │ →  │
│  │ 👥 Invite Manager            │ →  │
│  │ 👤 My Profile                │ →  │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

### Canteen Profile Sub-Page

```
┌──────────────────────────────────────┐
│  ← Settings     🏪 Canteen Profile  │
│  ┌──────────────────────────────┐    │
│  │ Name:   Rahim's Canteen      │    │
│  │ Status: 🟢 Active            │    │
│  │ Tier:   Free                 │    │
│  │ Created: Jan 15, 2026        │    │
│  └──────────────────────────────┘    │
│  [✏️ Edit Canteen Name]             │
└──────────────────────────────────────┘
```

**RPCs used**: Direct DB read/update for `tenants`

---

### Shifts & Meal Rates Sub-Page

```
┌──────────────────────────────────────┐
│  ← Settings     🍽️ Shifts & Rates   │
│  ┌──────────────────────────────┐    │
│  │ ☀️ Breakfast   6:00 – 9:00   │    │
│  │   Current Rate: ৳60         │    │
│  │   Since: Jul 1, 2026        │    │
│  │   [✏️ Edit]                  │    │
│  ├──────────────────────────────┤    │
│  │ 🌤️ Lunch      12:00 – 15:00 │    │
│  │   Current Rate: ৳80         │    │
│  │   Since: Jul 1, 2026        │    │
│  │   [✏️ Edit]                  │    │
│  ├──────────────────────────────┤    │
│  │ 🌙 Dinner     19:00 – 22:00 │    │
│  │   Current Rate: ৳80         │    │
│  │   Since: Jul 1, 2026        │    │
│  │   [✏️ Edit]                  │    │
│  └──────────────────────────────┘    │
│  Editing a rate creates a new        │
│  meal_config row with today's date   │
│  as effective_from. Old rates are    │
│  preserved for historical records.   │
└──────────────────────────────────────┘
```

**RPCs used**: Direct DB read `shifts` + `meal_configs`. Edit → DB update `shifts` + insert `meal_configs`.

---

### Invite Manager Sub-Page

```
┌──────────────────────────────────────┐
│  ← Settings     👥 Invite Manager   │
│  ┌──────────────────────────────┐    │
│  │ Generate a 6-digit code      │    │
│  │ to invite a manager.         │    │
│  │ Code expires in 24 hours.    │    │
│  │                              │    │
│  │ [🔑 Generate Code]           │    │
│  └──────────────────────────────┘    │
│  (after generate):                   │
│  ┌──────────────────────────────┐    │
│  │        4  8  2  7  1  3      │    │
│  │  Share this code with your   │    │
│  │  manager. Expires in 24hrs.  │    │
│  │  [📋 Copy] [📤 Share]        │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- `generate_invite_code(tenant_id, 'manager')` → generate button

---

### Vendors Sub-Page

```
┌──────────────────────────────────────┐
│  ← Settings     🏪 Vendors  [+ Add] │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Rahim Rice Dealer  ৳5,200│    │
│  │   📞 01712345678             │    │
│  │   ← swipe: [💵 Pay] [✏️ Edit]│    │
│  ├──────────────────────────────┤    │
│  │ 🏪 Karim Vegetables    ৳800 │    │
│  │   📞 01898765432             │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- Direct DB read/write for `vendors`
- `record_vendor_payment(tenant_id, vendor_id, amount, null, notes)` → swipe pay

---

### Vendor Detail Sub-Page

```
┌──────────────────────────────────────┐
│  ← Vendors   🏪 Rahim Rice Dealer   │
│  📞 01712345678                      │
├──────────────────────────────────────┤
│  Balance                             │
│  ┌──────────────────────────────┐    │
│  │     ৳5,200                   │    │
│  │     We Owe This Vendor       │    │
│  │     [💵 Pay Vendor]          │    │
│  └──────────────────────────────┘    │
├──────────────────────────────────────┤
│  Transaction History                 │
│  ┌──────────────────────────────┐    │
│  │ Jul 31 • Purchase 🛒 +৳1,200│    │
│  │   Rice 25kg                  │    │
│  │ Jul 28 • Payment  💵 -৳3,000│    │
│  │ Jul 25 • Purchase 🛒 +৳2,000│    │
│  │   Rice 40kg + Oil            │    │
│  │ ... (infinite scroll)        │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**RPCs used**:
- `get_vendor_statement(tenant_id, vendor_id, null, null)` → transaction list ⚠️
- `record_vendor_payment(tenant_id, vendor_id, amount, null, notes)` → Pay Vendor button

---

### My Profile Sub-Page

```
┌──────────────────────────────────────┐
│  ← Settings        👤 My Profile    │
│  ┌──────────────────────────────┐    │
│  │ 🖼️ [Google Avatar]           │    │
│  │ Name:  Marcel David          │    │
│  │ Email: marcel@gmail.com      │    │
│  │ (from Google — read only)    │    │
│  └──────────────────────────────┘    │
│  Canteen Memberships:                │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Rahim's Canteen  (Owner) │    │
│  └──────────────────────────────┘    │
│  [🚪 Sign Out]                       │
└──────────────────────────────────────┘
```

**RPCs used**: Direct DB read `user_profiles` + `tenant_members`. Sign out → Supabase `auth.signOut()`.

---

## Onboarding Flow (Pre-Tabs)

### Login → Google Sign-In
**RPCs used**: Supabase `auth.signInWithOAuth({ provider: 'google' })`

### Create Canteen
**RPCs used**: `create_tenant(p_name)` → creates tenant + member (owner) + seeds shifts → Home

### Join Canteen
**RPCs used**: `join_tenant_by_code(p_code)` → creates tenant_member (manager) → Home

---

## Complete Page Inventory (v1.0)

| # | Page | Type | Feature Module(s) |
|---|---|---|---|
| 1 | Login | Auth | `01_tenancy_and_auth` |
| 2 | Onboarding Choice | Auth | `01_tenancy_and_auth` |
| 3 | Create Canteen | Auth | `01_tenancy_and_auth` |
| 4 | Join Canteen | Auth | `01_tenancy_and_auth` |
| 5 | Home (Day Dashboard) | Tab | `06_shift_reconciliation` |
| 6 | Customer List | Tab | `02_meal_attendance`, `03_customer_wallets_ar` |
| 7 | Customer Detail | Sub-page | `03_customer_wallets_ar` |
| 8 | Cashbook | Tab | `04_bazar_and_expenses_ap`, `06_shift_reconciliation` |
| 9 | Staff List | Tab | `05_staff_payroll` |
| 10 | Staff Detail | Sub-page | `05_staff_payroll` |
| 11 | Settings | Tab | `01_tenancy_and_auth` |
| 12 | Shifts & Meal Rates | Sub-page | `02_meal_attendance` |
| 13 | Invite Manager | Sub-page | `01_tenancy_and_auth` |
| 14 | Vendors List | Sub-page | `04_bazar_and_expenses_ap` |
| 15 | Vendor Detail | Sub-page | `04_bazar_and_expenses_ap` |
| 16 | Canteen Profile | Sub-page | `01_tenancy_and_auth` |
| 17 | My Profile | Sub-page | `01_tenancy_and_auth` |

**Total: 17 pages** (4 auth + 5 tab screens + 8 sub-pages)

---

## Bottom Sheet Inventory (v1.0)

| # | Sheet | Fields | RPC / Action |
|---|---|---|---|
| 1 | Open Day | Opening cash amount | `start_business_day` |
| 2 | Close Day | Closing cash amount, notes | `end_business_day` |
| 3 | Add Customer | Name, phone (required), address, institution | DB insert `customers` |
| 4 | Edit Customer | Name, phone, address, institution, is_active toggle | DB update `customers` |
| 5 | Collect Baki | Amount (required), notes | `record_baki_payment` |
| 6 | Add Expense | Category picker (`market_cost` / `canteen_expense`), amount, vendor picker (optional), notes | `record_expense` |
| 7 | Add Income | Amount (required), notes | `record_misc_income` ⚠️ |
| 8 | Add Day Note | Type picker (`market_list` / `general_note` / `issue`), content | DB insert `day_notes` |
| 9 | Add Staff | Full name, role, phone (required) | DB insert `staff_members` |
| 10 | Edit Staff | Full name, role, phone, is_active toggle | DB update `staff_members` |
| 11 | Record Salary Payout | Amount (required), payment mode (`cash` / `bank` / `mobile_money`), notes | `record_salary_payout` |
| 12 | Add Vendor | Name (required), phone, address, notes | DB insert `vendors` |
| 13 | Edit Vendor | Name, phone, address, notes, is_active toggle | DB update `vendors` |
| 14 | Pay Vendor | Amount (required), notes | `record_vendor_payment` |
| 15 | Edit Shift/Meal Rate | Shift name, start/end time, rate (creates new `meal_configs` row) | DB update `shifts` + insert `meal_configs` |
