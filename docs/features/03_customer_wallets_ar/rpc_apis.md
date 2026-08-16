# Feature: Customer Wallets (AR) — RPC / APIs

> RPC functions for baki payment collection, balance queries, and customer ledger.

---

## `create_or_reactivate_customer`

Atomically creates a new customer or reactivates a previously inactive customer profile with the same phone number.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_name TEXT`, `p_phone TEXT`, `p_address TEXT (nullable)`, `p_institution TEXT (nullable)` |
| **Returns** | `JSONB` → `{ success: true, is_reactivated: bool, customer: { id, tenant_id, name, phone, address, institution, is_active, current_balance } }` |
| **Logic** | 1. Checks if active customer with same phone exists; if so, raises exception.<br>2. If inactive record exists, updates `is_active = true`, updates name/address/institution, and keeps historical debt.<br>3. Otherwise inserts brand new customer.<br>4. Returns customer object with existing wallet `current_balance`. |
| **Auth** | Tenant member or staff |

---

## `record_baki_payment`

Customer pays baki debt into a designated canteen account (Cash Drawer, bKash, Bank).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID`, `p_amount NUMERIC`, `p_canteen_account_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `NUMERIC` (updated wallet balance) |
| **Side effects** | INSERT `wallet_entries` (type: `payment`) + INSERT `day_entries` (inflow, category: `customer_payment`, linked to `canteen_account_id`). Increases the balance of the designated canteen account. |
| **Trigger** | `update_wallet_balance` updates `customer_wallets.current_balance` |

---

## `get_customer_balance`

Computed balance from the wallet ledger (not cached field).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID` |
| **Returns** | `NUMERIC` |
| **Logic** | `SUM(meal_charge) - SUM(payment) ± SUM(adjustment)` from `wallet_entries` |

---

## `get_customer_statement`

Paginated chronological history of a customer's charges, payments, and adjustments. Used in the **Customer Detail Screen** ledger list and PDF export.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_customer_id UUID`, `p_start DATE (nullable)`, `p_end DATE (nullable)`, `p_limit INT DEFAULT 50`, `p_offset INT DEFAULT 0` |
| **Returns** | `JSONB` → `{ entries: [...], total_count: BIGINT, opening_balance: NUMERIC }` |
| **Pagination & Sorting** | Ordered by `created_at DESC`. Supports infinite scroll / pagination via `p_limit` and `p_offset`. Backed by composite index `(tenant_id, wallet_id, created_at DESC)`. |
| **Opening Balance** | When date filters `p_start` are applied, calculates net opening balance from transactions prior to `p_start`. |

---

## `void_wallet_entry`

Void/reverse a mistakenly added Baki entry or payment record without deleting ledger history.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_entry_id UUID`, `p_reason TEXT`, `p_staff_id UUID (nullable)` |
| **Returns** | `JSONB` (summary of original entry & created reversal entry) |
| **Logic** | 1. Verifies entry belongs to active/open `business_day`.<br>2. Updates `wallet_entries.metadata` of original entry (`status: "voided"`, `void_info: {...}`).<br>3. Inserts balancing `wallet_entries` row (`type: "adjustment"`, amount = `-original_amount`, `metadata->status: "reversal"`).<br>4. If original was cash `payment`, inserts compensating cashbook `day_entries` row.<br>5. Trigger updates `customer_wallets.current_balance`. |

