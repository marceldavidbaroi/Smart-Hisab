import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

/// Clean Canteen Selection screen presented exclusively during the Login Flow.
/// Allows the user to tap their desired canteen to enter the dashboard.
/// Contains no management controls (delete/leave/create/join).
class LoginSelectCanteenScreen extends ConsumerWidget {
  const LoginSelectCanteenScreen({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final canteens = authState.availableTenants;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Canteen',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => _showSignOutConfirmation(context, ref),
          ),
        ],
      ),
      body: AppSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.store, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Canteens',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select a canteen to open its dashboard:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Canteen Selection List
              Expanded(
                child: canteens.isEmpty
                    ? Center(
                        child: Text(
                          'No canteens available for your account.',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: canteens.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = canteens[index];
                          final isOwner = item.role.toLowerCase() == 'owner';
                          final isCurrentActive = item.tenantId == authState.tenantId;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrentActive
                                    ? AppColors.primary
                                    : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                                width: isCurrentActive ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isOwner ? AppColors.primary : AppColors.accent).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isOwner ? LucideIcons.building : LucideIcons.userCheck,
                                  color: isOwner ? AppColors.primary : AppColors.accent,
                                ),
                              ),
                              title: Text(
                                item.tenantName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isOwner ? AppColors.primary : AppColors.accent).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isOwner ? AppColors.primary : AppColors.accent,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentActive) ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        '• Active',
                                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: const Icon(LucideIcons.chevronRight, size: 20),
                              onTap: () async {
                                await ref.read(authNotifierProvider.notifier).setActiveTenant(
                                      tenantId: item.tenantId,
                                      tenantName: item.tenantName,
                                      role: item.role,
                                    );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
