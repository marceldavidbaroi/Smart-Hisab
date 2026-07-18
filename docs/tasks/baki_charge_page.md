# Task Doc: Baki Charge Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)  
SL: **2** — see [SL.md](./SL.md)

**Goal:** Replace the StaffWorkspace inline `BakiChargeDialog` with a dedicated **Baki** page (same pattern as Customer Attendance). Searchable walk-in baki customer list → select customer → dialog with shift, note/amount line items, live total → save via `record_baki_transaction`.

---

## Task 1 — Baki Page (MVP)

### Scope

| In | Out |
| :--- | :--- |
| New `web/src/pages/kiosk/KioskBaki.vue` | Schema / RPC changes (`shift_name` column) |
| New `BakiEntryDialog.vue` (multi-line note + amount) | Collection / payment UI |
| Route `kiosk-baki`; StaffWorkspace tile navigates here | Contract-worker attendance extras (stay on Attendance dialog) |
| List: active `walk_in_baki` customers | Workspace baki page |
| Submit via existing `record_baki_transaction` | Redesign of collections tile |
| i18n `en-US` + `bn` | |

### Entry point (change from dialog → page)

1. Kiosk `StaffWorkspace` → tile **Baki** / Baki Charge
2. Today: `showBakiDialog = true` → change to `router.push({ name: 'kiosk-baki' })`
3. Page: `web/src/pages/kiosk/KioskBaki.vue`

**Keep the same tile.** Replace the click target only; remove inline `BakiChargeDialog` from StaffWorkspace once the page ships (dialog component may remain for reuse elsewhere or be superseded by `BakiEntryDialog`).

### UI Blueprint

#### 1. Main view (`KioskBaki.vue`)

```
[Top Bar]
  - Back → StaffWorkspace
  - Title: "Baki" / "বাকি"

[Action Row]
  - Search: "Search by name or phone..." (live filter)

[Main Content: vertical list]
  For each active walk_in_baki customer:
  +--------------------------------------------------+
  | Name / Phone / Institution (factory_unit)        |
  | Outstanding balance chip                         |
  | [➕ Add Baki]                                    |
  +--------------------------------------------------+
```

- List: active `walk_in_baki` only.
- Search: client-side match on `full_name` (case-insensitive) and `phone` digits.
- **Add Baki** disabled when no open session or staff lacks `baki_write`.
- Show session-missing banner when write is blocked.

#### 2. Dialog (`BakiEntryDialog.vue`)

Triggered by **Add Baki** on a card (customer preselected).

| Block | Spec |
| :--- | :--- |
| Header | Display: **Name:** {name} \| **Phone:** {phone}; close (X) |
| Shift | Radio / segmented — Breakfast, Lunch, Afternoon Snacks, Dinner; **default = current session shift**; changeable |
| Line items | One or more rows: **Note** (required per row) + **Amount** (Tk, > 0). Allow add/remove row |
| Total | Sticky / top summary: live sum of all line amounts (`formatMoney`) |
| Footer | Cancel \| Save |

**Shift persistence (MVP):** no DB column. On save, prefix the selected shift into `items_description` (e.g. `"Lunch — tea, biscuit; …"`). Session still supplies `session_id` / `business_date` via existing RPC.

#### 3. Submit logic

1. Validate: shift selected; ≥ 1 line; each note non-empty; each amount > 0; total > 0.
2. Build `items_description` = shift label + joined notes (or `"note (৳x); note (৳y)"`).
3. Call `record_baki_transaction` once with `amount = total` (prefer single RPC for MVP).
4. Patch customer `outstanding_balance` from RPC return; refresh list balance chip.
5. Close dialog; `showSuccess` toast.
6. On failure: `showApiError`; keep dialog open.

### Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | `meal-management` + `baki_read` (or `baki_write` if read not separately gated today — match kiosk tile) |
| Add Baki / submit | `baki_write` + open operational session |
| Feature off | Existing route guard redirect |

### Files to touch

| File | Action |
| :--- | :--- |
| `web/src/pages/kiosk/KioskBaki.vue` | Create |
| `web/src/components/customers/BakiEntryDialog.vue` | Create |
| `web/src/router/routes.ts` + `guards.ts` | Add `kiosk-baki` route + meal/baki gates |
| `web/src/pages/kiosk/StaffWorkspace.vue` | Tile → navigate to `kiosk-baki`; drop inline open of old dialog |
| `web/src/components/customers/BakiChargeDialog.vue` | Keep until unused, then delete or thin-wrap |
| `web/src/stores/customers.ts` | Reuse `recordBaki` / `fetchCustomers` |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | Baki page + dialog keys |

### Acceptance checklist

- [ ] Tap **Baki** on StaffWorkspace → new page (not inline old dialog).
- [ ] List shows active `walk_in_baki` only; search filters by name/phone.
- [ ] Card shows name, phone, institution, outstanding; **Add Baki** opens dialog.
- [ ] Dialog defaults shift to current session shift; shift can be changed.
- [ ] Multiple note + amount rows; top total updates live.
- [ ] Save → one `record_baki_transaction`; balance refreshes; success toast.
- [ ] No open session → cannot submit; clear warning.
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialog usable on phone.
- [ ] `en-US` + `bn` strings present.

### Backend note

No schema change for Task 1. Existing:

- `record_baki_transaction` — `items_description` + `amount`; session must be open.
- Shift is **UI-only** (embedded in description). Later task may add `shift_name` column if reporting needs it.

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
- Sibling tasks: [customer_attendance_page.md](./customer_attendance_page.md), [baki_payment_page.md](./baki_payment_page.md) (**Why owed?** lives on payment page; optional later reuse here), [advance_payment_page.md](./advance_payment_page.md)
- Master summary: [master_specifications.md](../master_specifications.md) §5
