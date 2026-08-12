import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showInviteManagerModal(BuildContext context) {
    CustomModalBottomSheet.show(
      context: context,
      title: "Invite Manager",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Give this 6-digit code to your manager. Valid for 24 hours.",
            style: TextStyle(color: AppColors.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: const Text(
              "8 4 9 2 0 1",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBorderDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(LucideIcons.check, color: Colors.white),
            label: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _buildTile(
              context,
              'Invite Manager',
              'Generate 6-digit join code for manager',
              LucideIcons.userPlus,
              () => _showInviteManagerModal(context),
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              'Shifts & Meal Configs',
              'Breakfast, Lunch, Dinner timings & rates',
              LucideIcons.clock,
              () {},
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              'Vendors Ledger',
              'Market suppliers & Bazar accounts',
              LucideIcons.truck,
              () {},
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              'Offline Storage & Outbox',
              'View pending offline sync queue',
              LucideIcons.database,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
        ),
        trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSecondaryDark, size: 20),
        onTap: onTap,
      ),
    );
  }
}
