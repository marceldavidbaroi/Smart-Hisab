# Screen: Customer Detail & Ledger

## 1. Screen Identity & Hierarchy
* **Screen / Widget Class**: `CustomerDetailScreen`
* **Dart Source File**: [customer_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/customer_detail_screen.dart)
* **Parent / Hosting Shell**: Standalone Route pushed from [customers_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/customers_screen.dart) (`CustomersScreen`)
* **Child Modals Launched**:
  * [collect_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/collect_baki_bottom_sheet.dart) (`CollectBakiBottomSheet`)
  * [add_manual_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/add_manual_baki_bottom_sheet.dart) (`AddManualBakiBottomSheet`)
  * [manage_meal_subscription_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/manage_meal_subscription_bottom_sheet.dart) (`ManageMealSubscriptionBottomSheet`)
  * [meal_attendance_calendar_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/meal_attendance_calendar_bottom_sheet.dart) (`MealAttendanceCalendarBottomSheet`)
  * [void_transaction_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/void_transaction_bottom_sheet.dart) (`VoidTransactionBottomSheet`)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch APIs
1. **Fetch Customer Balance**:
   * **RPC**: `get_customer_balance(p_customer_id: "uuid")`
   * **Response**:
```json
{
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "customer_name": "Rahim Uddin",
  "current_balance": 350.00,
  "total_debit": 1250.00,
  "total_credit": 900.00,
  "last_transaction_at": "2026-08-21T13:00:00Z"
}
```
2. **Fetch Chronological Statement**:
   * **RPC**: `get_customer_statement(p_customer_id: "uuid", p_start_date: null, p_end_date: null)`
   * **Response**:
```json
[
  {
    "id": "entry-1",
    "entry_type": "debit",
    "category": "meal",
    "amount": 60.00,
    "notes": "Lunch meal charge",
    "created_at": "2026-08-21T13:00:00Z",
    "is_voided": false,
    "account_name": null
  },
  {
    "id": "entry-2",
    "entry_type": "credit",
    "category": "baki_payment",
    "amount": 500.00,
    "notes": "Baki payment via Cash Drawer",
    "created_at": "2026-08-20T17:00:00Z",
    "is_voided": false,
    "account_name": "Cash Drawer"
  }
]
```

### B. Riverpod State
* **Provider Name**: `customerDetailNotifierProvider(customerId)`
* **Type**: `AsyncNotifier<CustomerDetailState>` (Holds `CustomerBalance` and `List<CustomerStatementEntry>`)
* **Local Cache**: In-memory + synchronized with `customersNotifierProvider`

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Collect Baki** | Tap "Collect Baki" CTA | `collectBaki(amount, accountId)` | `record_baki_payment_v2` | Decrements `current_balance` by amount; prepends credit row to statement list. |
| **Add Manual Baki** | Tap "Add Baki (Debit)" CTA | `addDebitCharge(amount, notes)` | `.from('wallet_entries').insert(...)` | Increments `current_balance` by amount; prepends debit row to statement list. |
| **Manage Subscriptions** | Tap "Subscriptions" card | `updateSubscriptions(shifts)` | `.from('customers').update(...)` | Updates `customer.subscribedShifts` array in state. |
| **Filter Date Range** | Date Range Filter Chip | `filterByDate(start, end)` | `get_customer_statement` | Fetches filtered statement rows for selected dates. |
| **Void Entry** | Swipe row -> Tap "Void" | `voidEntry(entryId, reason)` | `void_wallet_entry` | Sets `is_voided = true` on the entry; reverts the balance impact. |

---

## 4. Complete API & RPC Specifications

### 1. `get_customer_balance`
* **Method**: `supabase.rpc('get_customer_balance', params: {'p_customer_id': 'uuid'})`
* **Payload**: `{"p_customer_id": "99f8c12a-0000-0000-0000-000000000001"}`
* **Response**:
```json
{
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "customer_name": "Rahim Uddin",
  "current_balance": 350.00,
  "total_debit": 1250.00,
  "total_credit": 900.00
}
```

### 2. `void_wallet_entry`
* **Method**: `supabase.rpc('void_wallet_entry', params: {...})`
* **Payload**:
```json
{
  "p_entry_id": "entry-1",
  "p_reason": "Charged customer for wrong meal type"
}
```
* **Response**:
```json
{
  "success": true,
  "entry_id": "entry-1",
  "voided": true
}
```
