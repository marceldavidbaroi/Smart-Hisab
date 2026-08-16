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
  }

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
          content: Text('Updated active meals for ${widget.customer.name}'),
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
    final configuredMealConfigs = mealConfigsState.mealConfigs;

    final List<Map<String, dynamic>> mealList = configuredMealConfigs.isNotEmpty
        ? configuredMealConfigs.map((config) {
            final title = (config.note != null && config.note!.isNotEmpty)
                ? config.note!
                : (config.shiftName != null && config.shiftName!.isNotEmpty
                    ? config.shiftName!
                    : 'Rate Config (৳${config.rate.toStringAsFixed(0)})');

            final codeKey = (config.note != null && config.note!.isNotEmpty)
                ? config.note!
                : config.id;

            return {
              'name': title,
              'code': codeKey,
              'id': config.id,
              'icon': LucideIcons.utensils,
              'subtitle': '৳${config.rate.toStringAsFixed(0)} per meal',
            };
          }).toList()
        : [
            {'name': 'Morning Breakfast', 'code': 'Breakfast', 'id': 'b1', 'icon': LucideIcons.coffee, 'subtitle': '৳80 per meal'},
            {'name': 'Afternoon Lunch', 'code': 'Lunch', 'id': 'l1', 'icon': LucideIcons.utensils, 'subtitle': '৳120 per meal'},
            {'name': 'Evening Snacks', 'code': 'Snacks', 'id': 's1', 'icon': LucideIcons.cookie, 'subtitle': '৳40 per meal'},
            {'name': 'Night Dinner', 'code': 'Dinner', 'id': 'd1', 'icon': LucideIcons.moon, 'subtitle': '৳100 per meal'},
          ];

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 24 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // Rule #3
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle Bar (Rule #3)
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

              // Title Header
              Row(
                children: [
                  const Icon(LucideIcons.utensils, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Customer Meals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Select active meal configurations for ${widget.customer.name}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // Radio/Single-select List for Meal Configs (Customer can only have ONE active meal)
              if (mealList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No meal rates configured yet. Please configure meal rates in Settings.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...mealList.map((m) {
                  final code = m['code'] as String;
                  final id = m['id'] as String;
                  final name = m['name'] as String;
                  final subtitle = m['subtitle'] as String;
                  final icon = m['icon'] as IconData;

                  final isSelected = _selectedShifts.contains(code) || _selectedShifts.contains(id) || _selectedShifts.contains(name);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : (isDark ? AppColors.bgDark : AppColors.bgLight),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedShifts = {};
                          } else {
                            _selectedShifts = {code};
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? LucideIcons.disc : LucideIcons.circle,
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              icon,
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isSelected ? AppColors.success : (isDark ? AppColors.cardBorderDark : Colors.grey.shade300)).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isSelected ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.success : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        side: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
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
                          : const Text('Save Active Meals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
