# Remove Sessions and Automate Shift Tracking

The current system requires staff/managers to explicitly "Open Session" and "Close Session" based on a selected Shift. The goal of this change is to completely remove the concept of "Sessions" and instead rely strictly on "Shifts". Transactions will automatically be assigned to a Shift based on the current time of day.

## User Review Required

> [!WARNING]
> This is a destructive database change. We will be dropping the `sessions` table and removing `session_id` from all transactions and related RPCs. 
> 
> **Are there any existing transactions in the database that you want to preserve?** If this is a fresh setup or development environment, we can simply drop and recreate the necessary foreign keys. If we need to preserve data, we must migrate `session_id` to `shift_id` for existing records before dropping the table.
>
> Please confirm if this is a fresh environment where we can safely drop/recreate dependencies.

## Open Questions

1. **Midnight Shifts (Business Date):** If a shift runs from 10:00 PM to 06:00 AM, a transaction at 02:00 AM technically falls on the next calendar day. Should the system record a `business_date` (which would be the previous day for that 02:00 AM transaction) to group all transactions for that shift together, or is grouping them by `shift_id` and the `created_at` timestamp sufficient?
2. **Missing Shifts:** If a transaction is recorded at a time that does not fall into any active shift's time window, should we block the transaction (throw an error) or allow it with a `null` shift?
3. **Cash Register Balance:** Currently, opening and closing cash are tied to a session. If there are no sessions, do you want to keep track of opening/closing cash per shift per day, or should the "Running Balance" just be a continuous calculation of `Inflow - Outflow`?

## Proposed Changes

We will introduce a new migration: `20260728000000_remove_sessions_automate_shifts.sql`.

### Database Schema Changes
- **Create Helper `get_current_shift(tenant_id)`**: A function that takes the current time `now()::time` and finds the active shift. It will correctly handle shifts that span midnight (where `start_time > end_time`).
- **Modify `transaction_ledger`**:
  - `ALTER TABLE public.transaction_ledger DROP COLUMN session_id;`
  - `ALTER TABLE public.transaction_ledger ADD COLUMN shift_id uuid REFERENCES public.shifts(id);`
  - `ALTER TABLE public.transaction_ledger ADD COLUMN business_date date;` (calculated based on shift start)
- **Modify `meal_attendance` & `customer_baki_ledger`** (and other relevant tables):
  - Replace any `session_id` column with `shift_id` and `business_date`.
- **Drop `sessions` table**:
  - `DROP TABLE public.sessions CASCADE;` (after migrating data or if safe to drop).

### RPC (Remote Procedure Call) Updates
- **Remove Session Management RPCs**: Drop `open_session`, `close_session`, `reopen_session`.
- **Update Kiosk Transactions**: Modify `log_pos_sale`, `log_manual_ledger_entry`, `record_customer_collection`, etc. They will no longer accept `p_session_id`. Instead, they will call `get_current_shift(tenant_id)` to automatically attach the `shift_id` to the transaction.
- **Update Read RPCs**: Modify `list_session_ledger_entries`, `get_cash_register_running_balance_kiosk` to fetch by `shift_id` and `business_date` (e.g., `list_shift_ledger_entries(tenant_id, device_token, staff_id)`).

### Frontend / UI Changes
- **Remove Session Screens**: Remove the "Open Session" and "Close Session" UI from the terminal layout.
- **Update Terminal Dashboard**: The terminal dashboard will display the "Current Shift" automatically based on the time.
- **Update Transaction Calls**: All API calls from the mobile app (e.g., logging a POS sale, taking attendance) will drop the `sessionId` parameter.

## Verification Plan

### Automated Tests
- N/A for backend as we will test manually, but we will ensure migrations apply cleanly.

### Manual Verification
1. Open the mobile terminal app.
2. Observe that there is no prompt to "Open Session". The active shift is automatically detected.
3. Perform a POS sale or add a Baki transaction.
4. Verify in the database that the transaction is successfully recorded and automatically assigned the correct `shift_id` based on the current time.
