import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../l10n/generated/app_localizations.dart';
import 'business_day_notifier.dart';

class CloseDayBottomSheet extends ConsumerStatefulWidget {
  const CloseDayBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomModalBottomSheet.show(
      context: context,
      title: l10n?.homeCloseDayTitle ?? "End Business Day & Reconcile",
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
    final l10n = AppLocalizations.of(context);
    final openingCash = activeDay?.openingCash ?? 0.0;
    final cashIn = activeDay?.todayCash ?? 0.0;
    final expectedCash = openingCash + cashIn;
    final actualClosing = double.tryParse(_cashController.text) ?? expectedCash;
    final variance = actualClosing - expectedCash;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.homeExpectedCash ?? 'Expected Cash:',
                  style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
                ),
                Text(
                  AppFormatters.formatBdt(expectedCash),
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 18),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n?.homeActualClosingCash ?? 'Actual Closing Cash in Drawer (৳)',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              hintText: l10n?.homeClosingCashHint ?? 'Enter actual cash in drawer',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                variance > 0
                    ? (l10n?.homeCashSurplus ?? 'Cash Surplus (+):')
                    : variance < 0
                        ? (l10n?.homeCashShortage ?? 'Cash Shortage (-):')
                        : (l10n?.homeReconciliationBalanced ?? 'Balanced'),
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
              ),
              Text(
                AppFormatters.formatBdt(variance.abs()),
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
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n?.homeClosingNotesOptional ?? 'Closing Notes (Optional)',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              hintText: l10n?.homeClosingNotesHint ?? 'e.g. ৳200 short due to wrong change',
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
                : Text(
                    l10n?.homeCloseDayConfirm ?? 'Reconcile & Close Business Day',
                    style: const TextStyle(
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
