# Feature: Bazar & Expenses (AP) — Schema

> Tables, triggers, and RLS for vendor profiles, supplier debt tracking, and daily cashbook entries.

---

## Entity Relationship

```text
tenants
 ├── canteen_accounts   (tenant wallets: cash drawer, bKash, bank, safe)
 ├── vendors
 │     └── vendor_wallets     (one-to-one, auto-created by trigger)
 │           └── vendor_wallet_entries  (immutable ledger)
 │                 ▲ purchase  ← record_expense with vendor_id (pay-later)
 │                 ▲ payment   ← record_vendor_payment RPC
 │                 ▲ adjustment
 └── business_days
       └── day_entries  (company cashbook: linked to canteen_account_id)
             - customer_payment (inflow)
             - market_cost      (outflow, paid from account)
             - canteen_expense  (outflow)
             - salary_outflow   (outflow)
             - vendor_payment   (outflow)
             - account_transfer (inflow/outflow between accounts)
             - misc_earn        (inflow)
```

---

## Tables

### `canteen_accounts`

Tenant payment channels & money accounts (Canteen Wallets).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `name` | TEXT | NOT NULL | Display name (e.g., 'Cash Drawer', 'bKash Merchant', 'Bank Account', 'Petty Cash Safe') |
| `account_type` | TEXT | NOT NULL, CHECK IN ('cash_drawer', 'mobile_money', 'bank', 'safe', 'other') | Categorization |
| `current_balance` | NUMERIC(12,2) | NOT NULL DEFAULT 0 | Real-time liquid balance |
| `is_default_drawer` | BOOLEAN | NOT NULL DEFAULT false | True for the counter drawer linked to active shift |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`

---

### `vendors`

Supplier profiles — the people the canteen buys from (market, rice dealer, etc.).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `name` | TEXT | NOT NULL | Vendor display name |
| `phone` | TEXT | | Contact (optional) |
| `address` | TEXT | | Optional |
| `notes` | TEXT | | What they supply, payment terms |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`

---

### `vendor_wallets`

Vendor debt account. One-to-one with `vendors`. Auto-created by trigger.

> **Balance direction**: Positive = canteen owes vendor (reversed from customer wallets).

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

### `vendor_wallet_entries`

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
| `metadata` | JSONB | NOT NULL DEFAULT '{}'::jsonb | Audit metadata (status, void_info, reason) |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `vendor_wallet_id`, `business_day_id`, `(metadata->>'status')`

**Balance rule**:
- `purchase` → increases debt (canteen owes vendor more)
- `payment` → decreases debt (canteen paid vendor)
- `adjustment` → can go either way (manual correction)

---

### `day_entries`

Company cashbook ledger. Every cash movement during a business day linked to a specific canteen account/wallet.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `business_day_id` | UUID | FK → `business_days(id)` ON DELETE SET NULL | |
| `shift_id` | UUID | FK → `shifts(id)` ON DELETE SET NULL | |
| `canteen_account_id` | UUID | FK → `canteen_accounts(id)` ON DELETE SET NULL | Payment account (Cash Drawer, bKash, Bank, Safe) |
| `entry_type` | TEXT | NOT NULL, CHECK IN ('inflow', 'outflow') | |
| `category` | TEXT | NOT NULL, CHECK IN ('customer_payment', 'market_cost', 'canteen_expense', 'salary_outflow', 'vendor_payment', 'account_transfer', 'misc_earn') | |
| `amount` | NUMERIC(12,2) | NOT NULL, CHECK (amount > 0) | Always positive |
| `reference_type` | TEXT | CHECK IN ('wallet_entry', 'salary_payout', 'vendor_wallet_entry', 'direct_expense', 'direct_income', 'account_transfer') | |
| `reference_id` | UUID | | FK to source record |
| `notes` | TEXT | | |
| `metadata` | JSONB | NOT NULL DEFAULT '{}'::jsonb | Audit metadata (status, void_info, reason) |
| `created_by_staff_id` | UUID | FK → `staff_members(id)` ON DELETE SET NULL | |
| `created_by_user_id` | UUID | FK → `auth.users(id)` ON DELETE SET NULL | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `business_day_id`, `canteen_account_id`, `category`, `(metadata->>'status')`


---

### `day_notes`

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

---

## RLS Policies

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `vendors` | Tenant members | Tenant members |
| `vendor_wallets` | Tenant members | Tenant members (auto-created by trigger) |
| `vendor_wallet_entries` | Tenant members | Tenant members (via RPC) |
| `day_entries` | Tenant members | Tenant members (via RPC) |
| `day_notes` | Tenant members | Tenant members |

---

## Triggers

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `auto_create_vendor_wallet` | `vendors` | AFTER INSERT | Auto-create `vendor_wallets` row |
| `update_vendor_wallet_balance` | `vendor_wallet_entries` | AFTER INSERT | Update `vendor_wallets.current_balance` |
| `enforce_closed_day_lock` | `vendor_wallet_entries`, `day_entries` | BEFORE INSERT/UPDATE/DELETE | Prevent modifications tied to a closed business day |

---

## Ledger Flows (Bangladeshi Canteen Model)

### Flow C: Daily Cash Market Purchase (নগদ বাজার খরচ - e.g. শাক-সবজি, মাছ, ভ্যান ভাড়া)
```text
1. Staff records cash expense → calls record_expense_v2(tenant_id, category, amount, account_id, vendor_id=null, staff_id, notes, payment_mode='cash')
2. RPC inserts into day_entries (entry_type='outflow') and canteen_account_entries (outflow from selected Cash Drawer / bKash / Bank).
3. Physical cash in drawer decreases immediately.
4. Vendor debts remain 0.
```

### Flow C2: Wholesaler Credit Purchase (মহাজন থেকে বাকিতে মাল - e.g. চাল, তেল, মুরগি, এলপিজি গ্যাস)
```text
1. Staff records credit purchase → calls record_expense_v2(tenant_id, category, amount, account_id=null, vendor_id, staff_id, notes, payment_mode='baki')
2. RPC inserts into vendor_wallet_entries (type='purchase').
3. Trigger updates vendor_wallets.current_balance += amount (Canteen debt increases).
4. Physical cash drawer remains 100% UNTOUCHED (৳0 deduction today).
```

### Flow C3: Pay Wholesaler / Settle Baki (মহাজনের বাকি পরিশোধ)
```text
1. Owner/Manager pays vendor → calls record_vendor_payment_v2(tenant_id, vendor_id, amount, account_id, staff_id, notes)
2. RPC inserts into vendor_wallet_entries (type='payment') → Trigger updates vendor_wallets.current_balance -= amount.
3. RPC inserts into day_entries (entry_type='outflow', category='vendor_payment') and canteen_account_entries (outflow from chosen wallet: Cash Drawer / bKash / Bank).
4. Vendor debt decreases, and selected payment account balance decreases.
```
