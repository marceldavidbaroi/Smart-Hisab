import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/staff_member.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class AddStaffBottomSheet extends StatefulWidget {
  final Function({
    required String name,
    required String phone,
    required StaffRole role,
    required SalaryType salaryType,
    required double monthlySalary,
    String? pinCode,
  }) onAdd;

  const AddStaffBottomSheet({
    super.key,
    required this.onAdd,
  });

  static void show(
    BuildContext context, {
    required Function({
      required String name,
      required String phone,
      required StaffRole role,
      required SalaryType salaryType,
      required double monthlySalary,
      String? pinCode,
    }) onAdd,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Add New Staff Member',
      child: AddStaffBottomSheet(onAdd: onAdd),
    );
  }

  @override
  State<AddStaffBottomSheet> createState() => _AddStaffBottomSheetState();
}

class _AddStaffBottomSheetState extends State<AddStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _pinController = TextEditingController();
  SalaryType _selectedSalaryType = SalaryType.monthly;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final salary = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    final pin = _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : null;

    widget.onAdd(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: StaffRole.staff,
      salaryType: _selectedSalaryType,
      monthlySalary: salary,
      pinCode: pin,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Full Name *',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter staff name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
            validator: (v) => (v == null || v.trim().length < 6) ? 'Please enter valid phone' : null,
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 14),

          TextFormField(
            controller: _salaryController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: _selectedSalaryType == SalaryType.daily ? 'Daily Wage Rate (৳/day)' : 'Monthly Salary (৳/month)',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: '4-Digit Counter Mode PIN (Optional)',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              counterText: '',
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
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Save Staff Member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
