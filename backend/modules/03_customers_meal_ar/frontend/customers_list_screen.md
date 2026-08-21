# Screen: Customers Directory & Baki List

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `CustomersScreen`
* **Dart Source File**: [customers_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/customers_screen.dart)
* **Parent / Hosting Shell**: [app_scaffold.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/app_scaffold.dart) — **Tab 1: Customers**
* **Child Modals Launched**:
  * [add_customer_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/add_customer_bottom_sheet.dart) (`AddCustomerBottomSheet`)
  * [collect_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/collect_baki_bottom_sheet.dart) (`CollectBakiBottomSheet`)
  * [edit_customer_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/edit_customer_bottom_sheet.dart) (`EditCustomerBottomSheet`)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch API
* **Endpoint / Query**:
```dart
final response = await supabase
    .from('customers')
    .select('*, customer_wallets(*)')
    .eq('tenant_id', tenantId)
    .eq('is_active', true)
    .order('name', ascending: true);
```
* **Payload**: `tenant_id` (UUID)
* **Response**:
```json
[
  {
    "id": "99f8c12a-0000-0000-0000-000000000001",
    "tenant_id": "tenant-1",
    "name": "Rahim Uddin",
    "phone": "01711000000",
    "opening_balance": 0.0,
    "subscribed_shifts": ["33a1b2c3-0000-0000-0000-000000000001"],
    "is_active": true,
    "customer_wallets": {
      "current_balance": 350.00,
      "total_debit": 1250.00,
      "total_credit": 900.00
    }
  }
]
```

### B. Riverpod State
* **Provider Name**: `customersNotifierProvider`
* **Type**: `AsyncNotifier<List<Customer>>`
* **Local Cache**: Hive Box `customers_cache_<tenant_id>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Search Filter** | Search TextField (300ms debounce) | `filterByNameOrPhone(query)` | None (In-memory) | Filters current local list in memory. Zero API calls. |
| **Filter by Shift** | Shift Filter Chips | `filterByShift(shiftId)` | None (In-memory) | Matches `subscribed_shifts` UUID array in local list. |
| **Open Customer Detail** | Tap Customer Card | Navigation | `get_customer_balance` | Opens [customer_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/customer_detail_screen.dart). |
| **Add Customer** | Tap "Add Customer" FAB | `addCustomer(customer)` | `create_or_reactivate_customer` | Optimistically prepends new `Customer` to `state`. |
| **Edit Customer** | Swipe left -> Tap "Edit" | `updateCustomer(customer)` | `.from('customers').update(...)` | Replaces customer item in local `state` by ID. |
| **Deactivate Customer** | Swipe left -> Tap "Delete" | `deactivateCustomer(id)` | `.from('customers').update({'is_active': false})` | Removes customer from local `state` (Blocked if balance > 0). |
| **Quick Collect Baki** | Swipe right -> Tap "Collect" | `collectBaki(...)` | `record_baki_payment_v2` | Decrements `customer.wallet.current_balance` by payment amount. |

---

## 4. Complete API & RPC Specifications

### 1. `create_or_reactivate_customer`
* **Method**: `supabase.rpc('create_or_reactivate_customer', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_name": "Karim Hossain",
  "p_phone": "01811223344",
  "p_opening_balance": 0.00,
  "p_subscribed_shifts": ["33a1b2c3-0000-0000-0000-000000000001"]
}
```
* **Response**:
```json
{
  "success": true,
  "customer_id": "11b2c3d4-0000-0000-0000-000000000001",
  "name": "Karim Hossain",
  "reactivated": false
}
```

### 2. `record_baki_payment_v2`
* **Method**: `supabase.rpc('record_baki_payment_v2', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "p_canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_amount": 500.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001"
}
```
* **Response**:
```json
{
  "success": true,
  "wallet_entry_id": "55a6b7c8-0000-0000-0000-000000000001",
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "amount": 500.00
}
```
