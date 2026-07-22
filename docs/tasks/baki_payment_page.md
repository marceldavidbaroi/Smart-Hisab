# Task Doc: Baki Payment Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)  
SL: **3** — see [SL.md](./SL.md)

**Goal:** Replace the StaffWorkspace inline `CollectionDialog` with a dedicated **Baki Payment** page (same pattern as Customer Attendance). Searchable dues list → **Pay** dialog (total due + amount + method) → save via `record_customer_collection`. Staff can open **Why owed?** (recent charges − payments breakdown).

**Reference implementation:** Clone `KioskAttendance.vue` layout. Payment form patterns from `CollectionDialog.vue`. Statement UI from `CustomerStatementTable.vue` + `OutstandingBalanceChip.vue`.

**Shared backend with Advance Payment:** same RPC `record_customer_collection`. Product split is UX (dues-only list + Why owed?), not a new API. Optional RPC harden = [advance_payment_page.md](./advance_payment_page.md) Task 0 / Step 0.

---

## Scope

| In | Out |
| :--- | :--- |
| New `web/src/pages/kiosk/KioskBakiPayment.vue` | Schema / RPC changes |
| New `BakiPaymentDialog.vue` (due + amount + method + Why owed?) | Advance payment redesign (separate tile) |
| New `CustomerOwedBreakdownDialog.vue` | Workspace-only collection page |
| Route `kiosk-baki-payment`; StaffWorkspace tile navigates here | Multi-installment / schedule UI |
| List: active customers with `outstanding_balance > 0` | Changing ledger posting rules |
| Submit via existing `record_customer_collection` | Lifetime statement dump on every open |
| Recent-range statement fetch (default **last 30 days**) | New `get_customer_statement` RPC (optional later) |
| i18n `en-US` + `bn` | |

**Backend (no change for Task 1):**

- `record_customer_collection` — amount + method + optional notes; cash requires open `session_id`; ledger inflow `Debt Collection`.
- Balance: collections decrease `outstanding_balance` (negative = prepaid).
- Statement sources: `customer_daily_attendance`, `baki_transactions`, `customer_collections` — client date-range query only. Do **not** use `transaction_ledger`.

---

## Implementation steps (do in order)

> Each step is independently shippable/testable. Do **not** skip ahead. Finish a step’s Done criteria before the next.

### Step 1 — i18n keys (`en-US` + `bn`)

**Files:** `web/src/i18n/en-US/index.ts`, `web/src/i18n/bn/index.ts`

**Do:**

1. Add page keys under a clear nest (prefer new `customers.bakiPayment` so it does not clash with charge `customers.baki` or legacy `customers.collections`):

```
customers.bakiPayment
  title, subtitle, searchPlaceholder, empty, noSessionWarning
  payBtn, whyOwedBtn
  dialog
    title, name, phone, totalDue, amount, payFullDue
    paymentMethod, notes
    cancelBtn, saveBtn, success
    amountRequired, amountMin, paymentMethodRequired
    sessionRequiredCash
  owed
    title, outstanding, caption          // “Charges − payments = due”
    emptyRange, closeBtn, payBtn
    rangeDays                            // e.g. “Last {n} days”
  errors
    loadFailed, …
```

2. Reuse `customers.collections.methods.*` for cash / mobile_wallet / bank_transfer labels (or mirror under `bakiPayment.dialog.methods` if you prefer one tree — pick one and stick to it).
3. Add every new key in **both** locales in the same turn.

**Done when:** Key trees match between `en-US` and `bn`; no hardcoded EN/BN planned for page/dialogs.

---

### Step 2 — Route + stub page

**Files:** `web/src/router/routes.ts`, `web/src/router/guards.ts` (if used), stub `KioskBakiPayment.vue`

**Do:**

1. Add route mirroring `kiosk-attendance`:
   - `path: 'baki-payment'`
   - `name: 'kiosk-baki-payment'`
   - `component: () => import('@/pages/kiosk/KioskBakiPayment.vue')`
   - `requiredFeature: 'meal-management'` (match other meal kiosk pages)
2. Gate like the StaffWorkspace collections tile (`collections_read` / `collections_write` as applicable).
3. Stub page: title + back button so the route resolves.

**Done when:** Route loads stub without 404; feature-off behavior matches siblings.

---

### Step 3 — Page shell: dues list + search (`KioskBakiPayment.vue`)

**File:** `web/src/pages/kiosk/KioskBakiPayment.vue`  
**Clone from:** `KioskAttendance.vue`

**UI:**

```
[Top Bar] Back → StaffWorkspace | Title from $t('customers.bakiPayment.title')
[Search]  live filter
[Banner]  no-session → cash payment blocked (non-cash still OK later)
[List]    active customers with outstanding_balance > 0
          Name / Phone / Institution / Total due chip
          [Why owed?]  [Pay]   ← stack full-width on xs
```

**Do:**

1. `fetchCustomers({ activeOnly: true })`; filter `outstanding_balance > 0` (both categories).
2. Client-side search on `full_name` (case-insensitive) + `phone` digits.
3. Due chip via `OutstandingBalanceChip` or `formatMoney`.
4. Gate **Pay**: needs `collections_write`; cash path also needs open session (banner when session missing).
5. Gate **Why owed?**: read-only — same as list read; **no** session required.
6. All strings via `$t('customers.bakiPayment.*')`.
7. Mobile-first: CTAs ≥ 48px; no horizontal scroll.

**Do not** build payment/owed dialogs yet — buttons can be no-ops until Steps 4–7.

**Done when:** Page lists only customers with due > 0; search + session banner work.

---

### Step 4 — Payment dialog UI + reset (`BakiPaymentDialog.vue`)

**File:** `web/src/components/customers/BakiPaymentDialog.vue` (new)  
**Clone patterns from:** `CollectionDialog.vue`, `AttendanceEntryDialog.vue`

**Props (minimum):**

```ts
modelValue: boolean
customer: Customer   // required preselected
sessionId?: string | null
deviceToken?: string | null
staffId?: string | null
```

**Do not** wrap in `v-if="activeSession"` — non-cash must open without a session.

**UI blocks:**

| Block | Spec |
| :--- | :--- |
| Header | Name + phone; close (X) |
| Total due | Read-only `outstanding_balance` via `formatMoney` (prominent) |
| Why owed? | Secondary link/button (wire in Step 7; stub OK here) |
| Amount | Numeric Tk, required, `> 0`; optional **Pay full due** quick-fill |
| Method | Required: cash \| bank_transfer \| mobile_wallet |
| Notes | Optional |
| Footer | Cancel \| Save |

**Reset (required) — implement in this step:**

```ts
function resetForm() {
  // amount → null (or empty)
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

**Done when:** Open/cancel/reopen shows clean form; due always reflects current customer balance.

---

### Step 5 — Payment submit + wire to page

**Files:** `BakiPaymentDialog.vue`, `KioskBakiPayment.vue`, reuse `customersStore.recordCollection`

**Submit sequence:**

```ts
const sessionId =
  form.paymentMethod === 'cash'
    ? sessionStore.activeSession?.id ?? null
    : null;

if (form.paymentMethod === 'cash' && !sessionId) {
  // showWarning / block — match RPC
  return;
}

const newBalance = await customersStore.recordCollection({
  customerId: customer.id,
  sessionId,
  amount: form.amount,
  paymentMethod: form.paymentMethod,
  notes: form.notes || undefined,
  deviceToken,
  staffId,
});

// Patch store from RPC return
const row = customersStore.customers.find((c) => c.id === customer.id);
if (row) row.outstanding_balance = newBalance;

resetForm();
close;
showSuccess(t('customers.bakiPayment.dialog.success'));
```

1. Validate amount > 0 + method; cash ⇒ open session.
2. On success: patch balance; list drops card when `outstanding_balance ≤ 0`.
3. On failure: `showApiError`; keep dialog open (**no** reset).

**Wire page:** `selectedCustomer` + `showPayDialog`; **Pay** opens dialog; `@saved` refreshes list filter.

**Done when:** Cash/non-cash happy paths work; card disappears when fully paid; failed save keeps edits.

---

### Step 6 — Why owed? breakdown dialog + fetch

**File:** `web/src/components/customers/CustomerOwedBreakdownDialog.vue` (new)  
**Reuse:** `CustomerStatementTable.vue`, `OutstandingBalanceChip.vue`  
**Optional store helper:** `fetchCustomerStatementSlice(id, from)` in `customers.ts`

**UI:**

| Block | Spec |
| :--- | :--- |
| Header | Name \| Phone; close (X) |
| Summary | Outstanding chip; caption “Charges − payments = due” |
| Range | Default **last 30 days** (presets 7/30/90 = later task) |
| Timeline | `CustomerStatementTable` with three slices |
| Empty | “No activity in this range” + still show outstanding (balance may be older) |
| Footer | Close (optional **Pay** deferred to Step 7) |

**Line clarity:**

| Row type | Source | Sign |
| :--- | :--- | :--- |
| Regular meal | `customer_daily_attendance` | **+** (daily rate + shifts) |
| Extra / baki | `baki_transactions` | **+** (`items_description` + amount) |
| Payment | `customer_collections` | **−** (amount + method) |

**Fetch rules (bandwidth):**

1. Outstanding number = already-loaded `customers.outstanding_balance` (no extra call).
2. On open only, three parallel selects — **not** lifetime:

```ts
.from('customer_daily_attendance')
  .eq('customer_id', id).gte('business_date', rangeStart)
  .order('business_date', { ascending: false }).limit(100)

.from('baki_transactions')
  .eq('customer_id', id).gte('business_date', rangeStart)
  .order('business_date', { ascending: false }).limit(100)

.from('customer_collections')
  .eq('customer_id', id).gte('collected_at', rangeStartIso)
  .order('collected_at', { ascending: false }).limit(100)
```

3. `rangeStart` = today − 30 days (tenant local / session `business_date` base).
4. All UI strings via `$t('customers.bakiPayment.owed.*')`.

**Reset:** On close/hide, clear loaded slices + loading flags so next open refetches cleanly (avoid showing previous customer’s timeline).

**Done when:** Dialog shows outstanding + recent timeline for one customer; empty range still shows chip; no full-history fetch.

---

### Step 7 — Wire Why owed? to card + payment dialog

**Files:** `KioskBakiPayment.vue`, `BakiPaymentDialog.vue`, `CustomerOwedBreakdownDialog.vue`

**Do:**

1. Card **Why owed?** → open breakdown for that customer.
2. Inside `BakiPaymentDialog`, **Why owed?** → same breakdown (pass same customer).
3. Optional: breakdown footer **Pay** opens payment dialog if opened from card.
4. Ensure only one breakdown instance; switching customers resets data (Step 6 reset).

**Done when:** Why owed? works from card and from payment dialog; Pay flow still works.

---

### Step 8 — StaffWorkspace entry point

**File:** `web/src/pages/kiosk/StaffWorkspace.vue`

**Do:**

1. Keep the same **Baki Payment** / Collection tile.
2. Change `showCollectionDialog = true` → `router.push({ name: 'kiosk-baki-payment' })`.
3. Remove inline kiosk `CollectionDialog` open/ref/import **only if** unused on this page.
4. Keep `CollectionDialog` for workspace customer detail (`WorkspaceCustomerDetail.vue`).

**Done when:** Tap tile → new page; workspace detail collection still works.

---

### Step 9 — Cleanup

**Do:**

1. Grep `showCollectionDialog` on StaffWorkspace — should be gone if unused.
2. Do **not** delete `CollectionDialog.vue` (still used on workspace).
3. Prune obsolete coming-soon / unused keys only if nothing references them.

**Done when:** No dead kiosk collection dialog wiring; app builds.

---

### Step 10 — Acceptance pass

Verify against checklist below. Fix gaps before marking Task 1 complete.

---

## Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | `meal-management` + `collections_read` (or write if read not gated — match kiosk tile) |
| Why owed? / breakdown | Same as list read (no session required) |
| Pay / submit | `collections_write`; cash also needs open operational session |
| Feature off | Existing route guard redirect |

---

## Files to touch (summary)

| File | Step | Action |
| :--- | :--- | :--- |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | 1 | Add `customers.bakiPayment` (+ owed) |
| `web/src/router/routes.ts` (+ `guards.ts`) | 2 | Add `kiosk-baki-payment` |
| `web/src/pages/kiosk/KioskBakiPayment.vue` | 2–3, 5, 7 | Create / flesh out |
| `web/src/components/customers/BakiPaymentDialog.vue` | 4–5, 7 | Create |
| `web/src/components/customers/CustomerOwedBreakdownDialog.vue` | 6–7 | Create |
| `web/src/components/customers/CustomerStatementTable.vue` | 6 | Reuse as-is |
| `web/src/components/customers/OutstandingBalanceChip.vue` | 3, 6 | Reuse |
| `web/src/stores/customers.ts` | 5–6 | Reuse `recordCollection` / `fetchCustomers`; optional statement slice helper |
| `web/src/pages/kiosk/StaffWorkspace.vue` | 8 | Tile → navigate; drop inline collection open |
| `web/src/components/customers/CollectionDialog.vue` | 9 | Keep for workspace |

---

## Acceptance checklist

- [ ] Tap **Baki Payment** on StaffWorkspace → new page (not inline old dialog).
- [ ] List: search + cards; only customers with due > 0.
- [ ] Card shows name, phone, institution, total due; **Pay** opens payment dialog.
- [ ] **Why owed?** on card (and inside payment dialog) opens breakdown with outstanding + recent timeline.
- [ ] Breakdown lists meals, baki/extras, payments with +/− clarity.
- [ ] Breakdown fetch uses date range (default 30 days) + row limits — not full history.
- [ ] Breakdown resets when closed / customer changes (no stale timeline).
- [ ] Dialog shows total due, amount, method; save records collection.
- [ ] Save success → toast + form reset + close; balance refreshes / card drops when cleared.
- [ ] Cancel / close → form resets (no stale amount/method on next open).
- [ ] Failed save → dialog stays open with edits intact.
- [ ] Cash without open session → cannot submit; clear warning.
- [ ] Non-cash may succeed without session.
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialogs usable on phone.
- [ ] All UI strings via `$t` / `t`; `en-US` + `bn` mirrored under `customers.bakiPayment`.

---

## Later tasks (not in Task 1)

| Task | Summary |
| :--- | :--- |
| Task 2 | Range presets (7 / 30 / 90) + “Load older” pagination |
| Task 3 | Optional RPC `get_customer_statement(p_start, p_end)` |
| Task 4 | Partial-pay helpers / suggest remaining due after save |
| Task 5 | Merge with Advance Payment when prepaid path is built — see [advance_payment_page.md](./advance_payment_page.md) |
| Task 6 | Share `CustomerOwedBreakdownDialog` from Baki Charge / Attendance cards |

---

## Related

- Parent module RFC: [meal_customer_management.md](../meal_customer_management.md)
- Sibling tasks: [customer_attendance_page.md](./customer_attendance_page.md), [baki_charge_page.md](./baki_charge_page.md), [advance_payment_page.md](./advance_payment_page.md)
- Master summary: [master_specifications.md](../master_specifications.md) §5
