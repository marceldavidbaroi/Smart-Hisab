import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/staff_member.dart';
import '../../core/widgets/app_safe_area.dart';
import 'edit_staff_bottom_sheet.dart';
import 'record_salary_payout_bottom_sheet.dart';
import 'staff_notifier.dart';

class StaffDetailScreen extends ConsumerWidget {
  final StaffMember staff;

  const StaffDetailScreen({
    super.key,
    required this.staff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(staffNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find current updated staff object from provider state if updated
    final currentStaff = staffState.staffList.firstWhere(
      (s) => s.id == staff.id,
      orElse: () => staff,
    );

    final payouts = staffState.payoutsMap[currentStaff.id] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(currentStaff.name, style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.edit3, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, size: 20),
            onPressed: () => EditStaffBottomSheet.show(context, currentStaff),
          ),
        ],
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(staffNotifierProvider.notifier).fetchStaff(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
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
                          radius: 28,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStaff.name,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      currentStaff.role.name.toUpperCase(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  if (currentStaff.phone != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      currentStaff.phone!,
                                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStaff.salaryType == SalaryType.daily ? 'Daily Wage' : 'Monthly Salary',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            Text(
                              currentStaff.salaryType == SalaryType.daily
                                  ? '৳${currentStaff.monthlySalary.toStringAsFixed(0)}/d'
                                  : '৳${currentStaff.monthlySalary.toStringAsFixed(0)}/mo',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Advance Taken', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text(
                              '৳${currentStaff.totalAdvanceThisMonth.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentStaff.owesCanteen ? 'Staff Owes' : 'Net Due',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            Text(
                              currentStaff.owesCanteen
                                  ? '৳${currentStaff.owesCanteenAmount.toStringAsFixed(0)}'
                                  : '৳${currentStaff.netSalaryDue.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: currentStaff.owesCanteen ? AppColors.danger : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payout History & Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ElevatedButton.icon(
                    onPressed: () {
                      RecordSalaryPayoutBottomSheet.show(
                        context,
                        staff: currentStaff,
                        onConfirm: ({required staffId, required amount, required paymentMode, required payoutType, accountId, notes}) {
                          ref.read(staffNotifierProvider.notifier).recordSalaryPayout(
                                staffId: staffId,
                                amount: amount,
                                paymentMode: paymentMode,
                                payoutType: payoutType,
                                accountId: accountId,
                                notes: notes,
                              );
                        },
                      );
                    },
                    icon: const Icon(LucideIcons.dollarSign, size: 16, color: Colors.white),
                    label: const Text('Pay / Advance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: payouts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.receipt, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            const SizedBox(height: 12),
                            Text('No payouts recorded yet', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: payouts.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = payouts[idx];
                          final isAdv = item.isAdvance;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isAdv
                                      ? AppColors.warning.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(alpha: 0.15),
                                  child: Icon(
                                    isAdv ? Icons.handshake_rounded : LucideIcons.arrowUpRight,
                                    color: isAdv ? AppColors.warning : AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isAdv
                                                  ? AppColors.warning.withValues(alpha: 0.15)
                                                  : AppColors.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isAdv ? 'ADVANCE (অগ্রিম)' : 'SALARY',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isAdv ? AppColors.warning : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.paymentMode,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.notes != null) ...[
                                        const SizedBox(height: 2),
                                        Text(item.notes!, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '৳${item.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isAdv ? AppColors.warning : AppColors.primary,
                                    fontSize: 16,
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
    ),
    );
  }
}

