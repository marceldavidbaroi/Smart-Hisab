# Modal: Open Business Day

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `OpenDayBottomSheet`
* **Dart Source File**: [open_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/open_day_bottom_sheet.dart)
* **Parent / Hosting Screen**: Launched as Modal Bottom Sheet from [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart) (`HomeScreen`)

---

## 2. Initial Load & Riverpod State

### Riverpod State
* **Provider Name**: `businessDayNotifierProvider`
* **Type**: `AsyncNotifier<BusinessDayState>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Open Business Day** | Enter Opening Cash (BDT), tap "Confirm & Open Day" | `openBusinessDay(amount, notes)` | `start_business_day` | Sets `isOpen: true`, `activeDayId: id`, `openingBalance: amount` in state. Closes modal immediately. |

---

## 4. Complete API & RPC Specifications

### `start_business_day`
* **Method**: `supabase.rpc('start_business_day', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_opening_balance": 1500.00,
  "p_notes": "Morning cash float 1500 BDT"
}
```
* **Response**:
```json
{
  "success": true,
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "opening_balance": 1500.00,
  "opened_at": "2026-08-21T06:00:00Z"
}
```
