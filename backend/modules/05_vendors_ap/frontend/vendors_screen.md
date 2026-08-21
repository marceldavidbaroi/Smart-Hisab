# Screen: Vendors Directory & AP List

## 1. Description
Primary Accounts Payable (AP) directory. Displays suppliers/wholesalers, search filters by category/phone, and total outstanding debt owed by the canteen to each supplier.

* **Dart File**: [vendors_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/vendors_screen.dart)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch API
* **Query**:
```dart
final response = await supabase
    .from('vendors')
    .select('*, vendor_wallets(*)')
    .eq('tenant_id', tenantId)
    .eq('is_active', true)
    .order('name', ascending: true);
```
* **Payload**: `tenant_id` (UUID)
* **Response**:
```json
[
  {
    "id": "88e7d6c5-0000-0000-0000-000000000001",
    "tenant_id": "tenant-1",
    "name": "Bismillah Rice Agency",
    "phone": "01911223344",
    "category": "groceries",
    "is_active": true,
    "vendor_wallets": {
      "current_balance": 12500.00,
      "total_debit": 35000.00,
      "total_credit": 22500.00
    }
  }
]
```

### B. Riverpod State
* **Provider Name**: `vendorsNotifierProvider`
* **Type**: `AsyncNotifier<List<Vendor>>`
* **Local Cache**: Hive Box `vendors_cache_<tenant_id>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Search Vendors** | Search TextField (300ms debounce) | `filterByNameOrPhone(query)` | None (In-memory) | Filters list in memory without network call. |
| **Open Vendor Detail** | Tap Vendor Card | Navigation | `get_vendor_statement` | Opens [vendor_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/vendor_detail_screen.dart). |
| **Add Vendor** | Tap "Add Vendor" button | `addVendor(vendor)` | `.from('vendors').insert(...)` | Prepends new `Vendor` to local `state`. |
| **Quick Settle Payment** | Swipe Right -> Tap "Pay" | `payVendor(...)` | `record_vendor_payment_v2` | Decrements `vendor_wallets.current_balance` by payment amount. |
| **Edit Vendor** | Swipe Left -> Tap "Edit" | `updateVendor(vendor)` | `.from('vendors').update(...)` | Replaces vendor in local `state` by ID. |

---

## 4. Complete API & RPC Specifications

### 1. `record_vendor_payment_v2`
* **Method**: `supabase.rpc('record_vendor_payment_v2', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_vendor_id": "88e7d6c5-0000-0000-0000-000000000001",
  "p_canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_amount": 3500.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_notes": "Settled weekly supply invoice"
}
```
* **Response**:
```json
{
  "success": true,
  "vendor_entry_id": "33b4c5d6-0000-0000-0000-000000000001",
  "vendor_id": "88e7d6c5-0000-0000-0000-000000000001",
  "canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "amount": 3500.00
}
```
