# Modal: Void Transaction (Audit Log)

## 1. Description
Modal bottom sheet with mandatory reason text field to void an erroneous transaction (meal punch, baki repayment, expense, vendor payment, salary payout). Maintains complete database audit trail without hard deletes.

* **Dart File**: [void_transaction_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/void_transaction_bottom_sheet.dart)

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Void Entry** | Enter Reason (minimum 5 chars), tap "Confirm Void" | Invokes `void_wallet_entry` or `void_day_entry` RPC, flags transaction as voided, updates balances. |

---

## 3. APIs Used

### 1. Mutation RPC: `void_wallet_entry` (Customer / Vendor / Staff Ledger)
* **Method**: `supabase.rpc('void_wallet_entry', params: {...})`
* **Input Payload**:
```json
{
  "p_entry_id": "55a6b7c8-0000-0000-0000-000000000001",
  "p_reason": "Customer was double charged by mistake"
}
```
* **Output Response**:
```json
{
  "success": true,
  "entry_id": "55a6b7c8-0000-0000-0000-000000000001",
  "voided": true
}
```
* **Target Local Cache Mutation**:
  * Sets `is_voided: true` on entry in local ledger state.
  * Reverts the balance impact in `customer_wallets` / `vendor_wallets` / `staff_wallets`.

### 2. Mutation RPC: `void_day_entry` (Cashbook Expense / Income)
* **Method**: `supabase.rpc('void_day_entry', params: {'p_entry_id': 'uuid', 'p_reason': 'string'})`
* **Output Response**: `{"success": true, "entry_id": "uuid", "voided": true}`
