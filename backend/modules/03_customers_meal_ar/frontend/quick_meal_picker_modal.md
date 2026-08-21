# Modal: Quick Customer Meal Punch

## 1. Description
Rapid 1-tap POS meal attendance puncher used during rush hours. Filterable by current active shift. Punches meal attendance, snapshots rate, and debits customer's credit balance.

* **Dart File**: [quick_customer_picker_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/widgets/quick_customer_picker_bottom_sheet.dart)
* **Riverpod Provider**: `customersNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Punch Meal** | Tap on Customer Row / Checkmark | Calls `record_meal_attendance` RPC, updates customer balance, shows haptic feedback. |

---

## 3. APIs Used

### Mutation RPC: `record_meal_attendance`
* **Method**: `supabase.rpc('record_meal_attendance', params: {...})`
* **Input Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "p_shift_id": "33a1b2c3-0000-0000-0000-000000000001",
  "p_rate": 60.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_is_manual": false,
  "p_notes": null
}
```
* **Output Response**:
```json
{
  "success": true,
  "attendance_id": "77a8b9c0-0000-0000-0000-000000000001",
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "rate": 60.00,
  "meal_date": "2026-08-21"
}
```
* **Target Local Cache Mutation**:
  * Increments customer's `current_balance` by 60.00 in `customersNotifierProvider`.
  * Renders green success checkmark on the customer row.
