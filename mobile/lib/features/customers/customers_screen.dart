import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/empty_state_card.dart';
import 'add_customer_bottom_sheet.dart';
import 'collect_baki_bottom_sheet.dart';
import 'customer_detail_screen.dart';
import 'customers_notifier.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    // Rule #9: Debounce inputs for search queries
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(customersNotifierProvider.notifier).setSearchQuery(query);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(customersNotifierProvider.notifier).fetchCustomers();
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.cardBorderDark,
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersNotifierProvider);
    final filtered = state.filteredCustomers;
    final isListEmpty = state.customers.isEmpty;

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row (Rule #6: Hide top add button if list is empty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Directory',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Total: ${state.customers.length} Diners',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                  if (!isListEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.userPlus, color: AppColors.primary, size: 24),
                      onPressed: () => AddCustomerBottomSheet.show(context),
                      tooltip: 'Add Customer',
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Outstanding Baki Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.danger.withValues(alpha: 0.2),
                      AppColors.cardDark,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.wallet, color: AppColors.danger, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Total Baki Outstanding',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppFormatters.formatBdt(state.totalBakiOutstanding),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar with Debounce
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by customer name, phone, or hostel...',
                  hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondaryDark),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, color: AppColors.textSecondaryDark, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardDark,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Main Customer List, Shimmer Loading, or Empty State
              Expanded(
                child: state.isLoading
                    ? _buildShimmerLoader() // Rule #2: Skeleton / Shimmer loaders
                    : filtered.isEmpty
                        ? EmptyStateCard(
                            // Rule #6: Primary action directly inside empty state container
                            icon: LucideIcons.users,
                            title: state.searchQuery.isNotEmpty ? 'No Matching Customers' : 'No Customers Found',
                            description: state.searchQuery.isNotEmpty
                                ? 'No customer records match "${state.searchQuery}".'
                                : 'Add customer profiles to start recording meals and baki ledger.',
                            actionLabel: 'Add New Customer',
                            onActionPressed: () => AddCustomerBottomSheet.show(context),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final customer = filtered[idx];
                              final balance = customer.currentBalance;

                              return Dismissible(
                                // Rule #8: Swipeable row actions for item/entity list management
                                key: Key(customer.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(LucideIcons.trash2, color: Colors.white),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.cardDark,
                                          title: const Text('Delete Customer', style: TextStyle(color: Colors.white)),
                                          content: Text(
                                            'Are you sure you want to remove ${customer.name}?',
                                            style: const TextStyle(color: AppColors.textSecondaryDark),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) {
                                  ref
                                      .read(customersNotifierProvider.notifier)
                                      .deleteCustomer(customer.id);
                                },
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerDetailScreen(customer: customer),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
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
                                          radius: 22,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                          child: Text(
                                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Rule #7: Main title >= 16 bold
                                              Text(
                                                customer.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimaryDark,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                customer.institution ?? customer.phone ?? 'No phone',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondaryDark,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            // Rule #7: Secondary metadata >= 12-14
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
                                              onTap: () {
                                                CollectBakiBottomSheet.show(context, customer);
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
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
