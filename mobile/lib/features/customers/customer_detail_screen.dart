import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import 'customer_ledger_section.dart';
import 'customer_quick_action_grid.dart';
import 'customers_notifier.dart';
import 'edit_customer_bottom_sheet.dart';
import 'manage_meal_subscription_bottom_sheet.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  bool _isLoadingEntries = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchLedgerEntries();
      }
    });
  }

  Future<void> _fetchLedgerEntries() async {
    if (!mounted) return;
    setState(() => _isLoadingEntries = true);

    try {
      final res = await ref.read(customersNotifierProvider.notifier).fetchCustomerStatement(
        customerId: widget.customer.id,
      );

      final entriesList = List<Map<String, dynamic>>.from(res['entries'] as List? ?? []);

      // Check if there is any meal_attendance entry for today from statement data
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final hasEatenToday = entriesList.any((e) {
        final createdAt = e['created_at']?.toString() ?? '';
        final notes = (e['notes']?.toString() ?? '').toLowerCase();
        final type = e['type']?.toString() ?? '';
        return createdAt.startsWith(todayStr) &&
            (type == 'meal_charge' || notes.contains('meal attendance') || notes.contains('meal charge'));
      });

      if (hasEatenToday) {
        ref.read(customersNotifierProvider.notifier).markCustomerAsPresentLocally(widget.customer.id);
      }

      if (mounted) {
        setState(() {
          _entries = entriesList;
          _isLoadingEntries = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('_fetchLedgerEntries error: $e');
    }

    if (mounted) {
      setState(() {
        _entries = [];
        _isLoadingEntries = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersState = ref.watch(customersNotifierProvider);
    final activeCustomer = customersState.customers.firstWhere(
      (c) => c.id == widget.customer.id,
      orElse: () => widget.customer,
    );
    final isMarkedToday = customersState.markedCustomerIds.contains(activeCustomer.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          activeCustomer.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.edit3, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, size: 20),
            onPressed: () => EditCustomerBottomSheet.show(context, activeCustomer),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 20),
            onPressed: () async {
              if (activeCustomer.currentBalance > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Customer owes ৳${activeCustomer.currentBalance.toStringAsFixed(0)}. Collect payment before archiving profile.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  title: const Text('Delete Customer?', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to delete ${activeCustomer.name}? This customer profile will be archived/soft-deleted.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final success = await ref.read(customersNotifierProvider.notifier).deleteCustomer(activeCustomer.id);
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Customer ${activeCustomer.name} deleted'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  } else {
                    final err = ref.read(customersNotifierProvider).errorMessage ?? 'Failed to delete customer';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              }
            },
            tooltip: 'Delete Customer',
          ),
        ],
      ),

      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLedgerEntries,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer Profile Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            activeCustomer.name.isNotEmpty ? activeCustomer.name[0].toUpperCase() : 'C',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCustomer.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              if (activeCustomer.phone != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  activeCustomer.phone!,
                                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ],
                              if (activeCustomer.institution != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  activeCustomer.institution!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.utensils,
                          size: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeCustomer.activeMeals.isNotEmpty ? 'Subscribed Meals:' : 'Meal Subscription:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: activeCustomer.activeMeals.isNotEmpty
                              ? Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: activeCustomer.activeMeals.map((meal) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        meal,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              : Text(
                                  'None',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        InkWell(
                          onTap: () => ManageMealSubscriptionBottomSheet.show(context, activeCustomer),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              activeCustomer.activeMeals.isNotEmpty ? 'Edit' : '+ Add',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),

                    // Outstanding Balance Hero Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outstanding Baki',
                              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.formatBdt(activeCustomer.currentBalance),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: activeCustomer.currentBalance > 0 ? AppColors.danger : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (activeCustomer.currentBalance > 0 ? AppColors.danger : AppColors.success).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeCustomer.currentBalance > 0 ? 'Baki Due' : 'Cleared',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: activeCustomer.currentBalance > 0 ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4-Button Quick Actions Grid
              Text(
                'Customer Actions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              CustomerQuickActionGrid(
                customer: activeCustomer,
                isMarkedToday: isMarkedToday,
                onActionCompleted: _fetchLedgerEntries,
              ),
              const SizedBox(height: 20),

              // Ledger Section
              CustomerLedgerSection(
                customer: activeCustomer,
                isLoading: _isLoadingEntries,
                entries: _entries,
                onRefresh: _fetchLedgerEntries,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
