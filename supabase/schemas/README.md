# Supabase Declarative Schemas

This directory contains the active, declarative PostgreSQL schema definitions for Smart Hisab, partitioned into 6 isolated business domains with a strict 4-tier separation per domain.

## Directory Layout

```text
supabase/schemas/
├── README.md
├── _extensions.sql
├── 01_auth_tenancy/
│   ├── 01_types.sql
│   ├── 02_tables.sql
│   ├── 03_rpcs.sql
│   └── 04_rls.sql
├── 02_business_days_shifts/
│   ├── 01_types.sql
│   ├── 02_tables.sql
│   ├── 03_rpcs.sql
│   └── 04_rls.sql
├── 03_customers_meal_ar/
│   ├── 01_types.sql
│   ├── 02_tables.sql
│   ├── 03_rpcs.sql
│   └── 04_rls.sql
├── 04_cashbook_wallets/
│   ├── 01_types.sql
│   ├── 02_tables.sql
│   ├── 03_rpcs.sql
│   └── 04_rls.sql
├── 05_vendors_ap/
│   ├── 01_types.sql
│   ├── 02_tables.sql
│   ├── 03_rpcs.sql
│   └── 04_rls.sql
└── 06_staff_payroll/
    ├── 01_types.sql
    ├── 02_tables.sql
    ├── 03_rpcs.sql
    └── 04_rls.sql
```
