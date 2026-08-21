# Screen: Meal Configurations & Form

## 1. Description
Manage canteen meal types, default pricing rates per shift (e.g. Standard Lunch 60 BDT, VIP Dinner 120 BDT), and auto-punch schedules.

* **Dart Files**: [meal_configs_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/meal_configs_screen.dart), [meal_config_form_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/meal_config_form_bottom_sheet.dart)
* **Riverpod Provider**: `mealConfigsNotifierProvider` (`AsyncNotifier<List<MealConfig>>`)

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **View Meal Types** | Open Screen | Lists meal configurations grouped by shift. |
| **Add / Edit Meal Rate** | Submit `MealConfigFormBottomSheet` | Upserts meal config in `meal_configs` table. |
| **Toggle Active** | Tap Switch | Updates `is_active` boolean. |

---

## 3. APIs Used

### 1. Read: Fetch Meal Configs
* **Method**: Supabase query
* **Query**: `.from('meal_configs').select('*, shifts(*)').eq('tenant_id', tenantId)`
* **Response**:
```json
[
  {
    "id": "cfg-1",
    "meal_name": "Standard Lunch",
    "default_rate": 60.00,
    "is_active": true,
    "shifts": { "name": "Lunch" }
  }
]
```

### 2. Mutation: Upsert Meal Config
* **Method**: `.from('meal_configs').upsert({...})`
* **Target Local Cache Mutation**: Updates item in `mealConfigsNotifierProvider` without full refetch.
