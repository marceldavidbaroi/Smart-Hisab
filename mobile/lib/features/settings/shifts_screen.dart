import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'shift_form_bottom_sheet.dart';
import 'shift_timeline_view.dart';
import 'shifts_notifier.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, CanteenShift shift) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Delete Shift',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Are you sure you want to delete "${shift.name}"?',
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(shiftsNotifierProvider.notifier).deleteShift(shift.id);
                    NotificationService.showSuccess('Shift deleted successfully');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsState = ref.watch(shiftsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shifts Config', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
            tooltip: 'Add Shift',
            onPressed: () => ShiftFormBottomSheet.show(context),
          ),
        ],
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(shiftsNotifierProvider.notifier).fetchShifts(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operating Shifts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure daily meal operating windows (Breakfast, Lunch, Dinner, etc.).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ShiftTimelineView(shifts: shiftsState.shifts),
                const SizedBox(height: 20),
                if (shiftsState.isLoading)
                  const Expanded(child: ShimmerListLoader(itemCount: 3))
                else if (shiftsState.shifts.isEmpty)
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.clock, size: 48, color: AppColors.textSecondaryLight),
                            const SizedBox(height: 12),
                            const Text(
                              'No Shifts Configured',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create operating shifts for your canteen to mark attendance.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await ref.read(shiftsNotifierProvider.notifier).apply4ShiftPreset();
                                    NotificationService.showSuccess('Applied 4-Shift Preset!');
                                  },
                                  icon: const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primary),
                                  label: const Text('Apply 4-Shift Preset'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => ShiftFormBottomSheet.show(context),
                                  icon: const Icon(LucideIcons.plus, size: 16),
                                  label: const Text('Custom Shift'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: shiftsState.shifts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final shift = shiftsState.shifts[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: shift.isActive
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.clock,
                                color: shift.isActive ? AppColors.primary : Colors.grey,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  shift.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: shift.isActive
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    shift.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: shift.isActive ? AppColors.success : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${shift.startTime} - ${shift.endTime}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.edit2, size: 18, color: AppColors.primary),
                                  onPressed: () => ShiftFormBottomSheet.show(context, shift: shift),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                                  onPressed: () => _showDeleteConfirmation(context, ref, shift),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
