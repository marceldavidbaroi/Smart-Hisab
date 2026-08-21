import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

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
          label: l10n?.navHome ?? 'Home',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.users, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.users, color: AppColors.primary),
          label: l10n?.navCustomers ?? 'Customers',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.wallet, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.wallet, color: AppColors.primary),
          label: l10n?.navCashbook ?? 'Cashbook',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.userCheck, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.userCheck, color: AppColors.primary),
          label: l10n?.navStaff ?? 'Staff',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.settings, color: inactiveColor),
          selectedIcon: const Icon(LucideIcons.settings, color: AppColors.primary),
          label: l10n?.navSettings ?? 'Settings',
        ),
      ],
    );
  }
}

