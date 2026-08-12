import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'customers/customers_screen.dart';
import 'cashbook/cashbook_screen.dart';
import 'staff/staff_screen.dart';
import 'settings/settings_screen.dart';

/// 5-Tab Application Navigation Scaffold for Smart-Hisab Android
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CustomersScreen(),
    CashbookScreen(),
    StaffScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.cardDark,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        elevation: 12,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home, color: AppColors.textSecondaryDark),
            selectedIcon: Icon(LucideIcons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.users, color: AppColors.textSecondaryDark),
            selectedIcon: Icon(LucideIcons.users, color: AppColors.primary),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.wallet, color: AppColors.textSecondaryDark),
            selectedIcon: Icon(LucideIcons.wallet, color: AppColors.primary),
            label: 'Cashbook',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.userCheck, color: AppColors.textSecondaryDark),
            selectedIcon: Icon(LucideIcons.userCheck, color: AppColors.primary),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings, color: AppColors.textSecondaryDark),
            selectedIcon: Icon(LucideIcons.settings, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
