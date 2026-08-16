import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../customers/collect_baki_bottom_sheet.dart';
import '../../customers/customers_notifier.dart';

class QuickCustomerPickerBottomSheet extends ConsumerStatefulWidget {
  const QuickCustomerPickerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return CustomModalBottomSheet.show(
      context: context,
      title: 'Select Customer for Baki Collection',
      child: const QuickCustomerPickerBottomSheet(),
    );
  }

  @override
  ConsumerState<QuickCustomerPickerBottomSheet> createState() =>
      _QuickCustomerPickerBottomSheetState();
}

class _QuickCustomerPickerBottomSheetState
    extends ConsumerState<QuickCustomerPickerBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredCustomers = customersState.customers.where((c) {
      final q = _searchQuery.toLowerCase();
      final phoneMatch = c.phone?.toLowerCase().contains(q) ?? false;
      return c.name.toLowerCase().contains(q) || phoneMatch;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search customer by name or phone...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Customer List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Text(
                      'No matching customers found.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                    ),
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final isDue = customer.currentBalance < 0;
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context); // Close picker modal
                          CollectBakiBottomSheet.show(context, customer);
                        },
                        leading: CircleAvatar(
                          backgroundColor: isDark
                              ? AppColors.surfaceDark
                              : AppColors.bgLight,
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 16, // AGENTS.md rule 7
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          customer.phone ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isDue ? 'Due (বাকি)' : 'Balance',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              AppFormatters.formatBdt(customer.currentBalance.abs()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDue ? AppColors.danger : AppColors.primary,
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
    );
  }
}
