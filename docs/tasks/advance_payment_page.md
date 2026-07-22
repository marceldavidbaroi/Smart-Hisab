# Task Doc: Advance Payment Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)  
SL: **4** — see [SL.md](./SL.md)

**Goal:** Replace the `KioskAdvancePayment` stub with a searchable **all-active-customers** list + dialog that records payment via existing `record_customer_collection`. Same backend as Baki Payment; UX difference = all customers + **prepaid framing** (negative `outstanding_balance`).

**Reference implementation:** Clone `KioskAttendance.vue` / Baki Payment page shell. Form patterns from `CollectionDialog.vue`. Balance chip: `OutstandingBalanceChip.vue`.

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

1. Permission: staff → `has_staff_permission(..., 'collections_write')` + valid device/staff; else workspace `has_module_permission(..., 'collections_write')`.
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

`list_customers(..., p_active_only)` — requires **`customer_read`**, not `collections_read`.  
Store: `customersStore.fetchCustomers({ activeOnly: true })` when kiosk device+staff present.

### Table constraints (relevant)

- `customer_collections.amount > 0`
- Cash ⇒ `session_id not null` (`check_cash_session`)
- Collector: user **or** staff must be set
- Closed-session lock when `session_id` points at a closed session

### RPC gaps (optional Step 0)

Current RPC does **not** verify `p_customer_id` belongs to `p_tenant_id` or `is_active`. Harden in a small migration (shared with Baki Payment):

```sql
-- Pseudocode near top of record_customer_collection body
if not exists (
  select 1 from public.customers
  where id = p_customer_id and tenant_id = p_tenant_id and is_active = true
) then
  raise exception 'Customer not found or inactive.' using errcode = 'P0002';
end if;
```

**Out of scope for MVP:** new ledger category (`Customer Advance`), new table, amount-cap vs due, separate `record_customer_advance` wrapper.

---

## Scope (Task 1)

| In | Out |
| :--- | :--- |
| Rewrite `KioskAdvancePayment.vue` stub | New collection RPC / schema |
| New `AdvancePaymentDialog.vue` | Merge with Baki Payment page |
| Wire `customersStore.recordCollection` (existing) | Staff salary advances |
| Patch local `outstanding_balance` from RPC return | Why owed? (reuse Baki Payment later) |
| Fix StaffWorkspace session gate for this tile (non-cash) | Caps amount ≤ due |
| Route meta: meal-management feature gate | Workspace-only advance page |
| i18n `en-US` + `bn` | |

---

## Implementation steps (do in order)

> Each step is independently shippable/testable. Do **not** skip ahead. Finish a step’s Done criteria before the next.

### Step 0 — Harden `record_customer_collection` (optional but preferred)

**File:** new migration under `supabase/migrations/`

**Do:**

1. Add tenant + active customer check (pseudocode above).
2. Keep same signature / return / ledger category `Debt Collection`.

**Done when:** Inactive / wrong-tenant customer → clear RPC error; Baki Payment + Advance both benefit.

*Skip if deferring backend; UI steps still work without it.*

---

### Step 1 — i18n keys (`en-US` + `bn`)

**Files:** `web/src/i18n/en-US/index.ts`, `web/src/i18n/bn/index.ts`

**Do:**

1. Add page keys under `customers.advancePayment` (do not overload `kioskUI.workspace.actions.advancePayment` coming-soon strings for the page body):

```
customers.advancePayment
  title, subtitle, searchPlaceholder, empty
  noSessionWarning          // cash disabled; non-cash OK
  recordAdvanceBtn
  dialog
    title, name, phone
    currentBalance, prepaidHint   // amount above due → prepaid credit
    amount, paymentMethod, notes
    cancelBtn, saveBtn, success
    amountRequired, amountMin, paymentMethodRequired
    sessionRequiredCash
  errors
    loadFailed, …
```

2. Reuse `customers.collections.methods.*` for method labels (or mirror under `advancePayment.dialog.methods` — one tree only).
3. Mirror every key in **bn** in the same turn.
4. After page ships, coming-soon keys under `kioskUI.workspace.actions.advancePayment` can be pruned if unused (Step 7).

**Done when:** Key trees match `en-US` ↔ `bn`; no hardcoded page/dialog strings planned.

---

### Step 2 — Route meta + stub readiness

**Files:** `web/src/router/routes.ts`, existing `KioskAdvancePayment.vue`

**Do:**

1. Route `kiosk-advance-payment` already exists — **do not change the name**.
2. Add `requiredFeature: 'meal-management'` if missing.
3. Keep path/component; replace stub body in Step 3 (or leave a minimal title+back shell now).

**Done when:** Feature gate matches other meal kiosk pages; route still resolves.

---

### Step 3 — Page shell: all customers + search (`KioskAdvancePayment.vue`)

**File:** `web/src/pages/kiosk/KioskAdvancePayment.vue`  
**Clone from:** `KioskAttendance.vue` / Baki Payment page (when available)

**UI:**

```
[Top Bar] Back → StaffWorkspace | Title from $t('customers.advancePayment.title')
[Banner]  No open session → cash advances disabled (non-cash OK)
[Search]  live filter
[List]    ALL active customers (contract_worker + walk_in_baki) — not dues-only
          Name / Phone / Institution
          Balance chip (due OR prepaid via OutstandingBalanceChip)
          [Record Advance]
```

**Do:**

1. `fetchCustomers({ activeOnly: true })` on mount — **no** `outstanding_balance > 0` filter (unlike Baki Payment).
2. Client-side search on `full_name` (case-insensitive) + `phone` digits.
3. Balance chip: `OutstandingBalanceChip` (positive = due / negative = prepaid).
4. Gate **Record Advance**: needs `collections_write`; **cash** also needs open session.
5. Session-missing banner when cash is blocked; page still usable for non-cash.
6. All strings via `$t('customers.advancePayment.*')`.
7. Mobile-first: full-width CTA on `xs` (≥ 48px); no horizontal scroll.

**Do not** build the dialog yet — button can be a no-op until Steps 4–5.

**Done when:** Lists all active customers; search works; prepaid and due chips both visible; banner when no session.

---

### Step 4 — Dialog UI + reset (`AdvancePaymentDialog.vue`)

**File:** `web/src/components/customers/AdvancePaymentDialog.vue` (new)  
**Clone patterns from:** `CollectionDialog.vue`, Baki Payment dialog if already built

**Props:**

```ts
modelValue: boolean
customer: Customer  // required preselected
sessionId?: string | null
deviceToken?: string | null
staffId?: string | null
```

**Do not** wrap dialog in `v-if="activeSession"` (StaffWorkspace CollectionDialog does — bad for non-cash).

**UI blocks:**

| Block | Spec |
| :--- | :--- |
| Header | Name + phone; close (X) |
| Current balance | `OutstandingBalanceChip` + `formatMoney` (prominent) |
| Hint | Caption: amount above due becomes prepaid credit |
| Amount | Numeric Tk, required, `> 0`; `inputmode="decimal"` |
| Method | Required: cash \| bank_transfer \| mobile_wallet |
| Notes | Optional (e.g. “July advance”) |
| Footer | Cancel \| Save |

**No “Pay full due” required** (that belongs on Baki Payment).

**Reset (required) — implement in this step:**

```ts
function resetForm() {
  // amount → null
  // paymentMethod → '' or default
  // notes → ''
  // saving → false
  // clear validation state
}
```

| Trigger | Action |
| :--- | :--- |
| Dialog opens | `watch(isOpen)` → `true` → `resetForm()` |
| Save success | `resetForm()` then close |
| Cancel / X / hide | `@hide` or `watch(isOpen)` → `false` → `resetForm()` |
| Save failure | **Do not** reset — keep edits |

**Done when:** Open/cancel/reopen is clean; balance display updates per customer.

---

### Step 5 — Submit logic + wire dialog to page

**Files:** `AdvancePaymentDialog.vue`, `KioskAdvancePayment.vue`, reuse `customersStore.recordCollection`

**Submit sequence (exact):**

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

const row = customersStore.customers.find((c) => c.id === customer.id);
if (row) row.outstanding_balance = newBalance;

resetForm();
close;
showSuccess(t('customers.advancePayment.dialog.success'));
```

1. Validate amount > 0 + method; cash ⇒ open session.
2. Overpay / pay-when-zero / deepen prepaid must succeed (no client-side cap vs due).
3. On failure: `showApiError`; keep dialog open (**no** reset).

**Wire page:** `selectedCustomer` + `showDialog`; **Record Advance** opens dialog; `@saved` patches chip.

Same RPC as Baki Payment — product split is UX only.

**Done when:** Prepaid math works in UI; cash blocked without session; non-cash works with no session; failed save keeps edits.

---

### Step 6 — StaffWorkspace entry point (session gate fix)

**File:** `web/src/pages/kiosk/StaffWorkspace.vue`

**Do:**

1. Keep tile **Advance Payment** → `kiosk-advance-payment` (already).
2. **Fix:** `goToAdvancePayment` must **not** block navigation solely because session is closed (`isActionBlocked` wrongly blocks non-cash advances today).
   - Allow navigate whenever meal module is on (and tile permission allows).
   - Page/dialog enforce cash-only session requirement.
3. Do not change the route name.

**Done when:** Tap Advance Payment with **no** open session still opens the page; cash submit remains blocked on page/dialog.

---

### Step 7 — Cleanup

**Do:**

1. Remove coming-soon body from `KioskAdvancePayment.vue` (already replaced in Step 3).
2. Prune unused `kioskUI.workspace.actions.advancePayment.comingSoon*` keys if nothing references them.
3. No deletion of `CollectionDialog` (workspace still uses it).

**Done when:** No stub/coming-soon UI on the advance page; both locales cleaned if keys removed.

---

### Step 8 — Acceptance pass

Verify against checklist below. Fix gaps before marking Task 1 complete.

---

## Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | meal-management feature + staff `customer_read` (via `list_customers`) |
| Record Advance / submit | staff `collections_write`; cash also needs open operational session |
| Route meta | `requiredFeature: 'meal-management'` on `kiosk-advance-payment` |
| Feature off | Existing / updated route guard redirect |

---

## Files to touch (summary)

| File | Step | Action |
| :--- | :--- | :--- |
| `supabase/migrations/…_harden_record_customer_collection.sql` | 0 | Optional tenant/active check |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | 1, 7 | `customers.advancePayment`; prune coming-soon |
| `web/src/router/routes.ts` | 2 | Add `requiredFeature` if missing |
| `web/src/pages/kiosk/KioskAdvancePayment.vue` | 2–3, 5 | Rewrite stub → list + dialog open |
| `web/src/components/customers/AdvancePaymentDialog.vue` | 4–5 | Create |
| `web/src/components/customers/OutstandingBalanceChip.vue` | 3–4 | Reuse |
| `web/src/stores/customers.ts` | 5 | Reuse `recordCollection` / `fetchCustomers` |
| `web/src/pages/kiosk/StaffWorkspace.vue` | 6 | Fix session gate on navigate |

---

## Acceptance checklist

- [ ] Stub gone; list of all active customers + search.
- [ ] Chip shows due vs prepaid correctly.
- [ ] Save → `record_customer_collection`; row balance patches from return value.
- [ ] Pay more than due → prepaid (negative balance) without RPC error.
- [ ] Pay when balance already ≤ 0 → deeper prepaid.
- [ ] Cash without session → blocked in UI; RPC would also fail.
- [ ] Non-cash works with **no** open session (tile + page + dialog).
- [ ] Tile navigate works with no open session (Step 6 gate fix).
- [ ] Save success → toast + form reset + close.
- [ ] Cancel / close → form resets (no stale amount/method on next open).
- [ ] Failed save → dialog stays open with edits intact.
- [ ] Kiosk passes `deviceToken` + `staffId`.
- [ ] Ledger gets inflow `Debt Collection` (verify when cash/session present).
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialog usable on phone.
- [ ] All UI strings via `$t` / `t`; `en-US` + `bn` mirrored under `customers.advancePayment`.
- [ ] (If Step 0) inactive / wrong-tenant customer rejected.

---

## Backend note (MVP)

| Need new? | Item |
| :--- | :--- |
| No | `record_customer_collection` |
| No | Balance trigger / prepaid semantics |
| No | Ledger category (keep `Debt Collection`) |
| Optional | Customer tenant/active guard on existing RPC (Step 0) |
| Later | Separate category / `record_customer_advance` only if reporting needs it |

---

## Later tasks (not in Task 1)

| Task | Summary |
| :--- | :--- |
| Task 2 | Reuse Why owed? / `CustomerOwedBreakdownDialog` from [baki_payment_page.md](./baki_payment_page.md) |
| Task 3 | Live preview of post-save balance in dialog |
| Task 4 | Quick-fill “Clear due only” vs free advance amount |
| Task 5 | Merge with Baki Payment (Due / Prepaid tabs) — see Baki Payment Task 5 |
| Task 6 | Optional ledger category `Customer Advance` + thin RPC wrapper |

---

## Related

- Parent module RFC: [meal_customer_management.md](../meal_customer_management.md) (`record_customer_collection`, negative balance = prepaid)
- Sibling tasks: [customer_attendance_page.md](./customer_attendance_page.md), [baki_charge_page.md](./baki_charge_page.md), [baki_payment_page.md](./baki_payment_page.md)
- Migrations: `20260718163000_meal_customer_management.sql`, `20260718180000_kiosk_customer_session_reads.sql`
- Master summary: [master_specifications.md](../master_specifications.md) §5
