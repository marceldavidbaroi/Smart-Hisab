# Feature: Shift & Day Reconciliation — Schema

> Tables, triggers, and RLS for business day lifecycle, cash drawer tracking, and end-of-day reconciliation.

---

## Entity Relationship

```text
tenants
 └── business_days  (operational container — one open day at a time)
       ├── meal_attendance
       ├── staff_attendance
       ├── wallet_entries
       ├── day_entries    (all cash movements for the day)
       └── day_notes
```

---

## Tables

### `business_days`

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
| `opened_by_user_id` | UUID | FK → `auth.users(id)` | User who opened (owner/manager) |
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

## RLS Policies

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `business_days` | Tenant members | Tenant members (via RPC) |

---

## Triggers

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `enforce_closed_day_lock` | `wallet_entries`, `day_entries`, `meal_attendance`, `vendor_wallet_entries` | BEFORE INSERT/UPDATE/DELETE | Prevent modifications tied to a closed business day |
| `set_updated_at` | `business_days` | BEFORE UPDATE | Auto-set `updated_at = now()` |

---

## Reconciliation Flow: Day Close

```
1. Owner/Manager calls end_business_day(tenant, day_id, staff, closing_cash)
2. RPC calls calculate_expected_cash(day_id):
   expected = opening_cash + SUM(day_entries.inflow) - SUM(day_entries.outflow)
3. variance = closing_cash - expected_cash
4. UPDATE business_days SET status='closed', closing_cash, expected_cash, variance
5. Owner sees: "Expected ৳5,000. Actual ৳4,800. Shortage: ৳200."
```
