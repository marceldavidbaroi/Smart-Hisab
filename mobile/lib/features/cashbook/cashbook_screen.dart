import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  final List<Map<String, dynamic>> _entries = [
    {
      'id': '1',
      'title': 'Bazar Purchase (Vegetables)',
      'category': 'Market Expense',
      'amount': 2500.0,
      'type': 'expense',
      'time': '09:30 AM',
    },
    {
      'id': '2',
      'title': 'Baki Collected (Rahim)',
      'category': 'Collection',
      'amount': 450.0,
      'type': 'income',
      'time': '11:15 AM',
    },
  ];

  void _openAddExpenseModal() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    CustomModalBottomSheet.show(
      context: context,
      title: "Record Market Expense",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Expense Description',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount (৳)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final amt = num.tryParse(amountCtrl.text) ?? 0;
              setState(() {
                _entries.insert(0, {
                  'id': AppFormatters.generateUuid(),
                  'title': titleCtrl.text.isEmpty ? 'Market Expense' : titleCtrl.text,
                  'category': 'Expense',
                  'amount': amt.toDouble(),
                  'type': 'expense',
                  'time': 'Just now',
                });
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Save Expense',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cashbook & Bazar', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
                    onPressed: _openAddExpenseModal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final item = _entries[idx];
                    final isExpense = item['type'] == 'expense';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isExpense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                            color: isExpense ? AppColors.danger : AppColors.success,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['category']} • ${item['time']}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.formatBdt(item['amount']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpense ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
