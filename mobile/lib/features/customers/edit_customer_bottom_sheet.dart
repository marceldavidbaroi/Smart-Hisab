import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'customers_notifier.dart';

class EditCustomerBottomSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const EditCustomerBottomSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return CustomModalBottomSheet.show(
      context: context,
      title: 'Edit Customer',
      child: EditCustomerBottomSheet(customer: customer),
    );
  }

  @override
  ConsumerState<EditCustomerBottomSheet> createState() => _EditCustomerBottomSheetState();
}

class _EditCustomerBottomSheetState extends ConsumerState<EditCustomerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _institutionController;
  late final TextEditingController _addressController;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _institutionController = TextEditingController(text: widget.customer.institution ?? '');
    _addressController = TextEditingController(text: widget.customer.address ?? '');
    _isActive = widget.customer.isActive;
  }

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

    if (!_isActive && widget.customer.currentBalance > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Active debt exists (৳${widget.customer.currentBalance.toStringAsFixed(0)}). Settle balance before deactivating.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // If deactivating customer
    if (!_isActive && widget.customer.isActive) {
      final success = await ref.read(customersNotifierProvider.notifier).deleteCustomer(widget.customer.id);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deactivated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final err = ref.read(customersNotifierProvider).errorMessage ?? 'Failed to deactivate customer.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
      return;
    }

    final success = await ref.read(customersNotifierProvider.notifier).updateCustomer(
          customerId: widget.customer.id,
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
            content: Text('Customer updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final err = ref.read(customersNotifierProvider).errorMessage ?? 'Failed to update customer. Check phone number.';
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
    final hasDebt = widget.customer.currentBalance > 0;

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
            const SizedBox(height: 16),

            // Status Card & Debt Warning
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Customer Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            _isActive ? 'Customer can record meals and baki' : 'Customer profile is deactivated',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isActive,
                        activeTrackColor: AppColors.primary,
                        onChanged: hasDebt && _isActive
                            ? null
                            : (val) {
                                setState(() => _isActive = val);
                              },
                      ),
                    ],
                  ),
                  if (hasDebt) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Active debt exists (৳${widget.customer.currentBalance.toStringAsFixed(0)}). Settle balance before deactivating.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                            'Update Customer',
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
