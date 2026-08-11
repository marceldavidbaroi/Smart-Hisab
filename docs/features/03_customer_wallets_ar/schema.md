# Feature: Customer Wallets (AR) — Schema

> Tables, triggers, and RLS for customer profiles, debt tracking, and baki ledger.

---

## Entity Relationship

```text
tenants
 └── customers
       └── customer_wallets  (one-to-one, auto-created by trigger)
             └── wallet_entries  (immutable append-only ledger)
                   ▲ meal_charge  ← meal_attendance trigger
                   ▲ payment      ← record_baki_payment RPC
                   ▲ adjustment   ← manual correction
```

---

## Tables

### `customers`

Customer profiles — the diners who eat on credit.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `name` | TEXT | NOT NULL | Display name |
| `phone` | TEXT | NOT NULL | Contact number (required for SMS reminders) |
| `address` | TEXT | | Optional |
| `institution` | TEXT | | Factory, hostel, company, etc. |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | Soft delete |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`

---

### `customer_wallets`

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

### `wallet_entries`

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

## RLS Policies

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `customers` | Tenant members | Tenant members |
| `customer_wallets` | Tenant members | Tenant members (auto-created by trigger) |
| `wallet_entries` | Tenant members | Tenant members (via RPC) |

---

## Triggers

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `auto_create_customer_wallet` | `customers` | AFTER INSERT | Auto-create `customer_wallets` row |
| `update_wallet_balance` | `wallet_entries` | AFTER INSERT | Update `customer_wallets.current_balance` |
| `enforce_closed_day_lock` | `wallet_entries` | BEFORE INSERT/UPDATE/DELETE | Prevent modifications tied to a closed business day |

---

## Ledger Flow: Customer Pays Cash (Baki Payment)

```
1. Staff records payment → calls record_baki_payment(tenant, customer, amount, staff)
2. RPC resolves active business_day + current shift
3. INSERT into wallet_entries (type='payment', amount=X)
4. INSERT into day_entries (entry_type='inflow', category='customer_payment', amount=X)
5. Trigger updates customer_wallets.current_balance -= X
6. Customer debt decreases, cash drawer increases
```
