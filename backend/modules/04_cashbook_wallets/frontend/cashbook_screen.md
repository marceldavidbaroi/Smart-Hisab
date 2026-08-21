# Screen: Cashbook Register & Wallets

## 1. Description
Central accounting register. Displays multi-account wallet selector (All, Cash Drawer, bKash, Bank), daily cash in/out summaries, filterable transaction list, and quick action buttons for logging finances.

* **Dart File**: [cashbook_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/cashbook_screen.dart)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch APIs
1. **Fetch Canteen Accounts**:
   * **Query**: `.from('canteen_accounts').select('*').eq('tenant_id', tenantId).order('is_default', ascending: false)`
   * **Response**:
```json
[
  {
    "id": "11a2b3c4-0000-0000-0000-000000000001",
    "name": "Cash Drawer",
    "account_type": "cash_drawer",
    "is_default": true,
    "current_balance": 4550.00
  },
  {
    "id": "22b3c4d5-0000-0000-0000-000000000001",
    "name": "bKash Merchant",
    "account_type": "bkash",
    "is_default": false,
    "current_balance": 12000.00
  }
]
```
2. **Fetch Day Entries (Cashbook Register)**:
   * **Query**: `.from('day_entries').select('*, canteen_accounts(*)').eq('tenant_id', tenantId).order('created_at', ascending: false)`
   * **Response**:
```json
[
  {
    "id": "entry-1",
    "entry_type": "expense",
    "category": "bazar",
    "amount": 1250.00,
    "notes": "Morning grocery",
    "created_at": "2026-08-21T07:30:00Z",
    "is_voided": false,
    "canteen_accounts": { "name": "Cash Drawer" }
  }
]
```

### B. Riverpod State
* **Provider Name**: `cashbookNotifierProvider`
* **Type**: `AsyncNotifier<CashbookState>` (Stores `List<CanteenAccount>`, `List<DayEntry>`, `selectedAccountId`)
* **Local Cache**: Hive Box `cashbook_cache_<tenant_id>`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Select Wallet Tab** | Tap Wallet Chip (Cash/bKash) | `selectAccount(accountId)` | None (In-memory) | Filters transaction list to entries belonging to selected account. |
| **Add Expense** | Tap "Add Expense" FAB | `recordExpense(...)` | `record_expense_v2` | Prepends expense entry to local list; decrements account balance. |
| **Add Income** | Tap "Add Income" FAB | `recordIncome(...)` | `.from('day_entries').insert(...)` | Prepends income entry; increments account balance. |
| **Transfer Funds** | Tap "Transfer Funds" | `transferFunds(...)` | `transfer_canteen_funds` | Updates both account balances; adds transfer journal entries. |
| **Void Entry** | Swipe row -> Tap "Void" | `voidDayEntry(id, reason)` | `void_day_entry` | Sets `is_voided = true` on row; recalculates net balance. |

---

## 4. Complete API & RPC Specifications

### 1. `record_expense_v2`
* **Method**: `supabase.rpc('record_expense_v2', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_category": "bazar",
  "p_amount": 1250.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_notes": "Morning vegetable & poultry bazar"
}
```
* **Response**:
```json
{
  "success": true,
  "day_entry_id": "44a5b6c7-0000-0000-0000-000000000001",
  "canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "amount": 1250.00,
  "category": "bazar"
}
```

### 2. `transfer_canteen_funds`
* **Method**: `supabase.rpc('transfer_canteen_funds', params: {...})`
* **Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_from_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_to_account_id": "22b3c4d5-0000-0000-0000-000000000001",
  "p_amount": 5000.00
}
```
* **Response**:
```json
{
  "success": true,
  "from_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "to_account_id": "22b3c4d5-0000-0000-0000-000000000001",
  "amount": 5000.00
}
```
