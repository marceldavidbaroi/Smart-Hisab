# Feature: Shift & Day Reconciliation — RPC / APIs

> RPC functions for business day lifecycle management and cash reconciliation.

---

## `start_business_day`

Opens a new business day for the tenant. Only one day can be open at a time.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_staff_id UUID (nullable)`, `p_opening_cash NUMERIC` |
| **Returns** | `UUID` (business_day ID) |
| **Side effects** | INSERT `business_days` (status: `open`) |
| **Guard** | If a day is already open, **returns the existing day_id** (idempotent — does not raise an error) |
| **Auth** | `auth.uid()` (owner/manager) or staff PIN session |

---

## `end_business_day`

Closes the active business day. Calculates expected cash and variance.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_day_id UUID`, `p_staff_id UUID (nullable)`, `p_closing_cash NUMERIC`, `p_notes TEXT` |
| **Returns** | `TABLE(expected_cash NUMERIC, variance NUMERIC, status TEXT)` |
| **Logic** | Calls `calculate_expected_cash(p_day_id)` → sets `closing_cash`, `expected_cash`, `variance`, `status='closed'` |

---

## `resume_business_day`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Reopens a same-day closed business day. Only allowed if `business_date = today`.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_day_id UUID`, `p_staff_id UUID (nullable)` |
| **Returns** | `VOID` |
| **Guard** | Fails if `business_date != today` |

---

## `get_active_business_day`

Returns the currently open business day ID for the tenant.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID` |
| **Returns** | `UUID` or `NULL` |

---

## `calculate_expected_cash`

Pure calculation — does not write to DB.

| | |
|---|---|
| **Parameters** | `p_day_id UUID` |
| **Returns** | `NUMERIC` |
| **Formula** | `opening_cash + SUM(day_entries where entry_type='inflow') - SUM(day_entries where entry_type='outflow')` |

---

## `get_financial_summary`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Aggregated financial report from all ledgers for a date range.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_start_date DATE`, `p_end_date DATE` |
| **Returns** | `TABLE(total_meal_billed, total_customer_payments, total_market_cost, total_canteen_expenses, total_salary_outflow, total_vendor_payments, net_cash_flow, net_profit_loss)` |
| **Sources** | Aggregates from `wallet_entries`, `day_entries`, `vendor_wallet_entries` |
| **Used by** | Reports page (v1.5+), PDF export (v2.0+) |
