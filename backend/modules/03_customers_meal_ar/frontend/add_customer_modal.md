# Modal: Add Customer

## 1. Description
Modal bottom sheet (`showModalBottomSheet`) for registering a new canteen customer with initial opening balance and shift meal subscriptions.

* **Dart File**: [add_customer_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/add_customer_bottom_sheet.dart)
* **Riverpod Provider**: `customersNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Save Customer** | Enter details, tap "Save Customer" | Calls `create_or_reactivate_customer` RPC, updates local cache, closes modal. |

---

## 3. APIs Used

### Mutation RPC: `create_or_reactivate_customer`
* **Method**: `supabase.rpc('create_or_reactivate_customer', params: {...})`
* **Input Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_name": "Karim Hossain",
  "p_phone": "01811223344",
  "p_email": null,
  "p_address": "Flat 4B, Dhanmondi",
  "p_opening_balance": 0.00,
  "p_subscribed_shifts": [
    "33a1b2c3-0000-0000-0000-000000000001",
    "44b2c3d4-0000-0000-0000-000000000001"
  ]
}
```
* **Output Response**:
```json
{
  "success": true,
  "customer_id": "11b2c3d4-0000-0000-0000-000000000001",
  "name": "Karim Hossain",
  "reactivated": false
}
```
* **Target Local Cache Mutation**:
  * Constructs new `Customer` model and prepends directly into `customersNotifierProvider` list.
  * No full list refetch triggered.
