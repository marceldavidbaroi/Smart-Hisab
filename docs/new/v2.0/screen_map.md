# Smart-Hisab — Screen Map v2.0 (Business Tier)

> **Release goal**: Chain operator with full power — unlimited scale, multi-canteen oversight, professional reporting.
> **This document is ADDITIVE** — everything in [v1.0](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/v1.0/screen_map.md) and [v1.5](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/v1.5/screen_map.md) applies. Only new/changed screens are documented here.

---

## What's New in v2.0

| Feature | Impact on UI |
|---|---|
| **Unlimited tenants** | No cap on canteens |
| **Unlimited staff & managers** | No per-tenant caps |
| **Multi-canteen overview dashboard** | New dashboard page showing all canteens at a glance |
| **Export to PDF** | Export button on reports, analytics, and statements |
| **Bulk meal attendance** | New attendance mode: mark all present, un-toggle absentees |
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
| Counter Mode | ✅ Available |
| Reports | Daily + Weekly + Monthly + P&L + Full Analytics + Multi-canteen overview + PDF export |

---

## Active Roles

Same as v1.5: Owner, Manager, Counter Staff.

---

## Bottom Navigation — Same 5 tabs

No change to tab structure.

---

## Changes to Existing Screens

### Tab 1: 🏠 Home — NEW: Multi-Canteen Overview Link

**State B (Day Open)** — adds a new entry point:

```
  ┌──────────────────────────────┐
  │ 🏢  Multi-Canteen Overview   │  ← NEW
  │  See all canteens at a glance │
  └──────────────────────────────┘
```

Only visible if the user has 2+ canteens.
---

### Tab 2: 👥 Customers — NEW: Bulk Meal Attendance Mode

New toggle at the top of the customer list when a shift is active:

```
┌──────────────────────────────────────┐
│  Customers (120)    [+ Add]  [🔍]   │
├──────────────────────────────────────┤
│                                      │
│  Active Shift: 🍽️ Lunch (৳80)       │
│  [☑️ Bulk Mode]  ← NEW toggle        │
│  ─────────────────────────────────── │
```

#### Bulk Mode Activated

```
┌──────────────────────────────────────┐
│  Bulk Attendance         [✅ Done]  │
├──────────────────────────────────────┤
│                                      │
│  All marked PRESENT. Un-toggle       │
│  absentees:                          │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ ✅ Rahim Mia                 │    │
│  │ ✅ Karim Sheikh              │    │
│  │ ☐  Jamal Hossain  ← tapped  │    │
│  │ ✅ Fatima Begum              │    │
│  │ ☐  Abdul Rahman   ← tapped  │    │
│  │ ✅ Nasreen Akter             │    │
│  │ ...                          │    │
│  └──────────────────────────────┘    │
│                                      │
│  Present: 118 / 120                  │
│  [✅ Confirm Attendance]             │
│                                      │
└──────────────────────────────────────┘
```

**Flow:**
1. Toggle "Bulk Mode" → all customers are pre-checked as ✅ Present
2. Scroll through and un-check the absentees (much faster for 100+ customers)
3. Tap "Confirm Attendance" → batch-creates `meal_attendance` + `wallet_entry` for all present customers
4. Shows summary: "118 meals recorded for Lunch"

---

### Customer Detail — NEW: Export Button

```
  Statement:
  ┌──────────────────────────────┐
  │ Jul 31  Lunch     +৳80      │
  │ ...                         │
  └──────────────────────────────┘
  
  [📄 Export Statement to PDF]  ← NEW
```

Generates a PDF of the customer's wallet statement for a date range. Share via system share sheet.

---

### Reports Sub-Page (More) — NEW: PDF Export

Same Reports page from v1.5, but adds PDF export:

```
┌──────────────────────────────────────┐
│  ← More              Reports        │
├──────────────────────────────────────┤
│                                      │
│  (same as v1.5: Summary + P&L)       │
│                                      │
│  [📄 Export Report to PDF]   ← NEW   │
│                                      │
└──────────────────────────────────────┘
```

---

### Analytics Sub-Page (More) — UPGRADED: Advanced Analytics

The v1.5 Analytics page is upgraded with new sections:

```
┌──────────────────────────────────────┐
│  ← More            Analytics        │
├──────────────────────────────────────┤
│                                      │
│  Period: [This Month ▼]             │
│                                      │
│  (v1.5 sections: Meal Trend,         │
│   Cash Flow, Top Debtors,            │
│   Meal Breakdown, Expense Breakdown) │
│                                      │
│  ─────── NEW in v2.0 ────────────  │
│                                      │
│  📆 Comparative Report               │
│  ┌──────────────────────────────┐    │
│  │ This Week  vs  Last Week    │    │
│  │ Meals:  430 vs 395 (+9%)    │    │
│  │ Revenue:৳34k vs ৳31k (+10%) │    │
│  │ Expense:৳22k vs ৳25k (-12%) │    │
│  │ Profit: ৳12k vs ৳6k (+100%) │    │
│  └──────────────────────────────┘    │
│                                      │
│  🏪 Vendor Spend Analysis            │
│  ┌──────────────────────────────┐    │
│  │ 1. Kamal Vegetables  ৳18,200 │    │
│  │ 2. Rahim Rice        ৳12,500 │    │
│  │ 3. Fish Market       ৳ 8,400 │    │
│  │     (bar chart by vendor)    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ⏰ Peak Hours Analysis               │
│  ┌──────────────────────────────┐    │
│  │ Busiest Shift: Lunch (42%)  │    │
│  │ Peak Day: Thursday          │    │
│  │ Avg meals/day: 61           │    │
│  │     (heatmap: shifts x days) │    │
│  └──────────────────────────────┘    │
│                                      │
│  👥 Customer Trends                  │
│  ┌──────────────────────────────┐    │
│  │ Regular eaters: 38 (76%)    │    │
│  │ Irregular: 8 (16%)          │    │
│  │ Dormant (no meal 7d+): 4    │    │
│  │ Payment regularity: 72% ✅   │    │
│  └──────────────────────────────┘    │
│                                      │
│  👷 Staff Performance                │
│  ┌──────────────────────────────┐    │
│  │ Karim: 245 txns this month  │    │
│  │ Alam:  189 txns this month  │    │
│  │ Fatima: 132 txns this month │    │
│  │ Variance accuracy: 98% ✅   │    │
│  └──────────────────────────────┘    │
│                                      │
│  [📄 Export Analytics to PDF]         │
│                                      │
└──────────────────────────────────────┘
```

---

## NEW Page: Multi-Canteen Overview Dashboard

Accessed from: Home → "Multi-Canteen Overview" or long-press the canteen name in header.

```
┌──────────────────────────────────────┐
│  ← Home    All Canteens Overview    │
├──────────────────────────────────────┤
│                                      │
│  Today — [date]                      │
│                                      │
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
│  ├──────────────────────────────┤    │
│  │ 🏪 XYZ Hostel Kitchen 🔴 Closed│  │
│  │ Meals: 30 │ Cash: ৳8,000    │    │
│  │ Baki Out: ৳22,000            │    │
│  │ Variance: ৳0 ✅               │    │
│  └──────────────────────────────┘    │
│                                      │
│  Totals:                             │
│  ┌──────────────────────────────┐    │
│  │ Total Meals: 195              │    │
│  │ Total Cash In: ৳52,000       │    │
│  │ Total Baki Outstanding:       │    │
│  │   ৳152,000                    │    │
│  └──────────────────────────────┘    │
│                                      │
│  Tap any canteen to switch to it     │
│                                      │
└──────────────────────────────────────┘
```

**Actions:**
- Tap a canteen card → switches active tenant → navigates to Home
- Overview shows today's real-time data for all owned/managed canteens

---

## More Tab — NEW: Priority Support

Adds a new entry in the "About" section of the More tab:

```
  About
  ┌──────────────────────────────┐
  │ 📋 Subscription: Business   │
  │ 🎧 Priority Support          │  ← NEW
  │ ℹ️  App Version               │
  └──────────────────────────────┘
```

**Priority Support** → Opens in-app support chat or links to dedicated support channel.

---

## New Pages Added in v2.0

| # | Page | Parent | Type |
|---|---|---|---|
| 1 | Multi-Canteen Overview | Home | Sub-page |
| 2 | Bulk Meal Attendance | Customers | Mode (not a separate page) |

**New/updated features in More tab:**
- Reports: PDF export added
- Analytics: 5 new sections (Comparative, Vendor Spend, Peak Hours, Customer Trends, Staff Performance) + PDF export
- About: Priority Support added

**New bottom sheets:**

| # | Sheet | Fields |
|---|---|---|
| 1 | Export Statement to PDF | Date range picker → generate → share |
| 2 | Export Report to PDF | Same as above for financial reports |
| 3 | Export Analytics to PDF | Same as above for analytics data |

---

## Updated Page Count (v2.0)

v1.5 pages (23) + v2.0 additions (1 new page) = **24 pages total**
v1.5 bottom sheets (19) + v2.0 additions (3) = **22 bottom sheets total**

---

## Complete Page Inventory (All Versions)

| # | Page | Version | Type |
|---|---|---|---|
| 1 | Login | v1.0 | Auth |
| 2 | Onboarding Choice | v1.0 | Auth |
| 3 | Create Canteen | v1.0 | Auth |
| 4 | Join Canteen | v1.0 | Auth |
| 5 | Home (Day Dashboard) | v1.0 | Tab |
| 6 | Customer List | v1.0 | Tab |
| 7 | Customer Detail | v1.0 | Sub-page |
| 8 | Cashbook | v1.0 | Tab |
| 9 | Staff List | v1.0 | Tab |
| 10 | Staff Detail | v1.0 | Sub-page |
| 11 | Settings | v1.0 (moved to More in v1.5) | Tab → Section |
| 12 | Shifts & Meal Rates | v1.0 | Sub-page |
| 13 | Invite Manager | v1.0 | Sub-page |
| 14 | Vendors List | v1.0 | Sub-page |
| 15 | Vendor Detail | v1.0 | Sub-page |
| 16 | Canteen Profile | v1.0 | Sub-page |
| 17 | My Profile | v1.0 | Sub-page |
| 18 | PIN Gate | v1.5 | Screen |
| 19 | More (hub) | v1.5 | Tab Screen |
| 20 | Reports | v1.5 | Sub-page (under More) |
| 21 | Analytics | v1.5 (upgraded v2.0) | Sub-page (under More) |
| 22 | Staff Attendance History | v1.5 | Sub-page |
| 23 | Switch Canteen (sheet) | v1.5 | Bottom Sheet |
| 24 | Multi-Canteen Overview | v2.0 | Sub-page |

**Grand total: 24 pages + 22 bottom sheets across all tiers.**
