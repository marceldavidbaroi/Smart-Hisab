# Task Doc: Baki Charge Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)  
SL: **2** — see [SL.md](./SL.md)

**Goal:** Replace the StaffWorkspace inline `BakiChargeDialog` with a dedicated **Baki** page (same pattern as Customer Attendance). Searchable walk-in baki customer list → select customer → dialog with shift, note/amount line items, live total → save via `record_baki_transaction`.

**Reference implementation:** Clone structure from `KioskAttendance.vue` + `AttendanceEntryDialog.vue`; swap category to `walk_in_baki` and baki multi-line form.

---

## Scope

| In | Out |
| :--- | :--- |
| New `web/src/pages/kiosk/KioskBaki.vue` | Schema / RPC changes (`shift_name` column) |
| New `BakiEntryDialog.vue` (multi-line note + amount) | Collection / payment UI |
| Route `kiosk-baki`; StaffWorkspace tile navigates here | Contract-worker attendance extras (stay on Attendance dialog) |
| List: active `walk_in_baki` customers | Workspace baki page |
| Submit via existing `record_baki_transaction` | Redesign of collections tile |
| i18n `en-US` + `bn` | |

**Backend (no change):** `record_baki_transaction` — `items_description` + `amount`; session must be open. Shift is UI-only (embedded in description).

---

## Implementation steps (do in order)

> Each step is independently shippable/testable. Do **not** skip ahead. Finish a step’s Done criteria before the next.

### Step 1 — i18n keys (`en-US` + `bn`)

**Files:** `web/src/i18n/en-US/index.ts`, `web/src/i18n/bn/index.ts`

**Do:**

1. Extend existing `customers.baki` (do not invent a new root). Mirror attendance shape:

```
customers.baki
  title, subtitle, searchPlaceholder, addBakiBtn, empty, noSessionWarning
  dialog
    title, name, phone, shift, note, amount, total
    addRow, removeRow
    cancelBtn, saveBtn, success
    shiftRequired, noteRequired, amountRequired, amountMin, linesRequired
    shifts: { breakfast, lunch, afternoon_snacks, dinner }
  errors
    loadFailed, …
```

2. Reuse existing keys where they still fit (`cancelBtn`, `saveBtn`, `amount*`, `success`).
3. Add every new key in **both** locales in the same turn — never one locale only.

**Done when:** Key trees match between `en-US` and `bn`; no hardcoded EN/BN planned for later UI strings.

---

### Step 2 — Route + guards

**Files:** `web/src/router/routes.ts`, `web/src/router/guards.ts` (if attendance uses guards there)

**Do:**

1. Add route mirroring `kiosk-attendance`:
   - `path: 'baki'`
   - `name: 'kiosk-baki'`
   - `component: () => import('@/pages/kiosk/KioskBaki.vue')`
2. Apply the same meal-management / baki permission gates used by the StaffWorkspace Baki tile (`baki_read` / `baki_write` — match existing kiosk tile gating).
3. Stub `KioskBaki.vue` as a minimal page (title + back) so the route resolves.

**Done when:** Navigating to `/kiosk/.../baki` (or equivalent) loads the stub without 404; unauthenticated / feature-off behavior matches attendance.

---

### Step 3 — Page shell: list + search (`KioskBaki.vue`)

**File:** `web/src/pages/kiosk/KioskBaki.vue`  
**Clone from:** `web/src/pages/kiosk/KioskAttendance.vue`

**UI:**

```
[Top Bar] Back → StaffWorkspace | Title from $t('customers.baki.title')
[Search]  live filter placeholder from i18n
[Banner]  no-session / write-blocked warning
[List]    cards for active walk_in_baki only
          Name / Phone / Institution / Outstanding chip / [Add Baki]
```

**Do:**

1. `fetchCustomers({ activeOnly: true })`; filter `category === 'walk_in_baki'`.
2. Client-side search on `full_name` (case-insensitive) + `phone` digits.
3. Show outstanding balance (reuse existing money formatter if attendance/customers already use one).
4. Gate **Add Baki**: disabled when no open session or staff lacks `baki_write`.
5. Wire all strings with `$t('customers.baki.*')`.
6. Mobile-first: `col-12` cards; CTAs ≥ 48px; no horizontal scroll.

**Do not** build the dialog yet — button can be a no-op or `console`/TODO until Step 4–5.

**Done when:** Page lists walk-in baki customers; search works; session banner shows when write blocked.

---

### Step 4 — Dialog UI + reset (`BakiEntryDialog.vue`)

**File:** `web/src/components/customers/BakiEntryDialog.vue` (new)  
**Clone patterns from:** `AttendanceEntryDialog.vue`, current `BakiChargeDialog.vue`

**Props (minimum):** `modelValue`, `customer`, `sessionId`, session shift name / business date, `deviceToken`, `staffId` (match kiosk attendance dialog).

**UI blocks:**

| Block | Spec |
| :--- | :--- |
| Header | Name + phone from props; close (X) |
| Shift | Radio / segmented — Breakfast, Lunch, Afternoon Snacks, Dinner; **default = current session shift** |
| Line items | ≥ 1 row: Note (required) + Amount (Tk, > 0); add/remove row |
| Total | Live sum of line amounts (`formatMoney`) |
| Footer | Cancel \| Save |

**Reset (required) — implement in this step:**

```ts
function resetForm() {
  // shift → current session shift (or first option)
  // lines → [{ note: '', amount: null }]
  // saving → false
  // clear local validation state
}
```

| Trigger | Action |
| :--- | :--- |
| Dialog opens | `watch(isOpen)` → `true` → `resetForm()` |
| Save success | `resetForm()` then close |
| Cancel / X / hide | `@hide` or `watch(isOpen)` → `false` → `resetForm()` |
| Save failure | **Do not** reset — keep edits |

**Do:** Build form UI + `resetForm` only. Stub `onSubmit` or leave Save disabled until Step 5 if preferred — but reset must already work for cancel/open.

**Done when:** Opening dialog shows defaults; cancel/reopen shows empty single line + default shift; no stale data.

---

### Step 5 — Submit logic + wire dialog to page

**Files:** `BakiEntryDialog.vue`, `KioskBaki.vue`, reuse `customersStore.recordBaki`

**Submit sequence:**

1. Validate: shift selected; ≥ 1 line; each note non-empty; each amount > 0; total > 0.
2. Build `items_description` = **translated** shift label (`t('customers.baki.dialog.shifts.*')`) + joined notes (e.g. `"Lunch — tea (৳20); biscuit (৳10)"`). No hardcoded English shift names.
3. Single RPC: `recordBaki({ customerId, sessionId, itemsDescription, amount: total, deviceToken, staffId })`.
4. Patch customer `outstanding_balance` from return; page refreshes chip.
5. `resetForm()` → close → `showSuccess(t('customers.baki.dialog.success'))`.
6. On failure: `showApiError`; keep dialog open.

**Wire page:**

1. `selectedCustomer` + `showDialog` refs.
2. **Add Baki** sets customer and opens dialog.
3. `@saved` updates list balance / refetch as needed.

**Done when:** Happy path records one baki charge; balance chip updates; toast shows; failed save keeps form.

---

### Step 6 — StaffWorkspace entry point

**File:** `web/src/pages/kiosk/StaffWorkspace.vue`

**Do:**

1. Keep the same **Baki** tile.
2. Change `@click="showBakiDialog = true"` → `router.push({ name: 'kiosk-baki' })` (add `goToKioskBaki` like attendance).
3. Remove inline `BakiChargeDialog` usage, `showBakiDialog` ref, and related import if unused.
4. Do **not** change tile visibility / `canLogBaki` permission logic unless required for navigation consistency.

**Done when:** Tap Baki → new page (not old dialog). Old dialog no longer mounts from workspace.

---

### Step 7 — Cleanup

**Files:** `BakiChargeDialog.vue` (+ any remaining imports)

**Do:**

1. Grep for `BakiChargeDialog` / `showBakiDialog`.
2. If unused everywhere → delete `BakiChargeDialog.vue`.
3. If still used elsewhere → leave it; do not break other callers.
4. Optionally prune obsolete `customers.baki` keys that only served the old single-field dialog **only if** nothing references them.

**Done when:** No dead imports; app builds; workspace uses page only.

---

### Step 8 — Acceptance pass

Verify against checklist below. Fix gaps before marking Task 1 complete.

---

## Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | `meal-management` + `baki_read` (or `baki_write` if read not separately gated — match kiosk tile) |
| Add Baki / submit | `baki_write` + open operational session |
| Feature off | Existing route guard redirect |

---

## Files to touch (summary)

| File | Step | Action |
| :--- | :--- | :--- |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | 1 | Extend `customers.baki` |
| `web/src/router/routes.ts` (+ `guards.ts`) | 2 | Add `kiosk-baki` |
| `web/src/pages/kiosk/KioskBaki.vue` | 2–3, 5 | Create / flesh out |
| `web/src/components/customers/BakiEntryDialog.vue` | 4–5 | Create |
| `web/src/pages/kiosk/StaffWorkspace.vue` | 6 | Tile → navigate; drop old dialog |
| `web/src/components/customers/BakiChargeDialog.vue` | 7 | Delete if unused |
| `web/src/stores/customers.ts` | 5 | Reuse `recordBaki` / `fetchCustomers` (no API change expected) |

---

## Acceptance checklist

- [ ] Tap **Baki** on StaffWorkspace → new page (not inline old dialog).
- [ ] List shows active `walk_in_baki` only; search filters by name/phone.
- [ ] Card shows name, phone, institution, outstanding; **Add Baki** opens dialog.
- [ ] Dialog defaults shift to current session shift; shift can be changed.
- [ ] Multiple note + amount rows; top total updates live.
- [ ] Save → one `record_baki_transaction`; balance refreshes; success toast; form resets.
- [ ] Cancel / close (X) → form resets (no stale lines on next open).
- [ ] Failed save → dialog stays open with edits intact (no reset).
- [ ] No open session → cannot submit; clear warning.
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialog usable on phone.
- [ ] All UI strings via `$t` / `t`; `en-US` + `bn` keys present and mirrored under `customers.baki`.

---

## Later tasks (not in Task 1)

| Task | Summary |
| :--- | :--- |
| Task 2 | Persist `shift_name` on `baki_transactions` + RPC param |
| Task 3 | Multi-RPC save (one row per line item) vs single combined charge |
| Task 4 | Include `contract_worker` on this page for standalone extras (optional) |

---

## Related

- Parent module RFC: [meal_customer_management.md](../meal_customer_management.md)
- Sibling tasks: [customer_attendance_page.md](./customer_attendance_page.md), [baki_payment_page.md](./baki_payment_page.md), [advance_payment_page.md](./advance_payment_page.md)
- Master summary: [master_specifications.md](../master_specifications.md) §5
