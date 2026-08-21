import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../app_scaffold_notifier.dart';
import '../../customers/add_customer_bottom_sheet.dart';
import '../../settings/meal_configs_screen.dart';
import '../../staff/staff_screen.dart';
import '../onboarding_progress_notifier.dart';
import '../open_day_bottom_sheet.dart';

/// Interactive First-Time Setup Checklist Card displayed on Home Screen
class OnboardingChecklistCard extends ConsumerWidget {
  const OnboardingChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final isBangla = locale.languageCode == 'bn';

    if (!onboardingState.shouldShow) return const SizedBox.shrink();

    final completedCount = onboardingState.completedCount;
    final totalCount = onboardingState.totalCount;
    final progress = onboardingState.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.rocket, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBangla ? 'শুরু করার চেকলিস্ট' : 'Getting Started Checklist',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isBangla
                                  ? '$completedCount/$totalCount সম্পন্ন'
                                  : '$completedCount/$totalCount done',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBangla
                            ? 'সহজে খাতা থেকে ডিজিটাল হিসাবে আসার ধাপগুলো'
                            : 'Simple steps to transition from paper khata',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Linear Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Step Items List
          ...onboardingState.steps.map((step) => _buildStepRow(context, ref, step, isDark, isBangla)),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context,
    WidgetRef ref,
    OnboardingStep step,
    bool isDark,
    bool isBangla,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Step status icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: step.isCompleted
                  ? AppColors.success.withValues(alpha: 0.15)
                  : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight).withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: step.isCompleted ? AppColors.success : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: step.isCompleted
                  ? const Icon(Icons.check, size: 16, color: AppColors.success)
                  : Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.getTitle(isBangla),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                    color: step.isCompleted
                        ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
                Text(
                  step.getDescription(isBangla),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Action Button if not completed
          if (!step.isCompleted) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _handleStepAction(context, ref, step.stepNumber),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isBangla ? 'করুন' : 'Set Up',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleStepAction(BuildContext context, WidgetRef ref, int stepNumber) {
    switch (stepNumber) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MealConfigsScreen()),
        );
        break;
      case 2:
        AddCustomerBottomSheet.show(context);
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StaffScreen()),
        );
        break;
      case 4:
        OpenDayBottomSheet.show(context);
        break;
      default:
        ref.read(scaffoldNotifierProvider.notifier).setTab(0);
    }
  }
}
