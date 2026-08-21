# Dialog: Staff PIN Verification

## 1. Description
4-digit PIN verification modal bottom sheet used for cashier switch, drawer open overrides, or supervisor authorization.

---

## 2. User Actions
| Action Name | Trigger | Intended Outcome |
| :--- | :--- | :--- |
| **Enter PIN** | Tap 4 digits on custom keypad | Calls `verify_staff_pin` RPC, validates authorization, returns staff profile. |

---

## 3. APIs Used

### Mutation RPC: `verify_staff_pin`
* **Method**: `supabase.rpc('verify_staff_pin', params: {...})`
* **Input Payload**:
```json
{
  "p_tenant_id": "e2a3b4c5-0000-0000-0000-000000000001",
  "p_pin": "1234"
}
```
* **Output Response**:
```json
{
  "valid": true,
  "staff_id": "22f3e4d5-0000-0000-0000-000000000001",
  "name": "Abul Kashem",
  "role": "Head Chef"
}
```
