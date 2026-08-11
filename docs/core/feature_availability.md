# Smart-Hisab — Feature Availability by Version

> Single source of truth for what is available in each subscription tier.
> Cross-reference with `releases/vX.X/screen_map.md` for UI details and `features/0X_*/rpc_apis.md` for RPC details.

---

## How It Works

Each canteen (tenant) has a `subscription_tier` column in the `tenants` table. This field controls which features the owner and their staff/managers can access.

```
tenants.subscription_tier  →  'free' | 'pro' | 'business'
         ↕
  Maps to release version
         ↕
    'free'     =  v1.0  (Free tier)
    'pro'      =  v1.5  (Pro tier)
    'business' =  v2.0  (Business tier)
```

A user can own or belong to **multiple canteens**, and each canteen can be on a **different tier** independently. Upgrading one canteen does not affect others.

---

## Enforcement Strategy

> [!IMPORTANT]
> Feature gating is currently **client-side only**. The app reads `tenant.subscription_tier` after loading the tenant and conditionally renders UI elements based on it. The backend (RLS / RPCs) does **not** currently block access based on tier.

| Layer | What it does |
|---|---|
| **Client (Mobile app)** | Reads `tenants.subscription_tier`. Hides/shows screens, buttons, and tabs based on the feature matrix below. Shows "Upgrade" prompt when a locked feature is tapped. |
| **Supabase RLS** | Currently enforces **tenant membership** only (`is_tenant_member`). Does **not** check `subscription_tier`. |
| **RPC functions** | Currently do **not** check `subscription_tier`. They trust the client to gate access before calling. |

> **Future hardening**: Critical limits (e.g. max 50 customers on Free, bulk attendance on Business only) should eventually be enforced server-side inside the relevant RPCs to prevent bypass.

---

## Tier Limits

| Limit | `'free'` (v1.0) | `'pro'` (v1.5) | `'business'` (v2.0) |
|---|---|---|---|
| Canteens per account | 1 | 3 | Unlimited |
| Customers per tenant | 50 | Unlimited | Unlimited |
| Staff per tenant | 3 | 10 | Unlimited |
| Managers per tenant | 1 | 1 | Unlimited |

---

## Feature Availability Matrix

### 🔐 Auth & Tenancy

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Google Sign-In | ✅ | ✅ | ✅ | Supabase Auth |
| Create canteen (owner) | ✅ | ✅ | ✅ | `create_tenant` |
| Join canteen via 6-digit code (manager) | ✅ | ✅ | ✅ | `join_tenant_by_code` |
| Generate manager invite code | ✅ | ✅ | ✅ | `generate_invite_code` |
| Switch between canteens | ❌ | ✅ | ✅ | Client-side |
| Create additional canteens | ❌ | ✅ (up to 3) | ✅ (unlimited) | `create_tenant` |
| Multi-canteen overview dashboard | ❌ | ❌ | ✅ | `get_active_business_day` |
| Unlimited managers per tenant | ❌ | ❌ | ✅ | `join_tenant_by_code` |

---

### 🖥️ Counter Mode & Staff PIN

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Counter Mode (staff PIN login) | ❌ | ✅ | ✅ | `verify_staff_pin` |
| Staff PIN setup (temp PIN) | ❌ | ✅ | ✅ | `reset_staff_pin` ⚠️ |
| Staff PIN change (set permanent PIN) | ❌ | ✅ | ✅ | `set_staff_pin` ⚠️ |
| Transaction stamping (`recorded_by_staff_id`) | ❌ | ✅ | ✅ | All write RPCs |

> ⚠️ = RPC not yet implemented in migration SQL

---

### 🍽️ Meal Attendance

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| One-tap meal toggle | ✅ | ✅ | ✅ | `record_meal_attendance` |
| Auto-charge customer wallet on meal | ✅ | ✅ | ✅ | `record_meal_attendance` |
| Meal toggle unmark (remove charge) | ✅ | ✅ | ✅ | `record_meal_attendance` |
| Shift auto-resolution by time | ✅ | ✅ | ✅ | `get_current_shift` |
| Meal rate config per shift | ✅ | ✅ | ✅ | `meal_configs` table |
| Rate history (`effective_from`) | ✅ | ✅ | ✅ | `meal_configs` table |
| Bulk meal attendance (mark all, un-toggle absences) | ❌ | ❌ | ✅ | `bulk_record_meal_attendance` ⚠️ |

---

### 💰 Customer Wallets (AR)

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Customer baki balance | ✅ | ✅ | ✅ | `customer_wallets.current_balance` |
| Baki payment collection | ✅ | ✅ | ✅ | `record_baki_payment` |
| Customer wallet statement | ✅ | ✅ | ✅ | `get_customer_statement` ⚠️ |
| Computed balance (audit-grade) | ✅ | ✅ | ✅ | `get_customer_balance` ⚠️ |
| Export customer statement to PDF | ❌ | ❌ | ✅ | Client-side (v2.0) |

---

### 🛒 Bazar & Expenses (AP)

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Record market cost / canteen expense | ✅ | ✅ | ✅ | `record_expense` |
| Record misc income | ✅ | ✅ | ✅ | `record_misc_income` ⚠️ |
| Vendor profiles | ✅ | ✅ | ✅ | `vendors` table |
| Vendor baki tracking | ✅ | ✅ | ✅ | `vendor_wallet_entries` |
| Vendor payment settlement | ✅ | ✅ | ✅ | `record_vendor_payment` |
| Vendor statement / ledger | ✅ | ✅ | ✅ | `get_vendor_statement` ⚠️ |
| Day notes (market list, issues) | ✅ | ✅ | ✅ | `day_notes` table |

---

### 👷 Staff & Payroll

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Staff profiles | ✅ | ✅ | ✅ | `staff_members` table |
| Salary payout recording | ✅ | ✅ | ✅ | `record_salary_payout` |
| Staff attendance tracking | ❌ | ✅ | ✅ | `staff_attendance` table |
| Counter Mode PIN login | ❌ | ✅ | ✅ | `verify_staff_pin` |
| PIN reset by manager | ❌ | ✅ | ✅ | `reset_staff_pin` ⚠️ |

---

### 📅 Business Day & Reconciliation

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Open business day | ✅ | ✅ | ✅ | `start_business_day` |
| Close business day | ✅ | ✅ | ✅ | `end_business_day` |
| Expected cash calculation | ✅ | ✅ | ✅ | `calculate_expected_cash` |
| Cash variance on close | ✅ | ✅ | ✅ | `end_business_day` |
| Reopen same-day closed day | ✅ | ✅ | ✅ | `resume_business_day` ⚠️ |

---

### 📊 Reports & Analytics

| Feature | v1.0 | v1.5 | v2.0 | RPC / Module |
|---|---|---|---|---|
| Daily summary on Home | ✅ | ✅ | ✅ | `calculate_expected_cash` |
| Weekly / Monthly reports | ❌ | ✅ | ✅ | `get_financial_summary` ⚠️ |
| P&L report | ❌ | ✅ | ✅ | `get_financial_summary` ⚠️ |
| Basic analytics (meal trend, top debtors) | ❌ | ✅ | ✅ | Direct queries |
| Advanced analytics (vendor spend, peak hours, staff performance, comparative) | ❌ | ❌ | ✅ | Direct queries |
| Export reports to PDF | ❌ | ❌ | ✅ | Client-side (v2.0) |

---

## Implementation Status Legend

| Symbol | Meaning |
|---|---|
| ✅ | Feature available in this tier |
| ❌ | Feature not available in this tier |
| ⚠️ | RPC not yet implemented in migration SQL — client uses direct query or feature is pending |
