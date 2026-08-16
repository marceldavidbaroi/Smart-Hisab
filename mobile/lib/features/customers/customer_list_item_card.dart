import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/utils/formatters.dart';
import 'collect_baki_bottom_sheet.dart';
import 'customer_detail_screen.dart';

class CustomerListItemCard extends StatelessWidget {
  final Customer customer;

  const CustomerListItemCard({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = customer.currentBalance;

    return Dismissible(
      key: Key(customer.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collect Baki',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Icon(LucideIcons.banknote, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        CollectBakiBottomSheet.show(context, customer);
        return false; // Keep item in list after opening bottom sheet
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
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
            ),
          ),
          child: Row(
            children: [
              // Customer Avatar
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

              // Title and Metadata Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rule #7: Main title >= 16 bold
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.institution ?? customer.phone ?? 'No contact info',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Balance Display
              Text(
                AppFormatters.formatBdt(balance),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: balance > 0 ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
