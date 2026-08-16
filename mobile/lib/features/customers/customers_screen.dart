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
import 'customer_list_item_card.dart';
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
    // Rule #4: Debounce inputs for search queries
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(customersNotifierProvider.notifier).setSearchQuery(query);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(customersNotifierProvider.notifier).fetchCustomers();
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      highlightColor: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row (Screen Map v1.0: Customers (count/limit) + [+ Add])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customers (${state.customers.length}/50)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                      ),
                      Text(
                        'Meal attendance & Baki ledger',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

              // Active Shift Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.utensils, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Active Shift: ${state.activeShiftName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${AppFormatters.formatBdt(state.activeShiftRate)}/meal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Outstanding Baki Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.danger.withValues(alpha: 0.15),
                      isDark ? AppColors.cardDark : AppColors.cardLight,
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
                    Row(
                      children: [
                        const Icon(LucideIcons.wallet, color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Total Outstanding Baki',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by customer name, phone, or hostel...',
                  hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
                  prefixIcon: Icon(LucideIcons.search, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Main Customer List, Shimmer Loading, or Empty State
              Expanded(
                child: state.isLoading
                    ? _buildShimmerLoader(context) // Rule #2: Skeleton / Shimmer loader
                    : filtered.isEmpty
                        ? EmptyStateCard(
                            // Rule #6: Primary action directly inside empty state container when empty
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
                              return CustomerListItemCard(
                                customer: customer,
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
