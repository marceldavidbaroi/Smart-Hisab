import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/staff_member.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'staff_notifier.dart';

class EditStaffBottomSheet extends ConsumerStatefulWidget {
  final StaffMember staff;

  const EditStaffBottomSheet({super.key, required this.staff});

  static Future<void> show(BuildContext context, StaffMember staff) {
    return CustomModalBottomSheet.show(
      context: context,
      title: 'Edit Staff Member',
      child: EditStaffBottomSheet(staff: staff),
    );
  }

  @override
  ConsumerState<EditStaffBottomSheet> createState() => _EditStaffBottomSheetState();
}

class _EditStaffBottomSheetState extends ConsumerState<EditStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _salaryController;
  late StaffRole _selectedRole;
  late SalaryType _selectedSalaryType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _phoneController = TextEditingController(text: widget.staff.phone ?? '');
    _salaryController = TextEditingController(text: widget.staff.monthlySalary.toStringAsFixed(0));
    _selectedRole = widget.staff.role;
    _selectedSalaryType = widget.staff.salaryType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final salary = double.tryParse(_salaryController.text.trim()) ?? 0.0;

    final success = await ref.read(staffNotifierProvider.notifier).updateStaff(
          staffId: widget.staff.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          salaryType: _selectedSalaryType,
          monthlySalary: salary,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff details updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name Input
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Full Name *',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                prefixIcon: const Icon(LucideIcons.user, color: AppColors.primary),
                filled: true,
                fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter staff name' : null,
            ),
            const SizedBox(height: 12),

            // Phone Input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                prefixIcon: const Icon(LucideIcons.phone, color: AppColors.primary),
                filled: true,
                fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 12),

            // Payment Frequency / Salary Type Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Frequency *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedSalaryType = SalaryType.monthly),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSalaryType == SalaryType.monthly
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark ? AppColors.bgDark : AppColors.bgLight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSalaryType == SalaryType.monthly
                                  ? AppColors.primary
                                  : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                              width: _selectedSalaryType == SalaryType.monthly ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: _selectedSalaryType == SalaryType.monthly ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Monthly Salary',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSalaryType == SalaryType.monthly ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedSalaryType = SalaryType.daily),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSalaryType == SalaryType.daily
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark ? AppColors.bgDark : AppColors.bgLight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSalaryType == SalaryType.daily
                                  ? AppColors.primary
                                  : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                              width: _selectedSalaryType == SalaryType.daily ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.today_rounded,
                                size: 16,
                                color: _selectedSalaryType == SalaryType.daily ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Daily Wage (হাজিরা)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSalaryType == SalaryType.daily ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Salary Input
            TextFormField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: _selectedSalaryType == SalaryType.daily ? 'Daily Wage Rate (৳/day)' : 'Monthly Base Salary (৳/month)',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                prefixIcon: const Icon(LucideIcons.banknote, color: AppColors.success),
                filled: true,
                fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
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
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Update Staff',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
