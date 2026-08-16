import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/utils/formatters.dart';
import 'customers_notifier.dart';

class AddManualBakiBottomSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const AddManualBakiBottomSheet({
    super.key,
    required this.customer,
  });

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddManualBakiBottomSheet(customer: customer),
    );
  }

  @override
  ConsumerState<AddManualBakiBottomSheet> createState() => _AddManualBakiBottomSheetState();
}

class _AddManualBakiBottomSheetState extends ConsumerState<AddManualBakiBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(customersNotifierProvider.notifier).addManualBaki(
          customerId: widget.customer.id,
          amount: amount,
          notes: _notesController.text.trim().isEmpty ? 'Manual Baki Entry' : _notesController.text.trim(),
          entryDate: _selectedDate,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${AppFormatters.formatBdt(amount)} manual baki to ${widget.customer.name}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final inputBgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // Rule #3
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle Bar (Rule #3: no X button)
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  const Icon(LucideIcons.plusCircle, color: AppColors.danger, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Add Manual Baki Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Customer: ${widget.customer.name}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Baki Amount (৳) *',
                  labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  hintText: 'e.g. 150',
                  hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.6) : AppColors.textSecondaryLight.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(LucideIcons.fileText, color: AppColors.danger),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter baki amount';
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Date Picker Field
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Entry Date',
                    labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    prefixIcon: const Icon(LucideIcons.calendar, color: AppColors.primary),
                    filled: true,
                    fillColor: inputBgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppFormatters.formatDateShort(_selectedDate),
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notes / Reason Field (Multiline Text Area)
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                minLines: 2,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Reason / Item Note (Optional)',
                  labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  hintText: 'e.g. Extra tea, Cigarettes, Guest Meal',
                  hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.6) : AppColors.textSecondaryLight.withValues(alpha: 0.6)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Icon(LucideIcons.tag, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add Baki Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
