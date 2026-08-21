import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable Cloud Sync Indicator showing whether data is synced with Supabase or saved locally offline
class CloudSyncIndicator extends StatelessWidget {
  final bool isSynced;
  final double size;
  final bool showLabel;

  const CloudSyncIndicator({
    super.key,
    required this.isSynced,
    this.size = 14,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSynced ? AppColors.success : AppColors.warning;
    final icon = isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded;
    final label = isSynced ? 'Synced' : 'Local Only';

    if (!showLabel) {
      return Tooltip(
        message: isSynced ? 'Synced to Cloud' : 'Saved Locally (Pending Sync)',
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
