# Smart Hisab

High-speed, offline-first canteen POS & ERP platform for Android — built with **Flutter** + **Supabase**.

---

## Documentation

All project documentation lives in [`doc/`](./doc/):

| File | Purpose |
| :--- | :--- |
| [`doc/MASTER_PLAN.md`](./doc/MASTER_PLAN.md) | System overview, architecture rules, domain map, RPC contract matrix, dev setup & commands |
| [`doc/auth/AUTH.md`](./doc/auth/AUTH.md) | Auth & multi-tenancy domain blueprint |
| [`doc/shifts/SHIFTS.md`](./doc/shifts/SHIFTS.md) | Business days & shifts domain blueprint |
| [`doc/customers/CUSTOMERS.md`](./doc/customers/CUSTOMERS.md) | Customers & meal AR domain blueprint |
| [`doc/cashbook/CASHBOOK.md`](./doc/cashbook/CASHBOOK.md) | Cashbook & wallets domain blueprint |
| [`doc/vendors/VENDORS.md`](./doc/vendors/VENDORS.md) | Vendors & AP domain blueprint |
| [`doc/staff/STAFF.md`](./doc/staff/STAFF.md) | Staff & payroll domain blueprint |

Each module also has a `UI_FLOW.md` with screen maps, state transitions, bottom sheet specs, and validation rules.

---

## Database Schema

Declarative SQL source of truth lives in [`supabase/schemas/`](./supabase/schemas/) — split by domain into 4 tiers per module: `01_types`, `02_tables`, `03_rpcs`, `04_rls`.

See [`supabase/schemas/README.md`](./supabase/schemas/README.md) for the load order index.

---

## Quick Start

See **Section 8** of [`doc/MASTER_PLAN.md`](./doc/MASTER_PLAN.md) for full dev setup, emulator commands, and Supabase CLI workflow.

```bash
# Run Flutter app
cd mobile && flutter run

# Start local Supabase
npx supabase start

# Reset & reseed local DB
npx supabase db reset
```

---

## Tech Stack

| Layer | Technology |
| :--- | :--- |
| Mobile | Flutter (Dart), Riverpod, Hive |
| Backend | Supabase (PostgreSQL, RLS, PL/pgSQL RPCs) |
| Auth | Supabase Auth (OTP — email & phone) |
| Target Platform | Android |
