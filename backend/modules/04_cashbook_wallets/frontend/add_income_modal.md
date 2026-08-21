# Modal: Add Direct Income

## 1. Description
Modal bottom sheet to record non-customer miscellaneous cash inflow (e.g. scrap sales, catering advance, owner cash injection).

* **Dart File**: [add_income_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/add_income_bottom_sheet.dart)
* **Riverpod Provider**: `cashbookNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Record Income** | Enter Category, Account, Amount, tap "Confirm Income" | Inserts income row in `day_entries`, increments wallet balance. |

---

## 3. APIs Used

### Mutation API: Insert Income Entry
* **Method**: Supabase insert
* **Payload**:
```json
{
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "entry_type": "income",
  "category": "misc_income",
  "amount": 2000.00,
  "notes": "Event catering advance"
}
```
* **Target Local Cache Mutation**: Prepends income entry and increments account balance in `cashbookNotifierProvider`.
