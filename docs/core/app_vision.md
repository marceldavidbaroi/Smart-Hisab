# Smart-Hisab — App Vision & Product Definition (v2)

---

## 1. What is Smart-Hisab?

Smart-Hisab is a **mobile canteen management app** for Bangladesh. It replaces the paper "hisab khata" (baki notebook) with a digital system that tracks meals, manages debt (baki), handles cash flow, and provides full staff accountability — all from a phone.

**One line:** *"Your canteen's hisab, on your phone."*

---

## 2. Who is it for?

### Primary User: Canteen Owner (Malik)

- Owns one or multiple canteens (mess, factory canteen, hostel kitchen, office cafeteria)
- May or may not be physically present at the canteen daily
- Wants to know: *"How much am I owed? How much cash came in? Where did it go?"*
- May manage the canteen themselves (owner = manager), or hire a manager

### Secondary User: Canteen Manager

- Hired by the owner to run day-to-day operations
- Opens/closes the business day, oversees counter staff, handles disputes
- Reports to the owner — needs to show clean, traceable records

### Tertiary User: Counter Staff (Cashier)

- Operates the counter during meal hours
- Logs meals, collects baki payments, handles the cash drawer
- Low-tech user — needs the simplest possible interface (4-digit PIN, big buttons)
- Does NOT download the app — uses the shared counter device

### The Customer (End Consumer)

- Workers / residents who eat at the canteen on credit
- They don't use the app — the app tracks their baki for them
- Their interaction: eat → debt increases. Pay cash → debt decreases.

---

## 3. What Problem Does It Solve?

### The Bangladesh Canteen Reality

In Bangladesh, most canteens (mess / factory canteen / hostel kitchen) operate on a **credit-first, pay-later** system called "baki":

1. **Workers eat daily meals on credit** — no one pays per-meal
2. **The canteen owner tracks debt in a paper notebook** ("hisab khata")
3. **At week-end or month-end**, workers pay their accumulated baki
4. **Cash drawer reconciliation** is manual — the owner counts cash and hopes it matches

### Problems with the Paper System

| Problem | Impact |
|---|---|
| **Notebook gets lost, torn, or wet** | Entire month's records gone |
| **Handwriting disputes** | "I wrote ৳500" vs "It looks like ৳300" |
| **Arithmetic errors** | Manual addition across 50+ customers daily |
| **Cash shortages** | Can't trace if staff pocketed ৳200 or it was a counting error |
| **No remote visibility** | Owner must be at the counter to check the khata |
| **Staff blame game** | No record of who collected which payment |
| **Scaling impossible** | Second branch = second notebook = double the chaos |

### Smart-Hisab's Solution

**Replace the paper khata with a digital ledger that is:**
- ✅ **Immutable** — entries can't be erased or secretly modified
- ✅ **Timestamped** — every meal and payment has an exact time + who recorded it
- ✅ **Auto-calculated** — no manual arithmetic, balances are always correct
- ✅ **Accessible anywhere** — owner checks baki from their phone, even from home
- ✅ **Accountable** — every transaction is stamped with the staff member's name

---

## 4. Core Features (What the App Does)

### Feature Group 1: Staff & Payroll Management
| Feature | Description |
|---|---|
| **Staff Profiles** | Add staff with name, role (cashier, cook, manager), and 4-digit PIN |
| **Staff Attendance** | Track who worked which day/shift |
| **Salary Payouts** | Record salary payments, deductions, advances |
| **PIN Accountability** | Every transaction tied to the staff who recorded it |

### Feature Group 2: Meal System
| Feature | Description |
|---|---|
| **Meal Configs** | Set per-meal rates (e.g., Breakfast ৳50, Lunch ৳80, Dinner ৳70) |
| **Shifts** | Define meal periods (Breakfast, Lunch, Dinner) with time windows |
| **Meal Attendance** | One-tap: mark "customer X ate lunch" → auto-charges their wallet |
| **Bulk Attendance** | (Future) Mark all customers as present, un-toggle absentees |

### Feature Group 3: Baki (Debt) & Wallet
| Feature | Description |
|---|---|
| **Customer Wallets** | Each customer has a running balance (how much they owe) |
| **Auto Meal Charge** | When meal is logged, wallet balance increases automatically |
| **Baki Collection** | When customer pays cash, record it → wallet balance decreases |
| **Customer Statement** | Full history: every meal charge, every payment, with dates |
| **Dispute Resolution** | Show the customer their timestamped statement — no more arguments |

### Feature Group 4: Cashbook & Cash Flow
| Feature | Description |
|---|---|
| **Business Day** | Open day with opening cash → close day with closing cash |
| **Day Entries** | Every cash inflow (baki collection) and outflow (purchases, expenses) recorded |
| **Auto Reconciliation** | System calculates: expected cash = opening + inflows - outflows |
| **Variance Detection** | Compares expected vs actual closing cash → highlights shortage/overage |
| **Day Notes** | Record market purchases, issues, or notes for the day |

### Feature Group 5: Owner Dashboard
| Feature | Description |
|---|---|
| **Live Day Status** | Is the business day open? How much collected so far? |
| **Total Baki Outstanding** | How much are all customers combined owing right now? |
| **Daily/Weekly/Monthly Reports** | Meals served, cash collected, expenses, net profit |
| **Multi-Canteen View** | (Future) Switch between canteens from one account |

---

## 5. What Makes This App WIN Over the Paper Notebook?

| Advantage | Paper Khata | Smart-Hisab |
|---|---|---|
| **Speed** | Write name, meal, amount. ~15 sec/customer | Tap customer → meal toggled. ~2 sec/customer |
| **Accuracy** | Manual addition. Human errors daily | Auto-calculated. Always correct. |
| **Remote Access** | Must be at the counter | Check from anywhere on your phone |
| **Disputes** | "Your handwriting is wrong" | Timestamped digital record with staff name |
| **Cash Tracking** | Count cash and hope it matches | System tells you expected vs actual, highlights variance |
| **Scalability** | 1 notebook per counter | 1 account, unlimited canteens |
| **Staff Trust** | "I don't know who took the money" | Every transaction has a staff_id attached |

---

## 6. Design Philosophy

### Principle 1: Simpler Than Paper
If any feature takes more steps than writing in a notebook, it's too complex. Redesign it.

### Principle 2: Bangla First
Default language is Bangla (বাংলা). English available as a toggle. Labels, buttons, and error messages — all Bangla by default. Numerals stay English (123) for accounting clarity.

### Principle 3: One-Hand Canteen Use
The app will be used standing at a counter, often with one hand (other hand is serving food). Big touch targets (48px minimum), bottom-accessible actions, no tiny buttons.

### Principle 4: Counter Staff ≠ Tech Users
Counter cashiers may have limited smartphone experience. The POS interface should have: big icons, minimal text, obvious actions, no hidden menus. If a staff member needs training to use it, it's too complex.

### Principle 5: Owner's Peace of Mind
The owner should be able to open the app at night, glance at the dashboard, and know: "Today's cash is correct. ৳12,000 baki outstanding. 45 meals served." — in under 5 seconds.

---

## 7. Business Model: Freemium

> Full details in [tier_and_roles.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/tier_and_roles.md).

| Tier | Price | Limits | Key Features |
|---|---|---|---|
| **Free** | ৳0 | 1 canteen, 50 customers, 3 staff, 1 manager | All core features: baki, cashbook, meals, salary payouts, manager invite, daily summary |
| **Pro** | TBD / month | 3 canteens, unlimited customers, 10 staff/tenant, 1 manager/tenant | Counter Mode + Staff PIN, staff attendance, weekly/monthly reports, financial P&L |
| **Business** | TBD / month | Unlimited everything | Multi-canteen dashboard, PDF export, bulk meal attendance, priority support, advanced analytics |

### Tier Philosophy
- **Tiers gate scale and advanced tools, never core workflow.** Every tier can run a canteen end-to-end.
- **Each tier = a release milestone.** Free (v1.0) → Pro (v1.5) → Business (v2.0). Each release is fully functional.

### Why Freemium Works for Bangladesh
- Small canteen owners won't pay upfront for software they haven't tried
- Free tier solves their core pain (baki tracking) → they get hooked
- As they grow (more customers, more staff, second branch) → they upgrade naturally
- The free tier IS the marketing — word of mouth in the canteen community

---

## 8. Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Mobile App** | React Native / Expo (TypeScript) | Cross-platform, single codebase for Android (primary) and iOS (future) |
| **Styling** | NativeWind (TailwindCSS) | Rapid UI development, consistent design system |
| **Routing** | Expo Router (file-based) | Clean, predictable navigation |
| **State** | Zustand | Lightweight, minimal boilerplate |
| **Data Fetching** | TanStack Query (React Query) | Caching, background refresh, stale-while-revalidate |
| **Backend** | Supabase (Postgres + Auth + Edge Functions) | Managed backend, Google OAuth, RLS for multi-tenancy |
| **Auth** | Supabase Auth (Google OAuth) | One-tap sign in, no password management |
| **Language** | Bangla (default) + English toggle | `i18n` localization |

### Web Dashboard
**Status: Legacy / Frozen.** The Quasar v2 (Vue 3) web dashboard exists but is not actively developed. All new features are mobile-only. The web may be sunset or replaced by the mobile app's owner dashboard.

---

## 9. Target Market & Scale

### Phase 1: Bangladesh Canteen / Mess
- Factory canteens (garment, pharmaceutical, manufacturing)
- Hostel / mess kitchens (university, corporate)
- Office cafeterias
- Small restaurant takeaway counters with credit customers

### Phase 2 (Future): Expand Use Cases
- Grocery shops with "baki" customers
- Dairy / milk delivery tracking
- Any Bangladeshi small business with credit-based sales

### Phase 3 (Future): Regional
- Similar "credit meal" patterns exist in India, Pakistan, Myanmar, Nepal
- Same app, different localization

---

## 10. Success Metrics

| Metric | Target (6 months) |
|---|---|
| **Downloads** | 1,000+ |
| **Active canteens** | 100+ |
| **Meals logged per day** (across all canteens) | 5,000+ |
| **Retention** (canteen still active after 30 days) | >60% |
| **Pro upgrades** | 10% of active canteens |
| **Average session time** | <2 min (quick in, log meals, out) |
