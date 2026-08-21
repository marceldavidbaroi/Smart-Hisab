# Screen: Shifts Management & Form

## 1. Description
Provides a timeline view of all canteen shifts (Breakfast, Lunch, Dinner) and a modal sheet to add, edit, or toggle shifts.

* **Dart Files**: [shifts_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/shifts_screen.dart), [shift_form_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/shift_form_bottom_sheet.dart)
* **Riverpod Provider**: `shiftsNotifierProvider` (`AsyncNotifier<List<Shift>>`)

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **View Shifts** | Open Screen | Fetches active shifts list ordered by `sort_order`. |
| **Add / Edit Shift** | Submit `ShiftFormBottomSheet` | Inserts or updates shift in `shifts` table. |
| **Toggle Shift Active** | Tap toggle switch | Updates `is_active` boolean directly. |

---

## 3. APIs Used

### 1. Read: Fetch Shifts
* **Method**: Supabase query
* **Query**: `.from('shifts').select('*').eq('tenant_id', tenantId).order('sort_order', ascending: true)`
* **Response**:
```json
[
  {
    "id": "shift-1",
    "name": "Breakfast",
    "start_time": "06:00:00",
    "end_time": "11:00:00",
    "is_active": true,
    "sort_order": 1
  }
]
```

### 2. Mutation: Upsert Shift
* **Method**: `.from('shifts').upsert({...})`
* **Target Local Cache Mutation**: Updates the shift in `shiftsNotifierProvider` list without full refetch.
