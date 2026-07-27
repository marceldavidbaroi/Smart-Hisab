# Task: Day Tracking & Automated Shifts (Removing Sessions)

## Overview
The system is transitioning away from manual per-shift "Sessions" to a new "Day Tracking" model. Transactions will automatically determine their associated shift based on the current time, while financial reconciliation (opening/closing cash) is moved to a daily level.

## Key Rules
1. **Day Tracking**: A Manager must "Start Day" to begin operations, entering the opening drawer amount. They "End Day" to record the closing drawer amount.
2. **Sequential Days**: A new day cannot be started if the previous day is not ended.
3. **Resuming a Day**: If a day is ended, but it is still the same calendar date, the day can be resumed (re-opened) and ended again later.
4. **Automated Shifts**: Transactions (POS, expenses, etc.) no longer explicitly require a `session_id` from the client. Instead, they store the `shift_id` automatically resolved based on the current time of the request.
5. **Session Removal**: The `sessions` table is entirely removed.

---

## Phase 1: Backend Database Changes (Supabase)

### Goal
Remove the `sessions` table, create the new `business_days` table, and update all transaction tables and RPCs to use `business_day_id` and auto-selected `shift_id`.

### Files to Change
- `supabase/migrations/20260728000000_day_tracking_automated_shifts.sql` (New Migration)

### Details
1. **Create `business_days` Table**:
   - Fields: `id`, `tenant_id`, `business_date`, `status` (open/closed), `opening_cash`, `closing_cash`, `opened_by`, `closed_by`, `opened_at`, `closed_at`.
2. **Update Transaction Tables**:
   - `transaction_ledger`: Drop `session_id`, add `business_day_id` and `shift_id`.
   - `meal_attendance` & `customer_baki_ledger`: Drop `session_id`, add `business_day_id` and `shift_id`.
3. **Create Helper RPCs**:
   - `get_current_shift(tenant_id)`: Determines the active `shift_id` from the `shifts` table based on `now()::time`.
   - `start_business_day(tenant_id, ...)`: Enforces that the previous day is ended, records opening cash.
   - `end_business_day(tenant_id, ...)`: Records closing cash.
   - `resume_business_day(tenant_id, ...)`: Re-opens the day if it matches the current date.
4. **Refactor Existing RPCs**:
   - `log_pos_sale`, `log_manual_ledger_entry`, `record_customer_collection`, etc., will fetch the active `business_day_id` and `get_current_shift()` internally, rather than accepting `p_session_id` from the client.
5. **Drop `sessions`**:
   - Drop the `sessions` table and its associated `open_session` / `close_session` RPCs.

---

## Phase 2: Backend Policy & Read Access

### Goal
Ensure kiosks and managers can correctly read transactions based on the new daily structure instead of sessions.

### Files to Change
- Included in the `20260728000000` migration.

### Details
1. **Update `get_session_read_scope`**: Rename to `get_day_read_scope` or similar. Update RLS policies on `transaction_ledger` to rely on `business_day_id` or `created_at` rather than `session_id`.
2. **Kiosk Ledger Reads**: Update `list_session_ledger_entries` to `list_daily_ledger_entries(tenant_id, device_token, staff_id)`, which returns transactions for the currently active `business_day`.
3. **Running Balance**: Update `get_cash_register_running_balance_kiosk` to calculate based on the active `business_day`'s opening cash + inflows - outflows.

---

## Phase 3: Frontend Adjustments (Mobile Kiosk)

### Goal
Replace the "Open/Close Session" UI with "Start/End Day" UI, and update all API calls to stop passing `sessionId`.

### Files to Change
- `mobile/src/hooks/useTerminal.ts` (or equivalent session/terminal context).
- `mobile/src/app/terminal/index.tsx` (Terminal Dashboard).
- `mobile/src/app/(terminal)/...` (Transaction screens like POS, Baki).
- `mobile/src/services/kiosk.ts` (API service methods).

### Details
1. **State Management**: The terminal tracks `activeBusinessDay` rather than `activeSession`.
2. **Dashboard & Terminal Enforcement UI**:
   - If no day is active, enforce starting a day by prompting for **Opening Counter Cash**. Transactions (POS, Baki, Attendance) are blocked until a business day is started.
   - If a day is active, display the active day stats, counter cash, and allow normal sales/ledger operations. Provide an "End Day" button for closing counter cash entry.
   - If a day is ended on the same calendar date, display a "Resume Day" option.
3. **API Calls**: Remove `sessionId` from payload of `log_pos_sale`, `logExpense`, `recordBaki`, etc. The backend handles shift/day assignment automatically.
4. **Automated Shift Display**: The UI can fetch the `currentShift` to display it to the user ("Current Shift: Lunch"), but it doesn't need to pass it to the backend.
