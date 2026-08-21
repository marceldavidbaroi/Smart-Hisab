import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'meal_config_form_bottom_sheet.dart';
import 'meal_configs_notifier.dart';

class MealConfigsScreen extends ConsumerStatefulWidget {
  const MealConfigsScreen({super.key});

  @override
  ConsumerState<MealConfigsScreen> createState() => _MealConfigsScreenState();
}

class _MealConfigsScreenState extends ConsumerState<MealConfigsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealConfigsNotifierProvider.notifier).fetchMealConfigs();
    });
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, MealConfig config) {
    final titleName = (config.note != null && config.note!.isNotEmpty)
        ? config.note!
        : (config.shiftName != null && config.shiftName!.isNotEmpty ? config.shiftName! : 'Rate Config');

    CustomModalBottomSheet.show(
      context: context,
      title: 'Delete Meal Rate Config',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Are you sure you want to delete rate "$titleName" (৳${config.rate.toStringAsFixed(0)})?',
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
                    await ref.read(mealConfigsNotifierProvider.notifier).deleteMealConfig(config.id);
                    NotificationService.showSuccess('Meal rate config deleted');
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
  Widget build(BuildContext context) {
    final state = ref.watch(mealConfigsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Pricing & Rates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (state.mealConfigs.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
              tooltip: 'Add Rate Config',
              onPressed: () => MealConfigFormBottomSheet.show(context),
            ),
        ],
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(mealConfigsNotifierProvider.notifier).fetchMealConfigs(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal Price Rates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure meal prices and effective dates for customer meal calculations.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (state.isLoading)
                  const Expanded(child: ShimmerListLoader(itemCount: 3))
                else if (state.mealConfigs.isEmpty)
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
                            const Icon(LucideIcons.banknote, size: 48, color: AppColors.textSecondaryLight),
                            const SizedBox(height: 12),
                            const Text(
                              'No Meal Rates Configured',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add meal price rates to calculate customer wallet charges automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => MealConfigFormBottomSheet.show(context),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Add Meal Rate'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.mealConfigs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final config = state.mealConfigs[index];
                        final dateStr =
                            '${config.effectiveFrom.day}/${config.effectiveFrom.month}/${config.effectiveFrom.year}';

                        final title = (config.note != null && config.note!.isNotEmpty)
                            ? config.note!
                            : (config.shiftName != null && config.shiftName!.isNotEmpty
                                ? config.shiftName!
                                : 'Standard Meal Rate');

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
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.utensils, color: AppColors.success),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Effective from: $dateStr',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '৳${config.rate.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(LucideIcons.edit2, size: 18, color: AppColors.primary),
                                  onPressed: () => MealConfigFormBottomSheet.show(context, mealConfig: config),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                                  onPressed: () => _showDeleteConfirmation(context, ref, config),
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

