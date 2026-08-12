import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isCounterMode;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isCounterMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCounterMode) {
      return NavigationBar(
        selectedIndex: selectedIndex.clamp(0, 2),
        onDestinationSelected: onTabSelected,
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
        ],
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTabSelected,
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
    );
  }
}
