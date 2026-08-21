# Modal: Close Business Day & Reconciliation

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `CloseDayBottomSheet`
* **Dart Source File**: [close_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/close_day_bottom_sheet.dart)
* **Parent / Hosting Screen**: Launched as Modal Bottom Sheet from [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart) (`HomeScreen`)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch API
* **RPC**: `calculate_expected_cash(p_day_id: "uuid")`
* **Response**:
```json
{
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "opening_balance": 1500.00,
  "cash_in": 3500.00,
  "cash_out": 450.00,
  "expected_closing_cash": 4550.00
}
```

### B. Riverpod State
* **Provider Name**: `businessDayNotifierProvider`
* **Type**: `AsyncNotifier<BusinessDayState>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Fetch Expected Balance** | Sheet open (`initState`) | `getExpectedCash(dayId)` | `calculate_expected_cash` | Pre-fills expected drawer cash field in form. |
| **Close & Reconcile Day** | Input counted cash, tap "Confirm & Close Day" | `closeBusinessDay(cash, notes)` | `end_business_day` | Sets `isOpen: false`, `activeDayId: null` in state. Closes modal. |

---

## 4. Complete API & RPC Specifications

### `end_business_day`
* **Method**: `supabase.rpc('end_business_day', params: {...})`
* **Payload**:
```json
{
  "p_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_actual_closing_cash": 4550.00,
  "p_notes": "Physical cash matched exactly."
}
```
* **Response**:
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
