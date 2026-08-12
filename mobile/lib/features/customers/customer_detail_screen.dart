import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import 'collect_baki_bottom_sheet.dart';
import 'customers_notifier.dart';
import 'edit_customer_bottom_sheet.dart';


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
    _fetchLedgerEntries();
  }

  Future<void> _fetchLedgerEntries() async {
    setState(() => _isLoadingEntries = true);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('wallet_entries')
            .select('*, customer_wallets!inner(customer_id)')
            .eq('customer_wallets.customer_id', widget.customer.id)
            .order('created_at', ascending: false)
            .limit(50) as List<dynamic>;

        if (mounted) {
          setState(() {
            _entries = res.cast<Map<String, dynamic>>();
            _isLoadingEntries = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching customer ledger entries: $e');
    }

    // Mock fallback ledger entries
    if (mounted) {
      setState(() {
        _entries = [
          {
            'id': 'ent-1',
            'type': 'payment',
            'amount': 200.0,
            'notes': 'Cash payment received',
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          },
          {
            'id': 'ent-2',
            'type': 'meal_charge',
            'amount': 150.0,
            'notes': 'Lunch Meal',
            'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
          },
          {
            'id': 'ent-3',
            'type': 'meal_charge',
            'amount': 100.0,
            'notes': 'Breakfast Meal',
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          },
        ];
        _isLoadingEntries = false;
      });
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.cardBorderDark,
      child: Column(
        children: List.generate(
          5,
          (index) => Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch customer state for real-time updated balance
    final customersState = ref.watch(customersNotifierProvider);
    final activeCustomer = customersState.customers.firstWhere(
      (c) => c.id == widget.customer.id,
      orElse: () => widget.customer,
    );

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          activeCustomer.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: Colors.white, size: 20),
            onPressed: () => EditCustomerBottomSheet.show(context, activeCustomer),
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
              // Customer Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            activeCustomer.name.isNotEmpty ? activeCustomer.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCustomer.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              if (activeCustomer.phone != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.phone, size: 14, color: AppColors.textSecondaryDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      activeCustomer.phone!,
                                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
                                    ),
                                  ],
                                ),
                              ],
                              if (activeCustomer.institution != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.building, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      activeCustomer.institution!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.cardBorderDark),
                    // Wallet Balance Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Outstanding Baki',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
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
                        ElevatedButton.icon(
                          onPressed: () {
                            CollectBakiBottomSheet.show(context, activeCustomer);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.banknote, color: Colors.white, size: 18),
                          label: const Text(
                            'Collect Baki',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ledger Section Title
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
              ),
              const SizedBox(height: 12),

              // Ledger List or Loading Shimmer
              if (_isLoadingEntries)
                _buildShimmerLoading()
              else if (_entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No transaction history available.',
                      style: TextStyle(color: AppColors.textSecondaryDark),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final entry = _entries[idx];
                    final isPayment = entry['type'] == 'payment';
                    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
                    final notes = entry['notes'] as String? ?? (isPayment ? 'Baki Payment' : 'Meal Charge');
                    final dateStr = entry['created_at'] != null
                        ? AppFormatters.formatDateTime(DateTime.parse(entry['created_at'].toString()))
                        : '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (isPayment ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
                            child: Icon(
                              isPayment ? LucideIcons.arrowDownLeft : LucideIcons.utensils,
                              color: isPayment ? AppColors.success : AppColors.danger,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notes,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isPayment ? '-' : '+'}${AppFormatters.formatBdt(amount)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isPayment ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
