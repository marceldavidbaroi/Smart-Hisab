# Smart-Hisab — Screen Map v1.5 (Pro Tier)

> **Release goal**: Owner hires help, opens a second canteen, needs accountability and oversight.
> **ADDITIVE** — everything in [v1.0/screen_map.md](../v1.0/screen_map.md) applies. Only new/changed screens are documented here.

---

## What's New in v1.5

| Feature | Impact on UI |
|---|---|
| **Counter Mode + Staff PIN login** | New PIN gate screen, simplified 3-tab layout for staff |
| **Staff transaction stamping** | Every entry shows which staff recorded it |
| **Staff attendance tracking** | New sub-page under Staff tab |
| **Multi-tenant** (up to 3 canteens) | Tenant switcher in header/settings |
| **"More" tab** | Replaces Settings tab — houses Reports, Analytics, Settings |
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

## Tab 1: 🏠 Home — Counter Mode Toggle (NEW)

State B adds the Counter Mode entry:

```
│  ┌──────────────────────────────┐    │
│  │ 🖥️  Start Counter Mode       │    │
│  │  Hand off to counter staff   │    │
│  └──────────────────────────────┘    │
│  [🔄 Switch Canteen]  ← header icon  │
```

**RPCs used**:
- `verify_staff_pin(tenant_id, pin)` → called on PIN gate after staff selects their avatar
- `create_tenant(p_name)` → Create New Canteen sheet

---

## Tab 4: 👷 Staff — PIN Setup + Attendance (UPDATED)

### Staff List additions

```
│  │ 👤 Karim Sheikh     🟢 PIN   │    │
│  │   Cook  •  Today: ✅ Present │    │
│  │ [📋 Attendance History]      │    │
```

### Staff Detail additions

```
│  Counter Access:
│  │  PIN Login: ✅ Enabled        │
│  │  [🔄 Reset PIN]              │

│  Attendance This Month:
│  │  Present: 22 │ Absent: 4 │ Half Day: 2 │
│  │  [View Full Attendance]       │
```

**RPCs used**:
- `reset_staff_pin(staff_id)` → Reset PIN button
- `set_staff_pin(staff_id, temp_pin, new_pin)` → called from PIN gate on first login

---

## Tab 5 (New): ⋯ More

Hub for Reports, Analytics, and Settings. Replaces standalone Settings tab.

```
┌──────────────────────────────────────┐
│  ⋯ More                               │
│  ┌──────────────────────────────┐    │
│  │ 📊 Reports                   │ →  │
│  │ 📈 Analytics                 │ →  │
│  │ ──────────────────────────── │    │
│  │ 🏪 Canteen Profile           │ →  │
│  │ 🍽️ Shifts & Meal Rates       │ →  │
│  │ 🏪 Vendors                   │ →  │
│  │ 👥 Invite Manager            │ →  │
│  │ 👤 My Profile                │ →  │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

> Reports and Analytics are new in v1.5. All Settings sub-pages (Canteen Profile, Shifts, Vendors, Invite Manager, My Profile) are inherited from v1.0.

### Sub-Page: Reports

```
│  Period: [Daily ▼]  [◀ Jul 31 ▶]
│  📊 Summary: Meals, Baked Billed, Collected, Expenses, Net Cash Flow
│  💰 P&L: Revenue, Expenses, Salaries, Net Profit
```

**RPCs used**:
- `get_financial_summary(tenant_id, start_date, end_date)` → all report metrics

### Sub-Page: Analytics

```
│  📈 Meal Trend (bar chart)
│  💰 Cash Flow Trend (line chart)
│  🏆 Top Debtors
│  🍽️ Meal Breakdown (Breakfast / Lunch / Dinner %)
│  📤 Expense Breakdown
```

**RPCs used**:
- `get_financial_summary(tenant_id, start, end)` → cash flow data
- Supabase direct queries on `meal_attendance`, `wallet_entries` for charts

---

## Counter Mode (NEW in v1.5)

### PIN Gate Screen

```
│  Counter Mode — Who is at the counter?
│  ┌──────┐  ┌──────┐  ┌──────┐
│  │Karim │  │ Alam │  │Fatima│
│  └──────┘  └──────┘  └──────┘
│  Enter your 4-digit PIN:
│  [1][2][3]
│  [4][5][6]
│  [7][8][9]
│  [ ][0][⌫]
│  [Exit Counter Mode]
```

**RPCs used**:
- `verify_staff_pin(tenant_id, pin)` → validates PIN, returns `{ staff_id, full_name, role }`

### Counter Mode Navigation (3 Tabs)

```
┌────────────┬────────────┬────────────┐
│  🏠 Home   │  👥 Customers │  💰 Cashbook │
└────────────┴────────────┴────────────┘
```

**What counter staff CAN do**: Toggle meals, collect baki, record expenses, add notes
**What counter staff CANNOT do**: Open/close day, view reports, manage staff, access settings

All transactions auto-stamped with `recorded_by_staff_id`.

---

### First-Login PIN Setup Flow

When a staff member with a `temp_pin` enters it at the PIN Gate, they are redirected to set a permanent PIN:

```
┌──────────────────────────────────────┐
│  🔐 Set Your PIN                      │
│  Welcome, Karim!                     │
│                                      │
│  Create a new 4-digit PIN:           │
│  [●][●][●][●]                          │
│                                      │
│  Confirm your PIN:                   │
│  [○][○][○][○]                          │
│                                      │
│  [1][2][3]                           │
│  [4][5][6]                           │
│  [7][8][9]                           │
│  [ ][0][⌫]                           │
│                                      │
│  [✅ Set PIN & Continue]              │
└──────────────────────────────────────┘
```

**Flow**: PIN Gate (temp_pin matched) → Set PIN screen → `set_staff_pin(staff_id, temp_pin, new_pin)` ⚠️ → Counter Mode Home

This screen is shown **once** per staff member. After setting a permanent PIN, they go directly to Counter Mode on future logins.

---

## New Pages Added in v1.5

| # | Page | Type | Feature Module(s) | RPCs |
|---|---|---|---|---|
| 1 | PIN Gate | Screen | `01_tenancy_and_auth` | `verify_staff_pin` |
| 2 | Set PIN (first login) | Screen | `05_staff_payroll` | `set_staff_pin` ⚠️ |
| 3 | More (hub) | Tab | — | — |
| 4 | Reports | Sub-page | `06_shift_reconciliation` | `get_financial_summary` |
| 5 | Analytics | Sub-page | `02_meal_attendance`, `03_customer_wallets_ar` | direct queries |
| 6 | Staff Attendance History | Sub-page | `05_staff_payroll` | direct query `staff_attendance` |

## New Bottom Sheets in v1.5

| # | Sheet | RPC / Action |
|---|---|---|
| 1 | Switch Canteen | Supabase `tenant_members` query |
| 2 | Create New Canteen | `create_tenant` |
| 3 | Set Staff PIN (add flow) | DB update `allow_terminal_login`, `reset_staff_pin` |
| 4 | Reset Staff PIN | `reset_staff_pin` |

---

## Updated Page Count (v1.5)

v1.0 pages (17) + v1.5 additions (6) = **23 pages total**
v1.0 bottom sheets (15) + v1.5 additions (4) = **19 bottom sheets total**
