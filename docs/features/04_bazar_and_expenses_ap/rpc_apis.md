# Feature: Bazar & Expenses (AP) — RPC / APIs

> RPC functions for recording expenses, vendor payments, and querying vendor ledger.

---

## `record_expense`

Record a cash outflow — market cost or canteen expense.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_category TEXT`, `p_amount NUMERIC`, `p_vendor_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `UUID` (day_entry ID) |
| **Categories** | `market_cost`, `canteen_expense` |
| **Logic — cash purchase (no vendor)** | INSERT `day_entries` (outflow). Cash drawer decreases immediately. |
| **Logic — vendor credit purchase (`p_vendor_id` provided)** | INSERT `day_entries` (outflow) **AND** INSERT `vendor_wallet_entries` (purchase). Both are created. Cash drawer decreases AND vendor baki increases simultaneously. |

> [!IMPORTANT]
> When buying on vendor credit, `record_expense` still creates a `day_entries` outflow. There is currently **no separate "pay-later" mode** where cash stays in the drawer. If a future design requires tracking a purchase as pending cash-out, a new RPC or a `is_credit` flag on the call would be needed.

---

## `record_misc_income`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Record a miscellaneous cash inflow.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_amount NUMERIC`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `UUID` (day_entry ID) |
| **Side effects** | INSERT `day_entries` (inflow, category: `misc_earn`) |

---

## `record_vendor_payment`

Canteen pays vendor to settle baki.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID`, `p_amount NUMERIC`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `NUMERIC` (updated vendor balance) |
| **Side effects** | INSERT `vendor_wallet_entries` (payment) + INSERT `day_entries` (outflow, category: `vendor_payment`) |
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

