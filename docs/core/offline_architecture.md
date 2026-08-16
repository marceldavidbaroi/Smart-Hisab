# Smart-Hisab — Offline Architecture & Hive Local Schema

> Single source of truth for offline-first data persistence, Hive local box schemas, screen-by-screen offline behavior, and Supabase RPC synchronization.

---

## 1. System Overview

Smart-Hisab uses an **Outbox Pattern** powered by **Hive** (pure Dart key-value database) to provide full offline support for canteen operations (meal attendance, baki collections, market expenses, vendor payments).

```
┌─────────────────────────────────────────────────────────────┐
│                       FLUTTER APP                           │
│                                                             │
│  User Action ──► 1. Update UI (0ms Latency)                │
│             ──► 2. Mutate Local Hive Cache                │
│             ──► 3. Enqueue to Hive 'outbox_box'             │
│                                                             │
│                 Hive 'outbox_box' (Persistent)             │
└──────────────────────────────┬──────────────────────────────┘
                               │
                      (Connectivity Listener)
                               │ (When Online - FIFO Queue)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND                         │
│                                                             │
│       Executes Stored Procedure RPCs (Idempotent)           │
│       • Uses Client-Generated UUID (v4)                     │
│       • Preserves `client_timestamp`                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Core Offline Rules

1. **Client-Generated UUIDs**: All primary keys (`id`) MUST be generated client-side using `uuid.v4()` before inserting into the local outbox or calling an RPC.
2. **0ms Latency UI**: When an offline action occurs, the UI updates **instantly** by mutating local Hive cache without waiting for network confirmation.
3. **Idempotent RPC Execution**: RPCs on Supabase use `ON CONFLICT (id) DO NOTHING` or `idempotency_key` checking to guarantee that network retries never produce duplicate charges or wallet entries.
4. **Original Timestamps**: All write RPCs accept a `client_timestamp` parameter so transaction history reflects when the offline action took place, not when the sync engine ran.
5. **Append-Only Ledgers**: Financial entries (`wallet_entries`, `vendor_wallet_entries`, `meal_attendance`) are append-only. This eliminates complex multi-device offline merge conflicts.

---

## 3. Hive Box Architecture

Smart-Hisab maintains **3 core Hive Boxes**:

```
Hive Storage
├── 'outbox_box'     → Pending RPC calls awaiting network transmission
├── 'cache_box'      → Local entity read replicas (customers, vendors, shifts, etc.)
└── 'sync_box'       → Sync metadata (last sync time, queue status, connection flag)
```

### 3.1. `outbox_box` Schema (`HiveOutboxItem`)

Stores enqueued transactions that need to be pushed to Supabase.

```dart
class HiveOutboxItem {
  final String id;              // UUID v4
  final String rpcName;         // e.g. 'record_meal_attendance'
  final Map<String, dynamic> payload; // RPC argument payload
  final String clientTimestamp; // ISO-8601 string when action occurred
  String status;                // 'pending' | 'syncing' | 'failed'
  int retryCount;               // Default: 0
  String? lastError;            // Error message if sync failed

  Map<String, dynamic> toJson() => {
    'id': id,
    'rpc_name': rpcName,
    'payload': payload,
    'client_timestamp': clientTimestamp,
    'status': status,
    'retry_count': retryCount,
    'last_error': lastError,
  };
}
```

### 3.2. `cache_box` Schema (`HiveCache`)

Stores read replicas of server data for offline rendering. Keys are prefixed by entity type: `customer:<id>`, `vendor:<id>`, `shift:active`, `meal_config:active`.

#### A. Customer Cache Schema (`customer:<id>`)
```json
{
  "id": "uuid-v4",
  "tenant_id": "uuid-v4",
  "name": "Rahim Ahmed",
  "phone": "01711000000",
  "current_balance": 450.00,
  "is_active": true,
  "updated_at": "2026-08-12T00:00:00Z"
}
```

#### B. Vendor Cache Schema (`vendor:<id>`)
```json
{
  "id": "uuid-v4",
  "tenant_id": "uuid-v4",
  "name": "Bismillah Rice Store",
  "phone": "01811000000",
  "current_balance": -1200.00,
  "updated_at": "2026-08-12T00:00:00Z"
}
```

#### C. Meal Config & Shift Cache Schema (`shift:current`)
```json
{
  "shift_id": "uuid-v4",
  "shift_name": "Lunch",
  "start_time": "12:00",
  "end_time": "15:00",
  "rate": 60.00,
  "is_active": true
}
```

#### D. Active Business Day Cache Schema (`business_day:active`)
```json
{
  "id": "uuid-v4",
  "tenant_id": "uuid-v4",
  "date": "2026-08-12",
  "status": "open",
  "opening_balance": 1000.00,
  "started_at": "2026-08-12T06:00:00Z"
}
```

---

## 4. Screen-by-Screen Offline Action Matrix

This matrix maps every user action in [releases/v1.0/screen_map.md](file:///Users/daviditc/Documents/personal_projects/smart-hisab/docs/releases/v1.0/screen_map.md) to its offline Hive mutation and RPC queue behavior:

| Screen Name | User Action | Offline Support | Hive Local Cache Mutation | Enqueued RPC (`outbox_box`) |
|---|---|---|---|---|
| **01. Splash / Auth** | App Launch | ✅ Offline Ready | Loads `sync_box.tenant` & `sync_box.user` | None (reads local session) |
| **02. Home / Dashboard** | View Daily Summary | ✅ Offline Ready | Reads `business_day:active` & computes totals from local transactions | `get_financial_summary` (on reconnect) |
| **03. Customer List** | Search / View Customers | ✅ Offline Ready | Queries `cache_box` keys matching `customer:*` | None |
| **04. Customer Details** | View Statement & Balance | ✅ Offline Ready | Reads `customer:<id>` balance + local queued statement entries | `get_customer_statement` (on reconnect) |
| **04a. Record Baki Payment** | Submit Payment | ✅ Full Offline | • Decreases `customer:<id>.current_balance`<br>• Adds entry to local statement list | `record_baki_payment` |
| **05. Meal Attendance** | One-tap Meal Toggle | ✅ Full Offline | • Toggles meal state locally<br>• If turning ON: increases `customer:<id>.current_balance` by shift rate<br>• If turning OFF: decreases balance | `record_meal_attendance` |
| **05a. Bulk Meal Toggle** | Mark All / Un-toggle | ✅ Full Offline (v2.0) | • Updates all cached customers in shift<br>• Mutates multiple `customer:*` balances | `bulk_record_meal_attendance` |
| **06. Bazar & Expenses** | Record Expense | ✅ Full Offline | Reads/updates daily expense totals in `business_day:active` | `record_expense` |
| **06a. Vendor Payment** | Settlement Payout | ✅ Full Offline | • Decreases vendor baki in `vendor:<id>.current_balance` | `record_vendor_payment` |
| **06b. Misc Income** | Record Cash In | ✅ Full Offline | Increases local cash total in `business_day:active` | `record_misc_income` |
| **07. Staff List** | View Staff | ✅ Offline Ready | Reads `staff:*` keys from `cache_box` | None |
| **07a. Salary Payout** | Submit Payout | ✅ Full Offline | Updates `staff:<id>.wallet_balance` | `record_salary_payout` |
| **08. Counter Mode PIN Gate** | Verify Staff PIN | ✅ Full Offline | Validates 4-digit PIN against `staff:*` local hash | None (local authentication) |
| **09. Open Business Day** | Start Day | ⚠️ Offline Limited | Creates local `business_day:active` with `status: 'open_pending'` | `start_business_day` |
| **10. Close Business Day** | Reconcile & Close | ⚠️ Online Preferred | If offline, saves `business_day:active` with `status: 'close_pending'` | `end_business_day` |
| **11. Settings & Invites** | Create Tenant / Invite | ❌ Online Only | N/A (Requires live cloud validation) | N/A |

---

## 5. Offline Sync Engine Algorithm

The Flutter app runs a singleton `OfflineSyncEngine` background provider that handles automated network recovery:

```dart
class OfflineSyncEngine {
  final Box outboxBox = Hive.box('outbox_box');
  final SupabaseClient supabase = Supabase.instance.client;
  bool isSyncing = false;

  void initializeNetworkListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        processOutboxQueue();
      }
    });
  }

  Future<void> processOutboxQueue() async {
    if (isSyncing || outboxBox.isEmpty) return;
    isSyncing = true;

    final keys = outboxBox.keys.toList();
    for (var key in keys) {
      final item = outboxBox.get(key) as HiveOutboxItem;

      if (item.status == 'failed' && item.retryCount >= 5) {
        continue; // Skip items that exceeded max retries
      }

      try {
        item.status = 'syncing';
        await outboxBox.put(key, item);

        // Execute RPC on Supabase
        await supabase.rpc(
          item.rpcName,
          params: {
            ...item.payload,
            'idempotency_key': item.id,
            'client_timestamp': item.clientTimestamp,
          },
        );

        // On success: remove from local outbox queue
        await outboxBox.delete(key);
      } catch (e) {
        item.status = 'failed';
        item.retryCount += 1;
        item.lastError = e.toString();
        await outboxBox.put(key, item);
        break; // Stop loop on network error to preserve FIFO ordering
      }
    }

    isSyncing = false;
  }
}
```

---

## 6. Conflict Resolution & Edge Cases

1. **Simultaneous Offline Edits on 2 Devices**:
   - Financial ledger entries are **append-only** (each payment or expense adds a row with its own client UUID v4).
   - On server execution, `customer_wallets` and `vendor_wallets` calculate total balance dynamically or increment balance atomically via database triggers. Conflicts are eliminated by design.
2. **Business Day Closure Conflicts**:
   - If User A closes the business day offline while User B continues logging meals offline, User B's synced transactions will attach to the active business day based on their `client_timestamp`.
3. **Outbox Max Retries**:
   - If an item fails due to a server error (e.g. invalid permissions or bad data payload), it is flagged as `failed` with `retryCount = 5` and preserved in Hive for user inspection in Settings → "Pending Sync Queue".
