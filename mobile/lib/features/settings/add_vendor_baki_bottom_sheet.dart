import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'vendors_notifier.dart';

class AddVendorBakiBottomSheet extends ConsumerStatefulWidget {
  final Vendor vendor;

  const AddVendorBakiBottomSheet({
    super.key,
    required this.vendor,
  });

  static Future<void> show(BuildContext context, Vendor vendor) {
    return CustomModalBottomSheet.show(
      context: context,
      title: "Add Baki for ${vendor.name}",
      child: AddVendorBakiBottomSheet(vendor: vendor),
    );
  }

  @override
  ConsumerState<AddVendorBakiBottomSheet> createState() =>
      _AddVendorBakiBottomSheetState();
}

class _AddVendorBakiBottomSheetState extends ConsumerState<AddVendorBakiBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'market_cost';
  final List<Map<String, String>> _categories = [
    {'value': 'market_cost', 'label': 'Raw Groceries & Rice (কাঁচাবাজার/চাল)'},
    {'value': 'canteen_expense', 'label': 'LPG Gas & Utilities (গ্যাস/অন্যান্য)'},
    {'value': 'transport_labor', 'label': 'Transport & Labor (পরিবহন/কুলি)'},
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBaki() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      NotificationService.showError("Enter a valid purchase amount");
      return;
    }

    setState(() => _isSubmitting = true);

    final title = _titleController.text.trim().isEmpty
        ? 'Baki Purchase'
        : _titleController.text.trim();

    final success = await ref
        .read(vendorsNotifierProvider.notifier)
        .recordVendorBakiPurchase(
          vendorId: widget.vendor.id,
          amount: amount,
          category: _selectedCategory,
          title: title,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        NotificationService.showSuccess(
            "Baki purchase of ৳${amount.toStringAsFixed(2)} added for ${widget.vendor.name}");
      }
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Current Balance We Owe:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "৳${widget.vendor.currentBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Expense Category',
              labelStyle: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
            items: _categories.map((c) {
              return DropdownMenuItem<String>(
                value: c['value'],
                child: Text(c['label']!),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 14),

          // Title / Item Details
          TextFormField(
            controller: _titleController,
            style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Item / Description',
              hintText: 'e.g. 2 sacks miniket rice, mustard oil',
              prefixIcon: const Icon(LucideIcons.shoppingBag, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Purchase Amount
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Purchase Amount *',
              labelStyle: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              prefixText: '৳ ',
              prefixStyle: const TextStyle(
                color: AppColors.danger,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter purchase amount';
              }
              final val = double.tryParse(value);
              if (val == null || val <= 0) {
                return 'Enter an amount greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Memo / Voucher Notes
          TextFormField(
            controller: _notesController,
            style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Memo No. / Notes (Optional)',
              hintText: 'e.g. Voucher #4829',
              prefixIcon: const Icon(LucideIcons.fileText, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitBaki,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.plusCircle, color: Colors.white),
            label: Text(
              _isSubmitting ? 'Recording...' : 'Add Baki Purchase (বাকি ক্রয়)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
