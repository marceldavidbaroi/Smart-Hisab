import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_notifier.dart';
import '../../core/widgets/app_safe_area.dart';
import 'canteen_profile_screen.dart';
import 'invite_manager_screen.dart';
import 'my_profile_screen.dart';
import 'offline_storage_screen.dart';
import 'shifts_and_rates_screen.dart';
import 'vendors_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppSafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings & Config', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  // Canteen Profile Tile
                  _buildTile(
                    context,
                    title: 'Canteen Profile',
                    subtitle: 'Manage canteen name, tier status & profile',
                    icon: LucideIcons.store,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CanteenProfileScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Profile Header Tile
                  _buildTile(
                    context,
                    title: authState.userEmail ?? 'My Profile',
                    subtitle: 'Role: ${authState.role?.toUpperCase() ?? 'OWNER'} • ${authState.tenantName ?? 'Canteen'}',
                    icon: LucideIcons.user,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyProfileScreen()),
                      );
                    },
                  ),


                  const SizedBox(height: 12),

                  _buildTile(
                    context,
                    title: 'Invite Manager',
                    subtitle: 'Generate 6-digit join code for manager',
                    icon: LucideIcons.userPlus,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InviteManagerScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildTile(
                    context,
                    title: 'Shifts & Meal Configs',
                    subtitle: 'Breakfast, Lunch, Dinner timings & default rates',
                    icon: LucideIcons.clock,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShiftsAndRatesScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildTile(
                    context,
                    title: 'Vendors Ledger',
                    subtitle: 'Market suppliers & Bazar accounts payable',
                    icon: LucideIcons.truck,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VendorsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildTile(
                    context,
                    title: 'Offline Storage & Outbox',
                    subtitle: 'View pending offline sync queue',
                    icon: LucideIcons.database,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OfflineStorageScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Theme Toggle Switch Tile
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        themeMode == ThemeMode.dark ? 'Dark theme active' : 'Light theme active',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                      ),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(themeNotifierProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
        ),
        trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSecondaryDark, size: 20),
        onTap: onTap,
      ),
    );
  }
}
