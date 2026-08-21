# Modal: Transfer Funds Between Accounts

## 1. Description
Modal bottom sheet to transfer liquid funds between canteen accounts (e.g. depositing physical cash from the Cash Drawer into the Bank or bKash Merchant account).

* **Riverpod Provider**: `cashbookNotifierProvider`

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Transfer Funds** | Select From Account, To Account, Amount, tap "Confirm Transfer" | Calls `transfer_canteen_funds` RPC, updates both wallet balances, creates transfer logs. |

---

## 3. APIs Used

### Mutation RPC: `transfer_canteen_funds`
* **Method**: `supabase.rpc('transfer_canteen_funds', params: {...})`
* **Input Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_from_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "p_to_account_id": "22b3c4d5-0000-0000-0000-000000000001",
  "p_amount": 5000.00,
  "p_business_day_id": "8f3b6a9c-0000-0000-0000-000000000001",
  "p_notes": "Deposited daily cash to bank"
}
```
* **Output Response**:
```json
{
  "success": true,
  "from_account_id": "11a2b3c4-0000-0000-0000-000000000001",
  "to_account_id": "22b3c4d5-0000-0000-0000-000000000001",
  "amount": 5000.00
}
```
* **Target Local Cache Mutation**:
  * Decrements sender account balance by 5000.00.
  * Increments receiver account balance by 5000.00.
  * Inserts transfer_out and transfer_in records into local list.
