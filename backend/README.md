# Smart Hisab — Backend Architecture & API Directory

## 1. Overview
Smart Hisab is architected as a modular, multi-tenant POS and accounting system built on Supabase (PostgreSQL + RLS + PL/pgSQL).
The backend is strictly divided into **6 isolated modules**. Each module owns its **`schema.sql`** (table structures, types, indexes, and RLS policies), **`rpcs.sql`** (stored procedures, atomic functions, and database triggers), and **`README.md`** (API contract with payload and response definitions).

```text
backend/
├── README.md                          # Master API directory & Index Summary Table (This file)
└── modules/
    ├── 01_auth_tenancy/               # Auth, multi-tenancy, memberships, invites
    │   ├── schema.sql
    │   ├── rpcs.sql
    │   └── README.md
    ├── 02_business_days_shifts/       # Register open/close, shifts, cash drawer reconciliation
    │   ├── schema.sql
    │   ├── rpcs.sql
    │   └── README.md
    ├── 03_customers_meal_ar/          # Customer AR, meal configs, meal punches, baki collection
    │   ├── schema.sql
    │   ├── rpcs.sql
    │   └── README.md
    ├── 04_cashbook_wallets/           # Multi-wallet accounts, expenses, transfers, voiding
    │   ├── schema.sql
    │   ├── rpcs.sql
    │   └── README.md
    ├── 05_vendors_ap/                 # Vendor directory, credit purchases (AP), settlements
    │   ├── schema.sql
    │   ├── rpcs.sql
    │   └── README.md
    └── 06_staff_payroll/              # Staff contracts, advances, attendance, payroll vouchers
        ├── schema.sql
        ├── rpcs.sql
        └── README.md
```

---

## 2. Master API & RPC Index Summary Table

| # | Module | RPC / Function Name | HTTP / Supabase Call | Purpose | Primary Payload | Primary Response | Calling Screen / UI |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `01_auth_tenancy` | `create_tenant` | `rpc('create_tenant')` | Creates new canteen & sets owner | `{"p_name": "string"}` | `{"success": true, "tenant_id": "uuid"}` | [create_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/create_canteen_screen.dart) |
| **2** | `01_auth_tenancy` | `generate_invite_code` | `rpc('generate_invite_code')` | Generates 6-digit staff/manager code | `{"p_tenant_id": "uuid", "p_role": "string"}` | `{"success": true, "invite_code": "string"}` | [invite_manager_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/invite_manager_screen.dart) |
| **3** | `01_auth_tenancy` | `join_tenant_by_code` | `rpc('join_tenant_by_code')` | Redeems invite code to join canteen | `{"p_code": "string"}` | `{"success": true, "tenant_id": "uuid"}` | [join_canteen_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/join_canteen_screen.dart) |
| **4** | `01_auth_tenancy` | `leave_canteen` | `rpc('leave_canteen')` | Leaves member canteen | `{"p_tenant_id": "uuid"}` | `{"success": true}` | [canteen_action_sheets.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/widgets/canteen_action_sheets.dart) |
| **5** | `01_auth_tenancy` | `delete_canteen` | `rpc('delete_canteen')` | Deletes canteen and cascades (Owner) | `{"p_tenant_id": "uuid"}` | `{"success": true}` | [canteen_action_sheets.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/widgets/canteen_action_sheets.dart) |
| **6** | `01_auth_tenancy` | `delete_user_account` | `rpc('delete_user_account')` | Deletes current authenticated user profile | `{}` | `{"success": true}` | [my_profile_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/my_profile_screen.dart) |
| **7** | `02_business_days_shifts` | `get_active_business_day` | `rpc('get_active_business_day')` | Checks active business day & float | `{"p_tenant_id": "uuid"}` | `{"active": true, "id": "uuid", ...}` | [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart) |
| **8** | `02_business_days_shifts` | `start_business_day` | `rpc('start_business_day')` | Opens day with starting cash float | `{"p_tenant_id": "uuid", "p_opening_balance": 500.0}` | `{"success": true, "business_day_id": "uuid"}` | [open_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/open_day_bottom_sheet.dart) |
| **9** | `02_business_days_shifts` | `calculate_expected_cash` | `rpc('calculate_expected_cash')` | Computes theoretical drawer balance | `{"p_day_id": "uuid"}` | `{"expected_closing_cash": 1500.0, ...}` | [close_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/close_day_bottom_sheet.dart) |
| **10** | `02_business_days_shifts` | `end_business_day` | `rpc('end_business_day')` | Closes day, audits cash difference & locks day | `{"p_day_id": "uuid", "p_actual_closing_cash": 1500.0}` | `{"success": true, "cash_difference": 0.0}` | [close_day_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/close_day_bottom_sheet.dart) |
| **11** | `02_business_days_shifts` | `get_current_shift` | `rpc('get_current_shift')` | Resolves active shift by clock time | `{"p_tenant_id": "uuid"}` | `{"found": true, "id": "uuid", "name": "string"}` | [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart) |
| **12** | `03_customers_meal_ar` | `create_or_reactivate_customer` | `rpc('create_or_reactivate_customer')` | Creates/reactivates customer with meal plans | `{"p_tenant_id": "uuid", "p_name": "string", "p_phone": "string"}` | `{"success": true, "customer_id": "uuid"}` | [add_customer_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/add_customer_bottom_sheet.dart) |
| **13** | `03_customers_meal_ar` | `record_meal_attendance` | `rpc('record_meal_attendance')` | Fast meal punch & wallet debit charge | `{"p_tenant_id": "uuid", "p_customer_id": "uuid", "p_rate": 50.0}` | `{"success": true, "attendance_id": "uuid"}` | [quick_customer_picker_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/widgets/quick_customer_picker_bottom_sheet.dart) |
| **14** | `03_customers_meal_ar` | `record_baki_payment_v2` | `rpc('record_baki_payment_v2')` | Collects customer baki into cash/online account | `{"p_tenant_id": "uuid", "p_customer_id": "uuid", "p_canteen_account_id": "uuid", "p_amount": 500.0}` | `{"success": true, "wallet_entry_id": "uuid"}` | [collect_baki_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/collect_baki_bottom_sheet.dart) |
| **15** | `03_customers_meal_ar` | `get_customer_balance` | `rpc('get_customer_balance')` | Returns cached due balance & debits/credits | `{"p_customer_id": "uuid"}` | `{"current_balance": 350.0, "total_debit": 1000.0}` | [customer_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/customer_detail_screen.dart) |
| **16** | `03_customers_meal_ar` | `get_customer_statement` | `rpc('get_customer_statement')` | Returns chronological customer ledger | `{"p_customer_id": "uuid", "p_start_date": "...", "p_end_date": "..."}` | `[{"id": "uuid", "amount": 50.0, ...}]` | [customer_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/customer_detail_screen.dart) |
| **17** | `04_cashbook_wallets` | `record_expense_v2` | `rpc('record_expense_v2')` | Records operational expense against account | `{"p_tenant_id": "uuid", "p_canteen_account_id": "uuid", "p_category": "string", "p_amount": 500.0}` | `{"success": true, "day_entry_id": "uuid"}` | [add_expense_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/add_expense_bottom_sheet.dart) |
| **18** | `04_cashbook_wallets` | `transfer_canteen_funds` | `rpc('transfer_canteen_funds')` | Transfers funds between accounts | `{"p_tenant_id": "uuid", "p_from_account_id": "uuid", "p_to_account_id": "uuid", "p_amount": 1000.0}` | `{"success": true, "from_account_id": "uuid"}` | [cashbook_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/cashbook_screen.dart) |
| **19** | `04_cashbook_wallets` | `void_wallet_entry` | `rpc('void_wallet_entry')` | Voids customer/vendor/staff entry with audit | `{"p_entry_id": "uuid", "p_reason": "string"}` | `{"success": true, "entry_id": "uuid", "voided": true}` | [void_transaction_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/customers/void_transaction_bottom_sheet.dart) |
| **20** | `04_cashbook_wallets` | `void_day_entry` | `rpc('void_day_entry')` | Voids cashbook income/expense record | `{"p_entry_id": "uuid", "p_reason": "string"}` | `{"success": true, "entry_id": "uuid", "voided": true}` | [cashbook_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/cashbook/cashbook_screen.dart) |
| **21** | `05_vendors_ap` | `record_vendor_payment_v2` | `rpc('record_vendor_payment_v2')` | Settles supplier payable debt from account | `{"p_tenant_id": "uuid", "p_vendor_id": "uuid", "p_canteen_account_id": "uuid", "p_amount": 2000.0}` | `{"success": true, "vendor_entry_id": "uuid"}` | [record_vendor_payment_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/record_vendor_payment_bottom_sheet.dart) |
| **22** | `05_vendors_ap` | `get_vendor_statement` | `rpc('get_vendor_statement')` | Returns chronological vendor ledger | `{"p_vendor_id": "uuid", "p_start_date": "...", "p_end_date": "..."}` | `[{"id": "uuid", "amount": 2000.0, ...}]` | [vendor_detail_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/settings/vendor_detail_screen.dart) |
| **23** | `06_staff_payroll` | `record_salary_payout_v2` | `rpc('record_salary_payout_v2')` | Pays salary advance or monthly payroll | `{"p_tenant_id": "uuid", "p_staff_id": "uuid", "p_canteen_account_id": "uuid", "p_amount": 3000.0, "p_payout_type": "advance\|salary"}` | `{"success": true, "salary_payout_id": "uuid"}` | [record_salary_payout_bottom_sheet.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/staff/record_salary_payout_bottom_sheet.dart) |
| **24** | `06_staff_payroll` | `verify_staff_pin` | `rpc('verify_staff_pin')` | Validates 4-digit staff PIN for POS actions | `{"p_tenant_id": "uuid", "p_pin": "1234"}` | `{"valid": true, "staff_id": "uuid", "role": "staff"}` | [home_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/home/home_screen.dart) |

---

## 3. Module Links
- 🔐 [01_auth_tenancy Documentation](file:///Users/daviditc/Documents/personal_projects/smart-hisab/backend/modules/01_auth_tenancy/README.md)
- ☀️ [02_business_days_shifts Documentation](file:///Users/daviditc/Documents/personal_projects/smart-hisab/backend/modules/02_business_days_shifts/README.md)
- 👥 [03_customers_meal_ar Documentation](file:///Users/daviditc/Documents/personal_projects/smart-hisab/backend/modules/03_customers_meal_ar/README.md)
- 💰 [04_cashbook_wallets Documentation](file:///Users/daviditc/Documents/personal_projects/smart-hisab/backend/modules/04_cashbook_wallets/README.md)
- 🚚 [05_vendors_ap Documentation](file:///Users/daviditc/Documents/personal_projects/smart-hisab/backend/modules/05_vendors_ap/README.md)
- 🧑‍🍳 [06_staff_payroll Documentation](file:///Users/daviditc/Documents/personal_projects/smart-hisab/backend/modules/06_staff_payroll/README.md)
