import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../settings/meal_configs_notifier.dart';
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
  late Set<String> _selectedShifts;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedShifts = Set<String>.from(widget.customer.activeMeals);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Optimized API call: check if meal configs already loaded in memory/cache
      final currentConfigs = ref.read(mealConfigsNotifierProvider).mealConfigs;
      if (currentConfigs.isEmpty) {
        ref.read(mealConfigsNotifierProvider.notifier).fetchMealConfigs();
      }
    });
  }

  void _toggleShift(String shift) {
    setState(() {
      if (_selectedShifts.contains(shift)) {
        _selectedShifts.remove(shift);
      } else {
        _selectedShifts.add(shift);
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    // Single optimized update call: updates local Hive state & Supabase DB
    await ref.read(customersNotifierProvider.notifier).updateMealSubscription(
          customerId: widget.customer.id,
          subscribedShifts: _selectedShifts.toList(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedShifts.isEmpty
                ? 'Cleared meal subscription for ${widget.customer.name}'
                : 'Meal subscription set to ${_selectedShifts.join(', ')} for ${widget.customer.name}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final mealConfigsState = ref.watch(mealConfigsNotifierProvider);

    final availableShifts = mealConfigsState.mealConfigs.isNotEmpty
        ? mealConfigsState.mealConfigs
            .where((c) => c.shiftName != null && c.shiftName!.isNotEmpty)
            .map((c) => c.shiftName!)
            .toSet()
            .toList()
        : ['Breakfast', 'Lunch', 'Dinner'];

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle Bar (AGENTS.md Constraint #3)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.utensils, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal Subscriptions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select active meals for ${widget.customer.name}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // List of Meal Shifts to Select
          ...availableShifts.map((shift) {
            final isSelected = _selectedShifts.contains(shift);
            final config = mealConfigsState.mealConfigs.where((c) => c.shiftName == shift).firstOrNull;
            final rateText = config != null ? '৳${config.rate.toStringAsFixed(0)}/meal' : '';

            return InkWell(
              onTap: () => _toggleShift(shift),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Selection indicator icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white38 : Colors.black26),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),

                    // Meal name & status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelected ? 'Currently Selected' : 'Tap to select',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rate Badge
                    if (rateText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          rateText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Action shortcuts: Only One vs Clear
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_selectedShifts.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _selectedShifts.clear());
                  },
                  icon: const Icon(LucideIcons.xCircle, size: 15, color: AppColors.danger),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              else
                const SizedBox.shrink(),

              Text(
                _selectedShifts.isEmpty
                    ? 'No meal selected'
                    : '${_selectedShifts.length} meal${_selectedShifts.length > 1 ? 's' : ''} selected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Save Button
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save Subscription',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }
}
