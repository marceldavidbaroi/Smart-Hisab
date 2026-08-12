import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/auth_notifier.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_modal_bottom_sheet.dart';

class CanteenActionSheets {
  CanteenActionSheets._();

  /// Show Modal Bottom Sheet to confirm Canteen Deletion (Owner)
  static void showDeleteCanteen({
    required BuildContext context,
    required WidgetRef ref,
    required String tenantId,
    required String canteenName,
    VoidCallback? onSuccess,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Delete Canteen',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Warning: Deleting "$canteenName" is permanent and will remove all orders, inventory, and member data.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Are you sure you want to delete this canteen?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final success =
                        await ref.read(authNotifierProvider.notifier).deleteCanteen(tenantId);
                    if (success) {
                      NotificationService.showSuccess('Canteen deleted successfully');
                      onSuccess?.call();
                    } else {
                      final err =
                          ref.read(authNotifierProvider).errorMessage ?? 'Failed to delete canteen';
                      NotificationService.showError(err);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Delete Canteen',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show Modal Bottom Sheet to confirm Leaving Canteen (Manager)
  static void showLeaveCanteen({
    required BuildContext context,
    required WidgetRef ref,
    required String tenantId,
    required String canteenName,
    VoidCallback? onSuccess,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Leave Canteen',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.logOut, color: AppColors.warning, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will lose access to "$canteenName". You will need a new invite code from the owner to join again.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Are you sure you want to leave this canteen?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final success =
                        await ref.read(authNotifierProvider.notifier).leaveCanteen(tenantId);
                    if (success) {
                      NotificationService.showSuccess('Left canteen successfully');
                      onSuccess?.call();
                    } else {
                      final err =
                          ref.read(authNotifierProvider).errorMessage ?? 'Failed to leave canteen';
                      NotificationService.showError(err);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Leave Canteen',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
