import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../settings/vendors_notifier.dart';
import 'cashbook_notifier.dart';

class AddExpenseBottomSheet extends ConsumerStatefulWidget {
  final Function({
    required String title,
    required String category,
    required double amount,
    String? accountId,
    String? vendorId,
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
      String? accountId,
      String? vendorId,
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
  ConsumerState<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends ConsumerState<AddExpenseBottomSheet> {
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

  String? _selectedAccountId;
  String? _selectedVendorId;
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
      accountId: _selectedAccountId,
      vendorId: _selectedVendorId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final vendorsState = ref.watch(vendorsNotifierProvider);

    final accounts = cashbookState.accounts;
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      final defaultAcc = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
      _selectedAccountId = defaultAcc.id;
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selector Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Expense Category',
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
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Title / Description (Optional)',
              hintText: 'e.g. Kawran bazar vegetables',
              hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
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

          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Amount *',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter expense amount';
              }
              final val = double.tryParse(value);
              if (val == null || val <= 0) {
                return 'Please enter a valid amount greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Paid From (Canteen Wallet) Selector
          if (accounts.isNotEmpty) ...[
            Text(
              'Paid From (Canteen Wallet) *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accounts.map((acc) {
                final isSelected = _selectedAccountId == acc.id;
                return ChoiceChip(
                  avatar: Icon(
                    acc.accountType == 'mobile_money'
                        ? LucideIcons.smartphone
                        : (acc.accountType == 'bank' ? LucideIcons.landmark : LucideIcons.coins),
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  label: Text(
                    acc.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.danger,
                  backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                  onSelected: (val) {
                    if (val) setState(() => _selectedAccountId = acc.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Optional Vendor / Supplier Link
          if (vendorsState.vendors.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              initialValue: _selectedVendorId,
              dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Link Supplier / Vendor (Optional)',
                labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                prefixIcon: const Icon(LucideIcons.store, size: 18),
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
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None (Direct cash / store expense)'),
                ),
                ...vendorsState.vendors.map((v) {
                  return DropdownMenuItem<String?>(
                    value: v.id,
                    child: Text(v.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() => _selectedVendorId = val);
              },
            ),
            const SizedBox(height: 14),
          ],

          // Notes / Reference Input
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Notes / Voucher Details (Optional)',
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
          const SizedBox(height: 20),

          // Submit Action Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
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
                    'Record Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
