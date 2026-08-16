import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/cashbook_entry.dart';
import '../../../core/utils/formatters.dart';

class LiveActivityFeed extends StatelessWidget {
  final List<CashbookEntry> activities;

  const LiveActivityFeed({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Activity Feed',
              style: TextStyle(
                fontSize: 16, // AGENTS.md rule 7
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              'Recent 5',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
            ),
            child: Text(
              'No recent transactions recorded today.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
              ),
              itemBuilder: (context, index) {
                final entry = activities[index];
                final isIncome = entry.type == 'income';
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.danger.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                      size: 16,
                      color: isIncome ? AppColors.primary : AppColors.danger,
                    ),
                  ),
                  title: Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    entry.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${AppFormatters.formatBdt(entry.amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? AppColors.primary : AppColors.danger,
                        ),
                      ),
                      Text(
                        AppFormatters.formatTimeOnly(entry.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
