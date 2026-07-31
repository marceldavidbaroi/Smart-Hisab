# Smart-Hisab Master Entity & Architecture Specification

## 1. Core Architecture Principles

Everything in Smart-Hisab operates on a strict multi-tenant boundary rooted in operational time windows:

$$\text{Tenant} \longrightarrow \text{BusinessDay} \longrightarrow \text{Shift}$$

* **Operational Window Isolation**: Transactions, attendance, payouts, and spend entries are stamped with `shift_id` and `business_day_id`, resolving midnight shift rollover ambiguity.
* **Dual-Ledger Accounting**:
  * `WalletEntry`: Tracks **Customer Debt & Meal Charges** (Who owes what).
  * `DayEntry`: Tracks **Company Cash Flow & Expenses** (Actual money in drawer/bank).
* **Derived State**: No static balance columns (e.g. `outstanding_balance`). Customer balances and company net cash/profit are calculated dynamically from immutable ledger entries.

---

## 2. System Entity Map

```text
Tenant
 ├── Devices (Kiosk/POS Terminals)
 ├── Shifts (Breakfast / Lunch / Dinner)
 ├── MealConfigs (Base meal rates)
 ├── Staff (PIN authentication, StaffRole)
 │     ├── StaffAttendance
 │     └── SalaryPayouts ──► Auto-creates DayEntry (salary_outflow)
 ├── Customers ──► CustomerWallets ──► WalletEntries (Charges & Payments)
 │                                       ▲
 │                                       └── MealAttendance (meal_charge)
 └── BusinessDays (Operational container)
       ├── MealAttendance
       ├── StaffAttendance
       ├── DayEntries (Market cost / canteen expense / misc earn / salary outflow)
       └── DayNotes (Daily market list & operational notes)
```

---

## 3. Entity Specifications

### 3.1 Identity, Access & Terminals

#### `tenants`
Root entity representing a canteen/business operation.
* `id` (UUID, PK)
* `name` (TEXT)
* `status` (TEXT: `active`, `suspended`)
* `created_at` (TIMESTAMPTZ)

#### `users` & `user_profiles`
Platform login accounts (managers, owners).
* `id` (UUID, PK)
* `email` (TEXT)
* `full_name` (TEXT)

#### `tenant_members`
User-to-Tenant relationship with administrative roles.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `user_id` (UUID, FK -> `users`)
* `role` (TEXT: `owner`, `manager`)

#### `devices`
Paired kiosk terminals or handheld POS devices.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `device_name` (TEXT)
* `device_token` (TEXT, Unique)
* `is_active` (BOOLEAN)

---

### 3.2 Staff & Payroll

#### `staff_roles`
Permissions definition for counter workers.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `role_name` (TEXT: `counter_operator`, `cook`, `manager`)
* `permissions` (JSONB)

#### `staff`
Counter workers logging attendance and performing actions.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `user_id` (UUID, FK -> `users`, Optional)
* `role_id` (UUID, FK -> `staff_roles`)
* `name` (TEXT)
* `phone` (TEXT)
* `pin_code` (TEXT, Hashed/Encrypted PIN)
* `is_active` (BOOLEAN)

#### `staff_attendance`
Staff work tracking per day/shift.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `staff_id` (UUID, FK -> `staff`)
* `business_day_id` (UUID, FK -> `business_days`)
* `shift_id` (UUID, FK -> `shifts`)
* `status` (TEXT: `present`, `absent`, `half_day`)
* `created_at` (TIMESTAMPTZ)

#### `salary_payouts`
Staff salary payment records.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `staff_id` (UUID, FK -> `staff`)
* `business_day_id` (UUID, FK -> `business_days`)
* `amount` (NUMERIC(12, 2))
* `payment_mode` (TEXT: `cash`, `bank`, `mobile_money`)
* `notes` (TEXT)
* `created_at` (TIMESTAMPTZ)

#### `staff_wallets`
Staff account header (one-to-one with `staff`).
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `staff_id` (UUID, FK -> `staff`, Unique)
* `current_balance` (NUMERIC(12, 2), Cached current balance)
* `created_at` (TIMESTAMPTZ)

---

### 3.3 Customers & Wallet Ledger

#### `customers`
Customer profiles (diners, students, room members).
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `name` (TEXT)
* `phone` (TEXT)
* `address` (TEXT, optional)
* `institution` (TEXT, optional)
* `is_active` (BOOLEAN)
* `created_at` (TIMESTAMPTZ)

#### `customer_wallets`
Customer account header (one-to-one with `Customer`).
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `customer_id` (UUID, FK -> `customers`, Unique)
* `current_balance` (NUMERIC(12, 2), Cached current balance)
* `created_at` (TIMESTAMPTZ)

#### `wallet_entries`
Immutable ledger for customer debt and payments.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `wallet_id` (UUID, FK -> `customer_wallets`)
* `business_day_id` (UUID, FK -> `business_days`)
* `shift_id` (UUID, FK -> `shifts`)
* `type` (TEXT: `meal_charge`, `payment`, `adjustment`)
* `amount` (NUMERIC(12, 2))
* `reference_type` (TEXT: `meal_attendance`, `cash_collection`)
* `reference_id` (UUID)
* `notes` (TEXT)
* `created_at` (TIMESTAMPTZ)

---

### 3.4 Shifts & Meals

#### `shifts`
Operating windows within a day.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `name` (TEXT: `Breakfast`, `Lunch`, `Dinner`)
* `start_time` (TIME)
* `end_time` (TIME)
* `is_active` (BOOLEAN)

#### `meal_configs`
Meal rate rules.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `rate` (NUMERIC(10, 2))
* `effective_from` (DATE)
* `note` (TEXT, Optional — details/description of the meal)

#### `meal_attendance`
Record of customer consuming a meal during a shift.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `customer_id` (UUID, FK -> `customers`)
* `date` (DATE, Default: current_date)
* `shift_id` (UUID, FK -> `shifts`)
* `charge_amount` (NUMERIC(10, 2))
* `recorded_by_staff_id` (UUID, FK -> `staff`)
* `created_at` (TIMESTAMPTZ)

---

### 3.5 Business Day, Cashbook & Notes

#### `business_days`
Operational container for opening/closing day cash.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `business_date` (DATE)
* `opening_cash` (NUMERIC(12, 2))
* `closing_cash` (NUMERIC(12, 2), Optional until closed)
* `expected_cash` (NUMERIC(12, 2), Calculated at day close)
* `variance` (NUMERIC(12, 2), `closing_cash - expected_cash`)
* `status` (TEXT: `open`, `closed`)
* `opened_by_staff_id` (UUID, FK -> `staff`, Optional)
* `closed_by_staff_id` (UUID, FK -> `staff`, Optional)
* `opened_at` (TIMESTAMPTZ)
* `closed_at` (TIMESTAMPTZ)

#### `day_entries`
Company cashbook ledger (inflow & outflow).
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `business_day_id` (UUID, FK -> `business_days`)
* `shift_id` (UUID, FK -> `shifts`, Optional)
* `entry_type` (TEXT: `inflow`, `outflow`)
* `category` (TEXT: `customer_payment`, `market_cost`, `canteen_expense`, `salary_outflow`, `misc_earn`)
* `amount` (NUMERIC(12, 2))
* `reference_type` (TEXT: `wallet_entry`, `salary_payout`)
* `reference_id` (UUID)
* `notes` (TEXT)
* `created_by_staff_id` (UUID, FK -> `staff`)
* `created_at` (TIMESTAMPTZ)

#### `day_notes`
Simple operational notes and daily market/shopping list notes.
* `id` (UUID, PK)
* `tenant_id` (UUID, FK -> `tenants`)
* `business_day_id` (UUID, FK -> `business_days`)
* `note_type` (TEXT: `market_list`, `general_note`, `issue`)
* `content` (TEXT)
* `created_by_staff_id` (UUID, FK -> `staff`)
* `created_at` (TIMESTAMPTZ)

---

## 4. Ledger Workflows & Automation Rules

### Flow A: Customer Eats a Meal
1. A record is inserted into `MealAttendance`.
2. A trigger/RPC automatically inserts a `WalletEntry` (`type = 'meal_charge'`, `amount = MealConfig.rate`).
3. Customer balance increases (debt increases).

### Flow B: Customer Pays Cash (Baki Collection)
1. Counter staff logs customer cash collection.
2. A `WalletEntry` (`type = 'payment'`, `amount = $X`) is inserted → Customer balance decreases (debt cleared).
3. A `DayEntry` (`entry_type = 'inflow'`, `category = 'customer_payment'`, `amount = $X`) is inserted → Company cash drawer increases.

### Flow C: Market / Bazaar Purchase
1. Staff notes items needed in `DayNote` (`note_type = 'market_list'`).
2. Staff purchases bazaar items with canteen cash.
3. Staff records expense in `DayEntry` (`entry_type = 'outflow'`, `category = 'market_cost'`, `amount = $Y`).

### Flow D: Staff Salary Payout
1. Manager processes payout in `SalaryPayout`.
2. A linked `DayEntry` (`entry_type = 'outflow'`, `category = 'salary_outflow'`, `amount = $Z`) is created.

---

## 5. Financial Reporting Engine

All reporting is derived on-demand using SQL over `WalletEntry` and `DayEntry`:

```sql
CREATE OR REPLACE FUNCTION get_financial_summary(
  p_tenant_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  total_meal_billed NUMERIC,
  total_customer_payments NUMERIC,
  total_market_cost NUMERIC,
  total_canteen_expenses NUMERIC,
  total_salary_outflow NUMERIC,
  net_cash_flow NUMERIC,
  net_profit_loss NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH wallet_summary AS (
    SELECT 
      COALESCE(SUM(CASE WHEN type = 'meal_charge' THEN amount ELSE 0 END), 0) AS meal_billed,
      COALESCE(SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END), 0) AS payments
    FROM wallet_entries
    WHERE tenant_id = p_tenant_id
      AND created_at::date BETWEEN p_start_date AND p_end_date
  ),
  day_summary AS (
    SELECT 
      COALESCE(SUM(CASE WHEN category = 'market_cost' THEN amount ELSE 0 END), 0) AS market_cost,
      COALESCE(SUM(CASE WHEN category = 'canteen_expense' THEN amount ELSE 0 END), 0) AS canteen_expenses,
      COALESCE(SUM(CASE WHEN category = 'salary_outflow' THEN amount ELSE 0 END), 0) AS salary_outflow,
      COALESCE(SUM(CASE WHEN category = 'misc_earn' THEN amount ELSE 0 END), 0) AS misc_earn
    FROM day_entries
    WHERE tenant_id = p_tenant_id
      AND created_at::date BETWEEN p_start_date AND p_end_date
  )
  SELECT 
    ws.meal_billed,
    ws.payments,
    ds.market_cost,
    ds.canteen_expenses,
    ds.salary_outflow,
    -- Net Cash Flow: Cash Received (Payments + Misc Earn) - Cash Spent
    (ws.payments + ds.misc_earn) - (ds.market_cost + ds.canteen_expenses + ds.salary_outflow) AS net_cash_flow,
    -- Net Profit/Loss: Billed Revenue + Misc Earn - Expenses
    (ws.meal_billed + ds.misc_earn) - (ds.market_cost + ds.canteen_expenses + ds.salary_outflow) AS net_profit_loss
  FROM wallet_summary ws, day_summary ds;
END;
$$ LANGUAGE plpgsql STABLE;
```
