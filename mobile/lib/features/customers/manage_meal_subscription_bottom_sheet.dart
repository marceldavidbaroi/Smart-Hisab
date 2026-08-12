import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import 'customers_notifier.dart';

class ManageMealSubscriptionBottomSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const ManageMealSubscriptionBottomSheet({
    super.key,
    required this.customer,
  });

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageMealSubscriptionBottomSheet(customer: customer),
    );
  }

  @override
  ConsumerState<ManageMealSubscriptionBottomSheet> createState() =>
      _ManageMealSubscriptionBottomSheetState();
}

class _ManageMealSubscriptionBottomSheetState
    extends ConsumerState<ManageMealSubscriptionBottomSheet> {
  final Set<String> _selectedShifts = {'Breakfast', 'Lunch', 'Dinner'};
  bool _isSaving = false;

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await ref.read(customersNotifierProvider.notifier).updateMealSubscription(
          customerId: widget.customer.id,
          subscribedShifts: _selectedShifts.toList(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated meal subscription for ${widget.customer.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shifts = [
      {'name': 'Morning Breakfast', 'code': 'Breakfast', 'icon': LucideIcons.coffee},
      {'name': 'Afternoon Lunch', 'code': 'Lunch', 'icon': LucideIcons.utensils},
      {'name': 'Evening Snacks', 'code': 'Snacks', 'icon': LucideIcons.cookie},
      {'name': 'Night Dinner', 'code': 'Dinner', 'icon': LucideIcons.moon},
    ];

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // Rule #3
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Bar (Rule #3)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              const Icon(LucideIcons.calendarCheck2, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Manage Meal Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          Text(
            'Select regular daily meal shifts for ${widget.customer.name}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Checkbox List for Shifts
          ...shifts.map((s) {
            final code = s['code'] as String;
            final name = s['name'] as String;
            final icon = s['icon'] as IconData;
            final isSelected = _selectedShifts.contains(code);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedShifts.add(code);
                    } else {
                      _selectedShifts.remove(code);
                    }
                  });
                },
                secondary: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
                title: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Action Buttons
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
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
