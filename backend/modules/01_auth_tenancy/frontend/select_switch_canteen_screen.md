# Screen: Select & Switch Canteen

## 1. Description
Allows multi-canteen owners or multi-tenant staff to view all canteens they belong to and switch the active working tenant.

* **Dart Files**: [select_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/select_canteen_screen.dart), [switch_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/switch_canteen_screen.dart)
* **Riverpod Provider**: `authNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Switch Active Canteen** | Tap on canteen card | Switches active tenant in local cache and re-roots to `HomeScreen`. |
| **Create New Canteen** | Tap "Add Another Canteen" | Navigates to `CreateCanteenScreen`. |

---

## 3. APIs Used

### Read: Fetch Memberships
* **Method**: Supabase query
* **Query**:
```dart
final res = await supabase
    .from('tenant_members')
    .select('id, role, is_active, tenants(*)')
    .eq('user_id', currentUserId)
    .eq('is_active', true);
```
* **Output Response**:
```json
[
  {
    "id": "mem-1",
    "role": "owner",
    "tenants": {
      "id": "tenant-1",
      "name": "Branch 1 - Dhanmondi",
      "currency": "BDT"
    }
  },
  {
    "id": "mem-2",
    "role": "manager",
    "tenants": {
      "id": "tenant-2",
      "name": "Branch 2 - Gulshan",
      "currency": "BDT"
    }
  }
]
```
* **Target Local Cache Mutation**: Updates Hive active tenant ID; refreshes app state providers.
