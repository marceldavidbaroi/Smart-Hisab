# Modal: Record Vendor Payment (Settlement)

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `RecordVendorPaymentBottomSheet`
* **Dart Source File**: [record_vendor_payment_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/record_vendor_payment_bottom_sheet.dart)
* **Parent / Hosting Screen**: Launched as Modal Bottom Sheet from [vendors_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/vendors_screen.dart) (`VendorsScreen`) or [vendor_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/vendor_detail_screen.dart) (`VendorDetailScreen`)

---

## 2. Initial Load & Riverpod State

### Riverpod Providers
* **Providers**: `vendorsNotifierProvider`, `vendorDetailNotifierProvider(vendorId)`, `cashbookNotifierProvider`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Confirm Vendor Payment** | Select Account, enter Amount, tap "Confirm Payment" | `payVendor(...)` | `record_vendor_payment_v2` | Decrements `vendor_wallets.current_balance` by payment amount; adds outflow to cashbook. |

---

## 4. Complete API & RPC Specifications

### `record_vendor_payment_v2`
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
