# Task Doc: Customer Attendance Page

Parent RFC: [meal_customer_management.md](../meal_customer_management.md)

**Goal:** Replace the existing kiosk attendance UI with a clean Customer Attendance Dashboard. StaffWorkspace **Customer Attendance** tile already routes to `kiosk-attendance` — keep that entry point; **delete the old page body and rebuild from scratch**.

---

## Task 1 — Attendance Page (MVP)

### Scope

| In | Out |
| :--- | :--- |
| Rewrite `web/src/pages/kiosk/KioskAttendance.vue` from scratch | Weekly / monthly tabs & tables |
| New `AttendanceEntryDialog.vue` | Keeping `AttendanceGrid.vue` (delete if unused) |
| Live search by name / phone | Workspace attendance route (none today) |
| Submit via existing RPCs (`toggle_contract_attendance`, optional `record_baki_transaction`) | New attendance tables / RPCs |
| i18n `en-US` + `bn` for new strings | Standalone baki/collection redesign |

### Entry point (already wired)

1. Kiosk `StaffWorkspace` → tile **Customer Attendance**
2. `router.push({ name: 'kiosk-attendance' })`
3. Page: `web/src/pages/kiosk/KioskAttendance.vue`

**Do not change the navigation target.** Replace the page implementation only.

### Remove / start fresh

- [ ] Empty `KioskAttendance.vue` and rebuild to the blueprint below (no weekly/monthly, no per-shift Mark Present rows on cards).
- [ ] Delete `web/src/components/customers/AttendanceGrid.vue` if still present and unused.
- [ ] Remove orphan `WorkspaceAttendance.vue` if it remains unrouted and is not needed for this task.
- [ ] Prune obsolete `attendance.*` i18n keys that only served weekly/monthly / Mark Present.

### UI Blueprint

#### 1. Main view (`KioskAttendance.vue`)

```
[Top Bar]
  - Back → StaffWorkspace
  - Title: "Customer Attendance Dashboard"

[Action Row]
  - Search: "Search by name or phone..." (live filter)

[Main Content: vertical list]
  For each active contract_worker:
  +--------------------------------------------------+
  | Name / Phone / Institution (factory_unit)        |
  | [➕ Add Attendance]                              |
  +--------------------------------------------------+
```

- List: active `contract_worker` only.
- Search: client-side match on `full_name` (case-insensitive) and `phone` digits.
- **Add Attendance** disabled when no open session or staff lacks `attendance_write`.
- Show session-missing banner when write is blocked.

#### 2. Dialog (`AttendanceEntryDialog.vue`)

Triggered by **Add Attendance** on a card.

| Block | Spec |
| :--- | :--- |
| Header | Display: **Name:** {name} \| **Phone:** {phone}; close (X) |
| Date | Label “Select Date”; default = session `business_date` (else today) |
| Shift | Radio / segmented — Breakfast, Lunch, Afternoon Snacks, Dinner (required) |
| Extras toggle | “Add Extra Items?” default off → expands note/amount extras when on |
| Financial | Note (optional); Amount (Tk) numeric, prefilled with `contract_daily_rate` |
| Footer | Cancel \| Submit & Save |

#### 3. Submit logic

1. Validate: shift selected; amount is numeric (and > 0 if required by product — match existing baki rules).
2. Call `toggle_contract_attendance` with session + device/staff (kiosk path).
3. If extras toggle on: call `record_baki_transaction` with note + amount (or extras delta — prefer same fields as `BakiChargeDialog`).
4. Patch / refresh store attendance + customer balance from RPC returns.
5. Close dialog; `showSuccess` toast (“Attendance saved”).
6. On failure: `showApiError`; keep dialog open.

### Permissions & gates

| Action | Requirement |
| :--- | :--- |
| Open page / see list | `meal-management` + `attendance_read` |
| Add Attendance / submit | `attendance_write` + open operational session |
| Feature off | Existing route guard redirect |

### Files to touch

| File | Action |
| :--- | :--- |
| `web/src/pages/kiosk/KioskAttendance.vue` | Rewrite |
| `web/src/components/customers/AttendanceEntryDialog.vue` | Create |
| `web/src/components/customers/AttendanceGrid.vue` | Delete if unused |
| `web/src/pages/workspace/WorkspaceAttendance.vue` | Delete if orphan |
| `web/src/stores/customers.ts` | Reuse `fetchAttendanceForDate` / `toggleAttendance`; wire baki if needed |
| `web/src/i18n/en-US/index.ts` + `bn/index.ts` | New attendance dashboard + dialog keys |
| `web/src/pages/kiosk/StaffWorkspace.vue` | Keep `goToKioskAttendance` only (verify tile still correct) |

### Acceptance checklist

- [ ] Tap **Customer Attendance** on StaffWorkspace → new dashboard (not old weekly/monthly UI).
- [ ] Search filters cards by name or phone instantly.
- [ ] Card shows name, phone, institution; **Add Attendance** opens dialog.
- [ ] Dialog defaults date; requires shift; amount prefilled with daily rate.
- [ ] Extras off → attendance only; extras on → attendance + baki/extra charge.
- [ ] Success toast + dialog closes; balance/attendance refresh.
- [ ] No open session → cannot submit; clear warning.
- [ ] Mobile-first: no horizontal scroll; CTAs ≥ 48px; dialog usable on phone.
- [ ] `en-US` + `bn` strings present.

### Backend note

No schema change for Task 1. Existing:

- `toggle_contract_attendance` — shift on `customer_daily_attendance.attended_shifts`; daily rate once per day.
- `record_baki_transaction` — extras / note + amount.

---

## Later tasks (not in Task 1)

| Task | Summary |
| :--- | :--- |
| Task 2 | (TBD) Unmark / edit attendance from the same page |
| Task 3 | (TBD) Workspace read-only attendance oversight, if needed |
| Task 4 | (TBD) Line-item extras UI (multi-item) vs single note |

---

## Related

- Parent module RFC: [meal_customer_management.md](../meal_customer_management.md)
- Sibling tasks: [baki_charge_page.md](./baki_charge_page.md), [baki_payment_page.md](./baki_payment_page.md) (**Why owed?** on payment page), [advance_payment_page.md](./advance_payment_page.md)
- Master summary: [master_specifications.md](../master_specifications.md) §5
