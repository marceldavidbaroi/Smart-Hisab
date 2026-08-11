# Feature: Staff & Payroll — RPC / APIs

> RPC functions for staff management, salary payouts, and salary history.

---

## `record_salary_payout`

Record a salary payment to a staff member.

| | |
|---|---|
| **Parameters** | `p_tenant_id UUID`, `p_staff_id UUID`, `p_amount NUMERIC`, `p_payment_mode TEXT`, `p_notes TEXT` |
| **Returns** | `UUID` (salary_payout ID) |
| **Side effects** | INSERT `salary_payouts` + INSERT `day_entries` (outflow, category: `salary_outflow`) |
| **Payment modes** | `cash`, `bank`, `mobile_money` |
| **Auth** | Owner or Manager only |

---

## `reset_staff_pin`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Owner/Manager generates a new temporary PIN for a staff member.

| | |
|---|---|
| **Parameters** | `p_staff_id UUID` |
| **Returns** | `TEXT` (new 4-digit temp PIN — shown once, never stored in plain text after) |
| **Side effects** | Overwrites `staff_members.temp_pin`, clears `hashed_pin` |
| **Auth** | Owner or Manager of the tenant |

---

## `set_staff_pin`

> [!NOTE]
> **Status: Not yet implemented in migration SQL.**

Staff member replaces their temporary PIN with a permanent bcrypt-hashed PIN.

| | |
|---|---|
| **Parameters** | `p_staff_id UUID`, `p_temp_pin TEXT`, `p_new_pin TEXT` |
| **Returns** | `BOOLEAN` |
| **Side effects** | Sets `hashed_pin` (bcrypt), clears `temp_pin` |

> See also: `verify_staff_pin` in [01_tenancy_and_auth/rpc_apis.md](../01_tenancy_and_auth/rpc_apis.md) — used at the PIN Gate screen.
