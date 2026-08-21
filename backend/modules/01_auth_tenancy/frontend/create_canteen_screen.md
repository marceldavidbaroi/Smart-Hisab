# Screen: Create Canteen

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `CreateCanteenScreen`
* **Dart Source File**: [create_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/create_canteen_screen.dart)
* **Parent / Hosting Shell**: Pushed from [onboarding_choice_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/onboarding_choice_screen.dart) (`OnboardingChoiceScreen`)

---

## 2. Initial Load & Riverpod State

### Riverpod State
* **Provider Name**: `authNotifierProvider`
* **Type**: `Notifier<AuthState>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Create Canteen** | Tap "Create Canteen" button | `createTenant(name)` | `create_tenant` | Stores new tenant ID in Hive; transitions to `AppScaffold`. |

---

## 4. Complete API & RPC Specifications

### `create_tenant`
* **Method**: `supabase.rpc('create_tenant', params: {'p_name': 'Dhaka Central Canteen'})`
* **Response**:
```json
{
  "success": true,
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "name": "Dhaka Central Canteen",
  "role": "owner"
}
```
