# Module 01: Auth & Multi-Tenancy (`auth_tenancy`)

## 1. Domain & Scope
The **Auth & Multi-Tenancy** module handles user profile registration, tenant creation (canteen instances), role-based team management (`owner`, `manager`, `staff`), 6-digit invite codes, and account deletion.

---

## 2. Table Schema Dictionary

| Table | Primary Key | Description |
| :--- | :--- | :--- |
| `user_profiles` | `id` (UUID -> `auth.users`) | Extended user metadata (name, email, phone, superadmin flag). |
| `tenants` | `id` (UUID) | Canteen organization profile (name, currency, address, phone). |
| `tenant_members` | `id` (UUID) | Maps users to canteens with role (`owner`, `manager`, `staff`). |
| `tenant_invites` | `id` (UUID) | 6-digit join codes with expiration and multi-use tracking. |

---

## 3. API & RPC Endpoints Summary Table

| Function / RPC | Method | Purpose | Input Payload | Output Response |
| :--- | :--- | :--- | :--- | :--- |
| `create_tenant` | `POST /rpc/create_tenant` | Creates new canteen tenant, assigns current user as owner, seeds default shifts | `{"p_name": "string"}` | `{"success": true, "tenant_id": "uuid", "name": "string", "role": "owner"}` |
| `generate_invite_code` | `POST /rpc/generate_invite_code` | Generates 6-digit code for managers/staff | `{"p_tenant_id": "uuid", "p_role": "manager\|staff"}` | `{"success": true, "invite_code": "string", "expires_at": "timestamptz", "role": "string"}` |
| `join_tenant_by_code` | `POST /rpc/join_tenant_by_code` | Joins canteen by redeeming 6-digit code | `{"p_code": "string"}` | `{"success": true, "tenant_id": "uuid", "tenant_name": "string", "role": "string"}` |
| `leave_canteen` | `POST /rpc/leave_canteen` | Leaves canteen (blocked if sole owner) | `{"p_tenant_id": "uuid"}` | `{"success": true}` |
| `delete_canteen` | `POST /rpc/delete_canteen` | Deletes canteen and cascades all data (owner only) | `{"p_tenant_id": "uuid"}` | `{"success": true}` |
| `delete_user_account` | `POST /rpc/delete_user_account` | Deletes current authenticated user profile & auth record | `{}` | `{"success": true}` |
| `is_tenant_member` | Internal SQL | Checks if caller is active member of tenant | `p_tenant_id UUID` | `BOOLEAN` |
| `is_tenant_owner` | Internal SQL | Checks if caller is active owner of tenant | `p_tenant_id UUID` | `BOOLEAN` |
| `get_my_tenant_ids` | Internal SQL | Non-recursive tenant ID fetcher for RLS | `None` | `SETOF UUID` |

---

## 4. Detailed RPC Reference

### `create_tenant`
* **Triggered by**: [create_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/create_canteen_screen.dart)
* **Payload**:
```json
{
  "p_name": "Dhaka Central Canteen"
}
```
* **Success Response**:
```json
{
  "success": true,
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "name": "Dhaka Central Canteen",
  "role": "owner"
}
```

---

### `generate_invite_code`
* **Triggered by**: [invite_manager_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/invite_manager_screen.dart)
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_role": "manager"
}
```
* **Success Response**:
```json
{
  "success": true,
  "invite_code": "AB89X2",
  "expires_at": "2026-08-28T15:00:00Z",
  "role": "manager"
}
```

---

### `join_tenant_by_code`
* **Triggered by**: [join_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/join_canteen_screen.dart)
* **Payload**:
```json
{
  "p_code": "AB89X2"
}
```
* **Success Response**:
```json
{
  "success": true,
  "tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "tenant_name": "Dhaka Central Canteen",
  "role": "manager"
}
```

---

## 5. Mobile Screens & Consumers
* [splash_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/splash/splash_screen.dart)
* [login_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/login_screen.dart)
* [create_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/create_canteen_screen.dart)
* [join_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/join_canteen_screen.dart)
* [select_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/select_canteen_screen.dart)
* [switch_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/switch_canteen_screen.dart)
* [canteen_profile_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/canteen_profile_screen.dart)
* [invite_manager_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/invite_manager_screen.dart)
* [my_profile_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/my_profile_screen.dart)
