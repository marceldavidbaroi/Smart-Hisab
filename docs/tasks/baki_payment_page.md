# Task Doc: Baki Payment Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)  
SL: **3** — see [SL.md](./SL.md)

**Goal:** Replace the StaffWorkspace inline `CollectionDialog` with a dedicated **Baki Payment** page (same UI pattern as Customer Attendance). Searchable customer list → tap customer → dialog showing **total due**, **payment amount**, **method** → save via `record_customer_collection`. Staff can open a **Why owed?** report that explains the balance with a clear breakdown of meals, baki/extras, and payments (recent window only — no full-history fetch).

---

## Task 1 — Baki Payment Page (MVP)

### Scope

| In | Out |
| :--- | :--- |
| New `web/src/pages/kiosk/KioskBakiPayment.vue` | Schema / RPC changes |
| New `BakiPaymentDialog.vue` (due + amount + method + **Why owed?**) | Advance payment redesign (separate tile) |
| New or reused owed-breakdown dialog (see below) | Workspace-only collection page |
| Route `kiosk-baki-payment`; StaffWorkspace tile navigates here | Multi-installment / schedule UI |
| List: active customers with `outstanding_balance > 0` | Changing ledger posting rules |
| Submit via existing `record_customer_collection` | Lifetime statement dump on every open |
| Recent-range statement fetch (default **last 30 days**) | New `get_customer_statement` RPC (optional later) |
| i18n `en-US` + `bn` | |

### Entry point (change from dialog → page)

1. Kiosk `StaffWorkspace` → tile **Baki Payment** / Collection
2. Today: `showCollectionDialog = true` → change to `router.push({ name: 'kiosk-baki-payment' })`
3. Page: `web/src/pages/kiosk/KioskBakiPayment.vue`

**Keep the same tile.** Replace the click target only; remove inline `CollectionDialog` from StaffWorkspace once the page ships (`CollectionDialog` may remain for workspace customer detail).

### UI Blueprint

#### 1. Main view (`KioskBakiPayment.vue`) — same layout as Attendance

```
[Top Bar]
  - Back → StaffWorkspace
  - Title: "Baki Payment" / "বাকি পেমেন্ট"

[Action Row]
  - Search: "Search by name or phone..." (live filter)

[Main Content: vertical list]
  For each active customer with outstanding_balance > 0:
  +--------------------------------------------------+
  | Name / Phone / Institution (factory_unit)        |
  | Total due chip (outstanding_balance)             |
  | [📋 Why owed?]  [💳 Pay]                         |
  +--------------------------------------------------+
```

- List: active customers (`contract_worker` + `walk_in_baki`) where `outstanding_balance > 0`.
- Search: client-side match on `full_name` (case-insensitive) and `phone` digits.
- **Pay** disabled when staff lacks `collections_write`; for **cash**, also require open operational session.
- **Why owed?** allowed with `collections_read` (or same gate as list) — read-only; no open session required.
- Show session-missing banner when cash write is blocked by missing session.
- Card actions stacked full-width on `xs` (Pay primary; Why owed? secondary / outline).

#### 2. Dialog (`BakiPaymentDialog.vue`)

Triggered by **Pay** / tap on a card (customer preselected).

| Block | Spec |
| :--- | :--- |
| Header | Display: **Name:** {name} \| **Phone:** {phone}; close (X) |
| Total due | Read-only summary: `outstanding_balance` via `formatMoney` (prominent) |
| Why owed? | Secondary button / link under due: opens owed-breakdown dialog (same as card CTA) |
| Payment amount | Numeric (Tk), required, `> 0`; optional quick-fill “Pay full due” |
| Method | Required: `cash` \| `bank_transfer` \| `mobile_wallet` (match existing collection options) |
| Notes | Optional |
| Footer | Cancel \| Save |

#### 3. Owed breakdown dialog (`CustomerOwedBreakdownDialog.vue` — preferred new name; or reuse attendance breakdown pattern)

Triggered by **Why owed?** on the card or inside `BakiPaymentDialog`.

| Block | Spec |
| :--- | :--- |
| Header | Name \| Phone; close (X) |
| Summary | **Outstanding:** `outstanding_balance` (chip); short caption: “Charges − payments = due” |
| Range | Default **last 30 days**; optional preset chips: 7 / 30 / 90 days (MVP: fixed 30 if presets cost time) |
| Timeline | Reuse `CustomerStatementTable` with three slices for this customer + range |
| Empty | “No activity in this range” + still show outstanding chip (balance may be older than window) |
| Footer | Close (and optional **Pay** that opens payment dialog if opened from card) |

**Line clarity (what staff shows the customer):**

| Row type | Source | How it reads |
| :--- | :--- | :--- |
| Regular meal | `customer_daily_attendance` | Daily contract rate for that date (+ shifts list) — **+** |
| Extra / baki | `baki_transactions` | `items_description` (shift prefix + notes; multi-item text from one save) + `amount` — **+** |
| Payment | `customer_collections` | Amount + method (+ notes) — **−** |

Do **not** use `transaction_ledger` for this dialog — company cash book is not the customer statement.

#### 4. Submit logic (payment)

1. Validate: amount > 0; method selected; if method is `cash`, open `session_id` required.
2. Call `record_customer_collection` with session (cash) or `null` session (non-cash), device/staff (kiosk path).
3. Patch customer `outstanding_balance` from RPC return; refresh list (drop card if balance ≤ 0).
4. Close dialog; `showSuccess` toast.
5. On failure: `showApiError`; keep dialog open.

#### 5. Fetch logic (owed breakdown) — bandwidth rules

1. Always show due from **already-loaded** `customers.outstanding_balance` (no extra call for the number).
2. On dialog open only, fetch **recent** slices (not lifetime):

```ts
// Pseudocode — three parallel selects
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

3. Default `rangeStart` = today − 30 days (tenant local / session `business_date` base).
4. No schema / RPC change required. Optional later: `get_customer_statement(p_start, p_end)`.

### Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | `meal-management` + `collections_read` (or write if read not gated today — match kiosk tile) |
| Why owed? / breakdown | Same as list read (no session required) |
| Pay / submit | `collections_write`; cash also needs open operational session |
| Feature off | Existing route guard redirect |

### Files to touch

| File | Action |
| :--- | :--- |
| `web/src/pages/kiosk/KioskBakiPayment.vue` | Create |
| `web/src/components/customers/BakiPaymentDialog.vue` | Create (due + Why owed? + pay fields) |
| `web/src/components/customers/CustomerOwedBreakdownDialog.vue` | Create — wraps summary + `CustomerStatementTable` |
| `web/src/components/customers/CustomerStatementTable.vue` | Reuse as-is |
| `web/src/router/routes.ts` + `guards.ts` | Add `kiosk-baki-payment` route + meal/collections gates |
| `web/src/pages/kiosk/StaffWorkspace.vue` | Tile → navigate to `kiosk-baki-payment`; drop inline `CollectionDialog` open |
| `web/src/components/customers/CollectionDialog.vue` | Keep for workspace detail; unused on kiosk workspace after cutover |
| `web/src/stores/customers.ts` | Reuse `recordCollection` / `fetchCustomers`; optional helper `fetchCustomerStatementSlice(id, from)` |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | Baki payment page + Why owed? / breakdown keys |

### Acceptance checklist

- [ ] Tap **Baki Payment** on StaffWorkspace → new page (not inline old dialog).
- [ ] List matches Attendance layout: search + cards; only customers with due > 0.
- [ ] Card shows name, phone, institution, total due; **Pay** opens payment dialog.
- [ ] **Why owed?** on card (and inside payment dialog) opens breakdown with outstanding + recent timeline.
- [ ] Breakdown lists meals (attendance), baki/extras (`items_description`), and payments with +/− clarity.
- [ ] Breakdown fetch uses date range (default 30 days) + row limits — not full customer history.
- [ ] Dialog shows total due (read-only), amount, method; save records collection.
- [ ] Cash without open session → cannot submit; clear warning.
- [ ] Non-cash may succeed without session (match existing RPC rules).
- [ ] Success toast + dialog closes; balance refreshes / card drops when cleared.
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialogs usable on phone.
- [ ] `en-US` + `bn` strings present.

### Backend note

No schema change for Task 1. Existing:

- `record_customer_collection` — `amount` + `payment_method` + optional `notes`; cash requires `session_id`; ledger inflow `Debt Collection` side effect.
- Balance cache: collections decrease `customers.outstanding_balance` (same RPC / trigger as Advance Payment; negative = prepaid).
- Statement data already on `customer_daily_attendance`, `baki_transactions`, `customer_collections` (indexed by `customer_id`). Recent filter is client query only.
- Optional shared hardening: tenant + active customer check on this RPC — see [advance_payment_page.md](./advance_payment_page.md) Task 0.

---

## Later tasks (not in Task 1)

| Task | Summary |
| :--- | :--- |
| Task 2 | Range presets (7 / 30 / 90) + “Load older” pagination beyond the window |
| Task 3 | Optional RPC `get_customer_statement(p_start, p_end)` single round-trip |
| Task 4 | Partial-pay helpers / suggest remaining due after save |
| Task 5 | Unify with Advance Payment when prepaid path is built — see [advance_payment_page.md](./advance_payment_page.md) |
| Task 6 | Share same `CustomerOwedBreakdownDialog` from Baki Charge / Attendance cards |

---

## Related

- Parent module RFC: [meal_customer_management.md](../meal_customer_management.md)
- Sibling tasks: [customer_attendance_page.md](./customer_attendance_page.md), [baki_charge_page.md](./baki_charge_page.md), [advance_payment_page.md](./advance_payment_page.md)
- Master summary: [master_specifications.md](../master_specifications.md) §5
