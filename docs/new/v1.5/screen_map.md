# Smart-Hisab — Screen Map v1.5 (Pro Tier)

> **Release goal**: Owner hires help, opens a second canteen, needs accountability and oversight.
> **This document is ADDITIVE** — everything in [v1.0/screen_map.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/v1.0/screen_map.md) applies. Only new/changed screens are documented here.

---

## What's New in v1.5

| Feature | Impact on UI |
|---|---|
| **Counter Mode + Staff PIN login** | New PIN gate screen, simplified tab set for counter staff |
| **Staff transaction stamping** | Every entry shows which staff recorded it |
| **Staff attendance tracking** | New sub-page under Staff tab |
| **Multi-tenant** (up to 3 canteens) | Tenant switcher in header/settings |
| **"More" tab in bottom nav** | Replaces Settings tab — houses Reports, Analytics, Settings |
| **Weekly / Monthly reports** | Reports page under More tab |
| **Financial summary (P&L)** | Inside Reports |
| **Basic analytics** | Trend charts, top debtors, meal breakdown |
| **Unlimited customers** | 50-cap removed |
| **Up to 10 staff per tenant** | Staff limit increased |

---

## Tier Limits (v1.5)

| Limit | Value |
|---|---|
| Canteens | 3 |
| Customers | Unlimited |
| Staff | 10 per tenant |
| Managers | 1 per tenant |
| Counter Mode | ✅ Available |
| Reports | Daily + Weekly + Monthly + P&L + Basic Analytics |

---

## Active Roles

| Role | Auth Method | Layout |
|---|---|---|
| **Owner** | Google Sign-In | Full 5-tab layout (Home, Customers, Cashbook, Staff, More) |
| **Manager** | Google Sign-In + join code | Full 5-tab layout (restricted Settings inside More) |
| **Counter Staff** | 4-digit PIN on shared device | **Counter Mode layout** — simplified 3-tab |

---

## Normal Mode (Owner / Manager) — Changes from v1.0

### Bottom Navigation — UPDATED: 5 tabs (Settings → More)

```
┌─────────┬────────────┬──────────┬─────────┬──────────┐
│  🏠     │  👥        │  💰      │  👷     │  ⋯       │
│  Home   │  Customers │  Cashbook│  Staff  │  More    │
└─────────┴────────────┴──────────┴─────────┴──────────┘
```

The "More" tab replaces the standalone Settings tab. It becomes the hub for Reports, Analytics, and Settings.

---

### Tab 1: 🏠 Home — NEW: Counter Mode Toggle

**State B (Day Open)** — adds Counter Mode entry:

```
┌──────────────────────────────────────┐
│  Smart-Hisab  [🔄 Switch Canteen]   │
├──────────────────────────────────────┤
│                                      │
│  📅 Today — [date]        🟢 Open   │
│  Opening Cash: ৳5,000               │
│  (same stats cards as v1.0)          │
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
│  ┌──────────────────────────────┐    │
│  │ 🖥️  Start Counter Mode       │    │  ← NEW
│  │  Hand off to counter staff   │    │
│  └──────────────────────────────┘    │
│                                      │
│  (close day button at bottom)        │
│                                      │
└──────────────────────────────────────┘
```

**New actions:**

| Action | Flow |
|---|---|
| Switch Canteen | Header icon → bottom sheet showing tenant list → tap to switch active tenant |
| Start Counter Mode | → PIN gate screen (staff selects name → enters PIN → counter mode activates) |

> Reports and Analytics are now accessed via the **More** tab (not from Home).

---

### Tab 2: 👥 Customers — NEW: Staff Stamp on Entries

No layout change. The following additions:

- **Customer statement entries** now show `Recorded by: [staff name]` when a staff logged the transaction in Counter Mode
- **50-customer cap removed** — [+ Add] no longer shows limit warning

---

### Tab 3: 💰 Cashbook — NEW: Staff Stamp on Entries

- Each day entry now shows `By: [staff name]` if recorded during Counter Mode
- No other layout changes

---

### Tab 4: 👷 Staff — NEW: Attendance Tracking + PIN Setup

#### Staff List — Updated

```
┌──────────────────────────────────────┐
│  Staff (5/10)              [+ Add]  │
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 👤 Karim Sheikh     🟢 PIN   │    │  ← NEW: PIN status indicator
│  │   Cook  •  01798765432       │    │
│  │   Today: ✅ Present          │    │  ← NEW: today's attendance
│  ├──────────────────────────────┤    │
│  │ 👤 Alam Hossain     ⚪ No PIN│    │
│  │   Cashier  •  01612345678    │    │
│  │   Today: ❌ Absent           │    │
│  └──────────────────────────────┘    │
│                                      │
│  [📋 Attendance History]             │  ← NEW
│                                      │
└──────────────────────────────────────┘
```

#### Staff Detail — Updated

New fields and sections:

```
┌──────────────────────────────────────┐
│  ← Back          Karim Sheikh       │
├──────────────────────────────────────┤
│                                      │
│  (same profile info as v1.0)         │
│                                      │
│  Counter Access:                     │  ← NEW section
│  ┌──────────────────────────────┐    │
│  │  PIN Login: ✅ Enabled        │    │
│  │  [🔄 Reset PIN]              │    │
│  └──────────────────────────────┘    │
│                                      │
│  Attendance This Month:              │  ← NEW section
│  ┌──────────────────────────────┐    │
│  │  Present: 22 days             │    │
│  │  Absent: 4 days               │    │
│  │  Half Day: 2 days             │    │
│  │  [View Full Attendance]       │    │
│  └──────────────────────────────┘    │
│                                      │
│  (salary section same as v1.0)       │
│                                      │
└──────────────────────────────────────┘
```

**New actions on Add Staff sheet:**

| Field | v1.0 | v1.5 |
|---|---|---|
| Name | ✅ | ✅ |
| Role | ✅ | ✅ |
| Phone | ✅ | ✅ |
| Allow Counter Login | ❌ | ✅ (toggle) |
| Set Temporary PIN | ❌ | ✅ (auto-generated 4-digit, shown once) |

---

#### NEW Sub-Page: Staff Attendance History

```
┌──────────────────────────────────────┐
│  ← Staff       Attendance           │
├──────────────────────────────────────┤
│                                      │
│  Month: [◀ July 2026 ▶]             │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ Staff Name    │ P  │ A │ H  │    │
│  │───────────────┼────┼───┼────│    │
│  │ Karim Sheikh  │ 22 │ 4 │ 2  │    │
│  │ Alam Hossain  │ 18 │ 8 │ 2  │    │
│  │ Fatima Begum  │ 26 │ 2 │ 0  │    │
│  └──────────────────────────────┘    │
│                                      │
│  Tap any row for daily breakdown     │
│                                      │
└──────────────────────────────────────┘
```

---

### Tab 5: ⚙️ Settings — NEW: Tenant Switcher + Multi-Canteen

#### New Settings Entries

```
  Canteen
  ┌──────────────────────────────┐
  │ 🏪 Canteen Profile           │
  │ 🕐 Shifts & Meal Rates       │
  │ 🔄 Switch Canteen             │  ← NEW
  │ ＋ Create New Canteen          │  ← NEW (if < 3 canteens)
  └──────────────────────────────┘
```

#### Switch Canteen Bottom Sheet

```
┌──────────────────────────────────────┐
│  Your Canteens                      │
├──────────────────────────────────────┤
│                                      │
│  ┌──────────────────────────────┐    │
│  │ ✅ Rahim's Canteen (Owner)   │    │
│  ├──────────────────────────────┤    │
│  │    ABC Factory Mess (Manager)│    │
│  ├──────────────────────────────┤    │
│  │    XYZ Hostel Kitchen (Owner)│    │
│  └──────────────────────────────┘    │
│                                      │
│  [＋ Create New Canteen]             │
│                                      │
└──────────────────────────────────────┘
```

---

### NEW Tab 5: ⋯ More

#### Purpose
Hub for Reports, Analytics, and Settings. Replaces the standalone Settings tab from v1.0.

```
┌──────────────────────────────────────┐
│  More                               │
├──────────────────────────────────────┤
│                                      │
│  Insights                            │
│  ┌──────────────────────────────┐    │
│  │ 📊  Reports                   │    │
│  │ 📈  Analytics                 │    │
│  └──────────────────────────────┘    │
│                                      │
│  Canteen                             │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Canteen Profile           │    │
│  │ 🕐 Shifts & Meal Rates       │    │
│  │ 🔄 Switch Canteen             │    │
│  │ ＋ Create New Canteen          │    │
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
│  │ 📋 Subscription: Pro         │    │
│  │ ℹ️  App Version               │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

---

### Sub-Page: Reports (from More)

```
┌──────────────────────────────────────┐
│  ← More              Reports        │
├──────────────────────────────────────┤
│                                      │
│  Period: [Daily ▼]  [◀ Jul 31 ▶]    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  📊 Summary                  │    │
│  │  Meals Served: 45            │    │
│  │  Total Billed: ৳3,600       │    │
│  │  Baki Collected: ৳8,000     │    │
│  │  Expenses: ৳3,500           │    │
│  │  Net Cash Flow: +৳4,500     │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  💰 P&L (Profit & Loss)      │    │
│  │  Revenue: ৳85,000            │    │
│  │  Expenses: ৳52,000           │    │
│  │  Salaries: ৳24,000           │    │
│  │  ────────────────────        │    │
│  │  Net Profit: ৳9,000         │    │
│  └──────────────────────────────┘    │
│                                      │
│  Period options: Daily / Weekly /    │
│  Monthly                             │
│                                      │
└──────────────────────────────────────┘
```

---

### Sub-Page: Analytics (from More) — NEW

```
┌──────────────────────────────────────┐
│  ← More            Analytics        │
├──────────────────────────────────────┤
│                                      │
│  Period: [This Week ▼]              │
│                                      │
│  📈 Meal Trend                       │
│  ┌──────────────────────────────┐    │
│  │  ▁▃▅▇▅▇▆   (bar chart)      │    │
│  │  Mon Tue Wed Thu Fri Sat Sun │    │
│  │  Meals served per day        │    │
│  └──────────────────────────────┘    │
│                                      │
│  💰 Cash Flow Trend                  │
│  ┌──────────────────────────────┐    │
│  │  ╱╲╱──╱╲   (line chart)     │    │
│  │  Inflows vs Outflows         │    │
│  └──────────────────────────────┘    │
│                                      │
│  🏆 Top Debtors                      │
│  ┌──────────────────────────────┐    │
│  │ 1. Rahim Mia        ৳4,200  │    │
│  │ 2. Karim Sheikh     ৳3,800  │    │
│  │ 3. Jamal Hossain    ৳2,600  │    │
│  │ 4. Abdul Rahman     ৳1,900  │    │
│  │ 5. Nasreen Akter    ৳1,200  │    │
│  └──────────────────────────────┘    │
│                                      │
│  🍽️ Meal Breakdown (This Period)     │
│  ┌──────────────────────────────┐    │
│  │  Breakfast:  120 meals (28%) │    │
│  │  Lunch:      180 meals (42%)│    │
│  │  Dinner:     130 meals (30%)│    │
│  └──────────────────────────────┘    │
│                                      │
│  📤 Expense Breakdown               │
│  ┌──────────────────────────────┐    │
│  │  🥬 Market Cost:    ৳18,000 │    │
│  │  ⛽ Canteen Expense: ৳4,200 │    │
│  │  💰 Salaries:       ৳24,000 │    │
│  │      (pie chart visual)      │    │
│  └──────────────────────────────┘    │
│                                      │
└──────────────────────────────────────┘
```

---

## Counter Mode Layout (NEW in v1.5)

### How Counter Mode Activates

```
Owner/Manager taps "Start Counter Mode" on Home
  │
  ▼
PIN Gate Screen (staff selection)
  │
  ▼
Counter Mode Active (simplified 3-tab layout)
  │
  ▼
"Lock" → back to PIN Gate
"Exit Counter Mode" → requires Owner/Manager confirmation → back to Normal Mode
```

---

### PIN Gate Screen

```
┌──────────────────────────────────────┐
│                                      │
│  Counter Mode                        │
│  Who is at the counter?              │
│                                      │
│  ┌──────┐  ┌──────┐  ┌──────┐       │
│  │  👤  │  │  👤  │  │  👤  │       │
│  │Karim │  │ Alam │  │Fatima│       │
│  └──────┘  └──────┘  └──────┘       │
│                                      │
│  Enter your 4-digit PIN:            │
│                                      │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐                │
│  │ • │ │ • │ │ • │ │   │             │
│  └──┘ └──┘ └──┘ └──┘                │
│                                      │
│  ┌─┬─┬─┐                            │
│  │1│2│3│                             │
│  ├─┼─┼─┤                            │
│  │4│5│6│    (number pad)             │
│  ├─┼─┼─┤                            │
│  │7│8│9│                             │
│  ├─┼─┼─┤                            │
│  │ │0│⌫│                             │
│  └─┴─┴─┘                            │
│                                      │
│  [Exit Counter Mode] (needs owner auth)│
│                                      │
└──────────────────────────────────────┘
```

- Staff taps their avatar → enters 4-digit PIN → verified via `verify_staff_pin` RPC
- PIN is session-based — stays active until "Lock" is pressed

---

### Counter Mode Bottom Navigation (3 Tabs)

```
┌────────────┬────────────┬────────────┐
│  🏠        │  👥        │  💰        │
│  Home      │  Customers │  Cashbook  │
└────────────┴────────────┴────────────┘
```

**Removed tabs:** Staff, Settings (not needed at the counter)

---

### Counter Mode Header

```
┌──────────────────────────────────────┐
│  👤 Karim Sheikh    🔒 Lock  │
│  Active Shift: Lunch (৳80)          │
└──────────────────────────────────────┘
```

- "Lock" → clears staff session → returns to PIN Gate
- Staff name is always visible for accountability

---

### Counter Mode: Home Tab (Simplified)

```
┌──────────────────────────────────────┐
│  👤 Karim Sheikh         🔒 Lock    │
│  Active Shift: Lunch (৳80)          │
├──────────────────────────────────────┤
│                                      │
│  📅 Today — [date]        🟢 Open   │
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
│  (NO close day, NO reports,          │
│   NO counter mode toggle)            │
│                                      │
└──────────────────────────────────────┘
```

**What Counter Staff CAN do:**
- ✅ Toggle meals
- ✅ Collect baki
- ✅ Record expenses
- ✅ Add day notes

**What Counter Staff CANNOT do:**
- ❌ Open / Close day
- ❌ View reports
- ❌ Manage staff or customers
- ❌ Access settings

All transactions are auto-stamped with `recorded_by_staff_id`.

---

### Counter Mode: Customers Tab (Simplified)

Same as Normal Mode customer list, but:
- **[+ Add] button hidden** — staff can't create new customers
- **Edit profile disabled** — staff can't modify customer data
- **Meal toggle works** — primary action
- **Swipe for baki works** — secondary action
- **Customer detail** — shows statement (read-only), collect payment button works

---

### Counter Mode: Cashbook Tab (Simplified)

Same as Normal Mode cashbook, but:
- **Add Expense / Income works** — staff can record market costs and expenses
- **Day notes work** — staff can add notes
- **All entries show staff name** who recorded them

---

## New Pages Added in v1.5

| # | Page | Parent | Type |
|---|---|---|---|
| 1 | PIN Gate | Counter Mode | Screen |
| 2 | More (hub) | Tab 5 | Tab Screen |
| 3 | Reports | More | Sub-page |
| 4 | Analytics | More | Sub-page |
| 5 | Staff Attendance History | Staff | Sub-page |
| 6 | Switch Canteen (sheet) | More/Header | Bottom Sheet |

> **Note:** The v1.0 Settings tab is now a section inside the More tab. All Settings sub-pages (Canteen Profile, Shifts & Meal Rates, Invite Manager, Vendors, My Profile) are unchanged — they're just accessed from More instead of a dedicated tab.

**New bottom sheets:**

| # | Sheet | Fields |
|---|---|---|
| 1 | Switch Canteen | Canteen list (tap to switch) |
| 2 | Create New Canteen | Name |
| 3 | Set Staff PIN | Toggle counter access + auto-generate temp PIN |
| 4 | Reset Staff PIN | Confirm → generates new temp PIN |

---

## Updated Page Count (v1.5)

v1.0 pages (17) − Settings tab (now inside More) + v1.5 additions (6) = **23 pages total**
v1.0 bottom sheets (15) + v1.5 additions (4) = **19 bottom sheets total**
