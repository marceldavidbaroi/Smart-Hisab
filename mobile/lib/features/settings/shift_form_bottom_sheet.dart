import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'shifts_notifier.dart';

class ShiftFormBottomSheet extends ConsumerStatefulWidget {
  final CanteenShift? shift;

  const ShiftFormBottomSheet({super.key, this.shift});

  static void show(BuildContext context, {CanteenShift? shift}) {
    CustomModalBottomSheet.show(
      context: context,
      title: shift == null ? 'Add New Shift' : 'Edit Shift',
      child: ShiftFormBottomSheet(shift: shift),
    );
  }

  @override
  ConsumerState<ShiftFormBottomSheet> createState() => _ShiftFormBottomSheetState();
}

class _ShiftFormBottomSheetState extends ConsumerState<ShiftFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _overlapError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shift?.name ?? '');
    _startTimeController = TextEditingController(text: widget.shift?.startTime ?? '08:00 AM');
    _endTimeController = TextEditingController(text: widget.shift?.endTime ?? '10:00 AM');
    _isActive = widget.shift?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return 0;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _validateOverlap() {
    if (!_isActive) {
      setState(() => _overlapError = null);
      return;
    }

    final startMin = _parseTimeToMinutes(_startTimeController.text);
    final endMin = _parseTimeToMinutes(_endTimeController.text);

    if (startMin >= endMin) {
      setState(() => _overlapError = 'Start time must be earlier than end time');
      return;
    }

    final shiftsState = ref.read(shiftsNotifierProvider);
    String? conflictName;

    for (final s in shiftsState.shifts) {
      if (widget.shift != null && s.id == widget.shift!.id) continue;
      if (!s.isActive) continue;

      final sStart = _parseTimeToMinutes(s.startTime);
      final sEnd = _parseTimeToMinutes(s.endTime);

      if (startMin < sEnd && endMin > sStart) {
        conflictName = '${s.name} (${s.startTime} - ${s.endTime})';
        break;
      }
    }

    setState(() {
      _overlapError = conflictName != null ? 'Overlaps with $conflictName' : null;
    });
  }

  Future<void> _pickTime(TextEditingController controller, bool isStart) async {
    final currentMin = _parseTimeToMinutes(controller.text);
    final initialTod = TimeOfDay(hour: currentMin ~/ 60, minute: currentMin % 60);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTod,
    );

    if (picked != null) {
      controller.text = _formatTimeOfDay(picked);
      _validateOverlap();
    }
  }

  Future<void> _submit() async {
    _validateOverlap();
    if (!_formKey.currentState!.validate() || _overlapError != null) return;

    setState(() => _isSubmitting = true);

    final notifier = ref.read(shiftsNotifierProvider.notifier);
    bool success;

    if (widget.shift == null) {
      success = await notifier.addShift(
        name: _nameController.text.trim(),
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        isActive: _isActive,
      );
    } else {
      success = await notifier.updateShift(
        id: widget.shift!.id,
        name: _nameController.text.trim(),
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        isActive: _isActive,
      );
    }

    setState(() => _isSubmitting = false);

    if (mounted && success) {
      Navigator.pop(context);
      NotificationService.showSuccess(
        widget.shift == null ? 'Shift created successfully' : 'Shift updated successfully',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.flash_on, size: 14, color: AppColors.primary),
                  label: const Text('Preset: 6 AM - 12 PM (Morning)', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _nameController.text = 'Morning Shift';
                      _startTimeController.text = '06:00 AM';
                      _endTimeController.text = '12:00 PM';
                    });
                    _validateOverlap();
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.wb_sunny, size: 14, color: Colors.orange),
                  label: const Text('Preset: 12 PM - 4 PM (Lunch)', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _nameController.text = 'Lunch Shift';
                      _startTimeController.text = '12:00 PM';
                      _endTimeController.text = '04:00 PM';
                    });
                    _validateOverlap();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Shift Name',
              hintText: 'e.g. Morning Shift, Lunch, Dinner',
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Shift name is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_startTimeController, true),
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    suffixIcon: Icon(Icons.access_time, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endTimeController,
                  readOnly: true,
                  onTap: () => _pickTime(_endTimeController, false),
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    suffixIcon: Icon(Icons.access_time, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          if (_overlapError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _overlapError!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Active Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            subtitle: const Text('Allow attendance marking during this shift', style: TextStyle(fontSize: 12)),
            value: _isActive,
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _isActive = val);
              _validateOverlap();
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isSubmitting || _overlapError != null) ? null : _submit,
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
                    widget.shift == null ? 'Create Shift' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

