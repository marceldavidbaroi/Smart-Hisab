import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import '../app_scaffold_notifier.dart';
import 'business_day_notifier.dart';
import 'close_day_bottom_sheet.dart';
import 'open_day_bottom_sheet.dart';
import 'widgets/active_day_stats_card.dart';
import 'widgets/quick_actions_grid.dart';

/// Tab 1: Home Dashboard Screen complying with v1.0 Roadmap & AGENTS.md constraints
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final businessDayState = ref.watch(businessDayNotifierProvider);

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

              // Business Day Banner Card
              if (businessDayState.isLoading)
                _buildShimmerLoader(context)
              else if (!isDayOpen || activeDay == null)
                _buildStartDayCard(context)
              else
                ActiveDayStatsCard(
                  day: activeDay,
                  onCloseDayPressed: () => CloseDayBottomSheet.show(context),
                ),

              const SizedBox(height: 16),

              // Total Outstanding Baki Card
              _buildBakiCard(
                context,
                totalBaki: activeDay?.totalBakiOutstanding ?? 45000.0,
              ),

              const SizedBox(height: 20),

              // Quick Actions Grid
              Text(
                'Quick Actions',
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
                  ref.read(scaffoldNotifierProvider.notifier).setTab(1); // Customers Tab
                },
                onAddExpense: () {
                  ref.read(scaffoldNotifierProvider.notifier).setTab(2); // Cashbook Tab
                },
                onDayNotes: () {
                  ref.read(scaffoldNotifierProvider.notifier).setTab(2); // Cashbook Tab
                },
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart-Hisab',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              canteenName,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
            ),
          ],
        ),
        // Day Open/Closed Status Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDayOpen
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDayOpen ? AppColors.primary : AppColors.warning,
            ),
          ),
          child: Text(
            isDayOpen ? '🟢 Day Open' : '🟡 Day Closed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDayOpen ? AppColors.primary : AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartDayCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.sun, size: 40, color: AppColors.warning),
          const SizedBox(height: 12),
          Text(
            "Start Today's Business Day",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set opening cash and begin recording meals & baki.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => OpenDayBottomSheet.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LucideIcons.playCircle, size: 20),
            label: const Text(
              'Start Business Day',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBakiCard(BuildContext context, {required double totalBaki}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  'Total Outstanding Baki',
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
