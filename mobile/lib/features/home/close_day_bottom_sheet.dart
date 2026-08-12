import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'business_day_notifier.dart';

class CloseDayBottomSheet extends ConsumerStatefulWidget {
  const CloseDayBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return CustomModalBottomSheet.show(
      context: context,
      title: "End Business Day & Reconcile",
      child: const CloseDayBottomSheet(),
    );
  }

  @override
  ConsumerState<CloseDayBottomSheet> createState() => _CloseDayBottomSheetState();
}

class _CloseDayBottomSheetState extends ConsumerState<CloseDayBottomSheet> {
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final activeDay = ref.read(businessDayNotifierProvider).activeDay;
    if (activeDay != null) {
      final expected = activeDay.openingCash + activeDay.todayCash;
      _cashController.text = expected.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final closingCash = double.tryParse(_cashController.text) ?? 0.0;
    final notes = _notesController.text.trim();

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(businessDayNotifierProvider.notifier)
        .endDay(closingCash, notes);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDay = ref.watch(businessDayNotifierProvider).activeDay;
    final openingCash = activeDay?.openingCash ?? 0.0;
    final cashIn = activeDay?.todayCash ?? 0.0;
    final expectedCash = openingCash + cashIn;
    final actualClosing = double.tryParse(_cashController.text) ?? expectedCash;
    final variance = actualClosing - expectedCash;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expected Cash:',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                ),
                Text(
                  AppFormatters.formatBdt(expectedCash),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Actual Closing Cash in Drawer (৳)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Variance:',
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              ),
              Text(
                AppFormatters.formatBdt(variance),
                style: TextStyle(
                  color: variance >= 0 ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Day Notes / Variance Reason',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              hintText: 'e.g. Unrecorded tea expense ৳200',
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
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
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Confirm & Close Day',
                    style: TextStyle(
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
