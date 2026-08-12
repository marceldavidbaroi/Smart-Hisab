import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../settings/widgets/canteen_action_sheets.dart';
import 'create_canteen_screen.dart';
import 'join_canteen_screen.dart';

/// Screen displayed after login when a user belongs to multiple canteens.
class SelectCanteenScreen extends ConsumerWidget {
  const SelectCanteenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final canteens = authState.availableTenants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Canteen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 20),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: AppSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
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

              // Canteen List
              Expanded(
                child: canteens.isEmpty
                    ? Center(
                        child: Text(
                          'No canteens found. Create or join one below.',
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOwner ? AppColors.primary : AppColors.accent,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentActive) ...[
                                      const SizedBox(width: 8),
                                      const Text('• Active', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isOwner ? LucideIcons.trash2 : LucideIcons.logOut,
                                      size: 18,
                                      color: isOwner ? AppColors.danger : AppColors.warning,
                                    ),
                                    tooltip: isOwner ? 'Delete Canteen' : 'Leave Canteen',
                                    onPressed: () {
                                      if (isOwner) {
                                        CanteenActionSheets.showDeleteCanteen(
                                          context: context,
                                          ref: ref,
                                          tenantId: item.tenantId,
                                          canteenName: item.tenantName,
                                        );
                                      } else {
                                        CanteenActionSheets.showLeaveCanteen(
                                          context: context,
                                          ref: ref,
                                          tenantId: item.tenantId,
                                          canteenName: item.tenantName,
                                        );
                                      }
                                    },
                                  ),
                                  const Icon(LucideIcons.chevronRight, size: 20),
                                ],
                              ),
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

              const SizedBox(height: 16),

              // Action Options: Create / Join
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateCanteenScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('+ Create New', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JoinCanteenScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.link, size: 18),
                      label: const Text('+ Join Canteen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
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
