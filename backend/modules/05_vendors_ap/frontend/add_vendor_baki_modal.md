# Modal: Add Vendor Baki (Credit Supply Purchase)

## 1. Description
Modal bottom sheet to record goods or supplies received from a supplier on credit (increasing the canteen's payable debt to that vendor).

* **Dart File**: [add_vendor_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/add_vendor_baki_bottom_sheet.dart)
* **Riverpod Providers**: `vendorsNotifierProvider`, `vendorDetailNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Record Supply Baki** | Enter Amount, Category & Notes, tap "Save" | Inserts debit entry in `vendor_wallet_entries`, increments vendor balance. |

---

## 3. APIs Used

### Mutation API: Insert Vendor Debit
* **Method**: Supabase insert
* **Payload**:
```json
{
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "vendor_id": "88e7d6c5-0000-0000-0000-000000000001",
  "business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "entry_type": "debit",
  "amount": 4500.00,
  "category": "supplies",
  "notes": "3 cartons soybean oil received on credit"
}
```
* **Target Local Cache Mutation**: Increments `vendor_wallets.current_balance` by 4500.00 in local state.
