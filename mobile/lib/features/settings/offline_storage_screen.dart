import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/outbox_service.dart';
import '../../core/widgets/app_safe_area.dart';

class OfflineStorageScreen extends ConsumerStatefulWidget {
  const OfflineStorageScreen({super.key});

  @override
  ConsumerState<OfflineStorageScreen> createState() => _OfflineStorageScreenState();
}

class _OfflineStorageScreenState extends ConsumerState<OfflineStorageScreen> {
  int _pendingCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadQueueStatus();
  }

  void _loadQueueStatus() {
    setState(() {
      _pendingCount = OutboxService().pendingCount;
    });
  }

  Future<void> _triggerManualSync() async {
    setState(() {
      _isSyncing = true;
    });

    await OutboxService().syncPendingOutbox();
    _loadQueueStatus();

    setState(() {
      _isSyncing = false;
    });

    NotificationService.showSuccess("Offline outbox sync attempted");
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Storage & Outbox', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: AppSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Outbox Status Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _pendingCount == 0 ? LucideIcons.checkCircle : LucideIcons.cloudOff,
                      size: 48,
                      color: _pendingCount == 0 ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pendingCount == 0 ? 'All Changes Synced' : '$_pendingCount Pending Sync Requests',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pendingCount == 0
                          ? 'Your device local storage is up to date with cloud server.'
                          : 'Transactions queued while offline will be automatically uploaded when online.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Manual Sync Trigger Button
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _triggerManualSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.refreshCw, color: Colors.white, size: 20),
                label: Text(
                  _isSyncing ? 'Syncing...' : 'Force Sync Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
