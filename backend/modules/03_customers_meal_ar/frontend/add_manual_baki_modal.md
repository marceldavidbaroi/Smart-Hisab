# Modal: Add Manual Baki (Custom Charge)

## 1. Description
Modal bottom sheet to record custom non-meal debit charges (e.g. snack, beverage, or custom purchase) on customer's credit account.

* **Dart File**: [add_manual_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/add_manual_baki_bottom_sheet.dart)
* **Riverpod Providers**: `customersNotifierProvider`, `customerDetailNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Add Charge** | Enter Amount & Reason, tap "Record Charge" | Inserts debit wallet entry, increments customer due balance. |

---

## 3. APIs Used

### Mutation API: Insert Wallet Entry
* **Method**: Supabase insert
* **Payload**:
```json
{
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "entry_type": "debit",
  "amount": 150.00,
  "category": "manual_baki",
  "notes": "Extra snacks & cold drinks"
}
```
* **Target Local Cache Mutation**: Increments `customer_wallets.current_balance` by 150.00; appends debit transaction to ledger list.
