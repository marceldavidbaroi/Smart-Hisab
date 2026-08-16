# Feature: Bazar & Expenses (AP) — RPC / APIs

> RPC functions for recording expenses, wholesaler credit purchases (baki), vendor payments, and querying vendor ledger.

---

## `record_expense_v2`

Record an expense outflow (Cash/bKash/Bank) or wholesaler credit purchase (Baki).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_category TEXT`, `p_amount NUMERIC`, `p_account_id UUID (nullable)`, `p_vendor_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT`, `p_payment_mode TEXT DEFAULT 'cash'` |
| **Returns** | `UUID` (day_entry ID or vendor_wallet_entry ID) |
| **Categories** | `market_cost` (কাঁচাবাজার/শাক-সবজি/মাছ/চাল), `canteen_expense` (গ্যাস/বিদ্যুৎ/ভাড়া), `transport_labor` (পরিবহন/কুলি) |
| **Logic — Cash Mode (`p_payment_mode = 'cash'`)** | INSERT `day_entries` (outflow) + `canteen_account_entries` (outflow from `p_account_id`). If `p_account_id` is the active cash drawer, it updates shift cash balance. |
| **Logic — Baki Mode (`p_payment_mode = 'baki'`)** | INSERT `vendor_wallet_entries` (purchase). Vendor baki increases. Canteen cash accounts and active shift drawer remain completely untouched (৳0 deduction). |
| **Logic — Split Mode (`p_payment_mode = 'split'`)** | Inserts cash outflow for the paid portion and records vendor purchase for the remaining credit balance. |

---

## `record_misc_income`

Record a miscellaneous cash inflow into a canteen account.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_amount NUMERIC`, `p_canteen_account_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `UUID` (day_entry ID) |
| **Side effects** | INSERT `day_entries` (inflow, category: `misc_earn`, links to `canteen_account_id`) |

---

## `record_vendor_payment_v2`

Canteen pays vendor to settle baki from a selected canteen account (Cash Drawer, bKash, Bank, or Safe).

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID`, `p_amount NUMERIC`, `p_account_id UUID (nullable)`, `p_staff_id UUID (nullable)`, `p_notes TEXT` |
| **Returns** | `NUMERIC` (updated vendor balance) |
| **Side effects** | 1. INSERT `vendor_wallet_entries` (`type='payment'`, decreasing vendor debt via trigger).<br/>2. INSERT `day_entries` (`entry_type='outflow'`, `category='vendor_payment'`).<br/>3. INSERT `canteen_account_entries` (outflow from `p_account_id`). |
| **Trigger** | `update_vendor_wallet_balance` updates `vendor_wallets.current_balance` |

---

## `get_vendor_balance`

Computed balance from the vendor ledger.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID` |
| **Returns** | `NUMERIC` |
| **Logic** | `SUM(purchase) - SUM(payment) ± SUM(adjustment)` from `vendor_wallet_entries` |

---

## `get_vendor_statement`

Full chronological transaction history (Khata / খতিয়ান) for a vendor.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_vendor_id UUID`, `p_start DATE`, `p_end DATE` |
| **Returns** | `TABLE(id UUID, date TIMESTAMPTZ, type TEXT, amount NUMERIC, reference_type TEXT, notes TEXT, recorded_by TEXT, created_at TIMESTAMPTZ)` |
| **Pagination** | Supports `p_limit INT`, `p_offset INT` |


