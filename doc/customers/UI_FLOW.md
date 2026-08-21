# Customers & Meal AR — UI Flow

> **Module Blueprint**: [`CUSTOMERS.md`](file:///Users/daviditc/Documents/personal_projects/smart-hisab/doc/customers/CUSTOMERS.md)

---

## Screen Map

```
HomeScreen
  └── QuickCustomerPickerBottomSheet (Fast Meal Punch)
        └── [Select Customer + Shift] ─► record_meal_attendance ──► balance updated

CustomersScreen (Customer List)
  ├── [Search / Filter by Shift]
  ├── [Swipe Left]  ─► Quick Collect Baki (CollectBakiBottomSheet)
  ├── [Swipe Right] ─► Edit Customer (AddCustomerBottomSheet in edit mode)
  ├── [Tap Card]    ─► CustomerDetailScreen
  └── [FAB / Header] ─► AddCustomerBottomSheet

CustomerDetailScreen
  ├── [Quick Action: Collect Baki]     ─► CollectBakiBottomSheet
  ├── [Quick Action: Add Baki]         ─► AddManualBakiBottomSheet
  ├── [Quick Action: Subscriptions]    ─► ManageMealSubscriptionBottomSheet
  ├── [Quick Action: Calendar]         ─► MealAttendanceCalendarBottomSheet
  └── [Swipe on Transaction Row]       ─► VoidTransactionBottomSheet

Settings ─► MealConfigsScreen
  └── [Tap / FAB] ─► MealConfigFormBottomSheet
```

---

## Screen Flows & State Transitions

### 1. `CustomersScreen`

| State | UI |
| :--- | :--- |
| Loading | Shimmer skeleton (5 customer card rows) |
| Loaded | Customer cards with name, phone, balance badge |
| Searching | Debounced (300ms) — filters name/phone in local state, no extra API call |
| Filtered by Shift | Horizontal shift chip filter → local filter on `subscribed_shifts` array |
| Empty (no customers) | Empty state card with "Add First Customer" CTA centered — **header button hidden** |
| Empty (search no match) | "No customers match your search" message |

**Pull-to-Refresh**: Calls `customersNotifierProvider.refresh()`.

---

### 2. `AddCustomerBottomSheet` (Add / Edit)

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Name | TextInput | 2–60 chars, non-empty |
| Phone | TextInput | Optional; numeric, up to 15 digits |
| Opening Balance | NumericInput | `>= 0`; positive debt or 0 |
| Subscribed Shifts | Multi-select chips | Optional; uses shift IDs from `shiftsNotifierProvider` |

| Mode | CTA | Action |
| :--- | :--- | :--- |
| Add | "Add Customer" | `create_or_reactivate_customer` RPC → prepend to list optimistically |
| Edit | "Save Changes" | `.from('customers').update(...)` → mutate local item |

**Duplicate Guard**: If phone matches an inactive customer, reactivates them with `reactivated: true` response.

---

### 3. `QuickCustomerPickerBottomSheet` (Home POS Meal Punch)

| Step | State | UI |
| :--- | :--- | :--- |
| 1 | Idle | Search input + scrollable customer list, current shift badge at top |
| 1 | Loading | Shimmer rows |
| 2 | Customer Selected | Meal rate pre-filled from `meal_configs` for current shift |
| 2 | Confirming | "Punch Meal (৳60)" CTA button with rate shown |
| 3 | Success | Toast + balance badge increments visually — sheet closes |
| 3 | Error | "No active business day" or "Customer not found" inline error |

**RPC**: `record_meal_attendance(p_tenant_id, p_customer_id, p_shift_id, p_rate, p_business_day_id)`
**Optimistic Update**: `customer.wallet.current_balance += rate` immediately.

---

### 4. `CustomerDetailScreen`

| Section | Content |
| :--- | :--- |
| Header Card | Customer name, phone, current balance badge (color: red if `> 0`, green if `< 0`) |
| Quick Actions Grid | 4 tappable action buttons (Collect Baki, Add Baki, Subscriptions, Calendar) |
| Transaction History | Chronological scrollable list with debit/credit chips, amount, date |

| State | UI |
| :--- | :--- |
| Loading | Shimmer on header card + 5 skeleton transaction rows |
| Loaded | Full detail view |
| Empty statement | "No transactions yet" inline message |

**Pull-to-Refresh**: Calls `customerDetailNotifierProvider(id).refresh()`.
**Swipe on Transaction Row**: Opens `VoidTransactionBottomSheet`.

---

### 5. `CollectBakiBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Amount | NumericInput | `> 0`; cannot exceed current balance (warn, not block) |
| Payment Account | Dropdown | Required — selects from `canteen_accounts` |
| Notes | TextInput | Optional |

**RPC**: `record_baki_payment_v2(...)`
**Cache Mutations**:
1. `customer.wallet.current_balance -= amount`
2. Prepend credit row to detail statement
3. Append income entry to cashbook

---

### 6. `AddManualBakiBottomSheet`

| Field | Type | Validation |
| :--- | :--- | :--- |
| Amount | NumericInput | `> 0` |
| Notes | TextInput | Optional |

**API**: `.from('wallet_entries').insert({entry_type: 'debit', ...})`
**Cache Mutation**: `current_balance += amount` in list + prepend debit row in detail.

---

### 7. `VoidTransactionBottomSheet`

> **Modal**: Rounded top `32px`. No close button. Triggered by swiping transaction row.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Void Reason | TextInput | Required; 5–200 chars |

**RPCs**:
- `void_wallet_entry(p_entry_id, p_reason)` — for meal punches, baki entries
- `void_meal_attendance(p_attendance_id, p_reason)` — for meal attendance records

**Cache Mutation**: Set `is_voided = true` on row; reverse balance delta locally.

---

## Validation Rules

| Field | Rule |
| :--- | :--- |
| Customer Name | 2–60 characters, required |
| Phone | Optional; valid numeric format |
| Opening Balance | `>= 0` |
| Meal Rate | `> 0`; auto-filled from `meal_configs` |
| Collection Amount | `> 0`; show warning if exceeds balance (do not block) |
| Void Reason | Required; minimum 5 characters |
