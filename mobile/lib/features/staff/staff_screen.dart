import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/staff_member.dart';
import '../../core/widgets/app_safe_area.dart';
import 'add_staff_bottom_sheet.dart';
import 'staff_detail_screen.dart';
import 'staff_notifier.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffNotifierProvider.notifier).fetchStaff();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddStaffModal() {
    AddStaffBottomSheet.show(
      context,
      onAdd: ({
        required name,
        required phone,
        required role,
        required salaryType,
        required monthlySalary,
        pinCode,
      }) {
        ref.read(staffNotifierProvider.notifier).addStaff(
              name: name,
              phone: phone,
              role: role,
              salaryType: salaryType,
              monthlySalary: monthlySalary,
              pinCode: pinCode,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffNotifierProvider);
    final staffList = staffState.filteredStaffList;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: canPop
          ? AppBar(
              title: const Text('Staff Management / কর্মচারী'),
              elevation: 0,
            )
          : null,
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(staffNotifierProvider.notifier).fetchStaff();
          },
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Add Staff CTA
                if (!canPop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Staff Management', style: Theme.of(context).textTheme.titleLarge),
                      if (staffList.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _openAddStaffModal,
                          icon: const Icon(LucideIcons.userPlus, size: 16, color: Colors.white),
                          label: const Text('Add Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  )
                else if (staffList.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _openAddStaffModal,
                      icon: const Icon(LucideIcons.userPlus, size: 16, color: Colors.white),
                      label: const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                onChanged: (val) {
                  ref.read(staffNotifierProvider.notifier).setSearchQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Search staff by name or role...',
                  hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
                  prefixIcon: Icon(LucideIcons.search, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 18),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
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
              const SizedBox(height: 14),

              // Payroll Stats Overview Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Monthly Payroll', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text('৳${staffState.totalMonthlyPayroll.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    Column(
                      children: [
                        Text('Paid This Month', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                        const SizedBox(height: 2),
                        Text('৳${staffState.totalPaidPayrollThisMonth.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content List
              Expanded(
                child: staffState.isLoading
                    ? ListView.separated(
                        itemCount: 4,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) => Shimmer.fromColors(
                          baseColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                          highlightColor: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    : staffList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.users, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                const SizedBox(height: 12),
                                Text('No staff members found', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 16)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openAddStaffModal,
                                  icon: const Icon(LucideIcons.userPlus, size: 16, color: Colors.white),
                                  label: const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: staffList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final item = staffList[idx];

                              return Dismissible(
                                key: Key(item.id),
                                background: Container(
                                  color: AppColors.danger.withValues(alpha: 0.8),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(LucideIcons.trash2, color: Colors.white),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  ref.read(staffNotifierProvider.notifier).deleteStaff(item.id);
                                },
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StaffDetailScreen(staff: item),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                          child: const Icon(LucideIcons.userCheck, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      item.role.name.toUpperCase(),
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                    ),
                                                  ),
                                                  Text(
                                                    item.salaryType == SalaryType.daily
                                                        ? '৳${item.monthlySalary.toStringAsFixed(0)}/d'
                                                        : '৳${item.monthlySalary.toStringAsFixed(0)}/mo',
                                                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                                  ),
                                                  if (item.totalAdvanceThisMonth > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.warning.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Adv: ৳${item.totalAdvanceThisMonth.toStringAsFixed(0)}',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          size: 20,
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
      ),
    );
  }
}
