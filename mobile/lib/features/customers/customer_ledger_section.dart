import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/utils/formatters.dart';
import 'void_transaction_bottom_sheet.dart';

class CustomerLedgerSection extends StatelessWidget {
  final Customer customer;
  final bool isLoading;
  final List<Map<String, dynamic>> entries;
  final VoidCallback onRefresh;

  const CustomerLedgerSection({
    super.key,
    required this.customer,
    required this.isLoading,
    required this.entries,
    required this.onRefresh,
  });

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      highlightColor: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
      child: Column(
        children: List.generate(
          4,
          (index) => Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity Header
        Text(
          'Transaction Ledger',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),

        // Activity Content List
        if (isLoading)
          _buildShimmerLoading(context)
        else if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
              ),
            ),
            child: Center(
              child: Text(
                'No transaction history recorded yet.',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final entry = entries[idx];
              final entryId = entry['id']?.toString() ?? '$idx';
              final isPayment = entry['type'] == 'payment';
              final isAdjustment = entry['type'] == 'adjustment';
              final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
              final notes = entry['notes'] as String? ?? (isPayment ? 'Baki Payment' : 'Meal Charge');
              final dateStr = entry['created_at'] != null
                  ? AppFormatters.formatDateTime(DateTime.parse(entry['created_at'].toString()))
                  : '';

              final metadata = entry['metadata'] is Map
                  ? Map<String, dynamic>.from(entry['metadata'] as Map)
                  : <String, dynamic>{};

              final isVoided = metadata['status'] == 'voided';
              final isReversal = metadata['status'] == 'reversal';
              final voidInfo = metadata['void_info'] is Map
                  ? Map<String, dynamic>.from(metadata['void_info'] as Map)
                  : null;
              final voidReason = voidInfo?['reason'] as String?;

              final iconColor = isVoided
                  ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                  : (isPayment
                      ? AppColors.success
                      : (isAdjustment ? AppColors.warning : AppColors.danger));

              Widget itemTile = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isVoided
                        ? AppColors.danger.withValues(alpha: 0.3)
                        : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: iconColor.withValues(alpha: 0.15),
                      child: Icon(
                        isVoided
                            ? LucideIcons.ban
                            : (isPayment
                                ? LucideIcons.arrowDownLeft
                                : (isAdjustment ? LucideIcons.plusCircle : LucideIcons.utensils)),
                        color: iconColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notes,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isVoided
                                        ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                    decoration: isVoided ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (isVoided)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VOIDED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              if (isReversal)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'REVERSAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (isVoided && voidReason != null && voidReason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: $voidReason',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isPayment ? '-' : '+'}${AppFormatters.formatBdt(amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isVoided
                            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                            : (isPayment ? AppColors.success : AppColors.danger),
                        decoration: isVoided ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );

              // If already voided or a reversal entry, do not allow swiping
              if (isVoided || isReversal) {
                return itemTile;
              }

              // Swipeable row action for management (AGENTS.md Constraint #8)
              return Dismissible(
                key: Key('wallet_entry_$entryId'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(LucideIcons.ban, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Void Entry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  final res = await VoidTransactionBottomSheet.show(
                    context,
                    customer: customer,
                    entry: entry,
                  );
                  if (res == true) {
                    onRefresh();
                  }
                  return false;
                },
                child: GestureDetector(
                  onLongPress: () async {
                    final res = await VoidTransactionBottomSheet.show(
                      context,
                      customer: customer,
                      entry: entry,
                    );
                    if (res == true) {
                      onRefresh();
                    }
                  },
                  child: itemTile,
                ),
              );
            },
          ),
      ],
    );
  }
}
