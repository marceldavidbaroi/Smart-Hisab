# Screen: Vendor Detail & Statement

## 1. Description
Supplier profile, outstanding debt summary card, and chronological statement comparing credit supply purchases against canteen settlement disbursements.

* **Dart File**: [vendor_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/vendor_detail_screen.dart)
* **Riverpod Provider**: `vendorDetailNotifierProvider(vendorId)`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Settle / Pay Vendor** | Tap "Record Payment" CTA | Opens `RecordVendorPaymentBottomSheet`. |
| **Add Supply Baki** | Tap "Add Supply Baki" CTA | Opens `AddVendorBakiBottomSheet`. |
| **Filter Date Range** | Select Date Filter | Queries vendor statement within date range. |

---

## 3. APIs Used

### Read: Get Vendor Statement
* **Method**: `supabase.rpc('get_vendor_statement', params: {'p_vendor_id': vendorId, 'p_start_date': '...', 'p_end_date': '...'})`
* **Response**:
```json
[
  {
    "id": "v-entry-1",
    "entry_type": "debit",
    "category": "supplies",
    "amount": 5000.00,
    "notes": "5 bags of Miniket rice received on credit",
    "created_at": "2026-08-20T10:00:00Z",
    "is_voided": false,
    "account_name": null
  },
  {
    "id": "v-entry-2",
    "entry_type": "credit",
    "category": "payment",
    "amount": 3000.00,
    "notes": "Payment via Cash Drawer",
    "created_at": "2026-08-21T16:00:00Z",
    "is_voided": false,
    "account_name": "Cash Drawer"
  }
]
```
