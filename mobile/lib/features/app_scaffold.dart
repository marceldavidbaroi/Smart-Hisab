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

/// 5-Tab Application Navigation Scaffold for Smart-Hisab
class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldState = ref.watch(scaffoldNotifierProvider);
    final scaffoldNotifier = ref.read(scaffoldNotifierProvider.notifier);

    const screens = [
      HomeScreen(),
      CustomersScreen(),
      CashbookScreen(),
      StaffScreen(),
      SettingsScreen(),
    ];

    final currentIndex = scaffoldState.selectedIndex.clamp(0, 4);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: currentIndex,
        onTabSelected: (index) => scaffoldNotifier.setTab(index),
      ),
    );
  }
}

