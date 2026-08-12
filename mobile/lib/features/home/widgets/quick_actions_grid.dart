import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onMarkMeals;
  final VoidCallback onCollectBaki;
  final VoidCallback onAddExpense;
  final VoidCallback onDayNotes;

  const QuickActionsGrid({
    super.key,
    required this.onMarkMeals,
    required this.onCollectBaki,
    required this.onAddExpense,
    required this.onDayNotes,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionButton(
          context,
          'Mark Meals',
          LucideIcons.utensilsCrossed,
          AppColors.primary,
          onMarkMeals,
        ),
        _buildActionButton(
          context,
          'Collect Baki',
          LucideIcons.wallet,
          AppColors.success,
          onCollectBaki,
        ),
        _buildActionButton(
          context,
          'Add Expense',
          LucideIcons.shoppingBag,
          AppColors.warning,
          onAddExpense,
        ),
        _buildActionButton(
          context,
          'Day Notes',
          LucideIcons.fileText,
          AppColors.accent,
          onDayNotes,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
