# Modal: Add Operational Expense

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `AddExpenseBottomSheet`
* **Dart Source File**: [add_expense_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/add_expense_bottom_sheet.dart)
* **Parent / Hosting Screen**: Launched as Modal Bottom Sheet from [cashbook_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/cashbook_screen.dart) (`CashbookScreen`) or [bazar_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/bazar/bazar_screen.dart) (`BazarScreen`)

---

## 2. Initial Load & Riverpod State

### Riverpod State
* **Provider Name**: `cashbookNotifierProvider`
* **Type**: `AsyncNotifier<CashbookState>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Record Expense** | Select Category, Account, Amount, tap "Confirm Expense" | `recordExpense(...)` | `record_expense_v2` | Prepends entry to `day_entries` in `cashbookNotifierProvider`; decrements account balance. |

---

## 4. Complete API & RPC Specifications

### `record_expense_v2`
* **Method**: `supabase.rpc('record_expense_v2', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_category": "bazar",
  "p_amount": 1250.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_notes": "Morning vegetable & poultry bazar"
}
```
* **Response**:
```json
{
  "success": true,
  "day_entry_id": "44a5b6c7-0000-0000-0000-000000000001",
  "canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "amount": 1250.00,
  "category": "bazar"
}
```
