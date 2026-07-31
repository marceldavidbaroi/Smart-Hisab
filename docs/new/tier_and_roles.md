# Smart-Hisab — Tier, Role & Release Plan

> Single source of truth for subscription tiers, role permissions, and release scope.  
> Each tier = a release milestone. Every release is **fully functional, no broken features**.

---

## Philosophy

1. **Simple beats powerful.** A canteen owner standing at a counter with one free hand doesn't want features — they want speed.
2. **Each release is a complete product.** Free isn't a demo. It's a fully working canteen management app. Pro adds scale. Business adds power.
3. **Tiers gate scale and advanced tools, never core workflow.** Every paying and non-paying user can run a canteen end-to-end.

---

## The Three Tiers = Three Releases

```
v1.0 (Free)     →  Solo owner runs 1 canteen from their phone
v1.5 (Pro)      →  Growing owner delegates to staff, runs up to 3 canteens
v2.0 (Business) →  Chain operator with full analytics, unlimited scale
```

---

## Tier Summary

| | 🆓 Free (v1.0) | ⭐ Pro (v1.5) | 🏢 Business (v2.0) |
|---|---|---|---|
| **Who it's for** | Solo canteen owner | Owner with hired help | Multi-location operator |
| **Price** | ৳0 | TBD/month | TBD/month |
| **Canteens (tenants)** | 1 | 3 | Unlimited |
| **Customers** | 50 | Unlimited | Unlimited |
| **Staff members** | 3 | 10 per tenant | Unlimited |
| **Managers** | 1 | 1 per tenant | Unlimited |

---

## Feature Matrix

### 🟢 Core Workflow — ALL tiers, always available

These are the features that replace the paper khata. Every tier gets all of these with no restrictions (except numeric limits above).

| Feature | What it does |
|---|---|
| **Customer profiles** | Add customers with name, phone, institution |
| **Baki tracking** | Customer eats → debt increases. Customer pays → debt decreases. |
| **Meal attendance** | One-tap: "customer X ate lunch" → auto-charges wallet |
| **Baki collection** | Record cash payment → wallet balance decreases |
| **Customer wallet & statement** | Full history: every charge, every payment, with dates |
| **Shifts & meal rates** | Set Breakfast/Lunch/Dinner times and per-meal pricing |
| **Business day** | Open day with opening cash → close with closing cash |
| **Cashbook** | Every cash inflow and outflow recorded during the day |
| **Cash reconciliation** | Expected vs actual cash at day close, variance shown |
| **Expense recording** | Log market costs, canteen expenses |
| **Day notes** | Market lists, general notes, issues |
| **Staff profiles** | Add staff with name, role, phone (within tier limit) |
| **Staff salary payouts** | Record salary payments (creates cashbook outflow) |
| **Invite managers** | 6-digit code, manager joins canteen (within tier limit) |
| **Live day status** | Is the day open? How much collected today? |
| **Total baki outstanding** | How much all customers owe, combined |
| **Daily summary** | End-of-day recap: meals served, cash in/out, variance |

---

### 🔵 Pro Features — v1.5 release

Unlocked when the canteen grows beyond what one person can handle.

| Feature | Why it's Pro |
|---|---|
| **Counter Mode + Staff PIN login** | When the owner isn't at the counter, staff need PIN accountability. |
| **Staff transaction stamping** | Every transaction tagged with which staff recorded it. |
| **Staff attendance tracking** | Track who worked which day/shift. |
| **Multi-tenant** (up to 3 canteens) | Second location = real business growth. |
| **Weekly / monthly reports** | Solo owner checks daily. Growing owner needs trends. |
| **Financial summary (P&L)** | Revenue vs expenses over a date range. |

---

### 🟠 Business Features — v2.0 release

For chain operators who need maximum scale and insights.

| Feature | Why it's Business |
|---|---|
| **Unlimited tenants** | 4+ locations = chain operator. |
| **Unlimited staff & managers** | Large teams across locations. |
| **Multi-canteen overview dashboard** | See all canteens' status from one screen. |
| **Export to PDF** | Professional reports for accountants / investors. |
| **Bulk meal attendance** | Mark all customers present, un-toggle absentees. Speed for 100+ customer canteens. |
| **Priority support** | Dedicated help for paying businesses. |
| **Advanced analytics** (future) | Customer trends, peak hours, seasonal patterns. |

---

### 💬 Paid Add-Ons — Available to ALL tiers (v1.1+)

These features are **not gated by tier**. Any user can purchase them as a separate add-on. Revenue is independent of tier subscriptions.

| Feature | What it does | Pricing Model |
|---|---|---|
| **SMS Baki Reminder** | Send SMS to customers reminding them of outstanding baki. Individual or bulk send. | Prepaid credit bundles (100/500/2K/10K SMS). Manual bKash top-up for MVP. |

> Full specification: [sms_service.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/sms_service.md)

**Tier-specific SMS limits:**

| | Free | Pro | Business |
|---|---|---|---|
| **Daily SMS limit** | 50 | 200 | 500 |
| **Bulk send max** | 50 per batch | 100 per batch | 100 per batch |

---

## Role Permissions (Fixed — same across all tiers)

Tiers control **what features exist**. Roles control **who can access them**.

| Feature | Owner | Manager | Counter Staff |
|---|---|---|---|
| **Create canteen** | ✅ | ✅ (own) | ❌ |
| **Canteen settings & billing** | ✅ | ❌ | ❌ |
| **Invite / remove managers** | ✅ | ❌ | ❌ |
| **Add / edit staff** | ✅ | ✅ | ❌ |
| **Add / edit customers** | ✅ | ✅ | ❌ |
| **Open / close business day** | ✅ | ✅ | ❌ |
| **Record salary payouts** | ✅ | ✅ | ❌ |
| **View reports & financials** | ✅ | ✅ | ❌ |
| **View customer statements** | ✅ | ✅ | ❌ |
| **Toggle meals / collect baki** | ✅ | ✅ | ✅ |
| **Record expenses** | ✅ | ✅ | ✅ |
| **Add day notes** | ✅ | ✅ | ✅ |
| **Toggle Counter Mode on/off** | ✅ | ✅ | ❌ |
| **PIN clock-in / lock** | N/A | N/A | ✅ |
| **View own attendance** (self-service) | N/A | N/A | ✅ (read-only) |

---

## Release Scope

### v1.0 — Free Tier (Ship first)

**Goal**: A solo canteen owner downloads the app and replaces their paper notebook **today**.

```
Auth:
  ✅ Google Sign-In
  ✅ Create canteen (onboarding)
  ✅ Invite manager (1 manager, 6-digit code)
  ✅ Join canteen (manager joins via code)
  ❌ Counter Mode (no staff PIN on Free)

Core:
  ✅ Add customers (up to 50)
  ✅ Add staff (up to 3, for record-keeping + salary tracking)
  ✅ Shifts & meal config
  ✅ Business day open/close
  ✅ Meal attendance (owner operates directly)
  ✅ Baki collection
  ✅ Cashbook (expenses, day entries)
  ✅ Cash reconciliation
  ✅ Salary payouts
  ✅ Day notes

Dashboard:
  ✅ Live day status
  ✅ Total baki outstanding
  ✅ Daily summary (at day close)
  ❌ Weekly/monthly reports
  ❌ Financial P&L
```

### v1.5 — Pro Tier

**Goal**: Owner hires help, opens a second canteen, needs accountability and oversight.

```
Everything in v1.0, plus:

  ✅ Counter Mode + Staff PIN login
  ✅ Staff transaction stamping (staff_id on every record)
  ✅ Staff attendance tracking
  ✅ Multi-tenant (up to 3 canteens)
  ✅ Weekly / monthly reports
  ✅ Financial summary (P&L)
  ✅ Tenant switcher
  ✅ Unlimited customers
  ✅ Up to 10 staff per tenant
```

### v2.0 — Business Tier

**Goal**: Chain operator with full power.

```
Everything in v1.5, plus:

  ✅ Unlimited tenants, staff, managers
  ✅ Multi-canteen overview dashboard
  ✅ Export to PDF
  ✅ Bulk meal attendance
  ✅ Priority support
  ✅ Advanced analytics (future scope)
```

---

## Competitive Strategy: Win on Simplicity

| Principle | Implementation |
|---|---|
| **Faster than paper** | 1 tap to log a meal (2 seconds vs 15 seconds for paper) |
| **Zero training** | Big buttons, Bangla-first, no hidden menus |
| **One-hand use** | Bottom-accessible actions, 48px+ touch targets |
| **Instant value** | Download → Google Sign-In → create canteen → log first meal in under 2 minutes |
| **Trust through transparency** | Every transaction timestamped + staff-stamped. No disputes. |

> **Rule**: If any screen takes more than 3 taps to complete its primary action, redesign it. The competitor is a paper notebook, not another app.
