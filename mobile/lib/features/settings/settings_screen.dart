import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/theme_notifier.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import 'canteen_profile_screen.dart';
import 'invite_manager_screen.dart';
import 'meal_configs_screen.dart';
import 'my_profile_screen.dart';
import 'shifts_screen.dart';
import 'vendors_screen.dart';

import 'switch_canteen_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    CustomModalBottomSheet.show(
      context: context,
      title: "Sign Out",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Are you sure you want to sign out of Smart-Hisab?",
            style: TextStyle(fontSize: 15, color: AppColors.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authNotifierProvider.notifier).signOut();
                    NotificationService.showSuccess("Signed out successfully");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

                  // Switch Canteen Tile
                  _buildTile(
                    context,
                    title: 'Switch Canteen',
                    subtitle: 'Switch active canteen or create/join another',
                    icon: LucideIcons.arrowLeftRight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SwitchCanteenScreen()),
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
                    title: 'Shifts Config',
                    subtitle: 'Operating time windows (Breakfast, Lunch, Dinner)',
                    icon: LucideIcons.clock,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShiftsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildTile(
                    context,
                    title: 'Meal Pricing & Rates',
                    subtitle: 'Per-shift meal prices & effective date history',
                    icon: LucideIcons.utensils,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MealConfigsScreen()),
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
                        themeMode == ThemeMode.dark ? 'Dark theme active' : 'Light theme (White) active',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
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

                  const SizedBox(height: 12),

                  // Sign Out Tile
                  _buildTile(
                    context,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your Smart-Hisab account',
                    icon: LucideIcons.logOut,
                    isDanger: true,
                    onTap: () => _showSignOutConfirmation(context, ref),
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
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDanger ? AppColors.danger : AppColors.primary;
    final titleColor = isDanger
        ? AppColors.danger
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger
              ? AppColors.danger.withValues(alpha: 0.3)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: isDanger ? AppColors.danger : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
