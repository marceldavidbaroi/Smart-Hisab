import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/cloud_sync_indicator.dart';
import 'cashbook_notifier.dart';
import 'widgets/cashbook_summary_header.dart';
import 'widgets/cashbook_wallet_selector.dart';
import 'widgets/transaction_list.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashbookNotifierProvider.notifier).fetchAccountsAndEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final notifier = ref.read(cashbookNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;


    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await notifier.fetchAccountsAndEntries();
        },
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cashflow & Ledger',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  CloudSyncIndicator(
                    isSynced: !cashbookState.isLoading && cashbookState.entries.every((e) => e.isSynced),
                    showLabel: true,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'দৈনিক জমা, খরচ ও ওয়ালেট ব্যালেন্স হিসাব',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 14),

              // Cashflow Summary Header with Total Wallets Balance
              CashbookSummaryHeader(
                totalInflow: cashbookState.totalInflow,
                totalOutflow: cashbookState.totalOutflow,
                netBalance: cashbookState.netBalance,
                totalWalletsBalance: cashbookState.totalWalletsBalance,
              ),
              const SizedBox(height: 14),

              // Canteen Wallets Channel Filter Selector
              if (cashbookState.accounts.isNotEmpty) ...[
                CashbookWalletSelector(
                  accounts: cashbookState.accounts,
                  selectedAccountId: cashbookState.selectedAccountId,
                  onAccountSelected: (accId) => notifier.selectAccountFilter(accId),
                ),
                const SizedBox(height: 14),
              ],

              // Transaction List Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${cashbookState.filteredEntries.length} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Day Transactions List
              Expanded(
                child: TransactionList(
                  entries: cashbookState.filteredEntries,
                  isLoading: cashbookState.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
