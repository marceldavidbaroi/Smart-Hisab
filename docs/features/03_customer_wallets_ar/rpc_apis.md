# Feature: Customer Wallets (AR) — RPC / APIs

> RPC functions for baki payment collection, balance queries, and customer ledger.

---

## `record_baki_payment`

Customer pays cash to reduce their baki debt.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID`, `p_amount NUMERIC`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `NUMERIC` (updated wallet balance) |
| **Side effects** | INSERT `wallet_entries` (type: `payment`) + INSERT `day_entries` (inflow, category: `customer_payment`) |
| **Trigger** | `update_wallet_balance` updates `customer_wallets.current_balance` |

---

## `get_customer_balance`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Computed balance from the wallet ledger (not cached field).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID` |
| **Returns** | `NUMERIC` |
| **Logic** | `SUM(meal_charge) - SUM(payment) ± SUM(adjustment)` from `wallet_entries` |

---

## `get_customer_statement`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Full chronological history of a customer's charges, payments, and adjustments.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID`, `p_start DATE`, `p_end DATE` |
| **Returns** | `TABLE(date, shift_name, type, amount, notes, recorded_by_staff_name, created_at)` |
| **Pagination** | Supports `p_limit INT`, `p_offset INT` for infinite scroll |
