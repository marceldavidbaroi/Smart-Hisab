# Smart-Hisab Documentation

## Structure

```
docs/
├── README.md                              # You are here (navigation + RPC quick-reference)
├── core/                                  # System-wide references
│   ├── app_vision.md                      # Product definition, users, problems solved
│   ├── auth_flow_v2.md                    # Auth flow, Google Sign-In, multi-tenant
│   ├── feature_availability.md           # ✅/❌ feature matrix across v1.0 / v1.5 / v2.0
│   ├── first_time_setup_and_user_guide.md # Onboarding checklist & daily operating guidelines
│   └── offline_architecture.md           # Hive local box schemas, outbox pattern, sync engine
│
├── features/                          # Backend domain specs (Schema + RPCs)
│   ├── 01_tenancy_and_auth/
│   │   ├── schema.md                  # Tables: user_profiles, tenants, tenant_members, tenant_invites
│   │   └── rpc_apis.md               # create_tenant, generate_invite_code, join_tenant_by_code, verify_staff_pin
│   │
│   ├── 02_meal_attendance/
│   │   ├── schema.md                  # Tables: shifts, meal_configs, meal_attendance
│   │   └── rpc_apis.md               # get_current_shift, record_meal_attendance, bulk_record_meal_attendance
│   │
│   ├── 03_customer_wallets_ar/
│   │   ├── schema.md                  # Tables: customers, customer_wallets, wallet_entries
│   │   └── rpc_apis.md               # record_baki_payment, get_customer_balance, get_customer_statement
│   │
│   ├── 04_bazar_and_expenses_ap/
│   │   ├── schema.md                  # Tables: vendors, vendor_wallets, vendor_wallet_entries, day_entries, day_notes
│   │   └── rpc_apis.md               # record_expense, record_misc_income, record_vendor_payment, get_vendor_statement
│   │
│   ├── 05_staff_payroll/
│   │   ├── schema.md                  # Tables: staff_members, staff_wallets, staff_attendance, salary_payouts
│   │   └── rpc_apis.md               # record_salary_payout, reset_staff_pin, set_staff_pin
│   │
│   └── 06_shift_reconciliation/
│       ├── schema.md                  # Tables: business_days
│       └── rpc_apis.md               # start_business_day, end_business_day, resume_business_day, get_financial_summary
│
└── releases/                          # Frontend & release screen maps (Screens → RPCs)
    ├── v1.0/
    │   └── screen_map.md              # Free tier: 17 pages, 15 bottom sheets + RPC bindings
    ├── v1.5/
    │   └── screen_map.md              # Pro tier: +5 pages, Counter Mode, Reports/Analytics
    └── v2.0/
        └── screen_map.md              # Business tier: Multi-canteen, Bulk attendance, PDF export
```

## How to Use This Docs

### Backend Engineer
1. Open the relevant `features/0X_*/schema.md` for table definitions, RLS rules, and triggers.
2. Open `features/0X_*/rpc_apis.md` for the exact RPC signatures, parameters, return types, and side effects to implement.

### Frontend / Mobile Engineer
1. Open the target release `releases/vX.X/screen_map.md` — each screen lists:
   - The screens UI layout
   - Exact RPC names called for each action
   - Which feature module to cross-reference for parameter details

### Quick RPC Reference

| RPC | Feature Module |
|---|---|
| `create_tenant` | [01_tenancy_and_auth](features/01_tenancy_and_auth/rpc_apis.md) |
| `generate_invite_code` | [01_tenancy_and_auth](features/01_tenancy_and_auth/rpc_apis.md) |
| `join_tenant_by_code` | [01_tenancy_and_auth](features/01_tenancy_and_auth/rpc_apis.md) |
| `verify_staff_pin` | [01_tenancy_and_auth](features/01_tenancy_and_auth/rpc_apis.md) |
| `set_staff_pin` / `reset_staff_pin` | [05_staff_payroll](features/05_staff_payroll/rpc_apis.md) |
| `get_current_shift` | [02_meal_attendance](features/02_meal_attendance/rpc_apis.md) |
| `record_meal_attendance` | [02_meal_attendance](features/02_meal_attendance/rpc_apis.md) |
| `bulk_record_meal_attendance` | [02_meal_attendance](features/02_meal_attendance/rpc_apis.md) |
| `create_or_reactivate_customer` | [03_customer_wallets_ar](features/03_customer_wallets_ar/rpc_apis.md) |
| `record_baki_payment` | [03_customer_wallets_ar](features/03_customer_wallets_ar/rpc_apis.md) |
| `get_customer_balance` / `get_customer_statement` | [03_customer_wallets_ar](features/03_customer_wallets_ar/rpc_apis.md) |
| `record_expense` | [04_bazar_and_expenses_ap](features/04_bazar_and_expenses_ap/rpc_apis.md) |
| `record_vendor_payment` | [04_bazar_and_expenses_ap](features/04_bazar_and_expenses_ap/rpc_apis.md) |
| `record_misc_income` | [04_bazar_and_expenses_ap](features/04_bazar_and_expenses_ap/rpc_apis.md) |
| `record_salary_payout` | [05_staff_payroll](features/05_staff_payroll/rpc_apis.md) |
| `start_business_day` / `end_business_day` / `resume_business_day` | [06_shift_reconciliation](features/06_shift_reconciliation/rpc_apis.md) |
| `get_active_business_day` / `calculate_expected_cash` | [06_shift_reconciliation](features/06_shift_reconciliation/rpc_apis.md) |
| `get_financial_summary` | [06_shift_reconciliation](features/06_shift_reconciliation/rpc_apis.md) |
