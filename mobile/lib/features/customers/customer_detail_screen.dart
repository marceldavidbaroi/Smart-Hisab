import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import 'customer_quick_action_grid.dart';
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
    if (!mounted) return;
    setState(() => _isLoadingEntries = true);

    if (SupabaseService.isInitialized) {
      try {
        final walletRes = await SupabaseService.client
            .from('customer_wallets')
            .select('id')
            .eq('customer_id', widget.customer.id)
            .maybeSingle();

        if (walletRes != null && walletRes['id'] != null) {
          final walletId = walletRes['id'] as String;
          final entriesRes = await SupabaseService.client
              .from('wallet_entries')
              .select('*')
              .eq('wallet_id', walletId)
              .order('created_at', ascending: false);

          if (mounted) {
            setState(() {
              _entries = List<Map<String, dynamic>>.from(entriesRes as List);
              _isLoadingEntries = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('_fetchLedgerEntries error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _entries = [];
        _isLoadingEntries = false;
      });
    }
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      highlightColor: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
      child: Column(
        children: List.generate(
          4,
          (index) => Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
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

              // Activity Header
              Text(
                'Transaction Ledger',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              // Activity Content List
              if (_isLoadingEntries)
                _buildShimmerLoading(context)
              else if (_entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Center(
                    child: Text(
                      'No transaction history recorded yet.',
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final entry = _entries[idx];
                    final isPayment = entry['type'] == 'payment';
                    final isAdjustment = entry['type'] == 'adjustment';
                    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
                    final notes = entry['notes'] as String? ?? (isPayment ? 'Baki Payment' : 'Meal Charge');
                    final dateStr = entry['created_at'] != null
                        ? AppFormatters.formatDateTime(DateTime.parse(entry['created_at'].toString()))
                        : '';

                    final iconColor = isPayment
                        ? AppColors.success
                        : (isAdjustment ? AppColors.warning : AppColors.danger);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: iconColor.withValues(alpha: 0.15),
                            child: Icon(
                              isPayment
                                  ? LucideIcons.arrowDownLeft
                                  : (isAdjustment ? LucideIcons.plusCircle : LucideIcons.utensils),
                              color: iconColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notes,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isPayment ? '-' : '+'}${AppFormatters.formatBdt(amount)}',
                            style: TextStyle(
                              fontSize: 14,
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
