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

### Purpose
The owner's cockpit. Glance at today's status, take quick actions, open/close the day.

### State A: No Day Open

```
┌──────────────────────────────────────┐
│  Smart-Hisab          [canteen name] │
├──────────────────────────────────────┤
│                                      │
│  ☀️  Good Morning, [Owner Name]      │
│                                      │
│  ┌──────────────────────────────┐    │
│  │                              │    │
│  │  📅  Start Today's Day       │    │
│  │  Tap to open business day    │    │
│  │                              │    │
│  └──────────────────────────────┘    │
│                                      │
│  Yesterday's Summary (if exists):    │
│  ┌──────────────────────────────┐    │
│  │ Meals: 45  │ Cash: ৳12,000  │    │
│  │ Baki Collected: ৳8,000      │    │
│  │ Variance: ৳0 ✅              │    │
│  └──────────────────────────────┘    │
│                                      │
│  Total Baki Outstanding: ৳45,000    │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**
- Tap "Start Today's Day" → Bottom sheet: enter opening cash → day opens
- View yesterday's summary card (read-only)

**Auto-open behavior**: If the owner goes to Customers or Cashbook and performs any action (meal toggle, expense) without an open day, the system auto-opens the day with ৳0 opening cash. A subtle toast: "Day auto-opened. Set opening cash on Home."

---

### State B: Day is Open

```
┌──────────────────────────────────────┐
│  Smart-Hisab          [canteen name] │
├──────────────────────────────────────┤
│                                      │
│  📅 Today — [date]        🟢 Open   │
│  Opening Cash: ৳5,000               │
│                                      │
│  ┌────────┬────────┬────────┐        │
│  │ Meals  │ Cash   │  Baki  │        │
│  │  Served│ In     │  Coll. │        │
│  │  32    │ ৳8,200 │ ৳6,000 │        │
│  └────────┴────────┴────────┘        │
│                                      │
│  Quick Actions:                      │
│  ┌──────────────┬──────────────┐     │
│  │ 🍽️ Mark      │ 💵 Collect   │     │
│  │    Meals     │    Baki      │     │
│  ├──────────────┼──────────────┤     │
│  │ 🛒 Add       │ 📝 Day       │     │
│  │    Expense   │    Notes     │     │
│  └──────────────┴──────────────┘     │
│                                      │
│  Total Baki Outstanding: ৳45,000    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🔒  Close Today's Day       │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**
| Action | Tap Flow |
|---|---|
| Mark Meals | → navigates to Customers tab (meal mode) |
| Collect Baki | → navigates to Customers tab (payment mode) |
| Add Expense | → bottom sheet: amount, category (market_cost / canteen_expense), vendor (optional), notes |
| Day Notes | → bottom sheet: note type (market_list / general_note / issue), content |
| Close Day | → bottom sheet: enter closing cash → shows expected vs actual → confirm close |
| Edit Opening Cash | Tap the opening cash amount → bottom sheet to edit (only while day is open) |

**Role visibility:**

| Element | Owner | Manager |
|---|---|---|
| All stats & quick actions | ✅ | ✅ |
| Open / Close Day | ✅ | ✅ |
| Edit Opening Cash | ✅ | ✅ |

---

### State C: Day Closed (Reopenable — same day only)

```
┌──────────────────────────────────────┐
│  📅 Today — [date]       🔴 Closed  │
│                                      │
│  Summary:                            │
│  ┌──────────────────────────────┐    │
│  │ Opening:  ৳5,000             │    │
│  │ + Inflows: ৳8,200            │    │
│  │ - Outflows: ৳3,500           │    │
│  │ = Expected: ৳9,700           │    │
│  │ Actual:    ৳9,500            │    │
│  │ Variance:  -৳200 ⚠️          │    │
│  └──────────────────────────────┘    │
│                                      │
│  [🔄 Reopen Today's Day]            │
│                                      │
└──────────────────────────────────────┘
```

---

## Tab 2: 👥 Customers

### Purpose
The most-used tab. During meal hours, this is where the owner lives — toggling meals and collecting baki. Outside meal hours, it's for customer management.

### Customer List (Default View)

```
┌──────────────────────────────────────┐
│  Customers (32/50)     [+ Add]  [🔍]│
├──────────────────────────────────────┤
│                                      │
│  Active Shift: 🍽️ Lunch (৳80)       │
│  ─────────────────────────────────── │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 👤 Rahim Mia         ৳2,400 │    │
│  │    ABC Factory    [🍽️ ✅]    │    │
│  ├──────────────────────────────┤    │
│  │ 👤 Karim Sheikh      ৳1,800 │    │
│  │    ABC Factory    [🍽️ ☐]    │    │
│  ├──────────────────────────────┤    │
│  │ 👤 Jamal Hossain       ৳600 │    │
│  │    XYZ Hostel     [🍽️ ✅]    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ✅ = ate this meal  ☐ = not yet     │
│                                      │
└──────────────────────────────────────┘
```

**Key behaviors:**

| Action | Gesture | Result |
|---|---|---|
| **Toggle meal** | Tap the 🍽️ checkbox | Instantly toggles meal attendance for the active shift. Auto-charges/refunds wallet. |
| **Collect baki** | Swipe row left → 💵 button | Bottom sheet: enter payment amount → records wallet entry + day entry |
| **View profile** | Tap customer name/row | Opens Customer Detail page |
| **Add customer** | Tap [+ Add] | Bottom sheet: name (required), phone (optional), institution (optional) |
| **Search** | Tap 🔍 | Filter customer list by name |

**When no shift is active** (outside meal hours):
- The meal toggle checkboxes are hidden
- List shows customer name + baki balance only
- Swipe for baki collection still works

**Role visibility:**

| Action | Owner | Manager |
|---|---|---|
| Toggle meals | ✅ | ✅ |
| Collect baki | ✅ | ✅ |
| Add / Edit customer | ✅ | ✅ |
| View profile & statement | ✅ | ✅ |

---

### Customer Detail Page

Navigated from: tap customer row in list.

```
┌──────────────────────────────────────┐
│  ← Back          Rahim Mia          │
├──────────────────────────────────────┤
│                                      │
│  👤 Rahim Mia                        │
│  📱 01712345678                      │
│  🏭 ABC Factory                     │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Current Baki: ৳2,400       │    │
│  │  [💵 Collect Payment]        │    │
│  └──────────────────────────────┘    │
│                                      │
│  Statement:                          │
│  ┌──────────────────────────────┐    │
│  │ Jul 31  Lunch     +৳80      │    │
│  │ Jul 31  Payment   -৳500     │    │
│  │ Jul 30  Dinner    +৳70      │    │
│  │ Jul 30  Lunch     +৳80      │    │
│  │ Jul 30  Breakfast +৳50      │    │
│  │ ...                         │    │
│  └──────────────────────────────┘    │
│                                      │
│  [✏️ Edit Profile]                   │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**
- Collect Payment → bottom sheet: amount, notes → creates wallet_entry (payment) + day_entry (inflow)
- Edit Profile → bottom sheet: edit name, phone, institution
- Statement is an infinite-scroll list of wallet_entries

---

## Tab 3: 💰 Cashbook

### Purpose
All cash movement for the current day. Expenses, income, market costs — everything that affects the cash drawer.

### Cashbook View (Day Open)

```
┌──────────────────────────────────────┐
│  Cashbook — [Today's Date]    [+ Add]│
├──────────────────────────────────────┤
│                                      │
│  Opening Cash: ৳5,000               │
│                                      │
│  ┌────────────┬─────────────┐        │
│  │ 💵 Inflow  │ 📤 Outflow  │        │
│  │  ৳8,200    │  ৳3,500     │        │
│  │            │             │        │
│  │ Expected   │             │        │
│  │ Cash:৳9,700│             │        │
│  └────────────┴─────────────┘        │
│                                      │
│  Today's Entries:                    │
│  ┌──────────────────────────────┐    │
│  │ ↗️ Customer Payment  +৳500  │    │
│  │   Rahim Mia  •  12:30 PM   │    │
│  ├──────────────────────────────┤    │
│  │ ↙️ Market Cost       -৳1,200│    │
│  │   Vegetables  •  8:00 AM   │    │
│  ├──────────────────────────────┤    │
│  │ ↙️ Canteen Expense   -৳300  │    │
│  │   Gas refill  •  9:15 AM   │    │
│  ├──────────────────────────────┤    │
│  │ ↙️ Salary Outflow    -৳2,000│    │
│  │   Karim (Cook)  •  6:00 PM │    │
│  └──────────────────────────────┘    │
│                                      │
│  📝 Day Notes:                       │
│  ┌──────────────────────────────┐    │
│  │ 🛒 Market: potatoes, onions,│    │
│  │   rice (25kg), oil (5L)     │    │
│  │                    [+ Note] │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**

| Action | Flow |
|---|---|
| Add Expense | [+ Add] → bottom sheet: category (market_cost / canteen_expense), amount, vendor (optional dropdown), notes |
| Add Income | [+ Add] → bottom sheet: misc_earn, amount, notes |
| Add Day Note | [+ Note] → bottom sheet: type (market_list / general_note / issue), content |
| View Entry Detail | Tap any entry → detail bottom sheet (read-only) |

**When no day is open:**
- Shows the most recent closed day's summary
- [+ Add] still works — triggers auto-open with ৳0 opening cash

**Role visibility:**

| Action | Owner | Manager |
|---|---|---|
| View all entries | ✅ | ✅ |
| Add expense / income | ✅ | ✅ |
| Add day notes | ✅ | ✅ |

---

## Tab 4: 👷 Staff

### Purpose
Manage staff profiles and record salary payouts. Simple roster — no attendance tracking in v1.0.

### Staff List

```
┌──────────────────────────────────────┐
│  Staff (2/3)               [+ Add]  │
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 👤 Karim Sheikh              │    │
│  │   Cook  •  01798765432       │    │
│  │   Salary Due: ৳0            │    │
│  ├──────────────────────────────┤    │
│  │ 👤 Alam Hossain              │    │
│  │   Cashier  •  01612345678    │    │
│  │   Salary Due: ৳8,000        │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**

| Action | Gesture | Result |
|---|---|---|
| Add staff | Tap [+ Add] | Bottom sheet: name, role (free text), phone |
| View profile | Tap row | Staff Detail page |
| Pay salary | Swipe row left → 💵 | Bottom sheet: amount, payment mode (cash/bank/mobile_money), notes → creates salary_payout + day_entry |
| Edit / Deactivate | Inside Staff Detail page |

> **Note**: In v1.0, `allow_terminal_login` and `hashed_pin` fields are NOT exposed in the UI. No Counter Mode means no PIN setup needed.

---

### Staff Detail Page

```
┌──────────────────────────────────────┐
│  ← Back          Karim Sheikh       │
├──────────────────────────────────────┤
│                                      │
│  👤 Karim Sheikh                     │
│  🔧 Cook                            │
│  📱 01798765432                      │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Salary Balance: ৳0         │    │
│  │  [💵 Record Payout]          │    │
│  └──────────────────────────────┘    │
│                                      │
│  Payout History:                     │
│  ┌──────────────────────────────┐    │
│  │ Jul 15  Salary    ৳8,000    │    │
│  │ Jun 15  Salary    ৳8,000    │    │
│  │ ...                         │    │
│  └──────────────────────────────┘    │
│                                      │
│  [✏️ Edit]  [🚫 Deactivate]         │
│                                      │
└──────────────────────────────────────┘
```

**Role visibility:**

| Action | Owner | Manager |
|---|---|---|
| View staff list | ✅ | ✅ |
| Add / Edit staff | ✅ | ✅ |
| Record salary payout | ✅ | ✅ |
| Deactivate staff | ✅ | ✅ |

---

## Tab 5: ⚙️ Settings

### Purpose
Setup and configuration. Used during onboarding and occasionally after.

### Settings Page

```
┌──────────────────────────────────────┐
│  Settings                           │
├──────────────────────────────────────┤
│                                      │
│  Canteen                             │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Canteen Profile           │    │
│  │ 🕐 Shifts & Meal Rates       │    │
│  └──────────────────────────────┘    │
│                                      │
│  People                              │
│  ┌──────────────────────────────┐    │
│  │ 👥 Invite Manager             │    │
│  │ 🏪 Vendors / Suppliers        │    │
│  └──────────────────────────────┘    │
│                                      │
│  Account                             │
│  ┌──────────────────────────────┐    │
│  │ 👤 My Profile                 │    │
│  │ 🌐 Language (বাংলা / English) │    │
│  │ 🚪 Sign Out                   │    │
│  └──────────────────────────────┘    │
│                                      │
│  About                               │
│  ┌──────────────────────────────┐    │
│  │ 📋 Subscription: Free        │    │
│  │ ℹ️  App Version               │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

**Role visibility:**

| Setting | Owner | Manager |
|---|---|---|
| Canteen Profile (name, edit) | ✅ | ❌ (view only) |
| Shifts & Meal Rates | ✅ | ✅ |
| Invite Manager | ✅ | ❌ |
| Vendors / Suppliers | ✅ | ✅ |
| My Profile | ✅ | ✅ |
| Language toggle | ✅ | ✅ |
| Sign Out | ✅ | ✅ |
| Subscription info | ✅ | ❌ |

---

### Sub-Page: Shifts & Meal Rates

```
┌──────────────────────────────────────┐
│  ← Settings     Shifts & Meal Rates │
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 🌅 Breakfast                  │    │
│  │ 6:00 AM – 9:00 AM            │    │
│  │ Rate: ৳50/meal               │    │
│  │ Status: ✅ Active             │    │
│  ├──────────────────────────────┤    │
│  │ ☀️ Lunch                      │    │
│  │ 12:00 PM – 3:00 PM           │    │
│  │ Rate: ৳80/meal               │    │
│  │ Status: ✅ Active             │    │
│  ├──────────────────────────────┤    │
│  │ 🌙 Dinner                    │    │
│  │ 7:00 PM – 10:00 PM           │    │
│  │ Rate: ৳70/meal               │    │
│  │ Status: ✅ Active             │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

- Tap any shift → bottom sheet to edit time window & rate
- Toggle active/inactive per shift

---

### Sub-Page: Invite Manager

```
┌──────────────────────────────────────┐
│  ← Settings       Invite Manager    │
├──────────────────────────────────────┤
│                                      │
│  Current Managers:                   │
│  ┌──────────────────────────────┐    │
│  │ 👤 Sumon Ahmed               │    │
│  │   Joined: Jul 15, 2026       │    │
│  │                   [Remove]   │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Generate Invite Code         │    │
│  │                              │    │
│  │     [ 4  8  3  7  2  1 ]     │    │
│  │                              │    │
│  │  Expires in 24 hours          │    │
│  │  Share this with your manager │    │
│  │                              │    │
│  │  [📋 Copy]  [📤 Share]       │    │
│  └──────────────────────────────┘    │
│                                      │
│  Limit: 1 manager (Free tier)       │
│                                      │
└──────────────────────────────────────┘
```

---

### Sub-Page: Vendors / Suppliers

```
┌──────────────────────────────────────┐
│  ← Settings      Vendors       [+ Add]│
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Kamal Vegetable Store     │    │
│  │   📱 01712345678              │    │
│  │   We owe: ৳3,200             │    │
│  ├──────────────────────────────┤    │
│  │ 🏪 Rahim Rice Dealer         │    │
│  │   📱 01898765432              │    │
│  │   We owe: ৳0 ✅               │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**

| Action | Gesture | Result |
|---|---|---|
| Add vendor | [+ Add] | Bottom sheet: name, phone |
| View vendor detail | Tap row | Vendor Detail page (baki history) |
| Pay vendor | Swipe left → 💵 | Bottom sheet: amount, notes → records payment (creates day_entry outflow) |
| Add vendor baki | Inside Vendor Detail or when recording market expense (select vendor) |

### Vendor Detail Page

```
┌──────────────────────────────────────┐
│  ← Vendors    Kamal Vegetable Store │
├──────────────────────────────────────┤
│                                      │
│  🏪 Kamal Vegetable Store            │
│  📱 01712345678                      │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  We Owe: ৳3,200              │    │
│  │  [💵 Record Payment]         │    │
│  └──────────────────────────────┘    │
│                                      │
│  Transaction History:                │
│  ┌──────────────────────────────┐    │
│  │ Jul 31  Market purchase +৳1,200│   │
│  │ Jul 30  Payment to vendor -৳2,000│ │
│  │ Jul 28  Market purchase +৳4,000│   │
│  │ ...                           │   │
│  └──────────────────────────────┘    │
│                                      │
│  [✏️ Edit]                           │
│                                      │
└──────────────────────────────────────┘
```

---

## Onboarding Flow (Pre-Tabs)

These screens appear BEFORE the user ever sees the bottom tabs.

### Screen 1: Login

```
┌──────────────────────────────────────┐
│                                      │
│          Smart-Hisab                 │
│     আপনার ক্যান্টিনের হিসাব,        │
│        আপনার ফোনে।                   │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🔵 Continue with Google      │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

### Screen 2: Onboarding Choice (No tenant found)

```
┌──────────────────────────────────────┐
│                                      │
│  Welcome, [Name]!                    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🏪  Create My Canteen       │    │
│  │  Start fresh with a new      │    │
│  │  canteen                     │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🔗  Join a Canteen          │    │
│  │  I have a 6-digit code       │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

### Screen 3a: Create Canteen

```
┌──────────────────────────────────────┐
│                                      │
│  Name your canteen:                  │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Rahim's Canteen             │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  ✅  Create & Start           │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

→ Creates tenant + tenant_member (owner) + seeds default shifts → lands on Home tab.

### Screen 3b: Join Canteen

```
┌──────────────────────────────────────┐
│                                      │
│  Enter your 6-digit code:           │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  [4] [8] [3] [7] [2] [1]    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🔗  Join                     │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

→ Validates code → creates tenant_member (manager) → lands on Home tab.

---

## Complete Page Inventory (v1.0)

| # | Page | Parent | Type |
|---|---|---|---|
| 1 | Login | Auth | Screen |
| 2 | Onboarding Choice | Auth | Screen |
| 3 | Create Canteen | Auth | Screen |
| 4 | Join Canteen | Auth | Screen |
| 5 | Home (Day Dashboard) | Tab 1 | Tab Screen |
| 6 | Customer List | Tab 2 | Tab Screen |
| 7 | Customer Detail | Tab 2 | Sub-page |
| 8 | Cashbook | Tab 3 | Tab Screen |
| 9 | Staff List | Tab 4 | Tab Screen |
| 10 | Staff Detail | Tab 4 | Sub-page |
| 11 | Settings | Tab 5 | Tab Screen |
| 12 | Shifts & Meal Rates | Settings | Sub-page |
| 13 | Invite Manager | Settings | Sub-page |
| 14 | Vendors List | Settings | Sub-page |
| 15 | Vendor Detail | Settings | Sub-page |
| 16 | Canteen Profile | Settings | Sub-page |
| 17 | My Profile | Settings | Sub-page |

**Total: 17 pages** (4 auth + 5 tab screens + 8 sub-pages)

---

## Bottom Sheet Inventory (v1.0)

All modal interactions use bottom slide sheets (no center popups).

| # | Sheet | Triggered From | Fields |
|---|---|---|---|
| 1 | Open Day | Home | Opening cash amount |
| 2 | Close Day | Home | Closing cash → shows expected vs actual → confirm |
| 3 | Add Customer | Customer List | Name*, phone, institution |
| 4 | Edit Customer | Customer Detail | Name*, phone, institution |
| 5 | Collect Baki | Customer List (swipe) or Detail | Amount*, notes |
| 6 | Add Expense | Cashbook or Home quick action | Category*, amount*, vendor (dropdown), notes |
| 7 | Add Income | Cashbook | Amount*, notes |
| 8 | Add Day Note | Cashbook or Home quick action | Type (market_list/general_note/issue)*, content* |
| 9 | Add Staff | Staff List | Name*, role, phone* |
| 10 | Edit Staff | Staff Detail | Name*, role, phone* |
| 11 | Record Salary Payout | Staff List (swipe) or Detail | Amount*, payment mode, notes |
| 12 | Add Vendor | Vendor List | Name*, phone |
| 13 | Edit Vendor | Vendor Detail | Name*, phone |
| 14 | Pay Vendor | Vendor List (swipe) or Detail | Amount*, notes |
| 15 | Edit Shift/Meal Rate | Shifts & Meal Rates | Start time, end time, rate, active toggle |

**Total: 15 bottom sheets**

---

## Navigation Flow Summary

```
App Launch
  │
  ├── Not Authenticated → Login (Google Sign-In)
  │     │
  │     ├── No tenant → Onboarding Choice
  │     │     ├── Create Canteen → Home
  │     │     └── Join Canteen → Home
  │     │
  │     └── Has tenant(s) → Home
  │
  └── Authenticated → Home
        │
        ├── Tab: Home ──────────── [dashboard + quick actions]
        │     ├── → Customer List (via "Mark Meals")
        │     ├── → Customer List (via "Collect Baki")
        │     ├── → Add Expense (bottom sheet)
        │     └── → Day Notes (bottom sheet)
        │
        ├── Tab: Customers ──────── [list + meal toggle + swipe baki]
        │     └── → Customer Detail
        │           └── → Collect Payment (bottom sheet)
        │
        ├── Tab: Cashbook ────────── [day entries + notes]
        │     └── → Add Expense / Income / Note (bottom sheets)
        │
        ├── Tab: Staff ──────────── [list + swipe salary]
        │     └── → Staff Detail
        │           └── → Record Payout (bottom sheet)
        │
        └── Tab: Settings ────────── [config pages]
              ├── → Canteen Profile
              ├── → Shifts & Meal Rates
              ├── → Invite Manager
              ├── → Vendors List
              │     └── → Vendor Detail
              ├── → My Profile
              └── → Language / Sign Out
```

---

## Key UX Principles Applied

1. **3-tap rule**: Every primary action (meal toggle, baki collection, expense) is reachable in ≤ 3 taps from any tab.
2. **Bottom sheets everywhere**: No center popups. All input forms use bottom slide sheets with rounded corners and drag handle.
3. **Swipe for speed**: Salary payouts, baki collection, and vendor payments all accessible via swipe — zero tap overhead for power users.
4. **Auto-open day**: Never block the user from their primary task. If the day isn't open, open it automatically and let them set opening cash later.
5. **Bangla first**: All labels, buttons, and messages in Bangla by default. English available as toggle in Settings.
6. **One-hand operation**: All primary actions are in bottom-reachable zones. No top-right menus.
7. **48px+ touch targets**: Every interactive element meets minimum touch target size for counter use.
