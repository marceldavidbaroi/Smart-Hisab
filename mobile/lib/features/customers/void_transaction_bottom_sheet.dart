import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'customers_notifier.dart';

class VoidTransactionBottomSheet extends ConsumerStatefulWidget {
  final Customer customer;
  final Map<String, dynamic> entry;

  const VoidTransactionBottomSheet({
    super.key,
    required this.customer,
    required this.entry,
  });

  /// Shows the void transaction bottom sheet adhering to AGENTS.md rules.
  /// Returns `true` if the transaction was successfully voided, `false` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required Customer customer,
    required Map<String, dynamic> entry,
  }) {
    return CustomModalBottomSheet.show<bool>(
      context: context,
      title: 'Void Transaction',
      child: VoidTransactionBottomSheet(customer: customer, entry: entry),
    );
  }

  @override
  ConsumerState<VoidTransactionBottomSheet> createState() => _VoidTransactionBottomSheetState();
}

class _VoidTransactionBottomSheetState extends ConsumerState<VoidTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _quickReasons = [
    'Wrong Customer',
    'Duplicate Entry',
    'Wrong Amount',
    'Customer Canceled',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleVoid() async {
    if (!_formKey.currentState!.validate()) return;

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final entryId = widget.entry['id'] as String;

      final success = await ref.read(customersNotifierProvider.notifier).voidWalletEntry(
            customerId: widget.customer.id,
            entryId: entryId,
            reason: reason,
          );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction successfully voided & reversal logged.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          setState(() => _errorMessage = 'Failed to void transaction. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPayment = widget.entry['type'] == 'payment';
    final isAdjustment = widget.entry['type'] == 'adjustment';
    final amount = (widget.entry['amount'] as num?)?.toDouble() ?? 0.0;
    final notes = widget.entry['notes'] as String? ?? (isPayment ? 'Baki Payment' : 'Meal Charge');
    final dateStr = widget.entry['created_at'] != null
        ? AppFormatters.formatDateTime(DateTime.parse(widget.entry['created_at'].toString()))
        : '';

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Transaction Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                    child: Icon(
                      isPayment
                          ? LucideIcons.arrowDownLeft
                          : (isAdjustment ? LucideIcons.plusCircle : LucideIcons.utensils),
                      color: isPayment ? AppColors.success : AppColors.danger,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notes,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isPayment ? '-' : '+'}${AppFormatters.formatBdt(amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPayment ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Warning Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Voiding will mark this entry as voided and log an opposing reversal entry to correct the balance.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Reason Preset Chips
            Text(
              'Select Quick Reason',
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
              children: _quickReasons.map((reason) {
                final isSelected = _reasonController.text == reason;
                return ActionChip(
                  label: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.cardDark : AppColors.cardLight),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  onPressed: () {
                    setState(() {
                      _reasonController.text = reason;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Mandatory Reason Input Field
            TextFormField(
              controller: _reasonController,
              autofocus: true,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                labelText: 'Reason for Cancellation *',
                hintText: 'Describe why this transaction is being cut...',
                prefixIcon: const Icon(LucideIcons.messageSquare, size: 18),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Cancellation reason is required to void transaction';
                }
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            // Action Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleVoid,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.trash2, size: 18, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Voiding Transaction...' : 'Confirm & Void Transaction',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
