import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'meal_configs_notifier.dart';

class MealConfigFormBottomSheet extends ConsumerStatefulWidget {
  final MealConfig? mealConfig;

  const MealConfigFormBottomSheet({super.key, this.mealConfig});

  static void show(BuildContext context, {MealConfig? mealConfig}) {
    CustomModalBottomSheet.show(
      context: context,
      title: mealConfig == null ? 'Add Meal Rate Config' : 'Edit Meal Rate Config',
      child: MealConfigFormBottomSheet(mealConfig: mealConfig),
    );
  }

  @override
  ConsumerState<MealConfigFormBottomSheet> createState() => _MealConfigFormBottomSheetState();
}

class _MealConfigFormBottomSheetState extends ConsumerState<MealConfigFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rateController;
  late TextEditingController _noteController;
  DateTime _effectiveFrom = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.mealConfig != null ? widget.mealConfig!.rate.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: widget.mealConfig?.note ?? '');
    if (widget.mealConfig != null) {
      _effectiveFrom = widget.mealConfig!.effectiveFrom;
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _effectiveFrom = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate < 0) {
      NotificationService.showError('Please enter a valid price rate');
      return;
    }

    setState(() => _isSubmitting = true);

    final notifier = ref.read(mealConfigsNotifierProvider.notifier);
    bool success;

    final note = _noteController.text.trim();

    if (widget.mealConfig == null) {
      success = await notifier.addMealConfig(
        rate: rate,
        effectiveFrom: _effectiveFrom,
        note: note,
      );
    } else {
      success = await notifier.updateMealConfig(
        id: widget.mealConfig!.id,
        rate: rate,
        effectiveFrom: _effectiveFrom,
        note: note,
      );
    }

    setState(() => _isSubmitting = false);

    if (mounted && success) {
      Navigator.pop(context);
      NotificationService.showSuccess(
        widget.mealConfig == null ? 'Meal config added' : 'Meal config updated',
      );
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
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Meal Config Title',
              hintText: 'e.g. Regular Rate, Ramadan Rate',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Meal Price Rate (৳)',
              hintText: 'e.g. 80',
              prefixText: '৳ ',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Rate is required';
              final parsed = double.tryParse(v.trim());
              if (parsed == null || parsed < 0) return 'Enter a valid rate';
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Effective From Date',
                suffixIcon: Icon(Icons.calendar_today, size: 20),
              ),
              child: Text(
                '${_effectiveFrom.day}/${_effectiveFrom.month}/${_effectiveFrom.year}',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.mealConfig == null ? 'Add Rate Config' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

