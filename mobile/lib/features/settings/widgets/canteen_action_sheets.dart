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
  /// Requires typing the canteen name to enable deletion button
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
      child: _DeleteCanteenConfirmationForm(
        tenantId: tenantId,
        canteenName: canteenName,
        onSuccess: onSuccess,
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

class _DeleteCanteenConfirmationForm extends ConsumerStatefulWidget {
  final String tenantId;
  final String canteenName;
  final VoidCallback? onSuccess;

  const _DeleteCanteenConfirmationForm({
    required this.tenantId,
    required this.canteenName,
    this.onSuccess,
  });

  @override
  ConsumerState<_DeleteCanteenConfirmationForm> createState() =>
      _DeleteCanteenConfirmationFormState();
}

class _DeleteCanteenConfirmationFormState
    extends ConsumerState<_DeleteCanteenConfirmationForm> {
  final _inputController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  bool get _isMatch =>
      _inputController.text.trim().toLowerCase() ==
      widget.canteenName.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permanent Action: Deleting will wipe all sales, baki records, meal attendance, and inventory.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            children: [
              const TextSpan(text: 'Please type '),
              TextSpan(
                text: widget.canteenName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const TextSpan(text: ' to confirm deletion:'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inputController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.canteenName,
            hintStyle: TextStyle(
              color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                  .withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isMatch ? AppColors.danger : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
                onPressed: (!_isMatch || _isSubmitting)
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        Navigator.pop(context);
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .deleteCanteen(widget.tenantId);
                        if (success) {
                          NotificationService.showSuccess('Canteen deleted successfully');
                          widget.onSuccess?.call();
                        } else {
                          final err = ref.read(authNotifierProvider).errorMessage ??
                              'Failed to delete canteen';
                          NotificationService.showError(err);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Delete Canteen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

