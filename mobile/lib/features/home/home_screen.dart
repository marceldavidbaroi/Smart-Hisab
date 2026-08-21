import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/time_phase_helper.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/cloud_sync_indicator.dart';
import '../../l10n/generated/app_localizations.dart';
import '../app_scaffold_notifier.dart';
import '../cashbook/bazar_note_detail_screen.dart';
import '../cashbook/add_income_bottom_sheet.dart';
import '../cashbook/add_expense_bottom_sheet.dart';
import '../cashbook/cashbook_notifier.dart';
import 'business_day_notifier.dart';
import 'close_day_bottom_sheet.dart';
import 'widgets/active_day_stats_card.dart';
import 'widgets/dynamic_start_day_card.dart';
import 'widgets/live_activity_feed.dart';
import 'widgets/onboarding_checklist_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/quick_customer_picker_bottom_sheet.dart';
import 'widgets/yesterday_recap_card.dart';

/// Tab 1: Redesigned Zero-Friction Owner Home Dashboard Screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final businessDayState = ref.watch(businessDayNotifierProvider);
    final l10n = AppLocalizations.of(context);

    final canteenName = authState.tenantName ?? 'My Canteen';
    final activeDay = businessDayState.activeDay;
    final isDayOpen = businessDayState.isDayOpen;

    Future<void> handleRefresh() async {
      await ref.read(businessDayNotifierProvider.notifier).fetchActiveDay();
    }

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar Header
              _buildHeader(
                context,
                canteenName: canteenName,
                isDayOpen: isDayOpen,
              ),
              const SizedBox(height: 16),

              // Interactive First-Time Setup Checklist Card
              const OnboardingChecklistCard(),

              // Business Day Banner Card
              if (businessDayState.isLoading)
                _buildShimmerLoader(context)
              else if (!isDayOpen || activeDay == null) ...[
                const DynamicStartDayCard(),
                if (businessDayState.lastClosedDayRecap != null) ...[
                  const SizedBox(height: 16),
                  YesterdayRecapCard(recap: businessDayState.lastClosedDayRecap!),
                ],
              ] else
                ActiveDayStatsCard(
                  day: activeDay,
                  onCloseDayPressed: () => CloseDayBottomSheet.show(context),
                ),

              const SizedBox(height: 16),

              // Total Outstanding Baki Card
              _buildBakiCard(
                context,
                totalBaki: activeDay?.totalBakiOutstanding ?? 0.0,
              ),

              const SizedBox(height: 20),

              // Quick Actions Grid (Direct Modals)
              Text(
                l10n?.homeQuickActions ?? 'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // AGENTS.md rule 7
                    ),
              ),
              const SizedBox(height: 12),
              QuickActionsGrid(
                onMarkMeals: () {
                  ref.read(scaffoldNotifierProvider.notifier).setTab(1); // Customers Tab
                },
                onCollectBaki: () {
                  QuickCustomerPickerBottomSheet.show(context);
                },
                onAddIncome: () {
                  AddIncomeBottomSheet.show(
                    context,
                    onSubmit: ({
                      required String title,
                      required double amount,
                      String? accountId,
                      String? notes,
                    }) async {
                      ref.read(businessDayNotifierProvider.notifier).recordInflowOptimistic(amount);
                      await ref.read(cashbookNotifierProvider.notifier).recordMiscIncome(
                            title: title,
                            amount: amount,
                            accountId: accountId,
                            notes: notes,
                          );
                      ref.read(businessDayNotifierProvider.notifier).fetchActiveDay();
                    },
                  );
                },
                onAddExpense: () {
                  AddExpenseBottomSheet.show(
                    context,
                    onSubmit: ({
                      required String title,
                      required String category,
                      required double amount,
                      String? accountId,
                      String? vendorId,
                      String? notes,
                    }) async {
                      ref.read(businessDayNotifierProvider.notifier).recordOutflowOptimistic(amount);
                      await ref.read(cashbookNotifierProvider.notifier).addExpense(
                            title: title,
                            category: category,
                            amount: amount,
                            accountId: accountId,
                            vendorId: vendorId,
                            notes: notes,
                          );
                      ref.read(businessDayNotifierProvider.notifier).fetchActiveDay();
                    },
                  );
                },
                onDayNotes: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BazarNoteDetailScreen(),
                    ),
                  ).then((_) {
                    ref.read(businessDayNotifierProvider.notifier).fetchActiveDay();
                  });
                },
              ),

              const SizedBox(height: 20),

              // Live Activity Audit Feed
              LiveActivityFeed(
                activities: businessDayState.recentActivities,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String canteenName,
    required bool isDayOpen,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final phase = TimePhaseHelper.getPhase();
    final primaryAccent = TimePhaseHelper.getPrimaryAccent(phase);
    final isDaytime = TimePhaseHelper.isDaytime(phase);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n?.appName ?? 'Smart-Hisab',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isDaytime ? LucideIcons.sun : LucideIcons.moon,
                    size: 16,
                    color: primaryAccent,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                canteenName,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 14,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CloudSyncIndicator(
              isSynced: true,
              size: 16,
              showLabel: false,
            ),
            const SizedBox(width: 8),
            // Day Open/Closed Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDayOpen
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDayOpen ? AppColors.primary : AppColors.warning,
                ),
              ),
              child: Text(
                isDayOpen
                    ? (l10n?.homeDayOpen ?? '🟢 Day Open')
                    : (l10n?.homeDayClosed ?? '🟡 Day Closed'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDayOpen ? AppColors.primary : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBakiCard(BuildContext context, {required double totalBaki}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertCircle, color: AppColors.danger),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.homeTotalOutstandingBaki ?? 'Total Outstanding Customer Baki',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.formatBdt(totalBaki),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight,
      highlightColor: isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
