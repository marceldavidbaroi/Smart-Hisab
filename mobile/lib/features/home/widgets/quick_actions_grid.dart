import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildActionButton(
          context,
          l10n?.homeActionMarkMeals ?? 'Mark Meals',
          LucideIcons.utensilsCrossed,
          AppColors.primary,
          onMarkMeals,
        ),
        _buildActionButton(
          context,
          l10n?.homeActionCollectBaki ?? 'Collect Baki',
          LucideIcons.wallet,
          AppColors.success,
          onCollectBaki,
        ),
        _buildActionButton(
          context,
          l10n?.homeActionAddExpense ?? 'Add Expense',
          LucideIcons.shoppingBag,
          AppColors.warning,
          onAddExpense,
        ),
        _buildActionButton(
          context,
          l10n?.homeActionDayNotes ?? 'Day Notes',
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

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15, // AGENTS.md rule 7
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
