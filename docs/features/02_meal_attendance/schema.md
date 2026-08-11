# Feature: Meal Attendance — Schema

> Tables, triggers, and RLS for meal shift configuration and customer meal recording.

---

## Entity Relationship

```text
tenants
 ├── shifts              (Breakfast / Lunch / Dinner windows)
 │     └── meal_configs  (per-shift rate, supports rate history via effective_from)
 └── customers
       └── meal_attendance  (one row per customer-per-shift consumed)
             └── triggers → wallet_entries (meal_charge)
```

---

## Tables

### `shifts`

Operating time windows within a day. Auto-seeded with defaults when a tenant is created.

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
**Trigger**: Auto-seeded when a tenant is created (Breakfast 6–9, Lunch 12–15, Dinner 19–22).

---

### `meal_configs`

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

### `meal_attendance`

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

## RLS Policies

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `shifts` | Tenant members | Owner / Manager |
| `meal_configs` | Tenant members | Owner / Manager |
| `meal_attendance` | Tenant members | Tenant members (via RPC) |

---

## Triggers

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `enforce_closed_day_lock` | `meal_attendance` | BEFORE INSERT/UPDATE/DELETE | Prevent modifications tied to a closed business day |

---

## Ledger Flow: Customer Eats a Meal

```
1. Staff taps customer → calls record_meal_attendance(tenant, customer, staff)
2. RPC resolves active business_day + current shift
3. RPC resolves charge_amount from meal_configs (latest rate for this shift)
4. INSERT into meal_attendance
5. INSERT into wallet_entries (type='meal_charge', amount=charge_amount)
6. Trigger updates customer_wallets.current_balance += charge_amount
7. Customer now owes more
```
