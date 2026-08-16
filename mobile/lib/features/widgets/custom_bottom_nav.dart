import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTabSelected,
      backgroundColor: Theme.of(context).cardColor,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      elevation: 8,
      destinations: [
        NavigationDestination(
          icon: Icon(LucideIcons.home, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.home, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.users, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.users, color: AppColors.primary),
          label: 'Customers',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.wallet, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.wallet, color: AppColors.primary),
          label: 'Accounts',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.userCheck, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.userCheck, color: AppColors.primary),
          label: 'Staff',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.settings, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.settings, color: AppColors.primary),
          label: 'Settings',
        ),
      ],
    );
  }
}

