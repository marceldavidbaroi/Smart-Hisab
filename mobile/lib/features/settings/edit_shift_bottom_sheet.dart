import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'shifts_notifier.dart';

class EditShiftBottomSheet extends ConsumerStatefulWidget {
  final CanteenShift shift;

  const EditShiftBottomSheet({super.key, required this.shift});

  static Future<void> show(BuildContext context, CanteenShift shift) {
    return CustomModalBottomSheet.show(
      context: context,
      title: 'Edit ${shift.name} Shift',
      child: EditShiftBottomSheet(shift: shift),
    );
  }

  @override
  ConsumerState<EditShiftBottomSheet> createState() => _EditShiftBottomSheetState();
}

class _EditShiftBottomSheetState extends ConsumerState<EditShiftBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _priceController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTimeController = TextEditingController(text: widget.shift.startTime);
    _endTimeController = TextEditingController(text: widget.shift.endTime);
    _priceController = TextEditingController(text: widget.shift.defaultPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    final success = await ref.read(shiftsNotifierProvider.notifier).updateShift(
          shiftId: widget.shift.id,
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          defaultPrice: price,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.shift.name} shift updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Start Time *',
                      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                      prefixIcon: const Icon(LucideIcons.clock, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.bgDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endTimeController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'End Time *',
                      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                      prefixIcon: const Icon(LucideIcons.clock, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.bgDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Meal Price Input
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Default Meal Price (৳) *',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                prefixIcon: const Icon(LucideIcons.banknote, color: AppColors.success),
                prefixText: '৳ ',
                prefixStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 18),
                filled: true,
                fillColor: AppColors.bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) {
                final p = double.tryParse(val ?? '');
                if (p == null || p <= 0) return 'Enter valid meal price';
                return null;
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorderDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
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
                            'Save Shift Rate',
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
