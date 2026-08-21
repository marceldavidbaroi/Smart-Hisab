# Module 02: Business Days & Shifts (`business_days_shifts`)

## 1. Domain & Scope
The **Business Days & Shifts** module manages the daily cash register lifecycle for the canteen POS. It tracks the morning opening float, shift schedules (Breakfast, Lunch, Dinner), automated shift detection, expected cash calculation from all drawer activities, evening physical cash count reconciliation (surplus/shortage), and financial data freeze locks on closed days.

```mermaid
graph LR
    A[Open Business Day] --> B[Start Shift / Fast POS Pushes]
    B --> C[Track Cash In & Cash Out]
    C --> D[Calculate Expected Cash Drawer]
    D --> E[End Day & Record Physical Count]
    E --> F[Freeze Records: Closed Day Lock]
```

---

## 2. Table Schema Dictionary

| Table | Primary Key | Description |
| :--- | :--- | :--- |
| `business_days` | `id` (UUID) | Daily register instance with opening float, expected cash, actual physical cash, and surplus/shortage discrepancy. |
| `shifts` | `id` (UUID) | Canteen operating time windows (start/end times, sort order, active status). |
| `day_notes` | `id` (UUID) | Handover notes and manager memos attached to a business day. |

---

## 3. API & RPC Endpoints Summary Table

| Function / RPC | Method | Purpose | Input Payload | Output Response |
| :--- | :--- | :--- | :--- | :--- |
| `get_active_business_day` | `POST /rpc/get_active_business_day` | Checks if a business day is currently open | `{"p_tenant_id": "uuid"}` | `{"active": true, "id": "uuid", "opening_balance": 500.0, "opened_at": "...", "status": "open"}` |
| `start_business_day` | `POST /rpc/start_business_day` | Opens new business day with starting cash float | `{"p_tenant_id": "uuid", "p_opening_balance": 500.0, "p_notes": "string"}` | `{"success": true, "business_day_id": "uuid", "opening_balance": 500.0, "opened_at": "..."}` |
| `calculate_expected_cash` | `POST /rpc/calculate_expected_cash` | Computes expected drawer cash (Opening + Cash In - Cash Out) | `{"p_day_id": "uuid"}` | `{"business_day_id": "uuid", "opening_balance": 500.0, "cash_in": 1200.0, "cash_out": 300.0, "expected_closing_cash": 1400.0}` |
| `end_business_day` | `POST /rpc/end_business_day` | Closes day, reconciles physical cash, records difference, and freezes day | `{"p_day_id": "uuid", "p_actual_closing_cash": 1400.0, "p_notes": "string"}` | `{"success": true, "business_day_id": "uuid", "expected_closing_cash": 1400.0, "cash_difference": 0.0}` |
| `get_current_shift` | `POST /rpc/get_current_shift` | Resolves active shift based on current time | `{"p_tenant_id": "uuid"}` | `{"found": true, "id": "uuid", "name": "Lunch", "start_time": "11:00:00", "end_time": "16:00:00"}` |
| `check_closed_day_lock` | Trigger Guard | Prevents modifications to transactions linked to closed days | System trigger | `Raises Exception on closed day mutation` |

---

## 4. Detailed RPC Reference

### `start_business_day`
* **Triggered by**: [open_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/open_day_bottom_sheet.dart)
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_opening_balance": 1500.00,
  "p_notes": "Morning float 1500 BDT in drawer"
}
```
* **Success Response**:
```json
{
  "success": true,
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "opening_balance": 1500.00,
  "opened_at": "2026-08-21T06:00:00Z"
}
```

---

### `end_business_day`
* **Triggered by**: [close_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/close_day_bottom_sheet.dart)
* **Payload**:
```json
{
  "p_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_actual_closing_cash": 4550.00,
  "p_notes": "Reconciled drawer cash for the day"
}
```
* **Success Response**:
```json
{
  "success": true,
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "opening_balance": 1500.00,
  "actual_closing_cash": 4550.00,
  "expected_closing_cash": 4550.00,
  "cash_difference": 0.00,
  "closed_at": "2026-08-21T23:30:00Z"
}
```

---

## 5. Mobile Screens & Consumers
* [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart)
* [business_day_notifier.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/business_day_notifier.dart)
* [open_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/open_day_bottom_sheet.dart)
* [close_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/close_day_bottom_sheet.dart)
* [shifts_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/shifts_screen.dart)
* [shift_form_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/shift_form_bottom_sheet.dart)
* [add_day_note_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/add_day_note_bottom_sheet.dart)
