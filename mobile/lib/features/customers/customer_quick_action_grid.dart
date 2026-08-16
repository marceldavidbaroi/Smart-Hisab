import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import 'add_manual_baki_bottom_sheet.dart';
import 'collect_baki_bottom_sheet.dart';
import 'manage_meal_subscription_bottom_sheet.dart';
import 'meal_attendance_calendar_bottom_sheet.dart';

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
      childAspectRatio: 2.4,
      children: [
        _buildActionButton(
          context: context,
          icon: customer.activeMeals.isNotEmpty ? LucideIcons.utensils : LucideIcons.utensilsCrossed,
          label: customer.activeMeals.isNotEmpty ? 'Edit Meals' : 'Add Meal',
          color: AppColors.primary,
          onTap: () => ManageMealSubscriptionBottomSheet.show(context, customer),
        ),
        Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final hasActiveMeal = customer.activeMeals.isNotEmpty;
          final buttonColor = hasActiveMeal ? AppColors.success : Colors.grey;

          return IgnorePointer(
            ignoring: !hasActiveMeal,
            child: InkWell(
              onTap: hasActiveMeal
                  ? () async {
                      await MealAttendanceCalendarBottomSheet.show(context, customer);
                      onActionCompleted();
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Opacity(
                opacity: hasActiveMeal ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: buttonColor.withValues(alpha: hasActiveMeal ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: buttonColor.withValues(alpha: hasActiveMeal ? 0.3 : 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMarkedToday ? LucideIcons.checkCircle2 : LucideIcons.calendarCheck2,
                        color: buttonColor,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isMarkedToday ? 'Meal: Ate Today' : 'Mark Attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasActiveMeal
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
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
