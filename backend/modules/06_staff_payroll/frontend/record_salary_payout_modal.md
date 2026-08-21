# Modal: Record Salary Payout / Advance

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `RecordSalaryPayoutBottomSheet`
* **Dart Source File**: [record_salary_payout_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/record_salary_payout_bottom_sheet.dart)
* **Parent / Hosting Screen**: Launched as Modal Bottom Sheet from [staff_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/staff_screen.dart) (`StaffScreen`) or [staff_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/staff_detail_screen.dart) (`StaffDetailScreen`)

---

## 2. Initial Load & Riverpod State

### Riverpod Providers
* **Providers**: `staffNotifierProvider`, `staffDetailNotifierProvider(staffId)`, `cashbookNotifierProvider`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Confirm Payout** | Select Type (`advance`/`salary`), Account, Amount, tap "Confirm Payout" | `recordPayout(...)` | `record_salary_payout_v2` | For Advance: Increments `staff_wallets.current_advance_balance`. For Salary: Resets advance to 0 & increments `total_salary_paid`. Adds expense to cashbook. |

---

## 4. Complete API & RPC Specifications

### `record_salary_payout_v2`
* **Method**: `supabase.rpc('record_salary_payout_v2', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_staff_id": "22f3e4d5-0000-0000-0000-000000000001",
  "p_canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_amount": 3000.00,
  "p_payout_type": "advance",
  "p_payout_month": "2026-08-01",
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_notes": "Festival salary advance"
}
```
* **Response**:
```json
{
  "success": true,
  "salary_payout_id": "99c8b7a6-0000-0000-0000-000000000001",
  "staff_id": "22f3e4d5-0000-0000-0000-000000000001",
  "payout_type": "advance",
  "canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "amount": 3000.00
}
```
