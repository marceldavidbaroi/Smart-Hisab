# Staff & Payroll — UI Flow

> **Module Blueprint**: [`STAFF.md`](file:///Users/daviditc/Documents/personal_projects/smart-hisab/doc/staff/STAFF.md)

---

## Screen Map

```
StaffScreen (Staff Directory)
  ├── [Filter: Active / Inactive]
  ├── [Swipe Left]   ─► Quick Advance Payout (RecordSalaryPayoutBottomSheet)
  ├── [Swipe Right]  ─► Edit Staff (AddStaffBottomSheet in edit mode)
  ├── [Tap Card]     ─► StaffDetailScreen
  └── [FAB / Header] ─► AddStaffBottomSheet

StaffDetailScreen
  ├── [CTA: Record Payout]  ─► RecordSalaryPayoutBottomSheet
  ├── [CTA: Mark Attendance] ─► AttendanceMarkBottomSheet
  ├── [CTA: Set PIN]        ─► SetPinBottomSheet
  └── [CTA: Reset PIN]      ─► Confirmation dialog → reset_staff_pin

HomeScreen (POS)
  └── [Staff PIN Authorization] ─► PinEntryOverlay → verify_staff_pin
```

---

## Screen Flows & State Transitions

### 1. `StaffScreen`

| State | UI |
| :--- | :--- |
| Loading | Shimmer staff card list (4 rows) |
| Loaded | Staff cards with name, role chip, salary terms, advance balance |
| Filtered | Toggle "Active / Inactive" — local filter, no API call |
| Empty | Empty state card with "Add First Staff Member" CTA — **header button hidden** |

**Header Summary Card** (when non-empty):
- Total monthly payroll liability: `SUM(monthly_salary)` for active staff
- Total outstanding advances: `SUM(current_advance_balance)`

**Pull-to-Refresh**: Refreshes `staffNotifierProvider`.

---

### 2. `AddStaffBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Name | TextInput | 2–60 chars, required |
| Phone | TextInput | Optional; numeric |
| Role | Dropdown | Options: `owner`, `manager`, `staff`; Default: `staff` |
| Salary Type | Toggle | `monthly` or `daily` |
| Monthly Salary | NumericInput | Required if `salary_type = monthly`; `>= 0` |
| Daily Rate | NumericInput | Required if `salary_type = daily`; `>= 0` |

| Mode | CTA | Action |
| :--- | :--- | :--- |
| Add | "Add Staff Member" | `.from('staff_members').insert(...)` → trigger auto-creates `staff_wallets` → prepend to list |
| Edit | "Save Changes" | `.from('staff_members').update(...).eq('id', id)` → mutate local item |

---

### 3. `StaffDetailScreen`

| Section | Content |
| :--- | :--- |
| Header Card | Name, role chip, salary terms (`Monthly: ৳12,000` or `Daily: ৳500`) |
| Wallet Summary | Current Advance Balance (orange if `> 0`), Total Salary Paid |
| Quick Actions | "Record Payout", "Mark Attendance", "Set PIN" / "Reset PIN" |
| Payout History | Chronological payout list with advance vs salary indicators |

| State | UI |
| :--- | :--- |
| Loading | Shimmer on header + 3 payout skeleton rows |
| Loaded | Full detail view |
| Empty payouts | "No payouts yet" message |

**Pull-to-Refresh**: Refreshes payout list via `staffDetailNotifierProvider.refresh()`.

---

### 4. `RecordSalaryPayoutBottomSheet`

> **Modal**: Rounded top `32px`. No close button. Opens from CTA or swipe quick-action.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Payout Type | Segmented toggle | `Advance` or `Full Salary` |
| Amount | NumericInput | `> 0`; for `salary`, pre-fills `monthly_salary` |
| Payout Month | MonthPicker | Required for `salary` type; defaults to current month |
| Payment Account | Dropdown | Required — from `canteen_accounts` |
| Notes | TextInput | Optional |

**RPC**: `record_salary_payout_v2(p_tenant_id, p_staff_id, p_canteen_account_id, p_amount, p_payout_type, p_payout_month, p_business_day_id, p_notes)`

**Cache Mutations**:

| Payout Type | Mutations |
| :--- | :--- |
| `advance` | `current_advance_balance += amount`; prepend advance row to detail |
| `salary` | `total_salary_paid += amount`; **reset** `current_advance_balance = 0`; prepend salary row; append expense to cashbook |

---

### 5. `SetPinBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| New PIN | 4-digit NumericKeypad | Exactly 4 digits |
| Confirm PIN | 4-digit NumericKeypad | Must match New PIN |

**RPC**: `set_staff_pin(p_staff_id, p_pin)`
**Cache Mutation**: Update `pin_code` field on local staff item.

---

### 6. POS Staff PIN Authorization Overlay

> Full-screen overlay or modal with numeric keypad. Shown before unlocking restricted POS operations.

| State | UI |
| :--- | :--- |
| Idle | 4-dot placeholder row + numeric keypad |
| Entering | Dots fill left to right as digits entered |
| Verifying | Spinning indicator |
| Valid | Overlay dismisses, action unlocked |
| Invalid | Dots shake animation + "Incorrect PIN" label; clears input |

**RPC**: `verify_staff_pin(p_tenant_id, p_pin)`
**No local cache mutation** — ephemeral session authorization only.

---

### 7. Attendance Flow (`AttendanceMarkBottomSheet`)

> **Modal**: Rounded top `32px`. No close button.

| Field | Type |
| :--- | :--- |
| Status | Segmented picker: `Present`, `Absent`, `Half Day`, `Leave` |
| Check-in Time | TimePicker (optional) |
| Check-out Time | TimePicker (optional) |
| Notes | TextInput (optional) |

**API**: `.from('staff_attendance').insert(...)` or `.upsert(...)` on `(staff_id, attendance_date)` unique.

---

## Validation Rules

| Field | Rule |
| :--- | :--- |
| Staff Name | 2–60 characters, required |
| Monthly Salary | `>= 0` if salary type is monthly |
| Daily Rate | `>= 0` if salary type is daily |
| Payout Amount | `> 0` |
| Payout Month | Required for full salary payouts |
| PIN | Exactly 4 numeric digits |
| Confirm PIN | Must match new PIN |
