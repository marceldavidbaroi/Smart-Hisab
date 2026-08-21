# Module 01: Auth & Multi-Tenancy (`auth_tenancy`)

## 1. Domain & Scope
The **Auth & Multi-Tenancy** module handles user profile registration, tenant creation (canteen organizations), role-based team management (`owner`, `manager`, `staff`), 6-digit invite codes, and account deletion.

---

## 2. Table Schema Dictionary

| Table | Primary Key | Description |
| :--- | :--- | :--- |
| `user_profiles` | `id` (UUID -> `auth.users`) | Extended user metadata (name, email, phone, superadmin flag). |
| `tenants` | `id` (UUID) | Canteen organization profile (name, currency, address, phone). |
| `tenant_members` | `id` (UUID) | Maps users to canteens with role (`owner`, `manager`, `staff`). |
| `tenant_invites` | `id` (UUID) | 6-digit join codes with expiration and multi-use tracking. |

---

## 3. Screen & Page Wiring Directory

### 📱 `SplashScreen`
* **File**: [splash_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/splash/splash_screen.dart)
* **Riverpod Provider**: `authNotifierProvider`
* **Read APIs**: `supabase.auth.currentSession`, `.from('tenant_members').select('*, tenants(*)')`
* **Intended Actions**: Validates cached auth session. If authenticated, checks tenant memberships. Auto-routes to `AppScaffold` (if active tenant exists), `SelectCanteenScreen` (if multiple), or `OnboardingChoiceScreen` (if none).

---

### 📱 `LoginScreen` & `VerifyEmailScreen`
* **Files**: [login_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/login_screen.dart), [verify_email_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/verify_email_screen.dart)
* **Riverpod Provider**: `authNotifierProvider`
* **Mutation APIs**: `supabase.auth.signInWithOtp(email/phone)`, `supabase.auth.verifyOTP(...)`
* **Intended Actions**: Authenticate user without password via OTP. Syncs `user_profiles` via database trigger.

---

### 📱 `CreateCanteenScreen`
* **File**: [create_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/create_canteen_screen.dart)
* **Riverpod Provider**: `authNotifierProvider`
* **Mutation RPC**: `create_tenant(p_name: "Canteen Name")`
* **Payload**: `{"p_name": "string"}`
* **Response**: `{"success": true, "tenant_id": "uuid", "name": "string", "role": "owner"}`
* **Target Cache Mutation**: Sets newly created tenant ID as active in Hive/Riverpod state; transitions user immediately to `AppScaffold`.

---

### 📱 `JoinCanteenScreen`
* **File**: [join_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/join_canteen_screen.dart)
* **Riverpod Provider**: `authNotifierProvider`
* **Mutation RPC**: `join_tenant_by_code(p_code: "6-digit-code")`
* **Payload**: `{"p_code": "string"}`
* **Response**: `{"success": true, "tenant_id": "uuid", "tenant_name": "string", "role": "manager"}`
* **Target Cache Mutation**: Appends canteen membership to local state and sets as active tenant.

---

### 📱 `InviteManagerScreen`
* **File**: [invite_manager_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/invite_manager_screen.dart)
* **Riverpod Provider**: `inviteManagerNotifierProvider`
* **Mutation RPC**: `generate_invite_code(p_tenant_id, p_role)`
* **Payload**: `{"p_tenant_id": "uuid", "p_role": "manager|staff"}`
* **Response**: `{"success": true, "invite_code": "AB89X2", "expires_at": "...", "role": "manager"}`
* **Intended Actions**: Generates 6-digit code, renders copy-to-clipboard button and WhatsApp/SMS share triggers.

---

### 📱 `MyProfileScreen` & `CanteenActionSheets`
* **Files**: [my_profile_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/my_profile_screen.dart), [canteen_action_sheets.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/widgets/canteen_action_sheets.dart)
* **Mutation RPCs**:
  * `leave_canteen(p_tenant_id)` -> Clears active tenant, routes to `SelectCanteenScreen`.
  * `delete_canteen(p_tenant_id)` -> Clears tenant and all cascades, routes to `SelectCanteenScreen`.
  * `delete_user_account()` -> Signs out, cascades user records, routes to `LandingScreen`.

---

## 4. API & RPC Endpoints Summary Table

| Function / RPC | Method | Purpose | Input Payload | Output Response | Calling Screen / UI |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `create_tenant` | `POST /rpc/create_tenant` | Creates new canteen & sets owner | `{"p_name": "string"}` | `{"success": true, "tenant_id": "uuid"}` | [create_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/create_canteen_screen.dart) |
| `generate_invite_code` | `POST /rpc/generate_invite_code` | Generates 6-digit staff/manager code | `{"p_tenant_id": "uuid", "p_role": "string"}` | `{"success": true, "invite_code": "string"}` | [invite_manager_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/invite_manager_screen.dart) |
| `join_tenant_by_code` | `POST /rpc/join_tenant_by_code` | Redeems invite code to join canteen | `{"p_code": "string"}` | `{"success": true, "tenant_id": "uuid"}` | [join_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/join_canteen_screen.dart) |
| `leave_canteen` | `POST /rpc/leave_canteen` | Leaves canteen (blocked if sole owner) | `{"p_tenant_id": "uuid"}` | `{"success": true}` | [canteen_action_sheets.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/widgets/canteen_action_sheets.dart) |
| `delete_canteen` | `POST /rpc/delete_canteen` | Deletes canteen and cascades all data | `{"p_tenant_id": "uuid"}` | `{"success": true}` | [canteen_action_sheets.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/widgets/canteen_action_sheets.dart) |
| `delete_user_account` | `POST /rpc/delete_user_account` | Deletes user profile & auth account | `{}` | `{"success": true}` | [my_profile_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/my_profile_screen.dart) |
