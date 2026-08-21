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
import 'switch_canteen_screen.dart';
import 'vendors_screen.dart';

import '../../core/localization/locale_notifier.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    CustomModalBottomSheet.show(
      context: context,
      title: l10n?.settingsSignOut ?? "Sign Out",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.settingsSignOutConfirm ?? "Are you sure you want to sign out of Smart-Hisab?",
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondaryDark),
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
                  child: Text(l10n?.commonCancel ?? 'Cancel'),
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
                  child: Text(
                    l10n?.settingsSignOut ?? 'Sign Out',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
    final locale = ref.watch(localeNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final canteenName = authState.tenantName ?? 'My Canteen';
    final role = authState.role?.toUpperCase() ?? 'OWNER';
    final email = authState.userEmail ?? 'No email';

    return AppSafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            Text(
              l10n?.settingsTitle ?? 'Settings & Config',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 16),

            // Top Profile / Active Canteen Banner Card
            _buildProfileBanner(
              context,
              canteenName: canteenName,
              role: role,
              email: email,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Section Title
            Text(
              l10n?.settingsManagementSection ?? 'Management & Operations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),

            // 2-Column Grid Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGridCard(
                  context,
                  title: l10n?.settingsCanteenProfile ?? 'Canteen Profile',
                  subtitle: l10n?.settingsCanteenProfileSub ?? 'Name & tier info',
                  icon: LucideIcons.store,
                  iconColor: const Color(0xFF10B981), // Emerald
                  bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CanteenProfileScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  context,
                  title: l10n?.settingsSwitchCanteen ?? 'Switch Canteen',
                  subtitle: l10n?.settingsSwitchCanteenSub ?? 'Change active shop',
                  icon: LucideIcons.arrowLeftRight,
                  iconColor: const Color(0xFF3B82F6), // Blue
                  bgColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SwitchCanteenScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  context,
                  title: l10n?.settingsShiftsConfig ?? 'Shifts Config',
                  subtitle: l10n?.settingsShiftsConfigSub ?? 'Operating hours',
                  icon: LucideIcons.clock,
                  iconColor: const Color(0xFFF59E0B), // Amber
                  bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShiftsScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  context,
                  title: l10n?.settingsMealRates ?? 'Meal Rates',
                  subtitle: l10n?.settingsMealRatesSub ?? 'Pricing & history',
                  icon: LucideIcons.utensils,
                  iconColor: const Color(0xFF059669), // Dark Emerald
                  bgColor: const Color(0xFF059669).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MealConfigsScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  context,
                  title: l10n?.settingsVendorsLedger ?? 'Vendors Ledger',
                  subtitle: l10n?.settingsVendorsLedgerSub ?? 'Suppliers & baki',
                  icon: LucideIcons.truck,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  bgColor: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VendorsScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  context,
                  title: l10n?.settingsInviteManager ?? 'Invite Manager',
                  subtitle: l10n?.settingsInviteManagerSub ?? '6-digit join code',
                  icon: LucideIcons.userPlus,
                  iconColor: const Color(0xFF8B5CF6), // Purple
                  bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InviteManagerScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  context,
                  title: l10n?.settingsLanguage ?? 'Language',
                  subtitle: locale.languageCode == 'bn' ? 'বাংলা (Active)' : 'English (Active)',
                  icon: LucideIcons.globe,
                  iconColor: const Color(0xFF0284C7), // Sky
                  bgColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  isDark: isDark,
                  onTap: () {
                    ref.read(localeNotifierProvider.notifier).toggleLocale();
                  },
                ),
                _buildGridCard(
                  context,
                  title: isDark
                      ? (l10n?.settingsLightMode ?? 'Light Theme')
                      : (l10n?.settingsDarkMode ?? 'Dark Theme'),
                  subtitle: isDark ? 'Switch to Light' : 'Switch to Dark',
                  icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                  iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFF818CF8),
                  bgColor: (isDark ? const Color(0xFFFBBF24) : const Color(0xFF818CF8))
                      .withValues(alpha: 0.12),
                  isDark: isDark,
                  trailingWidget: Switch(
                    value: themeMode == ThemeMode.dark,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(themeNotifierProvider.notifier).toggleTheme();
                    },
                  ),
                  onTap: () {
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sign Out Row Card
            InkWell(
              onTap: () => _showSignOutConfirmation(context, ref),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: isDark ? 0.35 : 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.logOut,
                        size: 20,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.settingsSignOut ?? 'Sign Out',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n?.settingsSignOutSub ?? 'Sign out of your Smart-Hisab account',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBanner(
    BuildContext context, {
    required String canteenName,
    required String role,
    required String email,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyProfileScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.store,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            canteenName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isDark
                    ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailingWidget,
  }) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                  if (trailingWidget != null)
                    trailingWidget
                  else
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                          : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

