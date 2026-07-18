# Task Doc: Advance Payment Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)  
SL: **4** — see [SL.md](./SL.md)

**Goal:** Replace the `KioskAdvancePayment` stub with a searchable customer list + dialog that records a payment via existing `record_customer_collection`. Same backend as Baki Payment; UX difference = **all active customers** + **prepaid framing** (negative `outstanding_balance`).

**Balance math (authoritative):**

```
new_outstanding = old_outstanding - amount
```

- `old > 0`, `amount < old` → still due
- `old > 0`, `amount = old` → zero
- `old > 0`, `amount > old` → prepaid (`new < 0`)
- `old ≤ 0`, any `amount > 0` → deeper prepaid

Maintained by trigger `sync_customer_outstanding_balance` on `customer_collections` insert (`v_diff := -NEW.amount`).

---

## Backend contract (read before UI)

### Existing RPC — use this (no new RPC for MVP)

`public.record_customer_collection(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_session_id uuid,          -- required if cash; null OK for non-cash
  p_amount numeric,           -- must be > 0
  p_payment_method text,      -- 'cash' | 'mobile_wallet' | 'bank_transfer'
  p_notes text default null,
  p_device_token text default null,  -- kiosk: required with staff
  p_staff_id uuid default null       -- kiosk: required; workspace: omit
) returns numeric`  -- new `customers.outstanding_balance`

**Source:** `supabase/migrations/20260718163000_meal_customer_management.sql`  
**Kiosk grant:** also granted to `anon` in `20260718180000_kiosk_customer_session_reads.sql`

### Side effects (in order)

1. Permission check: staff → `has_staff_permission(..., 'collections_write')` + valid device/staff; else workspace `has_module_permission(..., 'collections_write')`.
2. If `payment_method = 'cash'`: `p_session_id` required; session must exist and not be `closed`.
3. Insert `customer_collections` → trigger updates `outstanding_balance`.
4. `post_ledger_entry(..., type := 'inflow', category := 'Debt Collection', ...)`.
5. Return updated balance.

There is **no** `amount ≤ outstanding_balance` check. Overpay / pay-when-zero / deepen prepaid all work today.

### Errors to surface in UI

| Condition | Message (approx.) |
| :--- | :--- |
| amount ≤ 0 | Amount must be greater than zero. |
| bad method | Invalid payment method. |
| cash + null session | Session ID is required for cash collections. |
| closed session | Cannot collect cash during a closed operational session. |
| bad device/staff / no perm | Permission denied. / Invalid… |

### List fetch (kiosk)

`list_customers(p_tenant_id, p_device_token, p_staff_id, p_active_only)` — requires **`customer_read`**, not `collections_read`.  
Store: `customersStore.fetchCustomers({ activeOnly: true })` already uses this when kiosk device+staff present.

### Table constraints (relevant)

- `customer_collections.amount > 0`
- Cash ⇒ `session_id not null` (`check_cash_session`)
- Collector: user **or** staff must be set
- Closed-session lock on collections when `session_id` points at a closed session

### RPC gaps (optional Task 0 — recommended)

Current RPC does **not** verify `p_customer_id` belongs to `p_tenant_id` or `is_active`. Harden in a small migration (shared with Baki Payment):

```sql
-- Pseudocode to add near top of record_customer_collection body
if not exists (
  select 1 from public.customers
  where id = p_customer_id and tenant_id = p_tenant_id and is_active = true
) then
  raise exception 'Customer not found or inactive.' using errcode = 'P0002';
end if;
```

**Out of scope for MVP:** new ledger category (`Customer Advance`), new table, amount-cap vs due, separate `record_customer_advance` wrapper.

---

## Task 0 — Harden `record_customer_collection` (optional but preferred)

| In | Out |
| :--- | :--- |
| Migration: tenant + active customer check | New RPC name |
| Same signature / return / ledger category | Ledger category split |

Acceptance: inactive / wrong-tenant customer → clear error; advance + baki payment both benefit.

---

## Task 1 — Advance Payment Page (MVP)

### Scope

| In | Out |
| :--- | :--- |
| Rewrite `KioskAdvancePayment.vue` stub | New collection RPC / schema |
| New `AdvancePaymentDialog.vue` | Merge with Baki Payment page |
| Wire `customersStore.recordCollection` (existing) | Staff salary advances |
| Patch local `outstanding_balance` from RPC return | Why owed? (later / reuse Baki Payment) |
| Fix StaffWorkspace session gate for this tile (non-cash) | Caps amount ≤ due |
| Route meta: meal-management feature gate | Workspace-only advance page |
| i18n `en-US` + `bn` | |

### Entry point

1. StaffWorkspace tile **Advance Payment** → `kiosk-advance-payment` (already).
2. **Change:** do **not** block navigation solely because session is closed.  
   Today `goToAdvancePayment` uses `isActionBlocked` (no open session) — that wrongly blocks **non-cash** advances.
   - Allow navigate always (when meal module on).
   - On page: banner if no session; disable **cash** submit only; allow `mobile_wallet` / `bank_transfer` without session.

**Do not change the navigation target.** Replace the stub page + add dialog; fix the session gate on the tile.

### UI Blueprint

#### 1. Main view (`KioskAdvancePayment.vue`) — same layout as Attendance / Baki Payment

```
[Top Bar]
  - Back → StaffWorkspace
  - Title: "Advance Payment" / "অগ্রিম পেমেন্ট"

[Banner]
  - No open session → cash advances disabled (non-cash OK)

[Action Row]
  - Search: "Search by name or phone..." (live filter)

[Main Content: vertical list]
  For each active customer:
  +--------------------------------------------------+
  | Name / Phone / Institution (factory_unit)        |
  | Balance chip (due OR prepaid)                    |
  | [💳 Record Advance]                              |
  +--------------------------------------------------+
```

- List: **all** active customers (`contract_worker` + `walk_in_baki`) — not dues-only (unlike Baki Payment).
- Load: `fetchCustomers({ activeOnly: true })` on mount.
- Search: client-side match on `full_name` (case-insensitive) and `phone` digits.
- Balance chip: reuse `OutstandingBalanceChip` (positive = due / negative = prepaid).
- **Record Advance** disabled when staff lacks `collections_write`; for **cash**, also require open operational session.
- Show session-missing banner when cash write is blocked by missing session.
- Card CTA full-width on `xs` (≥ 48px).

#### 2. Dialog (`AdvancePaymentDialog.vue`)

Triggered by **Record Advance** on a card (customer preselected).

| Block | Spec |
| :--- | :--- |
| Header | Display: **Name:** {name} \| **Phone:** {phone}; close (X) |
| Current balance | `OutstandingBalanceChip` + `formatMoney` (prominent) |
| Hint | Short caption: amount above due becomes prepaid credit |
| Payment amount | Numeric (Tk), required, `> 0`; `inputmode="decimal"` |
| Method | Required: `cash` \| `bank_transfer` \| `mobile_wallet` (match collection options) |
| Notes | Optional (e.g. “July advance”) |
| Footer | Cancel \| Save |

**Props** (mirror CollectionDialog kiosk wiring):

```ts
modelValue: boolean
customer: Customer  // required preselected
sessionId?: string | null
deviceToken?: string | null
staffId?: string | null
```

**Do not** wrap dialog in `v-if="activeSession"` (CollectionDialog on StaffWorkspace does — bad for non-cash).

**No “Pay full due” quick-fill required** (that belongs on Baki Payment). Optional later: suggest amount that zeros the balance.

#### 3. Submit logic (exact)

```ts
const sessionId =
  form.paymentMethod === 'cash'
    ? sessionStore.activeSession?.id ?? null
    : null; // non-cash may omit session

if (form.paymentMethod === 'cash' && !sessionId) {
  // block + showWarning — match RPC
  return;
}

const newBalance = await customersStore.recordCollection({
  customerId: customer.id,
  sessionId,
  amount: form.amount,
  paymentMethod: form.paymentMethod,
  notes: form.notes || undefined,
  deviceToken: kioskStore.deviceToken,
  staffId: kioskStore.currentStaff?.id,
});

// Patch store (RPC returns numeric)
const row = customersStore.customers.find((c) => c.id === customer.id);
if (row) row.outstanding_balance = newBalance;

showSuccess(...);
// close dialog
```

Store already calls:

```ts
supabase.rpc('record_customer_collection', {
  p_tenant_id,
  p_customer_id,
  p_session_id,
  p_amount,
  p_payment_method,
  p_notes,
  p_device_token,
  p_staff_id,
});
```

On failure: `showApiError`; keep dialog open.

Same RPC as Baki Payment — product split is UX (all customers + prepaid framing), not a new backend path.

### Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | meal-management feature + staff `customer_read` (via `list_customers`) |
| Record Advance / submit | staff `collections_write`; cash also needs open operational session |
| Route meta | Add `requiredFeature: 'meal-management'` on `kiosk-advance-payment` (missing today). Staff permission checks stay in-page like other kiosk floor pages. |
| Feature off | Existing / updated route guard redirect |

### Files to touch

| File | Action |
| :--- | :--- |
| `supabase/migrations/…_harden_record_customer_collection.sql` | Optional Task 0 |
| `web/src/pages/kiosk/KioskAdvancePayment.vue` | Rewrite stub → list + search + dialog open |
| `web/src/components/customers/AdvancePaymentDialog.vue` | Create |
| `web/src/components/customers/OutstandingBalanceChip.vue` | Reuse on cards |
| `web/src/stores/customers.ts` | Reuse `recordCollection` / `fetchCustomers`; optional `patchBalance(id, n)` helper |
| `web/src/pages/kiosk/StaffWorkspace.vue` | Fix `goToAdvancePayment` — don’t require session to open page |
| `web/src/router/routes.ts` | Add `requiredFeature: 'meal-management'` |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | Page + dialog + banner keys; drop coming-soon |

### Acceptance checklist

- [ ] Stub gone; list of all active customers + search.
- [ ] Chip shows due vs prepaid correctly.
- [ ] Save → `record_customer_collection`; row balance patches from return value.
- [ ] Pay more than due → prepaid (negative balance) without RPC error.
- [ ] Pay when balance already ≤ 0 → deeper prepaid.
- [ ] Cash without session → blocked in UI; RPC would also fail.
- [ ] Non-cash works with **no** open session (tile + page + dialog).
- [ ] Kiosk passes `deviceToken` + `staffId`.
- [ ] Ledger gets inflow `Debt Collection` for the amount (verify in session ledger if cash/session present).
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialog usable on phone.
- [ ] `en-US` + `bn` strings present.
- [ ] (If Task 0) inactive / wrong-tenant customer rejected.

### Backend note (MVP)

| Need new? | Item |
| :--- | :--- |
| No | `record_customer_collection` |
| No | Balance trigger / prepaid semantics |
| No | Ledger category (keep `Debt Collection`) |
| Optional | Customer tenant/active guard on existing RPC (Task 0) |
| Later | Separate category / `record_customer_advance` only if reporting needs it |

---

## Later tasks (not in Task 1)

| Task | Summary |
| :--- | :--- |
| Task 2 | Reuse Why owed? / `CustomerOwedBreakdownDialog` from [baki_payment_page.md](./baki_payment_page.md) |
| Task 3 | Live preview of post-save balance in dialog |
| Task 4 | Quick-fill “Clear due only” vs free advance amount |
| Task 5 | Unify with Baki Payment (Due / Prepaid tabs) — see Baki Payment Task 5 |
| Task 6 | Optional ledger category `Customer Advance` + thin RPC wrapper |

---

## Related

- Parent module RFC: [meal_customer_management.md](../meal_customer_management.md) (`record_customer_collection`, negative balance = prepaid)
- Sibling tasks: [customer_attendance_page.md](./customer_attendance_page.md), [baki_charge_page.md](./baki_charge_page.md), [baki_payment_page.md](./baki_payment_page.md)
- Migrations: `20260718163000_meal_customer_management.sql`, `20260718180000_kiosk_customer_session_reads.sql`
- Master summary: [master_specifications.md](../master_specifications.md) §5
