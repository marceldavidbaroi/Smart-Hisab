import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import 'app_scaffold_notifier.dart';
import 'widgets/custom_bottom_nav.dart';
import 'home/home_screen.dart';
import 'customers/customers_screen.dart';
import 'cashbook/cashbook_screen.dart';
import 'staff/staff_screen.dart';
import 'settings/settings_screen.dart';

/// 5-Tab / 3-Tab Application Navigation Scaffold for Smart-Hisab Android
class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldState = ref.watch(scaffoldNotifierProvider);
    final scaffoldNotifier = ref.read(scaffoldNotifierProvider.notifier);

    final screens = [
      const HomeScreen(),
      const CustomersScreen(),
      const CashbookScreen(),
      if (!scaffoldState.isCounterMode) const StaffScreen(),
      if (!scaffoldState.isCounterMode) const SettingsScreen(),
    ];

    final currentIndex = scaffoldState.isCounterMode
        ? scaffoldState.selectedIndex.clamp(0, 2)
        : scaffoldState.selectedIndex;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: currentIndex,
        isCounterMode: scaffoldState.isCounterMode,
        onTabSelected: (index) => scaffoldNotifier.setTab(index),
      ),
    );
  }
}
