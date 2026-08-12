import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class AddExpenseBottomSheet extends StatefulWidget {
  final Function({
    required String title,
    required String category,
    required double amount,
    String? notes,
  }) onSubmit;

  const AddExpenseBottomSheet({
    super.key,
    required this.onSubmit,
  });

  static void show(
    BuildContext context, {
    required Function({
      required String title,
      required String category,
      required double amount,
      String? notes,
    }) onSubmit,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Record Market Expense',
      child: AddExpenseBottomSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Market Expense';
  final List<String> _categories = [
    'Market Expense',
    'Vegetables & Grocery',
    'Meat & Fish',
    'LPG Gas & Fuel',
    'Utilities & Tea',
    'Transport & Labor',
    'Other Expense',
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final title = _titleController.text.trim().isEmpty
        ? _selectedCategory
        : _titleController.text.trim();

    widget.onSubmit(
      title: title,
      category: _selectedCategory,
      amount: amount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selector Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Expense Category',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            items: _categories.map((cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCategory = val);
              }
            },
          ),
          const SizedBox(height: 14),

          // Expense Title / Description
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Title / Description (Optional)',
              hintText: 'e.g. Kawran bazar vegetables',
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Amount (৳) *',
              hintText: '0.00',
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              prefixText: '৳ ',
              prefixStyle: const TextStyle(
                color: AppColors.danger,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter expense amount';
              }
              final numVal = double.tryParse(val);
              if (numVal == null || numVal <= 0) {
                return 'Enter a valid positive amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Notes Input
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Notes / Voucher Info (Optional)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save Expense Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Expense Entry',
                    style: TextStyle(
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
