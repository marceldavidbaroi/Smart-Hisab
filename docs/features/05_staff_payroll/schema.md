# Feature: Staff & Payroll — Schema

> Tables, triggers, and RLS for staff profiles, PIN access, attendance, and salary payouts.

---

## Entity Relationship

```text
tenants
 └── staff_members
       ├── staff_wallets      (one-to-one, auto-created by trigger)
       ├── staff_attendance   (per business_day + shift)
       └── salary_payouts     ──► auto-creates day_entry (salary_outflow)
```

---

## Tables

### `staff_members`

Counter workers who operate via PIN. They do NOT need a Google account or `auth.users` entry.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `full_name` | TEXT | NOT NULL | Display name |
| `role` | TEXT | NOT NULL | Free-text: `cashier`, `cook`, `manager`, etc. |
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

### `staff_wallets`

Staff salary account header. One-to-one with `staff_members`. Auto-created by trigger.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `staff_id` | UUID | NOT NULL UNIQUE, FK → `staff_members(id)` ON DELETE CASCADE | |
| `current_balance` | NUMERIC(12,2) | NOT NULL DEFAULT 0 | Cached balance |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

---

### `staff_attendance`

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

### `salary_payouts`

Staff salary payment records. Creating a payout also creates a `day_entry` (outflow, `salary_outflow`).

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

## RLS Policies

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `staff_members` | Tenant members | Owner / Manager (via RPC) |
| `staff_wallets` | Tenant members | Tenant members (auto-created by trigger) |
| `staff_attendance` | Tenant members | Tenant members |
| `salary_payouts` | Tenant members | Owner / Manager (via RPC) |

---

## Triggers

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `auto_create_staff_wallet` | `staff_members` | AFTER INSERT | Auto-create `staff_wallets` row |
| `set_updated_at` | `staff_members` | BEFORE UPDATE | Auto-set `updated_at = now()` |

> [!NOTE]
> `staff_wallets.current_balance` is **not currently updated by any trigger**. Salary payouts are recorded in `salary_payouts` + `day_entries` but do not feed back into `staff_wallets`. If a running salary balance is needed, a trigger or RPC update should be added.

---

## Ledger Flow: Salary Payout

```
1. Manager records salary → calls record_salary_payout(tenant, staff, amount, mode, notes)
2. INSERT into salary_payouts
3. INSERT into day_entries (entry_type='outflow', category='salary_outflow', amount=Z)
4. Cash drawer decreases
```
