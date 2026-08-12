import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'hive_service.dart';
import 'supabase_service.dart';
import '../utils/formatters.dart';

/// Offline Outbox Sync Engine based on docs/core/offline_architecture.md
class OutboxService {
  static final OutboxService _instance = OutboxService._internal();
  factory OutboxService() => _instance;
  OutboxService._internal();

  bool _isSyncing = false;

  /// Initialize connectivity listener for auto-sync on network regain
  void initialize() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncPendingOutbox();
      }
    });
  }

  /// Enqueue an RPC transaction for offline execution (0ms latency)
  Future<String> enqueue({
    required String rpcName,
    required Map<String, dynamic> payload,
  }) async {
    final itemId = AppFormatters.generateUuid();
    final clientTimestamp = DateTime.now().toIso8601String();

    final itemData = {
      'id': itemId,
      'rpc_name': rpcName,
      'payload': payload,
      'client_timestamp': clientTimestamp,
      'status': 'pending',
      'retry_count': 0,
      'created_at': clientTimestamp,
    };

    await HiveService.outboxBox.put(itemId, itemData);

    // Attempt immediate sync if online
    syncPendingOutbox();

    return itemId;
  }

  /// Flush pending outbox transactions to Supabase RPCs in FIFO order
  Future<void> syncPendingOutbox() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final keys = HiveService.outboxBox.keys.toList();
      for (final key in keys) {
        final raw = HiveService.outboxBox.get(key);
        if (raw == null) continue;
        final item = Map<String, dynamic>.from(raw as Map);

        if (item['status'] == 'pending' || item['status'] == 'failed') {
          try {
            item['status'] = 'syncing';
            await HiveService.outboxBox.put(key, item);

            final rpcName = item['rpc_name'] as String;
            final payload = Map<String, dynamic>.from(item['payload'] as Map);

            await SupabaseService.callRpc(rpcName, params: payload);

            // Successfully synced -> Remove from outbox
            await HiveService.outboxBox.delete(key);
          } catch (e) {
            debugPrint('Outbox sync error for item $key: $e');
            item['status'] = 'failed';
            item['retry_count'] = (item['retry_count'] as int? ?? 0) + 1;
            item['last_error'] = e.toString();
            await HiveService.outboxBox.put(key, item);
          }
        }
      }

      // Update sync metadata
      await HiveService.syncBox.put(
        'last_sync_at',
        DateTime.now().toIso8601String(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Get total pending outbox count
  int get pendingCount {
    return HiveService.outboxBox.values.where((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      return item['status'] == 'pending' || item['status'] == 'failed';
    }).length;
  }
}
