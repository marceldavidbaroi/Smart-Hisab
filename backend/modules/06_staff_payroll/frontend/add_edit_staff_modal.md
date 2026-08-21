# Modal: Add & Edit Staff Member

## 1. Description
Modal bottom sheet to register or edit staff employment profiles, salary terms (Monthly Fixed vs Daily Wage), and 4-digit POS PIN codes.

* **Dart Files**: [add_staff_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/add_staff_bottom_sheet.dart), [edit_staff_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/edit_staff_bottom_sheet.dart)
* **Riverpod Provider**: `staffNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Save Staff** | Fill form, tap "Save Staff" | Inserts or updates staff member in `staff_members` table. |

---

## 3. APIs Used

### Mutation API: Upsert Staff Member
* **Method**: Supabase insert/update
* **Payload**:
```json
{
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "name": "Abul Kashem",
  "phone": "01611223344",
  "role": "Head Chef",
  "salary_type": "monthly",
  "monthly_salary": 18000.00,
  "daily_rate": 0.00,
  "pin_code": "1234",
  "is_active": true
}
```
* **Target Local Cache Mutation**: Directly upserts the staff object in `staffNotifierProvider` list without full refetch.
