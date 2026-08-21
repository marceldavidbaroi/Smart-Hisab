# Screen: Splash & Session Verification

## 1. Description
Initial entry screen of the application. It checks existing auth tokens, verifies user profile status in `user_profiles`, loads tenant memberships, and routes the user to the appropriate screen.

* **Dart File**: [splash_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/splash/splash_screen.dart)
* **Riverpod Provider**: `authNotifierProvider`

---

## 2. User Actions & Routing
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Session Verification** | App Launch (`initState`) | Checks auth token. If valid and has active tenant -> routes to `HomeScreen`. If valid but no tenant -> routes to `OnboardingChoiceScreen`. If unauthenticated -> routes to `LandingScreen`. |

---

## 3. APIs Used

### Read: Fetch Active Session & Tenant Memberships
* **Method**: `supabase.auth.currentSession` + Supabase query
* **Query**:
```dart
final user = supabase.auth.currentUser;
final memberships = await supabase
    .from('tenant_members')
    .select('*, tenants(*)')
    .eq('user_id', user.id)
    .eq('is_active', true);
```
* **Response**:
```json
[
  {
    "id": "mem-uuid-1",
    "tenant_id": "tenant-uuid-1",
    "role": "owner",
    "tenants": {
      "id": "tenant-uuid-1",
      "name": "Dhaka Central Canteen",
      "currency": "BDT"
    }
  }
]
```
* **Local State Mutation**: Caches active tenant in Hive and sets `authNotifierProvider` state.
