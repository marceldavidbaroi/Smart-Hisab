import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class CanteenProfileScreen extends ConsumerStatefulWidget {
  const CanteenProfileScreen({super.key});

  @override
  ConsumerState<CanteenProfileScreen> createState() => _CanteenProfileScreenState();
}

class _CanteenProfileScreenState extends ConsumerState<CanteenProfileScreen> {
  void _showEditCanteenSheet(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    CustomModalBottomSheet.show(
      context: context,
      title: 'Edit Canteen Name',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Canteen / Business Name *',
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              prefixIcon: const Icon(LucideIcons.store, color: AppColors.primary),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Canteen name updated!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: AppSafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Icon(LucideIcons.store, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Rahim's Canteen",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🟢 Active • Free Tier v1.0',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metadata List
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.store, color: AppColors.primary),
                    title: Text('Canteen Name', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    subtitle: Text("Rahim's Canteen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.edit2, size: 18, color: AppColors.primary),
                      onPressed: () => _showEditCanteenSheet(context, "Rahim's Canteen"),
                    ),
                  ),
                  Divider(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight, height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.shieldCheck, color: AppColors.warning),
                    title: Text('Your Role', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    subtitle: Text(
                      authState.role?.toUpperCase() ?? 'OWNER',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                  Divider(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight, height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.users, color: AppColors.info),
                    title: Text('Subscription Limit', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    subtitle: Text('Max 50 Customers • Max 3 Staff', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
