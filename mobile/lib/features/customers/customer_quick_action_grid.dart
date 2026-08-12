import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import 'add_manual_baki_bottom_sheet.dart';
import 'collect_baki_bottom_sheet.dart';
import 'customers_notifier.dart';
import 'manage_meal_subscription_bottom_sheet.dart';

class CustomerQuickActionGrid extends ConsumerWidget {
  final Customer customer;
  final bool isMarkedToday;
  final VoidCallback onActionCompleted;

  const CustomerQuickActionGrid({
    super.key,
    required this.customer,
    required this.isMarkedToday,
    required this.onActionCompleted,
  });

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildActionButton(
          context: context,
          icon: LucideIcons.calendarCheck2,
          label: 'Subscription',
          color: AppColors.primary,
          onTap: () => ManageMealSubscriptionBottomSheet.show(context, customer),
        ),
        _buildActionButton(
          context: context,
          icon: isMarkedToday ? LucideIcons.checkCircle2 : LucideIcons.utensils,
          label: isMarkedToday ? 'Meal: Ate' : 'Mark Meal',
          color: AppColors.success,
          onTap: () async {
            await ref.read(customersNotifierProvider.notifier).recordMealAttendance(customer.id);
            onActionCompleted();
          },
        ),
        _buildActionButton(
          context: context,
          icon: LucideIcons.plusCircle,
          label: 'Add Baki',
          color: AppColors.danger,
          onTap: () async {
            await AddManualBakiBottomSheet.show(context, customer);
            onActionCompleted();
          },
        ),
        _buildActionButton(
          context: context,
          icon: LucideIcons.banknote,
          label: 'Collect Baki',
          color: AppColors.success,
          onTap: () async {
            await CollectBakiBottomSheet.show(context, customer);
            onActionCompleted();
          },
        ),
      ],
    );
  }
}
