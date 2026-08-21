# Screen: Staff Detail & Payout Ledger

## 1. Description
Staff profile screen showing wage contract terms, active accumulated advance debt, and historical salary payout vouchers.

* **Dart File**: [staff_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/staff_detail_screen.dart)
* **Riverpod Provider**: `staffDetailNotifierProvider(staffId)`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Pay Salary / Advance** | Tap "Record Payout" CTA | Opens `RecordSalaryPayoutBottomSheet`. |
| **Edit Staff Contract** | Tap "Edit Staff" | Opens `EditStaffBottomSheet`. |

---

## 3. APIs Used

### Read: Fetch Salary Payouts History
* **Method**: Supabase query
* **Query**:
```dart
final records = await supabase
    .from('salary_payouts')
    .select('*, canteen_accounts(*)')
    .eq('staff_id', staffId)
    .order('created_at', ascending: false);
```
* **Response**:
```json
[
  {
    "id": "payout-1",
    "amount": 3000.00,
    "payout_type": "advance",
    "payout_month": "2026-08-01",
    "notes": "Mid-month advance",
    "created_at": "2026-08-15T12:00:00Z",
    "is_voided": false,
    "canteen_accounts": { "name": "Cash Drawer" }
  }
]
```
