# Screen: Staff Directory & Payroll Overview

## 1. Description
Staff directory displaying employees, designations, employment types (Monthly Fixed Salary vs Daily Wage Rate), active advance balances, and header KPI summary of monthly payroll liabilities.

* **Dart File**: [staff_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/staff_screen.dart)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch API
* **Query**:
```dart
final response = await supabase
    .from('staff_members')
    .select('*, staff_wallets(*)')
    .eq('tenant_id', tenantId)
    .eq('is_active', true)
    .order('name', ascending: true);
```
* **Payload**: `tenant_id` (UUID)
* **Response**:
```json
[
  {
    "id": "22f3e4d5-0000-0000-0000-000000000001",
    "name": "Abul Kashem",
    "phone": "01611223344",
    "role": "Head Chef",
    "salary_type": "monthly",
    "monthly_salary": 18000.00,
    "daily_rate": 0.00,
    "is_active": true,
    "staff_wallets": {
      "current_advance_balance": 3000.00,
      "total_salary_paid": 36000.00
    }
  }
]
```

### B. Riverpod State
* **Provider Name**: `staffNotifierProvider`
* **Type**: `AsyncNotifier<List<StaffMember>>`
* **Local Cache**: Hive Box `staff_cache_<tenant_id>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Search Staff** | Search TextField | `filterByName(query)` | None (In-memory) | Filters list in memory without network call. |
| **Open Staff Detail** | Tap Staff Card | Navigation | None | Opens [staff_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/staff_detail_screen.dart). |
| **Add Staff** | Tap "Add Staff" FAB | `addStaff(staff)` | `.from('staff_members').insert(...)` | Prepends new `StaffMember` to local `state`. |
| **Quick Salary Payout** | Swipe Right -> Tap "Pay" | `recordPayout(...)` | `record_salary_payout_v2` | Updates advance/paid totals in `staff_wallets`. |
| **Edit Staff Terms** | Swipe Left -> Tap "Edit" | `updateStaff(staff)` | `.from('staff_members').update(...)` | Replaces staff member in local `state` by ID. |

---

## 4. Complete API & RPC Specifications

### 1. `record_salary_payout_v2`
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
  "p_notes": "Salary advance"
}
```
* **Response**:
```json
{
  "success": true,
  "salary_payout_id": "99c8b7a6-0000-0000-0000-000000000001",
  "staff_id": "22f3e4d5-0000-0000-0000-000000000001",
  "payout_type": "advance",
  "amount": 3000.00
}
```
