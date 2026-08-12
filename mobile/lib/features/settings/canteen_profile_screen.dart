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
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Canteen / Business Name *',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              prefixIcon: const Icon(LucideIcons.store, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Icon(LucideIcons.store, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Rahim's Canteen",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.store, color: AppColors.primary),
                    title: const Text('Canteen Name', style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark)),
                    subtitle: const Text("Rahim's Canteen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.edit2, size: 18, color: AppColors.primary),
                      onPressed: () => _showEditCanteenSheet(context, "Rahim's Canteen"),
                    ),
                  ),
                  const Divider(color: AppColors.cardBorderDark, height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.shieldCheck, color: AppColors.warning),
                    title: const Text('Your Role', style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark)),
                    subtitle: Text(
                      authState.role?.toUpperCase() ?? 'OWNER',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const Divider(color: AppColors.cardBorderDark, height: 1),
                  ListTile(
                    leading: const Icon(LucideIcons.users, color: AppColors.info),
                    title: const Text('Subscription Limit', style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark)),
                    subtitle: const Text('Max 50 Customers • Max 3 Staff', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
