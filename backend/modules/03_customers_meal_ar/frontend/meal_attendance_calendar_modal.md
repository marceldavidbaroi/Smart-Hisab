# Modal: Meal Attendance Calendar Audit

## 1. Description
Interactive monthly calendar sheet displaying meal punch history per customer across each calendar day and shift.

* **Dart File**: [meal_attendance_calendar_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/meal_attendance_calendar_bottom_sheet.dart)

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Change Month** | Tap Next/Previous Month | Queries attendance records for that month. |
| **Inspect Day** | Tap Day Cell on Calendar | Expands list of meals taken on that date with rate snapshots. |

---

## 3. APIs Used

### Read: Fetch Customer Attendance
* **Method**: Supabase query
* **Query**:
```dart
final records = await supabase
    .from('meal_attendance')
    .select('*, shifts(*)')
    .eq('customer_id', customerId)
    .gte('meal_date', startDate)
    .lte('meal_date', endDate)
    .order('meal_date', ascending: true);
```
* **Output Response**:
```json
[
  {
    "id": "att-1",
    "meal_date": "2026-08-21",
    "rate": 60.00,
    "is_voided": false,
    "shifts": {
      "name": "Lunch"
    }
  }
]
```
