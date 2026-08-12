import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import 'add_day_note_bottom_sheet.dart';
import 'add_expense_bottom_sheet.dart';
import 'add_income_bottom_sheet.dart';
import 'cashbook_notifier.dart';
import 'widgets/cashbook_summary_header.dart';
import 'widgets/transaction_list.dart';

class CashbookScreen extends ConsumerWidget {
  const CashbookScreen({super.key});

  void _openAddExpenseModal(BuildContext context, WidgetRef ref) {
    AddExpenseBottomSheet.show(
      context,
      onSubmit: ({
        required String title,
        required String category,
        required double amount,
        String? notes,
      }) {
        ref.read(cashbookNotifierProvider.notifier).addExpense(
              title: title,
              category: category,
              amount: amount,
              notes: notes,
            );
      },
    );
  }

  void _openAddNoteModal(BuildContext context, WidgetRef ref) {
    AddDayNoteBottomSheet.show(
      context,
      onSubmit: ({
        required String title,
        required String content,
      }) {
        ref.read(cashbookNotifierProvider.notifier).addDayNote(
              title: title,
              content: content,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final notifier = ref.read(cashbookNotifierProvider.notifier);

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await notifier.fetchCashbookEntries();
        },
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cashbook & Bazar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Daily inflow, market expense & notes',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Record Misc Income',
                        icon: const Icon(LucideIcons.arrowDownLeft, color: AppColors.success),
                        onPressed: () => AddIncomeBottomSheet.show(context),
                      ),
                      IconButton(
                        tooltip: 'Add Day Note',
                        icon: const Icon(LucideIcons.fileText, color: AppColors.info),
                        onPressed: () => _openAddNoteModal(context, ref),
                      ),
                      IconButton(
                        tooltip: 'Record Expense',
                        icon: const Icon(LucideIcons.plusCircle, color: AppColors.danger),
                        onPressed: () => _openAddExpenseModal(context, ref),
                      ),
                    ],
                  ),

                ],
              ),
              const SizedBox(height: 16),

              // Cashflow Summary Header
              CashbookSummaryHeader(
                totalInflow: cashbookState.totalInflow,
                totalOutflow: cashbookState.totalOutflow,
                netBalance: cashbookState.netBalance,
              ),
              const SizedBox(height: 16),

              // Transaction List Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Day Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    '${cashbookState.entries.length} entries',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Day Transactions List
              Expanded(
                child: TransactionList(
                  entries: cashbookState.entries,
                  isLoading: cashbookState.isLoading,
                  onDelete: (id) => notifier.deleteEntry(id),
                  onAddExpense: () => _openAddExpenseModal(context, ref),
                  onAddNote: () => _openAddNoteModal(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
