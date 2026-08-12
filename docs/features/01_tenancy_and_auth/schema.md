# Feature: Tenancy & Auth — Schema

> Tables, triggers, and RLS policies for identity, multi-tenancy, and access control.

---

## Entity Relationship

```text
auth.users (Supabase Auth — Google Sign-In)
 └── user_profiles (auto-created on signup)
      └── tenant_members (user ↔ tenant, role: owner/manager)

tenants
 └── tenant_invites (6-digit manager join codes)
 └── shifts
```

---

## Tables

### `user_profiles`

Auto-created when a user signs up via Google. One-to-one with `auth.users`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, FK → `auth.users(id)` ON DELETE CASCADE | Same as Supabase auth user ID |
| `full_name` | TEXT | NOT NULL | From Google profile |
| `avatar_url` | TEXT | | Google profile photo |
| `is_superadmin` | BOOLEAN | NOT NULL DEFAULT false | Platform admin flag |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Trigger**: `on_auth_user_created` — auto-inserts profile from `raw_user_meta_data`.

---

### `tenants`

Root entity representing a canteen/business.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `name` | TEXT | NOT NULL | Canteen display name |
| `status` | TEXT | NOT NULL DEFAULT 'active', CHECK IN ('active', 'suspended') | |
| `subscription_tier` | TEXT | NOT NULL DEFAULT 'free', CHECK IN ('free', 'pro', 'business') | Freemium tier |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

---

### `tenant_members`

Maps authenticated users (owners/managers) to canteens. A user can belong to multiple tenants.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `user_id` | UUID | NOT NULL, FK → `auth.users(id)` ON DELETE CASCADE | |
| `role` | TEXT | NOT NULL, CHECK IN ('owner', 'manager') | Flat role — no RBAC table |
| `joined_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| **UNIQUE** | | `(tenant_id, user_id)` | One membership per tenant per user |

**Indexes**: `tenant_id`, `user_id`

---

### `tenant_invites`

6-digit join codes for inviting managers. Single-use, 24-hour expiry.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `code` | TEXT | NOT NULL, UNIQUE | 6-digit numeric code |
| `role` | TEXT | NOT NULL DEFAULT 'manager', CHECK IN ('manager') | Role assigned on join |
| `created_by` | UUID | NOT NULL, FK → `auth.users(id)` | Owner who generated the code |
| `expires_at` | TIMESTAMPTZ | NOT NULL | 24 hours from creation |
| `used_by` | UUID | FK → `auth.users(id)` | NULL until redeemed |
| `used_at` | TIMESTAMPTZ | | NULL until redeemed |

---

## RLS Policies

```sql
-- Helper functions
is_tenant_member(p_tenant_id UUID) → BOOLEAN
  SELECT 1 FROM tenant_members WHERE tenant_id = p_tenant_id AND user_id = auth.uid()

is_tenant_owner(p_tenant_id UUID) → BOOLEAN
  SELECT 1 FROM tenant_members WHERE tenant_id = p_tenant_id AND user_id = auth.uid() AND role = 'owner'

is_superadmin() → BOOLEAN
  SELECT 1 FROM user_profiles WHERE id = auth.uid() AND is_superadmin = true
```

| Table | SELECT | INSERT/UPDATE/DELETE |
|---|---|---|
| `user_profiles` | All authenticated users | Own profile only |
| `tenants` | Tenant members | Superadmin only (creation via RPC) |
| `tenant_members` | Tenant members | Owner only (via RPC) |
| `tenant_invites` | Owner only | Owner only (via RPC) |

---

## Triggers

| Trigger | On Table | Event | Action |
|---|---|---|---|
| `on_auth_user_created` | `auth.users` | AFTER INSERT | Auto-create `user_profiles` from Google metadata |
| `set_updated_at` | `user_profiles` | BEFORE UPDATE | Auto-set `updated_at = now()` |
