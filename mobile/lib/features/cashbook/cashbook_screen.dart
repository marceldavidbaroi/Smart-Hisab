import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../settings/vendors_notifier.dart';
import 'cashbook_notifier.dart';
import 'widgets/bazar_hub_view.dart';
import 'widgets/cashbook_summary_header.dart';
import 'widgets/cashbook_wallet_selector.dart';
import 'widgets/transaction_list.dart';

class CashbookScreen extends ConsumerStatefulWidget {
  const CashbookScreen({super.key});

  @override
  ConsumerState<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends ConsumerState<CashbookScreen> {
  int _selectedSubTab = 0; // 0 = Cashbook, 1 = Bazar

  @override
  Widget build(BuildContext context) {
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final notifier = ref.read(cashbookNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (_selectedSubTab == 0) {
            await notifier.fetchAccountsAndEntries();
          } else {
            await ref.read(vendorsNotifierProvider.notifier).fetchVendors();
            await notifier.fetchCashbookEntries();
          }
        },
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title & Subtitle
              Text(
                _selectedSubTab == 0 ? 'Cashflow' : 'Bazar & Vendors',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              // Segmented Sub-View Switch
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardBorderLight.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _SubTabButton(
                        label: 'Cashbook',
                        isSelected: _selectedSubTab == 0,
                        onTap: () => setState(() => _selectedSubTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _SubTabButton(
                        label: 'Bazar Hub',
                        isSelected: _selectedSubTab == 1,
                        onTap: () => setState(() => _selectedSubTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Active View
              Expanded(
                child: _selectedSubTab == 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                      )
                    : const BazarHubView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
