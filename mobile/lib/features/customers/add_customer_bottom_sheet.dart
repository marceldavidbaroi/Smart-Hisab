import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'customers_notifier.dart';

class AddCustomerBottomSheet extends ConsumerStatefulWidget {
  const AddCustomerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return CustomModalBottomSheet.show(
      context: context,
      title: 'Add New Customer',
      child: const AddCustomerBottomSheet(),
    );
  }

  @override
  ConsumerState<AddCustomerBottomSheet> createState() => _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState extends ConsumerState<AddCustomerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(customersNotifierProvider.notifier).addCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          institution: _institutionController.text.trim().isEmpty
              ? null
              : _institutionController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final err = ref.read(customersNotifierProvider).errorMessage ?? 'Failed to add customer. Check phone number.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.danger,
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
                labelText: 'Customer Name *',
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
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
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
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Institution Input
            TextFormField(
              controller: _institutionController,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Institution / Hostel (Optional)',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                prefixIcon: Icon(LucideIcons.building, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
            const SizedBox(height: 12),

            // Address Input
            TextFormField(
              controller: _addressController,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Address (Optional)',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                prefixIcon: Icon(LucideIcons.mapPin, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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

            // Action buttons
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
                            'Save Customer',
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
