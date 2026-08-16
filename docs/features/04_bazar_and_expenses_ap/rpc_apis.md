# Feature: Bazar & Expenses (AP) — RPC / APIs

> RPC functions for recording expenses, vendor payments, and querying vendor ledger.

---

## `record_expense`

Record an expense outflow or credit purchase across designated canteen accounts (wallets).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_category TEXT`, `p_amount NUMERIC`, `p_canteen_account_id UUID (nullable)`, `p_vendor_id UUID (nullable)`, `p_is_credit BOOLEAN DEFAULT false`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `UUID` (day_entry ID or vendor_wallet_entry ID) |
| **Categories** | `market_cost`, `canteen_expense` |
| **Logic — direct payment (Cash/bKash/Bank)** | INSERT `day_entries` (outflow) referencing `canteen_account_id`. The chosen canteen account balance decreases. If `canteen_account_id` is the active cash drawer, it updates shift cash balance. |
| **Logic — vendor credit purchase (`p_is_credit = true`)** | INSERT `vendor_wallet_entries` (purchase). Vendor baki increases. Canteen cash accounts and active shift drawer remain untouched until paid later. |

---

## `record_misc_income`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Record a miscellaneous cash inflow into a canteen account.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_amount NUMERIC`, `p_canteen_account_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `UUID` (day_entry ID) |
| **Side effects** | INSERT `day_entries` (inflow, category: `misc_earn`, links to `canteen_account_id`) |

---

## `record_vendor_payment`

Canteen pays vendor to settle baki from a selected canteen account (Cash Drawer, bKash, Bank, or Safe).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID`, `p_amount NUMERIC`, `p_canteen_account_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `NUMERIC` (updated vendor balance) |
| **Side effects** | INSERT `vendor_wallet_entries` (payment) + INSERT `day_entries` (outflow, category: `vendor_payment`, linked to `canteen_account_id`). |
| **Trigger** | `update_vendor_wallet_balance` updates `vendor_wallets.current_balance` |

---

## `get_vendor_balance`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Computed balance from the vendor ledger.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID` |
| **Returns** | `NUMERIC` |
| **Logic** | `SUM(purchase) - SUM(payment) ± SUM(adjustment)` from `vendor_wallet_entries` |

---

## `get_vendor_statement`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Full chronological transaction history for a vendor.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID`, `p_start DATE`, `p_end DATE` |
| **Returns** | `TABLE(date, type, amount, notes, recorded_by, created_at)` |
| **Pagination** | Supports `p_limit INT`, `p_offset INT` |

