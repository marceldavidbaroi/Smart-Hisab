# Cashbook & Canteen Wallets — UI Flow

> **Module Blueprint**: [`CASHBOOK.md`](file:///Users/daviditc/Documents/personal_projects/smart-hisab/doc/cashbook/CASHBOOK.md)

---

## Screen Map

```
CashbookScreen
  ├── [Wallet Selector Chips] ─► Filter by account
  ├── [FAB: Add Expense]      ─► AddExpenseBottomSheet
  ├── [FAB: Add Income]       ─► AddIncomeBottomSheet
  ├── [FAB: Transfer Funds]   ─► TransferFundsBottomSheet
  ├── [Swipe on Entry Row]    ─► VoidTransactionBottomSheet
  └── [Pull to Refresh]       ─► Full refetch

BazarScreen
  └── BazarNoteDetailScreen (individual bazar note)

Settings ─► ManageAccountsScreen
  └── AccountFormBottomSheet (Add / Edit canteen account)
```

---

## Screen Flows & State Transitions

### 1. `CashbookScreen`

| State | UI |
| :--- | :--- |
| Loading | Shimmer on wallet chip row + 5 entry skeleton rows |
| Loaded | Account balance chips, day summary totals, scrollable entry feed |
| Filtered | Wallet chip tap → local filter on `canteen_account_id` (no API call) |
| Empty (no entries) | "No entries today" message, FABs still visible |

**Pull-to-Refresh**: Refreshes `cashbookNotifierProvider`.

**Wallet Chips**:
- "All Accounts" — unfiltered total
- One chip per `canteen_account` (Cash Drawer, bKash, Bank, etc.)
- Each chip shows live `current_balance`

**Day Summary Cards**:
- Cash In: `SUM(income entries)` for selected account filter
- Cash Out: `SUM(expense entries)` for selected account filter
- Net: `Cash In - Cash Out`

---

### 2. `AddExpenseBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Category | Dropdown/Chip | Required: `bazar`, `utilities`, `rent`, `other`, etc. |
| Amount | NumericInput | `> 0` |
| Account | Dropdown | Required — from `canteen_accounts` |
| Notes | TextInput | Optional |
| Business Day | Auto-resolved | From `businessDayNotifierProvider.activeDayId` |

**RPC**: `record_expense_v2(p_tenant_id, p_canteen_account_id, p_category, p_amount, p_business_day_id, p_notes)`

**Cache Mutations**:
1. Prepend entry row to feed
2. Decrement `account.current_balance -= amount`

---

### 3. `AddIncomeBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Income Source / Notes | TextInput | Optional |
| Amount | NumericInput | `> 0` |
| Account | Dropdown | Required |

**API**: `.from('day_entries').insert({entry_type: 'income', ...})`

**Cache Mutations**:
1. Prepend income row to feed
2. Increment `account.current_balance += amount`

---

### 4. `TransferFundsBottomSheet`

> **Modal**: Rounded top `32px`. No close button.

| Field | Type | Validation |
| :--- | :--- | :--- |
| From Account | Dropdown | Required; must differ from To Account |
| To Account | Dropdown | Required |
| Amount | NumericInput | `> 0`; warn if exceeds source balance |
| Notes | TextInput | Optional |

**RPC**: `transfer_canteen_funds(p_tenant_id, p_from_account_id, p_to_account_id, p_amount, p_business_day_id, p_notes)`

**Cache Mutations**:
1. Decrement `fromAccount.current_balance -= amount`
2. Increment `toAccount.current_balance += amount`
3. Append `transfer_out` row for source
4. Append `transfer_in` row for target

---

### 5. `VoidTransactionBottomSheet`

> **Modal**: Rounded top `32px`. No close button. Triggered by swiping entry row left.

| Field | Type | Validation |
| :--- | :--- | :--- |
| Void Reason | TextInput | Required; 5–200 chars |

**RPCs**:
- `void_day_entry(p_entry_id, p_reason)` — for cashbook income/expense entries
- `void_wallet_entry(p_entry_id, p_reason)` — for customer/vendor/staff journal entries

**Cache Mutations**:
1. Set `is_voided = true` on the row
2. Reverse balance delta on the affected account

---

### 6. `BazarScreen`

| State | UI |
| :--- | :--- |
| Loading | Shimmer bazar note cards |
| Loaded | Date-grouped bazar entries with daily total |
| Empty | "No bazar entries yet" card with CTA to add bazar expense |

**Tap on entry** → `BazarNoteDetailScreen` (itemized grocery breakdown, totals, date).

---

## Entry Row Design

Each `day_entries` row displays:
- **Category icon** (left)
- **Category label** + notes snippet
- **Account chip** (small badge showing which wallet)
- **Amount** (right-aligned; red for expense, green for income)
- **Time** (relative: "2h ago" or absolute if > 1 day)
- **Voided badge** (shown as strikethrough + "VOIDED" label)

**Swipe Actions** (swipeable row):
- Swipe left → Void action (red background, trash icon)

---

## Validation Rules

| Field | Rule |
| :--- | :--- |
| Expense / Income Amount | `> 0` |
| Transfer Amount | `> 0`; warn if source balance insufficient |
| From / To Accounts | Must be different accounts |
| Void Reason | Required; 5–200 characters |
| Business Day | Must be open — enforced at RPC level; UI disables add buttons if no active day |
