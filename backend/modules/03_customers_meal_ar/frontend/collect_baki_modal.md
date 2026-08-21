# Modal: Collect Baki (Customer Repayment)

## 1. Description
Modal bottom sheet to record customer debt repayments into a specific Canteen Account (Cash Drawer, bKash Merchant, Bank Account). Automatically credits customer ledger, updates customer cached balance, and logs cashbook income for the active business day.

* **Dart File**: [collect_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/collect_baki_bottom_sheet.dart)
* **Riverpod Providers**: `customersNotifierProvider`, `customerDetailNotifierProvider`, `cashbookNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Record Repayment** | Select Account (Cash Drawer / bKash), enter Amount, tap "Confirm Payment" | Calls `record_baki_payment_v2` RPC, updates customer balance, appends cashbook entry. |

---

## 3. APIs Used

### Mutation RPC: `record_baki_payment_v2`
* **Method**: `supabase.rpc('record_baki_payment_v2', params: {...})`
* **Input Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "p_canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_amount": 500.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_notes": "Paid at counter"
}
```
* **Output Response**:
```json
{
  "success": true,
  "wallet_entry_id": "55a6b7c8-0000-0000-0000-000000000001",
  "customer_id": "99f8c12a-0000-0000-0000-000000000001",
  "canteen_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "amount": 500.00
}
```
* **Target Local Cache Mutation**:
  * Decrements `customer.wallet.current_balance` by 500.00 in `customersNotifierProvider`.
  * Appends credit entry to statement list in `customerDetailNotifierProvider`.
  * Prepends income entry in `cashbookNotifierProvider`.
