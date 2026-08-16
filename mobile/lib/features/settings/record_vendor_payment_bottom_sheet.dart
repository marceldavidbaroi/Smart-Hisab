import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../cashbook/cashbook_notifier.dart';
import 'vendors_notifier.dart';

class RecordVendorPaymentBottomSheet extends ConsumerStatefulWidget {
  final Vendor vendor;

  const RecordVendorPaymentBottomSheet({
    super.key,
    required this.vendor,
  });

  static Future<void> show(BuildContext context, Vendor vendor) {
    return CustomModalBottomSheet.show(
      context: context,
      title: "Pay ${vendor.name}",
      child: RecordVendorPaymentBottomSheet(vendor: vendor),
    );
  }

  @override
  ConsumerState<RecordVendorPaymentBottomSheet> createState() =>
      _RecordVendorPaymentBottomSheetState();
}

class _RecordVendorPaymentBottomSheetState
    extends ConsumerState<RecordVendorPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAccountId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      NotificationService.showError("Enter a valid payment amount");
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(vendorsNotifierProvider.notifier)
        .recordVendorPayment(
          vendorId: widget.vendor.id,
          amount: amount,
          accountId: _selectedAccountId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        // Instantly refresh cashbook & canteen wallet balances
        ref.read(cashbookNotifierProvider.notifier).fetchAccountsAndEntries();

        Navigator.pop(context);
        NotificationService.showSuccess(
            "Payment of ৳${amount.toStringAsFixed(2)} recorded for ${widget.vendor.name}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final accounts = cashbookState.accounts;

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      final defaultAcc = accounts.firstWhere((a) => a.isDefault,
          orElse: () => accounts.first);
      _selectedAccountId = defaultAcc.id;
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Current Outstanding Due:",
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

          // Payment Amount
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: "Payment Amount *",
              labelStyle: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              prefixText: "৳ ",
              prefixStyle: const TextStyle(
                color: AppColors.success,
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
                return 'Enter payment amount';
              }
              final val = double.tryParse(value);
              if (val == null || val <= 0) {
                return 'Enter an amount greater than 0';
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
                        : (acc.accountType == 'bank'
                            ? LucideIcons.landmark
                            : LucideIcons.coins),
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
                  selectedColor: AppColors.success,
                  backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                  onSelected: (val) {
                    if (val) setState(() => _selectedAccountId = acc.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Notes / Reference Input
          TextFormField(
            controller: _notesController,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: "Notes / Voucher Ref (Optional)",
              hintText: "e.g. Cleared 2 sacks rice bill",
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
            onPressed: _isSubmitting ? null : _submitPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.checkCircle, color: Colors.white),
            label: Text(
              _isSubmitting ? 'Recording...' : 'Confirm Payment (পরিশোধ)',
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
