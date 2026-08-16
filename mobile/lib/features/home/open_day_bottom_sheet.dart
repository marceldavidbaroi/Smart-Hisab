import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'business_day_notifier.dart';

class OpenDayBottomSheet extends ConsumerStatefulWidget {
  const OpenDayBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return CustomModalBottomSheet.show(
      context: context,
      title: "Start Today's Business Day",
      child: const OpenDayBottomSheet(),
    );
  }

  @override
  ConsumerState<OpenDayBottomSheet> createState() => _OpenDayBottomSheetState();
}

class _OpenDayBottomSheetState extends ConsumerState<OpenDayBottomSheet> {
  final _cashController = TextEditingController(text: '5000');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_cashController.text) ?? 0.0;
    if (amount < 0) return;

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(businessDayNotifierProvider.notifier)
        .startDay(amount);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cashController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            labelText: 'Opening Cash Balance (৳)',
            labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            hintText: 'Enter drawer cash e.g. 5000',
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
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
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
                  'Confirm & Start Day',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }
}
