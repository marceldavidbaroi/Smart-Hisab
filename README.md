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

