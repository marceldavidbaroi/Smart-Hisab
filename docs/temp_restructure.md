# IMPLEMENT BRIEF — kiosk Manager customer CRUD

> Agent: execute **all steps below in order**. Do not expand scope. Do not edit docs except delete this file at end. Reuse existing patterns; no new packages.

**Done when:** Manager on `StaffWorkspace` can create/edit customers via RPC; Cashier cannot (`customer_write` false).

---

## 1. Migration (new file)

`supabase/migrations/20260718170000_manager_customer_upsert.sql`

```sql
-- Manager gets customer_write; Cashier stays false
update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "customer_write": true, "attendance_read": true, "attendance_write": true, "baki_read": true, "baki_write": true, "collections_read": true, "collections_write": true}'::jsonb
)
where name = 'Manager';

update public.staff_roles
set permissions = jsonb_set(
  permissions,
  '{modules,meal_management}',
  '{"customer_read": true, "customer_write": false, "attendance_read": true, "attendance_write": true, "baki_read": true, "baki_write": true, "collections_read": true, "collections_write": true}'::jsonb
)
where name = 'Cashier';

-- upsert_customer: copy device/staff validation from record_baki_transaction;
-- require has_staff_permission(..., 'customer_write') when p_staff_id set,
-- else has_module_permission(..., 'customer_write');
-- insert or update customers by p_id; never touch outstanding_balance;
-- returns setof customers (or single row).
-- grant execute to authenticated (same as other meal RPCs).
```

Implement full PL/pgSQL by **cloning** `record_baki_transaction` auth block from `supabase/migrations/20260718163000_meal_customer_management.sql` (~L359–385), swap permission key to `customer_write`, then insert/update.

Signature:
`upsert_customer(p_tenant_id uuid, p_full_name text, p_category text, p_phone text, p_contract_daily_rate numeric, p_contract_shifts text[], p_factory_unit text, p_is_active boolean, p_id uuid default null, p_device_token text default null, p_staff_id uuid default null) returns public.customers`

---

## 2. Types (minimal)

`web/src/types/supabase.ts` — add `upsert_customer` under `Functions` only (match other meal RPC entries). Skip full regen unless broken.

---

## 3. Form dialog (one file)

`web/src/components/customers/CustomerFormDialog.vue`

- Add optional props: `deviceToken?: string | null`, `staffId?: string | null`
- In save (~L248–251): if `deviceToken && staffId` → `supabase.rpc('upsert_customer', {…})`; else keep `.insert`/`.update`
- Keep `emit('saved')` on success

---

## 4. Kiosk page (one file)

`web/src/pages/kiosk/StaffWorkspace.vue`

Mirror baki tile:

- `canWriteCustomers = hasStaffPermission('meal_management', 'customer_write')`
- Tile `v-if="isMealManagementEnabled && canReadCustomers"` → opens sheet
- Sheet: `q-list` of `customersStore.customers`; Create if `canWriteCustomers`; row→edit if write
- `CustomerFormDialog` with `:device-token="kioskStore.deviceToken"` `:staff-id="kioskStore.currentStaff?.id"` `@saved="fetchCustomers({ activeOnly: true })"`
- No open-session gate
- Do not touch attendance/baki/collection blocks
- Prefer inline `q-dialog`+`q-list` — **no new component file**

---

## 5. i18n (two files)

`web/src/i18n/en-US/index.ts` + `bn/index.ts` — under `kioskUI.workspace.actions`:

```
customers: { title, desc }
```

Wire `$t` in StaffWorkspace. Minimal keys only.

---

## 6. Stop

Delete this file. Do not edit workspace pages/nav/other docs. No QA suite. No README.

## Out of scope

meal-plan catalog · merge Manager→tenant_members · remove WorkspaceCustomers · Cashier customer_write
