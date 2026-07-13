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

### 2. Workspace Setup
Run the following command at the root workspace directory to link all workspace projects and install dependencies:
```bash
pnpm install
```

### 3. Supabase CLI Setup
Link the local project configuration to your Supabase cloud backend or run it locally:
```bash
# Link the database with your Supabase project ref
pnpm run backend:link
```

### 4. Running the Dev Server
Launch the Quasar local development server:
```bash
pnpm run dev
```

---

## Key Monorepo Commands

All commands are run from the root workspace:

| Script | Command | Description |
| :--- | :--- | :--- |
| `pnpm run dev` | `pnpm --filter web dev` | Starts the Quasar Vite dev server |
| `pnpm run build` | `pnpm --filter web build` | Builds the Quasar web application |
| `pnpm run lint` | `pnpm --filter web lint` | Runs eslint and prettier formatting |
| `pnpm run backend:init` | `npx supabase init` | Re-initializes supabase setup |
| `pnpm run backend:push` | `npx supabase db push --linked` | Pushes local migrations to Supabase database |
| `pnpm run backend:types` | `npx supabase gen types ...` | Re-generates TypeScript database bindings |
