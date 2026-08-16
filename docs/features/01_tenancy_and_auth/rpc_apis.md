# Feature: Tenancy & Auth — RPC / APIs

> RPC functions for tenant creation, manager invitation, and staff PIN authentication.

---

## `create_tenant`

Self-service canteen creation.

| | |
|---|---|
| **Parameters** | `p_name TEXT` |
| **Returns** | `UUID` (new tenant ID) |
| **Side effects** | Creates `tenant` + `tenant_member` (role: `owner`) |
| **Auth** | Requires `auth.uid()` |

---

## `generate_invite_code`

Owner generates a 6-digit join code valid for 24 hours.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_role TEXT DEFAULT 'manager'` |
| **Returns** | `TEXT` (6-digit code) |
| **Side effects** | Inserts into `tenant_invites` |
| **Auth** | Owner of `p_tenant_id` only |

---

## `join_tenant_by_code`

Manager joins a canteen using a 6-digit invite code.

| | |
|---|---|
| **Parameters** | `p_code TEXT` |
| **Returns** | `JSON` (tenant info + role) |
| **Side effects** | Validates code, checks expiry, creates `tenant_member`, marks code as used |
| **Auth** | Requires `auth.uid()` |
| **Errors** | `INVALID_CODE`, `CODE_EXPIRED`, `CODE_ALREADY_USED` |

---

## `verify_staff_pin`

Authenticates a counter staff member by PIN. Used at the PIN Gate screen.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_pin TEXT` |
| **Returns** | `JSONB` → `{ staff_id, full_name, role }` or error |
| **Logic** | Loops active staff with `allow_terminal_login = true`. Checks `temp_pin` first, then `hashed_pin` (bcrypt) |
| **Auth** | No `auth.uid()` required — unauthenticated RPC (called from counter device) |

---

## `set_staff_pin`

Staff converts a temporary PIN to a private bcrypt-hashed PIN.

| | |
|---|---|
| **Parameters** | `p_staff_id UUID`, `p_temp_pin TEXT`, `p_new_pin TEXT` |
| **Returns** | `BOOLEAN` |
| **Side effects** | Clears `temp_pin`, sets `hashed_pin` |

---

## `reset_staff_pin`

Owner/Manager generates a new temporary PIN for a staff member.

| | |
|---|---|
| **Parameters** | `p_staff_id UUID` |
| **Returns** | `TEXT` (new temp PIN — shown once) |
| **Side effects** | Overwrites `temp_pin`, clears `hashed_pin` |
| **Auth** | Owner or Manager of the tenant |
