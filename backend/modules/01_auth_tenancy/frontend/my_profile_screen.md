# Screen: My Profile & Danger Zone

## 1. Description
Displays user profile information, app theme toggles, Bengali/English language selection, logout trigger, and danger zone actions (Leave Canteen, Delete Canteen, Delete Account).

* **Dart Files**: [my_profile_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/my_profile_screen.dart), [canteen_action_sheets.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/widgets/canteen_action_sheets.dart)
* **Riverpod Providers**: `authNotifierProvider`, `themeNotifierProvider`, `localeNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Toggle Language** | Tap Bengali / English switch | Updates `localeNotifierProvider` and persists in Hive. |
| **Toggle Theme** | Tap Dark / Light mode switch | Updates `themeNotifierProvider` and persists in Hive. |
| **Logout** | Tap "Log Out" button | Clears session, clears local storage, routes to `LandingScreen`. |
| **Leave Canteen** | Tap "Leave Canteen" in modal | Calls `leave_canteen` RPC, switches to next available canteen. |
| **Delete Canteen** | Tap "Delete Canteen" (Owner) | Calls `delete_canteen` RPC, deletes organization data. |
| **Delete Account** | Tap "Delete Account" | Calls `delete_user_account` RPC, purges user profile. |

---

## 3. APIs Used

### 1. Leave Canteen RPC: `leave_canteen`
* **Method**: `supabase.rpc('leave_canteen', params: {'p_tenant_id': 'uuid'})`
* **Output Response**: `{"success": true}`

### 2. Delete Canteen RPC: `delete_canteen`
* **Method**: `supabase.rpc('delete_canteen', params: {'p_tenant_id': 'uuid'})`
* **Output Response**: `{"success": true}`

### 3. Delete Account RPC: `delete_user_account`
* **Method**: `supabase.rpc('delete_user_account')`
* **Output Response**: `{"success": true}`
