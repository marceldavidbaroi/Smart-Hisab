# Feature: Bazar & Expenses (AP) — Schema

> Tables, triggers, and RLS for vendor profiles, supplier debt tracking, and daily cashbook entries.

---

## Entity Relationship

```text
tenants
 ├── vendors
 │     └── vendor_wallets     (one-to-one, auto-created by trigger)
 │           └── vendor_wallet_entries  (immutable ledger)
 │                 ▲ purchase  ← record_expense with vendor_id (pay-later)
 │                 ▲ payment   ← record_vendor_payment RPC
 │                 ▲ adjustment
 └── business_days
       └── day_entries  (company cashbook: all cash movements)
             - customer_payment (inflow)
             - market_cost      (outflow, cash paid)
             - canteen_expense  (outflow)
             - salary_outflow   (outflow)
             - vendor_payment   (outflow)
             - misc_earn        (inflow)
```

---

## Tables

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
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `vendor_wallet_id`, `business_day_id`

**Balance rule**:
- `purchase` → increases debt (canteen owes vendor more)
- `payment` → decreases debt (canteen paid vendor)
- `adjustment` → can go either way (manual correction)

---

### `day_entries`

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

## Ledger Flows

### Flow C: Market Purchase (cash, no vendor)
```
1. Staff records expense → calls record_expense(tenant, 'market_cost', amount, vendor_id=null, staff, notes)
2. RPC resolves active business_day
3. INSERT into day_entries (entry_type='outflow', category='market_cost')
4. Cash drawer decreases
```

### Flow C2: Market Purchase (vendor credit — recorded at time of purchase)
```
1. Staff records expense with vendor → calls record_expense(tenant, 'market_cost', amount, vendor_id, staff, notes)
2. INSERT into day_entries (entry_type='outflow', category='market_cost')  ← cash drawer decreases now
3. INSERT into vendor_wallet_entries (type='purchase')                       ← vendor baki also increases
4. Trigger updates vendor_wallets.current_balance += amount
```

> **Note**: There is no deferred/pay-later mode. Both the cash outflow and vendor baki are recorded at the same time.

### Flow C3: Pay Vendor (settle baki)
```
1. Owner/Manager pays vendor → calls record_vendor_payment(tenant, vendor_id, amount, staff, notes)
2. INSERT into vendor_wallet_entries (type='payment')
3. INSERT into day_entries (entry_type='outflow', category='vendor_payment')
4. Trigger updates vendor_wallets.current_balance -= amount
5. Vendor baki decreases, cash drawer decreases
```
