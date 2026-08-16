# Feature: Meal Attendance — RPC / APIs

> RPC functions for shift resolution, meal toggling, and bulk attendance.

---

## `get_current_shift`

Auto-resolves the active shift from the current server timestamp.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID` |
| **Returns** | `UUID` (shift ID) or `NULL` if no active shift |
| **Logic** | Compares `now()::TIME` against `shifts.start_time` and `shifts.end_time` where `is_active = true` |

---

## `record_meal_attendance`

Toggles meal attendance for a customer in the current shift. This is the **core action** of the app — called every time a customer eats.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID`, `p_staff_id UUID (nullable)` |
| **Returns** | `JSONB` → `{ action: 'added' \| 'removed', new_balance: NUMERIC }` |
| **Logic** | 1. Resolves active `business_day_id` + `shift_id`<br>2. Resolves `charge_amount` from `meal_configs` (latest effective rate for shift)<br>3. If no existing attendance for this customer/day/shift → **INSERT** `meal_attendance` + **INSERT** `wallet_entry` (type: `meal_charge`) → returns `action: 'added'`<br>4. If attendance exists → **DELETE** `meal_attendance` row + **DELETE** matching `wallet_entries` row → returns `action: 'removed'` |
| **Side effects** | On mark: trigger `update_wallet_balance` fires (`AFTER INSERT OR DELETE ON wallet_entries`) and increments `customer_wallets.current_balance`. On unmark: ledger entry deletion triggers `sync_customer_wallet_balance` which deducts the charge amount from `customer_wallets.current_balance`. |
| **Auth** | Tenant member or staff via PIN session |

---

## `bulk_record_meal_attendance`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.** Planned for v2.0 (Business tier).

Batch-marks all customers as present and creates meal entries. Used in Bulk Mode.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_shift_id UUID`, `p_business_day_id UUID`, `p_absent_customer_ids UUID[]`, `p_staff_id UUID (nullable)` |
| **Returns** | `JSONB` → `{ total_marked: INT, skipped: INT }` |
| **Logic** | Fetches all active customers. Excludes `p_absent_customer_ids`. Batch-inserts `meal_attendance` + `wallet_entries` for all remaining. |
