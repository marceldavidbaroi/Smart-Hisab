# Smart-Hisab — Database Schema Architecture (v2)

> Definitive schema specification aligned with [app_vision.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/app_vision.md) and [auth_flow_v2.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/auth_flow_v2.md).
> Replaces `master_entity_architecture.md`.

---

## 1. Architecture Principles

1. **Google-Only Auth** — No device tokens, no email/password, no web dashboard pairing. All platform users authenticate via Google Sign-In through Supabase Auth.
2. **Flat Role Model** — Two roles: `owner` and `manager`. Stored as a TEXT column. No RBAC table. Counter staff exist only in `staff_members` with a PIN.
3. **Multi-Tenant Boundary** — Every data row is scoped by `tenant_id`. RLS enforces this via `tenant_members`.
4. **Operational Window Isolation** — Transactions are stamped with `business_day_id` and `shift_id`.
5. **Dual-Ledger Accounting** — `wallet_entries` (customer debt) and `day_entries` (company cash flow) are immutable append-only ledgers.
6. **Derived Balances** — Customer balances are computed from `wallet_entries`. The `current_balance` on wallets is a cached optimization, kept in sync by triggers.

---

## 2. Entity Relationship Map

```text
auth.users (Supabase Auth — Google Sign-In)
 └── user_profiles (auto-created on signup)
      └── tenant_members (user ↔ tenant, role: owner/manager)

tenants (Canteen / Business)
 ├── tenant_invites (6-digit join codes for managers)
 ├── shifts (Breakfast / Lunch / Dinner time windows)
 ├── meal_configs (per-shift meal rates)
 ├── staff_members (counter workers with PIN auth)
 │     ├── staff_wallets (salary account header)
 │     ├── staff_attendance (per day/shift)
 │     └── salary_payouts ──► auto-creates day_entry (salary_outflow)
 ├── customers
 │     └── customer_wallets (debt account header)
 │           └── wallet_entries (meal_charge / payment / adjustment)
 │                 ▲
 │                 └── meal_attendance (triggers wallet_entry)
 ├── vendors (suppliers — markets, rice dealers, etc.)
 │     └── vendor_wallets (what the canteen owes)
 │           └── vendor_wallet_entries (purchase / payment / adjustment)
 └── business_days (operational container)
       ├── meal_attendance
       ├── staff_attendance
       ├── day_entries (market_cost / canteen_expense / customer_payment / salary_outflow / vendor_payment / misc_earn)
       └── day_notes (market_list / general_note / issue)
```

---

## 3. Table Specifications

### 3.1 Identity & Access

#### `user_profiles`

Auto-created when a user signs up via Google. One-to-one with `auth.users`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, FK → `auth.users(id)` ON DELETE CASCADE | Same as Supabase auth user ID |
| `full_name` | TEXT | NOT NULL | From Google profile |
| `avatar_url` | TEXT | | Google profile photo |
| `is_superadmin` | BOOLEAN | NOT NULL DEFAULT false | Platform admin flag |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Trigger**: `on_auth_user_created` — auto-inserts profile from `raw_user_meta_data`.

---

#### `tenants`

Root entity representing a canteen/business.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `name` | TEXT | NOT NULL | Canteen display name |
| `status` | TEXT | NOT NULL DEFAULT 'active', CHECK IN ('active', 'suspended') | |
| `subscription_tier` | TEXT | NOT NULL DEFAULT 'free', CHECK IN ('free', 'pro', 'business') | Freemium tier — see [tier_and_roles.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/tier_and_roles.md) |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

> **Removed from legacy**: `slug`, `parent_id`, separate `tenant_settings`, `tenant_billing`, `tenant_roles` tables.

---

#### `tenant_members`

Maps authenticated users (owners/managers) to canteens. A user can belong to multiple tenants.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `user_id` | UUID | NOT NULL, FK → `auth.users(id)` ON DELETE CASCADE | |
| `role` | TEXT | NOT NULL, CHECK IN ('owner', 'manager') | Flat role — no RBAC table |
| `joined_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| **UNIQUE** | | `(tenant_id, user_id)` | One membership per tenant per user |

**Indexes**: `tenant_id`, `user_id`

---

#### `tenant_invites`

6-digit join codes for inviting managers. Single-use, 24-hour expiry.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `code` | TEXT | NOT NULL, UNIQUE | 6-digit numeric code |
| `role` | TEXT | NOT NULL DEFAULT 'manager', CHECK IN ('manager') | Role to assign on join |
| `created_by` | UUID | NOT NULL, FK → `auth.users(id)` | Owner who generated the code |
| `expires_at` | TIMESTAMPTZ | NOT NULL | 24 hours from creation |
| `used_by` | UUID | FK → `auth.users(id)` | NULL until redeemed |
| `used_at` | TIMESTAMPTZ | | NULL until redeemed |

---

### 3.2 Staff & Payroll

#### `staff_members`

Counter workers who operate via PIN. They do NOT need a Google account or `auth.users` entry.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `full_name` | TEXT | NOT NULL | Display name |
| `role` | TEXT | NOT NULL | Free-text role: `cashier`, `cook`, `manager`, etc. |
| `phone` | TEXT | NOT NULL | Contact number |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | Soft delete |
| `allow_terminal_login` | BOOLEAN | NOT NULL DEFAULT false | Can this staff use counter mode PIN? |
| `hashed_pin` | TEXT | | bcrypt-hashed 4-digit PIN |
| `temp_pin` | TEXT | | Temporary setup PIN (cleared after first real PIN set) |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| **UNIQUE** | | `(tenant_id, phone)` | No duplicate phones per canteen |

**Indexes**: `tenant_id`

---

#### `staff_wallets`

Staff salary account header. One-to-one with `staff_members`. Auto-created by trigger.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `staff_id` | UUID | NOT NULL UNIQUE, FK → `staff_members(id)` ON DELETE CASCADE | |
| `current_balance` | NUMERIC(12,2) | NOT NULL DEFAULT 0 | Cached balance |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

---

#### `staff_attendance`

Staff work tracking per business day/shift.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `staff_id` | UUID | NOT NULL, FK → `staff_members(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `shift_id` | UUID | FK → `shifts(id)` ON DELETE SET NULL | |
| `status` | TEXT | NOT NULL, CHECK IN ('present', 'absent', 'half_day') | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `staff_id`, `business_day_id`

---

#### `salary_payouts`

Staff salary payment records. Creating a payout should also create a `day_entry` (outflow, salary_outflow).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `staff_id` | UUID | NOT NULL, FK → `staff_members(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `amount` | NUMERIC(12,2) | NOT NULL, CHECK (amount > 0) | |
| `payment_mode` | TEXT | NOT NULL DEFAULT 'cash', CHECK IN ('cash', 'bank', 'mobile_money') | |
| `notes` | TEXT | | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `staff_id`, `business_day_id`

---

### 3.3 Customers & Wallet Ledger

#### `customers`

Customer profiles — the diners who eat on credit.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `name` | TEXT | NOT NULL | Display name |
| `phone` | TEXT | NOT NULL | Contact number (required — needed for SMS reminders, see [sms_service.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/sms_service.md)) |
| `address` | TEXT | | Optional |
| `institution` | TEXT | | Factory, hostel, company, etc. |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`

---

#### `customer_wallets`

Customer debt account header. One-to-one with `customers`. Auto-created by trigger.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `customer_id` | UUID | NOT NULL UNIQUE, FK → `customers(id)` ON DELETE CASCADE | |
| `current_balance` | NUMERIC(12,2) | NOT NULL DEFAULT 0 | Cached balance (positive = customer owes) |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`
**Trigger**: Auto-created when a customer is inserted.

---

#### `wallet_entries`

Immutable append-only ledger for customer debt tracking.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `wallet_id` | UUID | NOT NULL, FK → `customer_wallets(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `shift_id` | UUID | FK → `shifts(id)` ON DELETE SET NULL | |
| `type` | TEXT | NOT NULL, CHECK IN ('meal_charge', 'payment', 'adjustment') | |
| `amount` | NUMERIC(12,2) | NOT NULL | Positive for charges, positive for payments |
| `reference_type` | TEXT | CHECK IN ('meal_attendance', 'cash_collection', 'manual_adjustment') | |
| `reference_id` | UUID | | FK to source record |
| `recorded_by_staff_id` | UUID | FK → `staff_members(id)` ON DELETE SET NULL | Staff who recorded this entry |
| `notes` | TEXT | | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `wallet_id`, `business_day_id`

**Balance rule**:
- `meal_charge` → increases debt (customer owes more)
- `payment` → decreases debt (customer paid)
- `adjustment` → can go either way (manual correction)

---

### 3.4 Shifts & Meals

#### `shifts`

Operating time windows within a day. Auto-seeded with defaults (Breakfast, Lunch, Dinner).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `name` | TEXT | NOT NULL | Breakfast, Lunch, Dinner |
| `start_time` | TIME | NOT NULL | |
| `end_time` | TIME | NOT NULL | |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`
**Trigger**: Auto-seeded when a tenant is created.

---

#### `meal_configs`

Per-shift meal rate. Supports rate changes over time via `effective_from`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `shift_id` | UUID | FK → `shifts(id)` ON DELETE SET NULL | Which meal (Breakfast/Lunch/Dinner) |
| `rate` | NUMERIC(10,2) | NOT NULL, CHECK (rate >= 0) | Price per meal |
| `effective_from` | DATE | NOT NULL DEFAULT current_date | When this rate starts |
| `note` | TEXT | | Description |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `shift_id`

---

#### `meal_attendance`

Record of a customer consuming a meal. Triggers a `wallet_entry` (meal_charge).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `customer_id` | UUID | NOT NULL, FK → `customers(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `shift_id` | UUID | FK → `shifts(id)` ON DELETE SET NULL | |
| `charge_amount` | NUMERIC(10,2) | NOT NULL DEFAULT 0 | Resolved from meal_configs at time of recording |
| `recorded_by_staff_id` | UUID | FK → `staff_members(id)` ON DELETE SET NULL | Staff who toggled this meal |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `customer_id`, `business_day_id`

---

### 3.5 Business Day & Cashbook

#### `business_days`

Operational container. Only one open day per tenant at a time.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `business_date` | DATE | NOT NULL | |
| `status` | TEXT | NOT NULL, CHECK IN ('open', 'closed') | |
| `opening_cash` | NUMERIC(12,2) | NOT NULL DEFAULT 0 | Cash in drawer at start |
| `closing_cash` | NUMERIC(12,2) | | Set on close |
| `expected_cash` | NUMERIC(12,2) | | Calculated at close |
| `variance` | NUMERIC(12,2) | | `closing_cash - expected_cash` |
| `opened_by_staff_id` | UUID | FK → `staff_members(id)` | Staff who opened (counter mode) |
| `opened_by_user_id` | UUID | FK → `auth.users(id)` | User who opened (owner/manager direct) |
| `closed_by_staff_id` | UUID | FK → `staff_members(id)` | |
| `closed_by_user_id` | UUID | FK → `auth.users(id)` | |
| `opened_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `closed_at` | TIMESTAMPTZ | | |
| `notes` | TEXT | | End-of-day notes |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Unique constraint**: Only one `status = 'open'` per `tenant_id` (partial unique index).
**Indexes**: `tenant_id`, `business_date`

---

#### `day_entries`

Company cashbook ledger. Every cash movement during a business day.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `shift_id` | UUID | FK → `shifts(id)` ON DELETE SET NULL | |
| `entry_type` | TEXT | NOT NULL, CHECK IN ('inflow', 'outflow') | |
| `category` | TEXT | NOT NULL, CHECK IN ('customer_payment', 'market_cost', 'canteen_expense', 'salary_outflow', 'vendor_payment', 'misc_earn') | |
| `amount` | NUMERIC(12,2) | NOT NULL, CHECK (amount > 0) | Always positive |
| `reference_type` | TEXT | CHECK IN ('wallet_entry', 'salary_payout', 'vendor_wallet_entry', 'direct_expense', 'direct_income') | |
| `reference_id` | UUID | | FK to source record |
| `notes` | TEXT | | |
| `created_by_staff_id` | UUID | FK → `staff_members(id)` ON DELETE SET NULL | |
| `created_by_user_id` | UUID | FK → `auth.users(id)` ON DELETE SET NULL | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `business_day_id`, `category`

---

#### `day_notes`

Simple operational notes and daily market/shopping lists.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `note_type` | TEXT | NOT NULL, CHECK IN ('market_list', 'general_note', 'issue') | |
| `content` | TEXT | NOT NULL | |
| `created_by_staff_id` | UUID | FK → `staff_members(id)` ON DELETE SET NULL | |
| `created_by_user_id` | UUID | FK → `auth.users(id)` ON DELETE SET NULL | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `business_day_id`

### 3.6 Vendors & Supplier Ledger

#### `vendors`

Supplier/vendor profiles — the people the canteen buys from (market, rice dealer, etc.).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `name` | TEXT | NOT NULL | Vendor display name |
| `phone` | TEXT | | Contact (optional) |
| `address` | TEXT | | Optional |
| `notes` | TEXT | | What they supply, payment terms, etc. |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`

---

#### `vendor_wallets`

Vendor debt account header. One-to-one with `vendors`. Auto-created by trigger. Balance represents **how much the canteen owes the vendor** (reversed from customer wallets).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `vendor_id` | UUID | NOT NULL UNIQUE, FK → `vendors(id)` ON DELETE CASCADE | |
| `current_balance` | NUMERIC(12,2) | NOT NULL DEFAULT 0 | Cached balance (positive = canteen owes vendor) |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`
**Trigger**: Auto-created when a vendor is inserted.

---

#### `vendor_wallet_entries`

Immutable append-only ledger for vendor debt tracking.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `vendor_wallet_id` | UUID | NOT NULL, FK → `vendor_wallets(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `type` | TEXT | NOT NULL, CHECK IN ('purchase', 'payment', 'adjustment') | |
| `amount` | NUMERIC(12,2) | NOT NULL | Always positive |
| `reference_type` | TEXT | CHECK IN ('market_expense', 'cash_payment', 'manual_adjustment') | |
| `reference_id` | UUID | | FK to source record (e.g., day_entry) |
| `recorded_by_staff_id` | UUID | FK → `staff_members(id)` ON DELETE SET NULL | |
| `recorded_by_user_id` | UUID | FK → `auth.users(id)` ON DELETE SET NULL | |
| `notes` | TEXT | | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `vendor_wallet_id`, `business_day_id`

**Balance rule**:
- `purchase` → increases debt (canteen owes vendor more)
- `payment` → decreases debt (canteen paid vendor)
- `adjustment` → can go either way (manual correction)

---

## 4. Security & RLS

### 4.1 Helper Functions

```sql
-- Check if current user is a member of a tenant
is_tenant_member(p_tenant_id UUID) → BOOLEAN
  SELECT 1 FROM tenant_members
  WHERE tenant_id = p_tenant_id AND user_id = auth.uid()

-- Check if current user is the owner of a tenant
is_tenant_owner(p_tenant_id UUID) → BOOLEAN
  SELECT 1 FROM tenant_members
  WHERE tenant_id = p_tenant_id AND user_id = auth.uid() AND role = 'owner'

-- Check if current user is a superadmin
is_superadmin() → BOOLEAN
  SELECT 1 FROM user_profiles WHERE id = auth.uid() AND is_superadmin = true
```

### 4.2 RLS Policy Pattern

All tenant-scoped tables use the same RLS pattern:

```sql
-- Read: any tenant member can view
CREATE POLICY "tenant_read" ON <table>
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM tenant_members WHERE user_id = auth.uid())
  );

-- Write: any tenant member can insert/update/delete
-- (Specific owner-only restrictions are enforced at the RPC level, not RLS)
CREATE POLICY "tenant_write" ON <table>
  FOR ALL USING (
    tenant_id IN (SELECT tenant_id FROM tenant_members WHERE user_id = auth.uid())
  );
```

### 4.3 Table-Level RLS Summary

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `user_profiles` | All authenticated users | Own profile only |
| `tenants` | Tenant members | Superadmin only (creation via RPC) |
| `tenant_members` | Tenant members | Owner only (via RPC) |
| `tenant_invites` | Owner only | Owner only (via RPC) |
| `staff_members` | Tenant members | Owner / Manager (via RPC) |
| `customers` | Tenant members | Tenant members |
| `customer_wallets` | Tenant members | Tenant members (auto-created) |
| `wallet_entries` | Tenant members | Tenant members (via RPC) |
| `shifts` | Tenant members | Owner / Manager |
| `meal_configs` | Tenant members | Owner / Manager |
| `meal_attendance` | Tenant members | Tenant members (via RPC) |
| `business_days` | Tenant members | Tenant members (via RPC) |
| `day_entries` | Tenant members | Tenant members (via RPC) |
| `day_notes` | Tenant members | Tenant members |
| `staff_attendance` | Tenant members | Tenant members |
| `salary_payouts` | Tenant members | Owner / Manager (via RPC) |
| `staff_wallets` | Tenant members | Tenant members (auto-created) |
| `vendors` | Tenant members | Tenant members |
| `vendor_wallets` | Tenant members | Tenant members (auto-created) |
| `vendor_wallet_entries` | Tenant members | Tenant members (via RPC) |

---

## 5. RPC Functions

### 5.1 Auth & Tenant Management

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `create_tenant` | `p_name TEXT` | `UUID` | Self-service canteen creation. Creates tenant + tenant_member (owner) + default shifts. |
| `generate_invite_code` | `p_tenant_id UUID, p_role TEXT DEFAULT 'manager'` | `TEXT` | Owner generates 6-digit code valid 24 hours. |
| `join_tenant_by_code` | `p_code TEXT` | `JSON` | Manager joins canteen. Validates code, checks expiry, creates tenant_member. Returns tenant info. |

### 5.2 Staff PIN

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `verify_staff_pin` | `p_tenant_id UUID, p_pin TEXT` | `JSONB` | Loops active staff, checks temp_pin then hashed_pin. Returns staff info or error. |
| `set_staff_pin` | `p_staff_id UUID, p_temp_pin TEXT, p_new_pin TEXT` | `BOOLEAN` | Staff converts temp PIN to private bcrypt PIN. |
| `reset_staff_pin` | `p_staff_id UUID` | `TEXT` | Owner/Manager generates new temp PIN for a staff member. |

### 5.3 Business Day Operations

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `start_business_day` | `p_tenant_id UUID, p_staff_id UUID (nullable), p_opening_cash NUMERIC` | `UUID` | Opens a new business day. Auth via `auth.uid()`. |
| `end_business_day` | `p_tenant_id UUID, p_day_id UUID, p_staff_id UUID (nullable), p_closing_cash NUMERIC, p_notes TEXT` | `TABLE(expected, variance, status)` | Closes day. Calculates expected cash from `day_entries`. |
| `resume_business_day` | `p_tenant_id UUID, p_day_id UUID, p_staff_id UUID (nullable)` | `VOID` | Reopens a same-day closed day. |
| `get_active_business_day` | `p_tenant_id UUID` | `UUID` | Returns the currently open day ID, or NULL. |
| `get_current_shift` | `p_tenant_id UUID` | `UUID` | Auto-resolves shift from current time. |
| `calculate_expected_cash` | `p_day_id UUID` | `NUMERIC` | `opening_cash + SUM(inflows) - SUM(outflows)` from `day_entries`. |

### 5.4 Meal & Wallet Operations

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `record_meal_attendance` | `p_tenant_id UUID, p_customer_id UUID, p_staff_id UUID (nullable)` | `JSONB` | Toggles meal attendance for current shift. Auto-resolves day/shift. Creates `meal_attendance` + `wallet_entry` (meal_charge). Returns action taken + new balance. |
| `record_baki_payment` | `p_tenant_id UUID, p_customer_id UUID, p_amount NUMERIC, p_staff_id UUID (nullable), p_notes TEXT` | `NUMERIC` | Customer pays cash. Creates `wallet_entry` (payment) + `day_entry` (inflow, customer_payment). Returns updated balance. |
| `get_customer_balance` | `p_tenant_id UUID, p_customer_id UUID` | `NUMERIC` | Computed from `SUM(meal_charge) - SUM(payment) ± SUM(adjustment)` on `wallet_entries`. |
| `get_customer_statement` | `p_tenant_id UUID, p_customer_id UUID, p_start DATE, p_end DATE` | `TABLE(...)` | Full chronological history of charges, payments, and adjustments. |

### 5.5 Cashbook Operations

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `record_expense` | `p_tenant_id UUID, p_category TEXT, p_amount NUMERIC, p_vendor_id UUID (nullable), p_staff_id UUID (nullable), p_notes TEXT` | `UUID` | Creates `day_entry` (outflow). Categories: `market_cost`, `canteen_expense`. If `p_vendor_id` is provided, also creates `vendor_wallet_entry` (purchase) to track vendor baki. |
| `record_misc_income` | `p_tenant_id UUID, p_amount NUMERIC, p_staff_id UUID (nullable), p_notes TEXT` | `UUID` | Creates `day_entry` (inflow, misc_earn). |
| `record_salary_payout` | `p_tenant_id UUID, p_staff_id UUID, p_amount NUMERIC, p_payment_mode TEXT, p_notes TEXT` | `UUID` | Creates `salary_payout` + linked `day_entry` (outflow, salary_outflow). |

### 5.6 Vendor Operations

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `record_vendor_payment` | `p_tenant_id UUID, p_vendor_id UUID, p_amount NUMERIC, p_staff_id UUID (nullable), p_notes TEXT` | `NUMERIC` | Canteen pays vendor. Creates `vendor_wallet_entry` (payment) + `day_entry` (outflow, vendor_payment). Returns updated vendor balance. |
| `get_vendor_balance` | `p_tenant_id UUID, p_vendor_id UUID` | `NUMERIC` | Computed from `SUM(purchase) - SUM(payment) ± SUM(adjustment)` on `vendor_wallet_entries`. |
| `get_vendor_statement` | `p_tenant_id UUID, p_vendor_id UUID, p_start DATE, p_end DATE` | `TABLE(...)` | Full chronological history of purchases, payments, and adjustments. |

### 5.7 Reporting

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `get_financial_summary` | `p_tenant_id UUID, p_start_date DATE, p_end_date DATE` | `TABLE(total_meal_billed, total_customer_payments, total_market_cost, total_canteen_expenses, total_salary_outflow, total_vendor_payments, net_cash_flow, net_profit_loss)` | Aggregated financial report from all ledgers (customer, vendor, cashbook). |

---

## 6. Triggers & Automation

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `on_auth_user_created` | `auth.users` | AFTER INSERT | Auto-create `user_profiles` from Google metadata |
| `auto_create_customer_wallet` | `customers` | AFTER INSERT | Auto-create `customer_wallets` row |
| `auto_create_staff_wallet` | `staff_members` | AFTER INSERT | Auto-create `staff_wallets` row |
| `auto_create_vendor_wallet` | `vendors` | AFTER INSERT | Auto-create `vendor_wallets` row |
| `auto_seed_default_shifts` | `tenants` | AFTER INSERT | Seed Breakfast (6:00–9:00), Lunch (12:00–15:00), Dinner (19:00–22:00) |
| `update_wallet_balance` | `wallet_entries` | AFTER INSERT | Update `customer_wallets.current_balance` |
| `update_vendor_wallet_balance` | `vendor_wallet_entries` | AFTER INSERT | Update `vendor_wallets.current_balance` |
| `enforce_closed_day_lock` | `wallet_entries`, `day_entries`, `meal_attendance`, `vendor_wallet_entries` | BEFORE INSERT/UPDATE/DELETE | Prevent modifications to records tied to a closed business day |
| `set_updated_at` | Various | BEFORE UPDATE | Auto-set `updated_at = now()` |

---

## 7. Ledger Workflows

### Flow A: Customer Eats a Meal (meal_charge)

```
1. Staff taps customer → calls record_meal_attendance(tenant, customer, staff)
2. RPC resolves active business_day + current shift
3. RPC resolves charge_amount from meal_configs (latest rate for this shift)
4. INSERT into meal_attendance
5. INSERT into wallet_entries (type='meal_charge', amount=charge_amount)
6. Trigger updates customer_wallets.current_balance += charge_amount
7. Customer now owes more
```

### Flow B: Customer Pays Cash (baki_payment)

```
1. Staff records payment → calls record_baki_payment(tenant, customer, amount, staff)
2. RPC resolves active business_day + current shift
3. INSERT into wallet_entries (type='payment', amount=X)
4. INSERT into day_entries (entry_type='inflow', category='customer_payment', amount=X)
5. Trigger updates customer_wallets.current_balance -= X
6. Customer debt decreases, cash drawer increases
```

### Flow C: Market Purchase (expense — cash paid)

```
1. Staff records expense → calls record_expense(tenant, 'market_cost', amount, vendor_id, staff, notes)
2. RPC resolves active business_day + current shift
3. INSERT into day_entries (entry_type='outflow', category='market_cost', amount=Y)
4. If vendor_id provided AND paid in cash:
   → Cash drawer decreases (day_entry handles this)
   → No vendor_wallet_entry needed (paid immediately)
5. Cash drawer decreases
```

### Flow C2: Market Purchase (vendor baki — pay later)

```
1. Staff records expense with vendor baki → calls record_expense(tenant, 'market_cost', amount, vendor_id, staff, notes)
2. RPC resolves active business_day + current shift
3. INSERT into vendor_wallet_entries (type='purchase', amount=Y)
4. Trigger updates vendor_wallets.current_balance += Y
5. NOTE: No day_entry created yet — cash hasn't left the drawer
6. Vendor baki increases, cash drawer unchanged
```

### Flow C3: Pay Vendor (settle baki)

```
1. Owner/Manager pays vendor → calls record_vendor_payment(tenant, vendor_id, amount, staff, notes)
2. RPC resolves active business_day
3. INSERT into vendor_wallet_entries (type='payment', amount=X)
4. INSERT into day_entries (entry_type='outflow', category='vendor_payment', amount=X)
5. Trigger updates vendor_wallets.current_balance -= X
6. Vendor baki decreases, cash drawer decreases
```

### Flow D: Salary Payout

```
1. Manager records salary → calls record_salary_payout(tenant, staff, amount, mode, notes)
2. INSERT into salary_payouts
3. INSERT into day_entries (entry_type='outflow', category='salary_outflow', amount=Z)
4. Cash drawer decreases
```

### Flow E: Day Close & Reconciliation

```
1. Owner/Manager calls end_business_day(tenant, day_id, staff, closing_cash)
2. RPC calls calculate_expected_cash(day_id):
   expected = opening_cash + SUM(day_entries.inflow) - SUM(day_entries.outflow)
3. variance = closing_cash - expected_cash
4. UPDATE business_days SET status='closed', closing_cash, expected_cash, variance
5. Owner sees: "Expected ৳5,000. Actual ৳4,800. Shortage: ৳200."
```

---

## 8. Complete Table Count

| # | Table | Category |
|---|---|---|
| 1 | `user_profiles` | Identity |
| 2 | `tenants` | Identity |
| 3 | `tenant_members` | Identity |
| 4 | `tenant_invites` | Identity |
| 5 | `staff_members` | Staff |
| 6 | `staff_wallets` | Staff |
| 7 | `staff_attendance` | Staff |
| 8 | `salary_payouts` | Staff |
| 9 | `customers` | Customers |
| 10 | `customer_wallets` | Customers |
| 11 | `wallet_entries` | Customers (Ledger) |
| 12 | `vendors` | Vendors |
| 13 | `vendor_wallets` | Vendors |
| 14 | `vendor_wallet_entries` | Vendors (Ledger) |
| 15 | `shifts` | Meals |
| 16 | `meal_configs` | Meals |
| 17 | `meal_attendance` | Meals |
| 18 | `business_days` | Cashbook |
| 19 | `day_entries` | Cashbook (Ledger) |
| 20 | `day_notes` | Cashbook |

**Total: 20 tables**
