# Boilerplate Supabase Quasar

A clean, multi-tenant boilerplate workspace combining the **Quasar Framework** (Vite, Vue 3, TypeScript, Pinia) on the frontend and **Supabase** (PostgreSQL, RLS, CLI migrations) on the backend.

Inspired by the workspace structure of `brandwala-wholesale-quasar-v2`.

---

## Project Structure

```
boilerplate_supabase_quasar/
├── .cursor/                       # Cursor Editor rules & MDC files
│   └── rules/
│       ├── core.mdc               # Core response efficiency guidelines
│       └── agent-efficiency.mdc   # AI agent-mode tool optimization rules
├── supabase/                      # Supabase backend CLI setup
│   └── config.toml                # Local Supabase service configurations
├── web/                           # Quasar SPA frontend application
│   ├── src/                       # Frontend application sources
│   │   ├── boot/
│   │   │   └── supabase.ts        # Supabase client instantiation & tenant header injector
│   │   ├── layouts/               # Page templates and frames
│   │   ├── pages/                 # Main screen views
│   │   ├── router/                # Vue routing configuration
│   │   └── stores/                # Pinia state stores
│   ├── quasar.config.ts           # Quasar and Vite configurations
│   └── package.json               # Frontend dependencies
├── package.json                   # Root monorepo configuration
├── pnpm-workspace.yaml            # Monorepo workspaces definition
├── .cursorrules                   # Legacy AI behavioral configuration file
└── CLAUDE.md                      # AI rules for fast development (token-optimized)
```

---

## Setup and Startup Instructions

### 1. Prerequisite Installations
Ensure you have the following installed on your machine:
* **Node.js**: Version 22.x or 20.x
* **PNPM**: Global package manager (`npm install -g pnpm`)
* **Supabase CLI**: Required for database management and local environment simulation
* **Docker Desktop**: Required to run the local Supabase container environment

### 2. Workspace Setup
Run the following command at the root workspace directory to link all workspace projects and install dependencies:
```bash
pnpm install
```

### 3. Local Development Startup (Recommended)
You can run the entire database and backend stack locally using Docker:
```bash
# 1. Start the local database containers
pnpm run backend:start

# 2. Reset database and run local migrations & seeds
pnpm run backend:reset

# 3. Create the web configuration env file
cp web/.env.example web/.env
```
Once seeded, a platform superadmin account is automatically created for local testing:
* **Email**: `admin@example.com`
* **Password**: `Superadmin123!`

### 4. Running the Dev Server
Launch the Quasar local development server:
```bash
pnpm run dev
```
Open `http://localhost:9000` in your browser.

---

## Key Monorepo Commands

All commands are run from the root workspace:

| Script | Command | Description |
| :--- | :--- | :--- |
| `pnpm run dev` | `pnpm --filter web dev` | Starts the Quasar Vite dev server (runs on `http://localhost:9000`) |
| `pnpm run build` | `pnpm --filter web build` | Builds the Quasar web application |
| `pnpm run lint` | `pnpm --filter web lint` | Runs eslint and prettier formatting |
| `pnpm run backend:start` | `npx supabase start` | Starts the local Supabase Docker containers |
| `pnpm run backend:stop` | `npx supabase stop` | Stops the local Supabase Docker containers |
| `pnpm run backend:reset` | `npx supabase db reset` | Resets local DB schemas and loads the database seeds |
| `pnpm run backend:status` | `npx supabase status` | Displays configuration details of running local containers |
| `pnpm run backend:types:local` | `npx supabase gen types ...` | Generates TypeScript bindings from local database schema |
| `pnpm run backend:init` | `npx supabase init` | Re-initializes supabase setup |
| `pnpm run backend:push` | `npx supabase db push --linked` | Pushes local migrations to linked remote Supabase database |
| `pnpm run backend:types` | `npx supabase gen types ...` | Generates TypeScript database bindings from linked remote database |

---

## Starting a New Project (Cloning / Forking)

This repository is designed to be a reusable **base boilerplate template**. If you want to build a new application using this setup, you should create a new independent repository by cloning/forking this base.

### Step-by-Step setup:

1. **Clone this base template** to a new local folder:
   ```bash
   git clone <boilerplate-git-url> my-new-application
   cd my-new-application
   ```

2. **Re-link the remote repository**:
   Rename the current origin to `upstream` (so you can still pull core boilerplate updates later) and add your new project's git repository as `origin`:
   ```bash
   git remote rename origin upstream
   git remote add origin <your-new-project-git-url>
   ```

3. **Publish to your new repository**:
   ```bash
   git push -u origin main
   ```

4. **Environment Variables**:
   Create a `web/.env` file from the example:
   ```bash
   cp web/.env.example web/.env
   ```
   Update the `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` with your new Supabase project's keys from your Supabase dashboard.

5. **Pulling Upstream Updates**:
   If the base template gets updated with improvements, bugfixes, or features, you can merge them into your project at any time:
   ```bash
   git fetch upstream
   git merge upstream/main
   ```

---

## How to Add New Features (Best Practices)

When extending your new cloned application with custom functionality (like tenant-specific portals, dashboards, or tables):

### 1. Database Schema Extensions (Backend)
- Add migrations inside the `supabase/migrations/` directory.
- Use Supabase CLI to generate updated TypeScript bindings after changing your database schema:
  ```bash
  pnpm run backend:types
  ```

### 2. Frontend Features
- **Global Services**: Place core APIs or database services inside `web/src/services/`.
- **Views & Routes**: Add pages in `web/src/pages/` (such as `web/src/pages/workspace/` for tenant-specific dashboards) and register them in `web/src/router/routes.ts`.
- **Tenant Context**: Access the current tenant's active ID, permissions, settings, and billing information in any Vue component via the Pinia store:
  ```typescript
  import { useTenantStore } from 'src/stores/tenant';
  const tenantStore = useTenantStore();
  
  console.log(tenantStore.activeTenant?.id);
  console.log(tenantStore.hasPermission('settings', 'write'));
  ```

---

## Mess/Canteen Management System Modules

This section describes the modular features and requirements to be implemented within this project.

### Module 1: Auth, Multi-Tenancy & Device Management
This module manages system roles, tenant identification, and secures physical devices placed at the canteen counter.
*   **Tenant Boarding & Device Pairing:** The Owner/Manager generates a temporary 6-digit activation code (expires in 30 minutes) from their personal dashboard. Entering this code on a new client device binds it to the tenant database and configures the device's local storage. This eliminates text typing for counter staff.
*   **Access Roles & Logins:**
    *   **Owner:** Email/Social login. Full dashboard access, settings configuration, adjustment entries, and reporting.
    *   **Manager:** Email login. Accesses daily logs, payroll trackers, and bazar inputs, but cannot edit settings or view analytics.
    *   **Staff:** 4-digit numeric PIN. Active only on devices locked to Counter Mode.
*   **Counter Mode (Locked Terminal UI):** The active terminal device runs in "Counter Mode" locked to a 4-digit PIN grid. Toggling off Counter Mode to configure the device requires the Admin email password.
    *   **Auto-Expiry:** Manager sessions auto-expire at 11:59 PM daily to prevent leftover sessions from leaking.
    *   **Lockout:** Enforces a 15-minute lockout after 5 consecutive failed PIN attempts and registers a security log.

### Module 2: Shift-Based POS (Point of Sale)
This module replaces granular transactional logs with simple, shift-based aggregations to handle cash transactions rapidly.
*   **Bulk Cash Entry:** Instead of logging every cash transaction, managers enter the total drawer cash counted at the end of each operational shift (Breakfast, Lunch, Afternoon Snacks, Dinner).
*   **Walk-in Baki (Credit) Logging:** A dropdown interface to select a registered customer and log a credit transaction instantly. These entries are explicitly tagged as "walk-in credit" transactions to separate them from monthly subscription logs.
*   **Immutable Ledger Constraints:** Once a shift cash total or walk-in baki sale is saved, the client application locks the fields. The database layer rejects any updates or deletes of these records, enforcing an append-only structure.

### Module 3: Customer Attendance Tracker
Tracks daily meals consumed by fixed contract/factory workers and accumulates them into a monthly tab.
*   **Attendance Grid Interface:** Renders a clean grid list of all 40-45 fixed factory customers. The grid loads instantly from the device's local cache.
*   **One-Tap Logging:** Displays three checkboxes (Breakfast, Lunch, Dinner) per customer. Tapping a checkbox automatically logs a meal and captures a snapshot of the customer’s predefined rate (`rate_applied = rate_at_time_of_meal`).
*   **Attendance Time-Lock:** Box toggles automatically lock at 11:59 PM. The database rejects any attendance logs submitted or modified for previous calendar days.

### Module 4: Accounts Receivable (Customer Collections)
Handles collection tracking and verification for customers carrying outstanding debts.
*   **Debt Directory:** A directory listing all credit-carrying customers, ordered from highest balance due to lowest.
*   **Partial Payments:** Managers log the exact cash amount received from a debtor. The system decrements their balance in real-time.
*   **Automated SMS Receipts:** Saving a payment triggers an API call to an SMS gateway to text the customer their received amount and new remaining balance.

### Module 5: Accounts Payable (Bazar & Expense Ledger)
Tracks canteen food expenditures and supplier relationships.
*   **Daily Bazar Logging:** Form inputs for daily purchases categorized by raw items (e.g., Rice, Meat, Vegetables) linked to a specific supplier profile.
*   **Payment Routing Toggle:** Requires selecting either `Cash Expense` (deducts cash directly from the current shift's drawer) or `Vendor Baki` (adds to the supplier's outstanding credit ledger).
*   **Supplier Payouts:** A ledger entry screen to record cash handed to suppliers, automatically decrementing the supplier's accumulated balance.

### Module 6: Employee Payroll & Cash Advances
Handles staff wages and tracking of mid-month cash advance payments.
*   **Cash Advance Tracker:** Captures cash advances taken by staff (cooks, servers, managers), requiring an employee ID, cash amount, and a short explanation note.
*   **Dynamic Payroll Calculator:** Automatically aggregates monthly base salaries and subtracts the sum of all logged mid-month advances to output the exact cash due. Once finalized, records are locked as read-only.

### Module 7: Shift Reconciliation Engine
The primary fraud detection core running on the Owner's dashboard.
*   **Expected vs. Reported Revenue Math:** When a shift is closed, the system calculates expected revenue and compares it to reported revenue:
    *   $\text{Expected} = \sum(\text{Attendance Meals Logged} \times \text{Predefined Rate Snapshot})$
    *   $\text{Reported} = \text{Shift Cash Entered} + \text{Baki Sales Logged}$
    *   $\text{Variance} = \text{Reported} - \text{Expected}$
    *   $\text{Variance \%} = \frac{\text{Variance}}{\text{Expected}}$
*   **Configurable Variance Threshold:** The owner sets a variance percentage threshold (e.g., 5%) in the settings panel to filter out normal counting errors.
*   **Dashboard Variance Feed:** A main dashboard feed showing closed shifts, the manager on duty, expected vs. reported revenue, and variance %. Discrepancies are sorted descending by absolute negative variance.

### Module 8: Sync & Background Automation Engine
Ensures continuous canteen operations in low-connectivity areas and automates end-of-day processes.
*   **Zero-Block Offline Cache:** The client application writes all transactions (attendance, POS, bazar) to a local cache instantly. The UI runs without blocking on network requests.
*   **Background Sync:** A background scheduler monitors internet connectivity. When online, it syncs local operations to the central database in batches, resolving conflicts using client-side generated transaction UUIDs.
*   **End-of-Day (EOD) SMS Batching:** A backend scheduler triggers a cron job daily at 10:00 PM. It identifies all credit (baki) customers with transactions logged that day and sends a single consolidated SMS showing their daily consumption and remaining balance.


