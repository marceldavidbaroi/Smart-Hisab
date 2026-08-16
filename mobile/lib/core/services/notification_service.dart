import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';

enum NotificationType { success, error, warning, info }

/// Global notification service for displaying styled SnackBars & Toasts
/// without requiring a BuildContext.
class NotificationService {
  NotificationService._();

  /// Global key attached to MaterialApp's scaffoldMessengerKey
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Display a success notification
  static void showSuccess(String message, {Duration? duration}) {
    show(
      message: message,
      type: NotificationType.success,
      duration: duration,
    );
  }

  /// Display an error notification
  static void showError(String message, {Duration? duration}) {
    show(
      message: message,
      type: NotificationType.error,
      duration: duration,
    );
  }

  /// Display a warning notification
  static void showWarning(String message, {Duration? duration}) {
    show(
      message: message,
      type: NotificationType.warning,
      duration: duration,
    );
  }

  /// Display an informational notification
  static void showInfo(String message, {Duration? duration}) {
    show(
      message: message,
      type: NotificationType.info,
      duration: duration,
    );
  }

  /// Show custom styled toast/SnackBar across any screen
  static void show({
    required String message,
    NotificationType type = NotificationType.info,
    Duration? duration,
  }) {
    final state = messengerKey.currentState;
    if (state == null) return;

    final config = _getNotificationConfig(type);

    final context = messengerKey.currentContext;
    final isDark = context != null ? Theme.of(context).brightness == Brightness.dark : true;
    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    state.hideCurrentSnackBar();
    state.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              config.icon,
              color: config.iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: config.borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration ?? const Duration(seconds: 4),
        elevation: 6,
      ),
    );
  }

  static _NotificationStyleConfig _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationStyleConfig(
          icon: LucideIcons.checkCircle2,
          iconColor: AppColors.success,
          borderColor: AppColors.success.withValues(alpha: 0.4),
        );
      case NotificationType.error:
        return _NotificationStyleConfig(
          icon: LucideIcons.alertCircle,
          iconColor: AppColors.danger,
          borderColor: AppColors.danger.withValues(alpha: 0.4),
        );
      case NotificationType.warning:
        return _NotificationStyleConfig(
          icon: LucideIcons.alertTriangle,
          iconColor: AppColors.warning,
          borderColor: AppColors.warning.withValues(alpha: 0.4),
        );
      case NotificationType.info:
        return _NotificationStyleConfig(
          icon: LucideIcons.info,
          iconColor: AppColors.info,
          borderColor: AppColors.info.withValues(alpha: 0.4),
        );
    }
  }
}

class _NotificationStyleConfig {
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  const _NotificationStyleConfig({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });
}
