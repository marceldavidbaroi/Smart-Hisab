import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../core/widgets/empty_state_card.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final List<Map<String, dynamic>> _customers = [
    {
      'id': '1',
      'name': 'Rahim Ahmed',
      'phone': '01711000001',
      'balance': 450.0,
      'hasMealToday': true,
    },
    {
      'id': '2',
      'name': 'Karim Chowdhury',
      'phone': '01819000002',
      'balance': 1200.0,
      'hasMealToday': false,
    },
    {
      'id': '3',
      'name': 'Tanvir Hasan',
      'phone': '01912000003',
      'balance': 0.0,
      'hasMealToday': true,
    },
  ];

  String _searchQuery = '';

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  void _openBakiCollectionSheet(Map<String, dynamic> customer) {
    final amountController = TextEditingController();

    CustomModalBottomSheet.show(
      context: context,
      title: "Collect Baki — ${customer['name']}",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Current Outstanding Baki: ${AppFormatters.formatBdt(customer['balance'])}",
            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Collected Amount (৳)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final paid = num.tryParse(amountController.text) ?? 0;
              setState(() {
                customer['balance'] = (customer['balance'] as num) - paid;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Save Collection',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      return (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c['phone'] as String).contains(_searchQuery);
    }).toList();

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header & Search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Customers (${_customers.length})', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(LucideIcons.userPlus, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search customer name or phone...',
                  hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer List with Swipeable rows
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateCard(
                        icon: LucideIcons.users,
                        title: 'No Customers Found',
                        description: 'Add customer profiles to start recording meals and baki.',
                        actionLabel: 'Add New Customer',
                        onActionPressed: () {},
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final item = filtered[idx];
                          final balance = item['balance'] as num;

                          return Dismissible(
                            // Strict Rule #8: Swipeable row actions
                            key: Key(item['id']),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.trash2, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              setState(() => _customers.removeAt(idx));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorderDark),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                    child: Text(
                                      (item['name'] as String)[0],
                                      style: const TextStyle(
                                          color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Main Title >= 16 bold
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['phone'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppFormatters.formatBdt(balance),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: balance > 0 ? AppColors.danger : AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _openBakiCollectionSheet(item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Collect Baki',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
