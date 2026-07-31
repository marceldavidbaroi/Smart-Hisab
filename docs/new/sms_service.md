# Smart-Hisab — SMS Baki Reminder Service (v1.1)

> Paid add-on for all tiers. Canteen owners buy SMS credit bundles and send baki reminders to customers.
> **Release**: v1.1 (separate point release, after v1.0 Free launch).
> **API Integration**: Infrastructure built first (DB, UI, credit system). Actual SMS provider endpoint connection discussed and added separately.

---

## 1. Feature Overview

### What It Does

Lets canteen owners send SMS messages to customers reminding them of their outstanding baki (debt). SMS is a **prepaid credit-based add-on** — any tier user (Free, Pro, Business) can purchase SMS credit bundles to send messages.

### Why It Matters

- The #1 pain for canteen owners: *"My customers forget to pay their baki."*
- An SMS reminder directly to the customer's phone is the most effective nudge in Bangladesh.
- Customers don't use the app — SMS is the only digital channel to reach them.
- This is a separate revenue stream from tier subscriptions.

### Key Decisions (Resolved)

| Decision | Resolution |
|---|---|
| **Tier availability** | All tiers — cross-tier paid add-on |
| **Payment for credits** | Manual bKash top-up for MVP (simplest) |
| **Release timing** | v1.1 (separate point release) |
| **Customer phone** | **Required** — `customers.phone` becomes NOT NULL |
| **SMS language** | Owner chooses per-template (Bangla / English) |
| **Rate limiting** | Yes — daily limits per tenant |
| **Duplicate prevention** | Yes — max 1 reminder per customer per 24 hours |
| **SMS provider** | To be selected later (BulkSMSBD likely candidate) |
| **Provider account** | Smart-Hisab owns master account, tenants buy credits from us |
| **SMS type** | Non-masking for MVP (cheaper, no BTRC registration) |
| **API endpoint** | NOT connected in initial build — stub/mock only |

---

## 2. Bangladesh SMS Context

### SMS Types

| Type | Sender Shows As | Cost (BDT/SMS) | Best For | BTRC Requirement |
|---|---|---|---|---|
| **Non-Masking** | Random numeric (e.g., `16XXX`) | ৳0.25 – ৳0.36 | Transactional alerts, baki reminders | Minimal — API key only |
| **Masking** | Custom brand (e.g., `SmartHisab`) | ৳0.45 – ৳0.56 | Professional branding | BTRC Sender ID registration + company docs |

**Decision**: Start with **Non-Masking SMS**. Cheaper, no BTRC registration hassle. Upgrade to Masking later.

### BTRC Compliance

1. Must use a **BTRC-licensed SMS aggregator** (BulkSMSBD, MiM SMS, REVE SMS, Alpha Net)
2. Bangla content preferred for promotional SMS (our reminders default to Bangla)
3. Transactional messages (baki reminders) are generally permitted
4. Minimum tariff: ~৳0.30/SMS including VAT for non-masking

### Candidate Providers

| Provider | API Style | Bangla Unicode | BTRC Licensed |
|---|---|---|---|
| **BulkSMSBD** | REST (GET/POST) | ✅ | ✅ |
| **MiM SMS** | REST | ✅ | ✅ |
| **REVE SMS** | REST | ✅ | ✅ |
| **Alpha Net** | REST/SMPP | ✅ | ✅ |

> Provider selection and signup deferred to post-infrastructure build.

---

## 3. Business Model — SMS Credit Bundles

### Prepaid Bundle System

Canteen owners buy SMS credits in bundles. Credits are consumed when SMS is sent. No post-paid billing.

**Why prepaid bundles:**
- Matches the bKash/Nagad "recharge" mental model familiar to BD users
- Zero credit risk — money collected upfront
- Simple to understand: "I bought 500 SMS for ৳400"

### Proposed Bundles

| Bundle | SMS Count | Sell Price (BDT) | Est. Cost (~) | Est. Margin |
|---|---|---|---|---|
| **Starter** | 100 SMS | ৳100 | ~৳35 | ~65% |
| **Standard** | 500 SMS | ৳400 | ~৳175 | ~56% |
| **Bulk** | 2,000 SMS | ৳1,200 | ~৳700 | ~42% |
| **Enterprise** | 10,000 SMS | ৳4,500 | ~৳3,500 | ~22% |

> Final pricing TBD after negotiating rates with the selected SMS provider.

### Payment Collection (MVP)

**Manual bKash top-up:**
1. Owner sends bKash to Smart-Hisab's merchant number
2. Owner submits the bKash Transaction ID in the app
3. Smart-Hisab admin verifies payment manually
4. Admin credits the tenant's SMS balance

**Future**: bKash Merchant API / Nagad Payment Gateway / Google Play billing.

---

## 4. SMS Use Cases

### Primary: Baki Reminder (MVP — v1.1)

The only SMS type for initial release.

**Bangla template:**
```
আপনার {{canteen_name}}-এ বকেয়া আছে ৳{{amount}}।
অনুগ্রহ করে পরিশোধ করুন। - Smart-Hisab
```

**English template:**
```
You have ৳{{amount}} outstanding at {{canteen_name}}.
Please settle your dues. - Smart-Hisab
```

### Future Use Cases (Post v1.1)

| Use Case | Template Key | Priority |
|---|---|---|
| Payment received confirmation | `payment_received` | Medium |
| Daily meal logged notification | `meal_logged` | Medium |
| Weekly statement summary | `weekly_statement` | Low |
| Canteen announcement (custom) | `announcement` | Low |

---

## 5. User Experience Flows

### Flow 1: Send to Individual Customer

```
Customer Profile Screen
  → View baki amount (৳1,200)
  → Tap "Send Reminder SMS" button
  → Bottom sheet shows:
      - Customer name + phone
      - Message preview (rendered in chosen language)
      - "1 SMS credit will be used"
      - [Send] [Cancel]
  → SMS sent → Success toast
  → 1 credit deducted from balance
```

**Guard rails:**
- If customer has no baki (balance = 0), button is hidden
- If customer phone is missing/invalid, show inline error
- If tenant has 0 credits, show "Buy Credits" prompt instead
- If same customer received reminder < 24h ago, show warning + confirmation

### Flow 2: Bulk Send (Baki Reminder to Multiple Customers)

```
Baki Overview Screen (or Dashboard)
  → Tap "Send Reminders" button
  → Bottom sheet / Full screen:
      - Minimum baki threshold slider (default: ৳0, adjustable)
      - Customer list with checkboxes (pre-selected: all with baki above threshold who have phone)
      - Excluded: customers without phone, customers reminded < 24h ago
      - Summary: "18 customers selected — 18 credits will be used"
      - [Send All] [Cancel]
  → Progress indicator during send
  → Results summary: "16 sent ✅, 2 failed ❌"
  → Credits deducted for successful sends only
```

**Guard rails:**
- Daily rate limit check before starting batch
- If credits < customer count, show "Insufficient credits" with buy prompt
- Max batch size: 100 customers per bulk send (rate limit)

### Flow 3: Buy SMS Credits

```
Settings → SMS Service
  → Current balance: 42 SMS credits
  → Tap "Buy Credits"
  → Bundle selection cards:
      - 100 SMS = ৳100
      - 500 SMS = ৳400
      - 2,000 SMS = ৳1,200
      - 10,000 SMS = ৳4,500
  → Select bundle → Payment instructions:
      "Send ৳400 via bKash to 01XXXXXXXXX"
      "Enter your bKash Transaction ID below"
  → Submit transaction ID
  → "Your credits will be added within 1 hour after verification"
  → Admin verifies → Credits added → Push notification to user
```

### Flow 4: SMS History Log

```
Settings → SMS Service → History
  → Filterable list of all sent SMS
  → Each row: Customer name, phone, date, status badge
  → Status: Sent ✅ | Delivered ✅✅ | Failed ❌ | Pending ⏳
  → Tap row → Full message body + delivery details
```

---

## 6. Database Schema

### 6.0 Schema Change: `customers.phone` → NOT NULL

**Breaking change for v1.1**: Customer phone becomes mandatory.

```sql
-- Migration: make phone required
ALTER TABLE customers ALTER COLUMN phone SET NOT NULL;
ALTER TABLE customers ALTER COLUMN phone SET DEFAULT '';
```

> **Migration strategy**: Before applying, backfill any NULL phones with empty string, then prompt owners in the app to update customer phone numbers.

| Column | Old | New |
|---|---|---|
| `phone` | TEXT (nullable) | TEXT NOT NULL |

---

### 6.1 `sms_credit_balances`

Cached SMS credit balance per tenant. Auto-created when tenant is created (same pattern as `customer_wallets`).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL UNIQUE, FK → `tenants(id)` ON DELETE CASCADE | |
| `current_balance` | INTEGER | NOT NULL DEFAULT 0 | SMS credits remaining |
| `total_purchased` | INTEGER | NOT NULL DEFAULT 0 | Lifetime credits purchased |
| `total_used` | INTEGER | NOT NULL DEFAULT 0 | Lifetime credits consumed |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Trigger**: `auto_create_sms_credit_balance` — auto-inserts when a tenant is created.

**RLS**: Same as tenant-scoped tables (read/write by tenant members).

---

### 6.2 `sms_credit_ledger`

Immutable append-only ledger for SMS credit transactions. Follows the same philosophy as `wallet_entries` and `vendor_wallet_entries`.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `type` | TEXT | NOT NULL, CHECK IN ('purchase', 'usage', 'refund', 'bonus', 'expiry') | |
| `amount` | INTEGER | NOT NULL | Positive for credits in, negative for credits out |
| `bundle_name` | TEXT | | e.g., "Standard 500" (for purchase entries) |
| `payment_reference` | TEXT | | bKash transaction ID, manual ref, etc. |
| `reference_type` | TEXT | CHECK IN ('sms_log', 'manual_topup', 'bkash', 'system') | What triggered this entry |
| `reference_id` | UUID | | FK to `sms_logs` or payment record |
| `notes` | TEXT | | |
| `created_by_user_id` | UUID | FK → `auth.users(id)` ON DELETE SET NULL | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `type`, `created_at`

**Balance rule:**
- `purchase` → positive (credits added)
- `usage` → negative (credits consumed on SMS send)
- `refund` → positive (credits returned on send failure)
- `bonus` → positive (promotional credits)
- `expiry` → negative (if we add credit expiration later)

**Trigger**: `update_sms_credit_balance` — after INSERT, updates `sms_credit_balances.current_balance`, `total_purchased`, `total_used` accordingly.

---

### 6.3 `sms_templates`

Pre-defined message templates. Seeded with system defaults. Tenants can customize their own.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | FK → `tenants(id)` ON DELETE CASCADE | NULL = system default template |
| `template_key` | TEXT | NOT NULL | `baki_reminder`, `payment_received`, etc. |
| `language` | TEXT | NOT NULL DEFAULT 'bn', CHECK IN ('bn', 'en') | |
| `body` | TEXT | NOT NULL | Template with placeholders: `{{customer_name}}`, `{{amount}}`, `{{canteen_name}}` |
| `is_active` | BOOLEAN | NOT NULL DEFAULT true | |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**UNIQUE**: `(tenant_id, template_key, language)` — one template per key per language per tenant.

**Seed data** (system defaults, `tenant_id = NULL`):

| template_key | language | body |
|---|---|---|
| `baki_reminder` | `bn` | `আপনার {{canteen_name}}-এ বকেয়া আছে ৳{{amount}}। অনুগ্রহ করে পরিশোধ করুন। - Smart-Hisab` |
| `baki_reminder` | `en` | `You have ৳{{amount}} outstanding at {{canteen_name}}. Please settle your dues. - Smart-Hisab` |

---

### 6.4 `sms_logs`

Complete audit trail of every SMS sent or attempted.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `customer_id` | UUID | FK → `customers(id)` ON DELETE SET NULL | |
| `recipient_phone` | TEXT | NOT NULL | Snapshot of phone at send time |
| `template_key` | TEXT | | Which template was used |
| `message_body` | TEXT | NOT NULL | Actual rendered message sent |
| `language` | TEXT | NOT NULL DEFAULT 'bn', CHECK IN ('bn', 'en') | Language used |
| `status` | TEXT | NOT NULL DEFAULT 'pending', CHECK IN ('pending', 'sent', 'delivered', 'failed', 'rejected') | |
| `provider` | TEXT | | e.g., `bulksmsbd` (NULL until provider connected) |
| `provider_message_id` | TEXT | | Gateway's reference ID |
| `provider_response_code` | TEXT | | e.g., `202` for success |
| `error_message` | TEXT | | If failed, why |
| `credits_charged` | INTEGER | NOT NULL DEFAULT 1 | Credits deducted for this SMS |
| `sent_by_user_id` | UUID | FK → `auth.users(id)` ON DELETE SET NULL | Who triggered the send |
| `sent_at` | TIMESTAMPTZ | | When actually dispatched to provider |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**: `tenant_id`, `customer_id`, `status`, `created_at`

---

### 6.5 `sms_rate_limits`

Tracks daily SMS usage per tenant for rate limiting.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | |
| `tenant_id` | UUID | NOT NULL, FK → `tenants(id)` ON DELETE CASCADE | |
| `date` | DATE | NOT NULL DEFAULT current_date | |
| `sms_sent_count` | INTEGER | NOT NULL DEFAULT 0 | SMS sent today |
| `daily_limit` | INTEGER | NOT NULL DEFAULT 100 | Max SMS per day for this tenant |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**UNIQUE**: `(tenant_id, date)`

**Default daily limits by tier:**

| Tier | Daily SMS Limit |
|---|---|
| Free | 50 |
| Pro | 200 |
| Business | 500 |

---

### 6.6 Entity Relationship (Additions to Schema)

```text
tenants
 ├── (existing 20 tables...)
 ├── sms_credit_balances (cached credit balance — 1:1 with tenant)
 │     └── auto-created on tenant INSERT
 ├── sms_credit_ledger (immutable credit transaction log)
 ├── sms_templates (message templates per tenant + system defaults)
 ├── sms_logs (audit trail of every SMS sent)
 │     └── links to → customers (who received the SMS)
 └── sms_rate_limits (daily usage tracking per tenant)
```

**New table count**: 5 tables → **Total: 25 tables**

---

## 7. RPC Functions

### 7.1 SMS Sending

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `send_baki_reminder_sms` | `p_tenant_id UUID, p_customer_id UUID, p_language TEXT DEFAULT 'bn'` | `JSONB` | Resolves customer baki, renders template, checks credits + rate limit + duplicate, inserts `sms_log` (status='pending'), deducts credit. Returns `{status, message_preview, credits_remaining}`. |
| `send_bulk_baki_reminder` | `p_tenant_id UUID, p_min_baki NUMERIC DEFAULT 0, p_language TEXT DEFAULT 'bn'` | `JSONB` | Sends reminder to all active customers with baki ≥ threshold, valid phone, and not reminded in last 24h. Returns `{total_selected, total_sent, total_skipped, credits_remaining}`. |

### 7.2 Credit Management

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `get_sms_credit_balance` | `p_tenant_id UUID` | `INTEGER` | Returns current SMS credit balance. |
| `add_sms_credits` | `p_tenant_id UUID, p_amount INTEGER, p_bundle_name TEXT, p_payment_ref TEXT` | `INTEGER` | Admin/system adds credits after payment verification. Inserts ledger entry (type='purchase'). Returns new balance. |
| `request_sms_credit_purchase` | `p_tenant_id UUID, p_bundle_name TEXT, p_payment_ref TEXT` | `UUID` | Tenant submits a purchase request with bKash transaction ID. Creates a pending purchase record for admin to verify. |

### 7.3 History & Reporting

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `get_sms_history` | `p_tenant_id UUID, p_start DATE, p_end DATE, p_status TEXT DEFAULT NULL` | `TABLE(...)` | Paginated SMS log with customer name, phone, status, date. |
| `get_sms_credit_history` | `p_tenant_id UUID, p_start DATE, p_end DATE` | `TABLE(...)` | Credit ledger history (purchases, usage, refunds). |
| `get_sms_usage_stats` | `p_tenant_id UUID, p_start DATE, p_end DATE` | `JSONB` | Summary: total sent, total delivered, total failed, credits used, credits remaining. |

---

## 8. Technical Architecture

### 8.1 SMS Sending Pipeline

```text
┌─────────────────┐
│  Mobile App     │
│  (React Native) │
└────────┬────────┘
         │ RPC call
         ▼
┌─────────────────────────────────────┐
│  Supabase RPC: send_baki_reminder   │
│  1. Validate: customer has baki     │
│  2. Validate: customer has phone    │
│  3. Check: credit balance ≥ 1       │
│  4. Check: rate limit not exceeded  │
│  5. Check: not duplicate (24h)      │
│  6. Render template with data       │
│  7. Deduct 1 credit (ledger entry)  │
│  8. Insert sms_log (status=pending) │
│  9. Return log_id + preview         │
└────────┬────────────────────────────┘
         │ (Future: invoke Edge Function)
         ▼
┌─────────────────────────────────────┐
│  Supabase Edge Function: send-sms   │  ◄── NOT CONNECTED IN v1.1 INITIAL BUILD
│  1. Receive log_id + phone + body   │
│  2. Call SMS provider API           │
│  3. Update sms_log with response    │
│  4. If failed → refund credit       │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  SMS Provider (BulkSMSBD / TBD)    │  ◄── PROVIDER SELECTED LATER
│  REST API: send SMS to phone        │
└─────────────────────────────────────┘
```

### 8.2 Initial Build Scope (v1.1 — Infrastructure Only)

**What gets built:**
- ✅ All 5 database tables + triggers + RLS policies
- ✅ All RPC functions (credit management, send logic, history)
- ✅ SMS template seeding (Bangla + English defaults)
- ✅ Mobile app screens (SMS dashboard, buy credits, send reminder, history)
- ✅ Rate limiting + duplicate prevention logic
- ✅ Credit deduction + refund logic
- ✅ Edge Function stub (`send-sms`) that logs but does NOT call any real API

**What is NOT built yet:**
- ❌ Actual SMS provider API integration (no HTTP calls to BulkSMSBD etc.)
- ❌ bKash Payment Gateway API (manual verification only)
- ❌ Delivery status webhooks from SMS provider
- ❌ Push notifications for credit top-up confirmation

**Behavior in initial build:**
- `send_baki_reminder_sms` → all validation + credit deduction works → `sms_log` created with `status = 'pending'` → Edge Function stub marks it as `status = 'sent'` (simulated) → no real SMS delivered
- This lets us fully test the credit system, UI, rate limiting, and duplicate prevention without spending money on real SMS

### 8.3 Provider Integration (Future — Separate Discussion)

When ready to connect a real provider:
1. Sign up with selected provider (likely BulkSMSBD)
2. Store API key in Supabase Vault / Edge Function env vars
3. Update `send-sms` Edge Function to make actual HTTP calls
4. Add delivery status webhook handler
5. Update `sms_logs.status` based on provider callbacks
6. Add credit refund logic for genuinely failed sends

---

## 9. Guards & Validation

### 9.1 Rate Limiting

| Tier | Daily SMS Limit | Bulk Send Max |
|---|---|---|
| Free | 50 SMS/day | 50 per batch |
| Pro | 200 SMS/day | 100 per batch |
| Business | 500 SMS/day | 100 per batch |

Rate limit resets at midnight (Bangladesh time, UTC+6).

### 9.2 Duplicate Prevention

- **Rule**: Max 1 baki reminder SMS per customer per 24 hours.
- **Implementation**: Before sending, check `sms_logs` for existing record with same `tenant_id + customer_id + template_key = 'baki_reminder'` within last 24 hours.
- **UX**: If duplicate detected, show warning: "This customer received a reminder X hours ago. Send again?" with explicit confirmation.

### 9.3 Phone Validation

- Bangladesh mobile format: `01[3-9]XXXXXXXX` (11 digits)
- Store with leading `0` (local format): `01712345678`
- For SMS API, prepend `88`: `8801712345678`
- Validate on customer creation/edit AND before SMS send

### 9.4 Credit Sufficiency

- Before individual send: check `current_balance >= 1`
- Before bulk send: check `current_balance >= selected_customer_count`
- Atomic deduction: use `SELECT ... FOR UPDATE` on `sms_credit_balances` to prevent race conditions

---

## 10. Mobile App Screens

### Screen 1: SMS Service Dashboard

**Location**: Settings → SMS Service

```
┌─────────────────────────────────┐
│  SMS Service                    │
│                                 │
│  ┌───────────────────────────┐  │
│  │  SMS Credits              │  │
│  │  ┌─────────┐              │  │
│  │  │   42    │  remaining   │  │
│  │  └─────────┘              │  │
│  │  [Buy Credits]            │  │
│  └───────────────────────────┘  │
│                                 │
│  Today's Usage: 12 / 50 limit   │
│                                 │
│  Quick Actions:                 │
│  [Send Bulk Reminder]           │
│                                 │
│  Recent SMS ─────────────────   │
│  Rahim    01712...  ✅ Sent     │
│  Karim    01819...  ✅ Sent     │
│  Jamal    01612...  ❌ Failed   │
│                                 │
│  [View All SMS History →]       │
└─────────────────────────────────┘
```

### Screen 2: Buy Credits (Bottom Sheet)

```
┌─────────────────────────────────┐
│  ━━━━  (drag handle)            │
│                                 │
│  Buy SMS Credits                │
│                                 │
│  ┌─────────────────────────┐    │
│  │ 🟢 Starter              │    │
│  │ 100 SMS — ৳100          │    │
│  │ ৳1.00 per SMS            │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ ⭐ Standard (Popular)    │    │
│  │ 500 SMS — ৳400          │    │
│  │ ৳0.80 per SMS            │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🔵 Bulk                  │    │
│  │ 2,000 SMS — ৳1,200      │    │
│  │ ৳0.60 per SMS            │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🏢 Enterprise            │    │
│  │ 10,000 SMS — ৳4,500     │    │
│  │ ৳0.45 per SMS            │    │
│  └─────────────────────────┘    │
│                                 │
│  After selecting:               │
│  "Send ৳400 to bKash 01XXXXXXX"│
│  [Enter bKash Transaction ID]  │
│  [Submit Request]               │
└─────────────────────────────────┘
```

### Screen 3: Send Individual Reminder (Bottom Sheet)

**Trigger**: Customer Profile → "Send SMS Reminder" button (visible only if baki > 0)

```
┌─────────────────────────────────┐
│  ━━━━  (drag handle)            │
│                                 │
│  Send Baki Reminder             │
│                                 │
│  To: Rahim Uddin                │
│  Phone: 01712345678             │
│  Baki: ৳1,200                   │
│                                 │
│  Language: [🔘 বাংলা] [⚪ English] │
│                                 │
│  Preview:                       │
│  ┌─────────────────────────┐    │
│  │ আপনার রহিম ক্যান্টিন-এ    │    │
│  │ বকেয়া আছে ৳1,200।         │    │
│  │ অনুগ্রহ করে পরিশোধ করুন।    │    │
│  │ - Smart-Hisab              │    │
│  └─────────────────────────┘    │
│                                 │
│  1 SMS credit will be used      │
│  Balance after: 41 credits      │
│                                 │
│  [Send Reminder]  [Cancel]      │
└─────────────────────────────────┘
```

### Screen 4: Bulk Send (Full Screen)

**Trigger**: SMS Dashboard → "Send Bulk Reminder" OR Baki Overview → "Send Reminders"

```
┌─────────────────────────────────┐
│  ← Bulk Baki Reminder           │
│                                 │
│  Minimum Baki: ৳[  500  ]      │
│  Language: [🔘 বাংলা] [⚪ English] │
│                                 │
│  ☑ Select All (18)              │
│  ─────────────────────────────  │
│  ☑ Rahim Uddin     ৳1,200  📱  │
│  ☑ Karim Hossain   ৳850   📱   │
│  ☑ Jamal Ahmed     ৳2,100  📱  │
│  ☐ Fatima Begum    ৳600   📱   │
│  ⚠ Salim (no phone)        ⛔  │
│  ⚠ Noor (reminded 3h ago)  🕐  │
│  ...                            │
│                                 │
│  ─────────────────────────────  │
│  Selected: 18 customers         │
│  Credits needed: 18             │
│  Your balance: 42 credits       │
│                                 │
│  [Send 18 Reminders]            │
└─────────────────────────────────┘
```

### Screen 5: SMS History

**Location**: Settings → SMS Service → View All History

```
┌─────────────────────────────────┐
│  ← SMS History                  │
│                                 │
│  [All] [Sent] [Failed] [Pending]│
│                                 │
│  Today ──────────────────────   │
│  Rahim Uddin    01712..  ✅ Sent│
│  12:30 PM · Baki Reminder       │
│                                 │
│  Karim Hossain  01819..  ✅ Sent│
│  12:30 PM · Baki Reminder       │
│                                 │
│  Jamal Ahmed    01612..  ❌ Fail│
│  12:31 PM · Invalid number      │
│                                 │
│  Yesterday ──────────────────   │
│  ...                            │
│                                 │
│  (Pull to refresh)              │
└─────────────────────────────────┘
```

---

## 11. Admin Panel (Future — Web Dashboard)

For the manual bKash top-up flow, we need a simple admin interface to verify payments and credit tenants. This could be:

1. **MVP**: Supabase Dashboard SQL → manually run `add_sms_credits(tenant_id, amount, bundle, ref)`
2. **Better**: Simple admin page in the web dashboard (if it gets unfrozen)
3. **Best**: Automated via bKash API webhook (future)

---

## 12. Complete Table Count (Updated)

| # | Table | Category |
|---|---|---|
| 1–20 | (existing tables) | See [database_schema_v2.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/new/database_schema_v2.md) |
| 21 | `sms_credit_balances` | SMS |
| 22 | `sms_credit_ledger` | SMS (Ledger) |
| 23 | `sms_templates` | SMS |
| 24 | `sms_logs` | SMS |
| 25 | `sms_rate_limits` | SMS |

**Total: 25 tables** (20 existing + 5 new)
