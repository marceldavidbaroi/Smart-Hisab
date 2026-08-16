import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/canteen_account.dart';
import '../../../core/utils/formatters.dart';

class CashbookWalletSelector extends StatelessWidget {
  final List<CanteenAccount> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountSelected;

  const CashbookWalletSelector({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
  });

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'mobile_money':
        return LucideIcons.smartphone;
      case 'bank':
        return LucideIcons.landmark;
      case 'safe':
        return LucideIcons.lock;
      case 'cash_drawer':
      default:
        return LucideIcons.coins;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Wallets Pill
          _FilterChip(
            label: 'All Wallets',
            icon: LucideIcons.wallet,
            isSelected: selectedAccountId == null,
            isDark: isDark,
            onTap: () => onAccountSelected(null),
          ),
          const SizedBox(width: 8),

          // Dynamic Canteen Wallets
          ...accounts.map((acc) {
            final isSelected = selectedAccountId == acc.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: '${acc.name} (${AppFormatters.formatBdt(acc.currentBalance)})',
                icon: _getAccountIcon(acc.accountType),
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => onAccountSelected(acc.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
