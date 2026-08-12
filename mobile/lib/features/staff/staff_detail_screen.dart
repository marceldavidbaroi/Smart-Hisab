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
    // Find current updated staff object from provider state if updated
    final currentStaff = staffState.staffList.firstWhere(
      (s) => s.id == staff.id,
      orElse: () => staff,
    );

    final payouts = staffState.payoutsMap[currentStaff.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(currentStaff.name),
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: Colors.white, size: 20),
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
                          child: const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStaff.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.cardBorderDark, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Salary', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                            Text('৳${currentStaff.monthlySalary.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Paid This Month', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                            Text('৳${currentStaff.totalPaidThisMonth.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Unpaid Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                            Text('৳${currentStaff.unpaidBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: currentStaff.unpaidBalance > 0 ? AppColors.danger : AppColors.success,
                                )),
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
                  const Text('Payout History & Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ElevatedButton.icon(
                    onPressed: () {
                      RecordSalaryPayoutBottomSheet.show(
                        context,
                        staff: currentStaff,
                        onConfirm: ({required amount, required paymentMode, required staffId, notes}) {
                          ref.read(staffNotifierProvider.notifier).recordSalaryPayout(
                                staffId: staffId,
                                amount: amount,
                                paymentMode: paymentMode,
                                notes: notes,
                              );
                        },
                      );
                    },
                    icon: const Icon(LucideIcons.dollarSign, size: 16, color: Colors.white),
                    label: const Text('Pay Salary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
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
                            const Icon(LucideIcons.receipt, size: 48, color: AppColors.textSecondaryDark),
                            const SizedBox(height: 12),
                            const Text('No payouts recorded yet', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: payouts.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = payouts[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorderDark),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.bgDark,
                                  child: Icon(LucideIcons.arrowUpRight, color: AppColors.accent, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Payout (${item.paymentMode})',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                      if (item.notes != null)
                                        Text(item.notes!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '৳${item.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16),
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

