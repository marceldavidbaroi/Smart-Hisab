# Smart-Hisab — Screen Map v2.0 (Business Tier)

> **Release goal**: Chain operator with full power — unlimited scale, multi-canteen oversight, professional reporting.
> **ADDITIVE** — everything in [v1.0](../v1.0/screen_map.md) and [v1.5](../v1.5/screen_map.md) applies. Only new/changed screens are documented here.

---

## What's New in v2.0

| Feature | Impact on UI |
|---|---|
| **Unlimited tenants** | No cap on canteens |
| **Unlimited staff & managers** | No per-tenant caps |
| **Multi-canteen overview dashboard** | New page showing all canteens at a glance |
| **Export to PDF** | Export button on reports, analytics, and customer statements |
| **Bulk meal attendance** | Mark all present, un-toggle absentees |
| **Advanced analytics** | Vendor spend, comparative reports, peak hours, staff performance, customer trends |
| **Priority support** | Support entry in More tab |

---

## Tier Limits (v2.0)

| Limit | Value |
|---|---|
| Canteens | Unlimited |
| Customers | Unlimited |
| Staff | Unlimited |
| Managers | Unlimited |
| Counter Mode | ✅ |
| Reports | Daily + Weekly + Monthly + P&L + Full Analytics + Multi-canteen + PDF export |

---

## Tab 1: 🏠 Home — Multi-Canteen Overview Link (NEW)

When user has 2+ canteens, a new entry appears in State B:

```
│  ┌──────────────────────────────┐    │
│  │ 🏢  Multi-Canteen Overview   │    │
│  │  See all canteens at a glance │    │
│  └──────────────────────────────┘    │
```

**RPCs used**:
- `get_active_business_day(tenant_id)` × all tenants → for each canteen card
- `calculate_expected_cash(day_id)` × all open days → for live stats per canteen

---

## Tab 2: 👥 Customers — Bulk Meal Attendance (NEW)

New toggle at top of Customer List when a shift is active:

```
│  Active Shift: 🍽️ Lunch (৳80)
│  [☑️ Bulk Mode]  ← NEW
```

### Bulk Mode Activated

```
│  Bulk Attendance         [✅ Done]
│  All marked PRESENT. Un-toggle absentees:
│  ┌──────────────────────────────┐
│  │ ✅ Rahim Mia                 │
│  │ ☐  Jamal Hossain  ← absent  │
│  │ ✅ Fatima Begum              │
│  └──────────────────────────────┘
│  Present: 118 / 120
│  [✅ Confirm Attendance]
```

**RPCs used**:
- `bulk_record_meal_attendance(tenant_id, shift_id, business_day_id, absent_customer_ids[], null)` → on Confirm

---

## Customer Detail — Export Button (NEW)

```
│  Statement: [...]
│  [📄 Export Statement to PDF]
```

**RPCs used**:
- `get_customer_statement(tenant_id, customer_id, start, end)` → generates PDF data

---

## Reports Sub-Page — PDF Export (UPDATED)

```
│  (same as v1.5: Summary + P&L)
│  [📄 Export Report to PDF]
```

**RPCs used**:
- `get_financial_summary(tenant_id, start_date, end_date)` → PDF data source

---

## Analytics Sub-Page — Advanced Analytics (UPGRADED)

New sections added to v1.5 analytics page:

```
│  📆 Comparative Report (This Week vs Last Week)
│  🏪 Vendor Spend Analysis (bar chart by vendor)
│  ⏰ Peak Hours Analysis (heatmap: shifts × days)
│  👥 Customer Trends (regular / irregular / dormant)
│  👷 Staff Performance (txn count, variance accuracy)
│  [📄 Export Analytics to PDF]
```

**RPCs used**:
- `get_financial_summary(...)` × two periods → comparative report
- `get_vendor_statement(...)` aggregated → vendor spend
- Direct queries on `meal_attendance`, `wallet_entries`, `day_entries` → charts

---

## NEW Page: Multi-Canteen Overview Dashboard

Accessed from: Home → "Multi-Canteen Overview"

```
┌──────────────────────────────────────┐
│  ← Home    All Canteens Overview    │
│  Today — [date]                      │
│  ┌──────────────────────────────┐    │
│  │ 🏪 Rahim's Canteen    🟢 Open│    │
│  │ Meals: 45 │ Cash: ৳12,000   │    │
│  │ Baki Out: ৳45,000            │    │
│  │ Variance: ৳0 ✅               │    │
│  ├──────────────────────────────┤    │
│  │ 🏪 ABC Factory Mess  🟢 Open│    │
│  │ Meals: 120 │ Cash: ৳32,000  │    │
│  │ Baki Out: ৳85,000            │    │
│  │ Variance: -৳500 ⚠️           │    │
│  └──────────────────────────────┘    │
│  Totals: Meals: 195 │ Cash: ৳52,000 │
└──────────────────────────────────────┘
```

- Tap a canteen card → switches active tenant → navigates to Home

**RPCs used**:
- `get_active_business_day(tenant_id)` for each tenant
- `calculate_expected_cash(day_id)` for each open day

---

## New Pages Added in v2.0

| # | Page | Type | Feature Module(s) | RPCs |
|---|---|---|---|---|
| 1 | Multi-Canteen Overview | Sub-page | `06_shift_reconciliation` | `get_active_business_day`, `calculate_expected_cash` |
| 2 | Bulk Attendance Mode | Mode (inline) | `02_meal_attendance` | `bulk_record_meal_attendance` |

## New Bottom Sheets in v2.0

| # | Sheet | RPC / Action |
|---|---|---|
| 1 | Export Statement to PDF | `get_customer_statement` → date range picker |
| 2 | Export Report to PDF | `get_financial_summary` → date range picker |
| 3 | Export Analytics to PDF | direct queries → date range picker |

---

## Updated Page Count (v2.0)

v1.5 pages (23) + v2.0 additions (1 page + 1 inline mode) = **24 pages total**
v1.5 bottom sheets (19) + v2.0 additions (3) = **22 bottom sheets total**

> Bulk Attendance Mode is an inline mode on the Customer List page, not a separate page. Counted separately for completeness.

---

## Complete Page Inventory (All Versions)

| # | Page | Version | Type | Feature Module(s) |
|---|---|---|---|---|
| 1 | Login | v1.0 | Auth | `01_tenancy_and_auth` |
| 2 | Onboarding Choice | v1.0 | Auth | `01_tenancy_and_auth` |
| 3 | Create Canteen | v1.0 | Auth | `01_tenancy_and_auth` |
| 4 | Join Canteen | v1.0 | Auth | `01_tenancy_and_auth` |
| 5 | Home (Day Dashboard) | v1.0 | Tab | `06_shift_reconciliation` |
| 6 | Customer List | v1.0 | Tab | `02_meal_attendance`, `03_customer_wallets_ar` |
| 7 | Customer Detail | v1.0 | Sub-page | `03_customer_wallets_ar` |
| 8 | Cashbook | v1.0 | Tab | `04_bazar_and_expenses_ap`, `06_shift_reconciliation` |
| 9 | Staff List | v1.0 | Tab | `05_staff_payroll` |
| 10 | Staff Detail | v1.0 | Sub-page | `05_staff_payroll` |
| 11 | Settings | v1.0 → More in v1.5 | Tab | `01_tenancy_and_auth` |
| 12 | Shifts & Meal Rates | v1.0 | Sub-page | `02_meal_attendance` |
| 13 | Invite Manager | v1.0 | Sub-page | `01_tenancy_and_auth` |
| 14 | Vendors List | v1.0 | Sub-page | `04_bazar_and_expenses_ap` |
| 15 | Vendor Detail | v1.0 | Sub-page | `04_bazar_and_expenses_ap` |
| 16 | Canteen Profile | v1.0 | Sub-page | `01_tenancy_and_auth` |
| 17 | My Profile | v1.0 | Sub-page | `01_tenancy_and_auth` |
| 18 | PIN Gate | v1.5 | Screen | `01_tenancy_and_auth` |
| 19 | Set PIN (first login) | v1.5 | Screen | `05_staff_payroll` |
| 20 | More (hub) | v1.5 | Tab | — |
| 21 | Reports | v1.5 | Sub-page | `06_shift_reconciliation` |
| 22 | Analytics | v1.5 (upgraded v2.0) | Sub-page | `02_meal_attendance`, `03_customer_wallets_ar`, `04_bazar_and_expenses_ap` |
| 23 | Staff Attendance History | v1.5 | Sub-page | `05_staff_payroll` |
| 24 | Multi-Canteen Overview | v2.0 | Sub-page | `06_shift_reconciliation` |
| — | Bulk Attendance Mode | v2.0 | Inline mode | `02_meal_attendance` |
