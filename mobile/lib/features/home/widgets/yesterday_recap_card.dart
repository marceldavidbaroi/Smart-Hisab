import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/business_day.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';

class YesterdayRecapCard extends StatelessWidget {
  final LastClosedDayRecap recap;

  const YesterdayRecapCard({
    super.key,
    required this.recap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isBalanced = recap.isBalanced;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.history, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.homeYesterdayRecap ?? "Yesterday's Recap",
                    style: TextStyle(
                      fontSize: 16, // AGENTS.md rule 7
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBalanced
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBalanced ? AppColors.primary : AppColors.warning,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBalanced ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                      size: 14,
                      color: isBalanced ? AppColors.primary : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBalanced
                          ? (l10n?.homeBalanced ?? 'Balanced')
                          : (l10n?.homeVarianceDiff(AppFormatters.formatBdt(recap.variance.abs())) ??
                              'Diff: ${AppFormatters.formatBdt(recap.variance.abs())}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isBalanced ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RecapStatTile(
                  label: l10n?.homeMealsServed ?? 'Meals Served',
                  value: '${recap.totalMeals}',
                  icon: LucideIcons.utensils,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RecapStatTile(
                  label: l10n?.homeCashCollected ?? 'Cash Collected',
                  value: AppFormatters.formatBdt(recap.totalInflows),
                  icon: LucideIcons.wallet,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _RecapStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
