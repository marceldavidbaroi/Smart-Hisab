# Screen: Invite Manager & Staff

## 1. Description
Enables owners and managers to generate temporary 6-digit alphanumeric invite codes with custom roles (`manager` or `staff`) to onboard team members without sharing passwords.

* **Dart File**: [invite_manager_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/invite_manager_screen.dart)
* **Riverpod Provider**: `inviteManagerNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Generate Code** | Select Role (`manager` / `staff`) & tap "Generate Code" | Invokes `generate_invite_code` RPC, displays large 6-digit code. |
| **Copy Code** | Tap "Copy Code" button | Copies 6-digit string to clipboard with snackbar alert. |
| **Share WhatsApp / SMS** | Tap "Share Invite" button | Opens native system share sheet with join link/code. |

---

## 3. APIs Used

### Mutation RPC: `generate_invite_code`
* **Method**: `supabase.rpc('generate_invite_code', params: {...})`
* **Input Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_role": "manager"
}
```
* **Output Response**:
```json
{
  "success": true,
  "invite_code": "HG78K9",
  "expires_at": "2026-08-28T15:00:00Z",
  "role": "manager"
}
```
* **Target Local Cache Mutation**: Displays generated code and expiration timestamp in UI state.
