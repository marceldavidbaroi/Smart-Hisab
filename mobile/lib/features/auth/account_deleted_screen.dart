import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import 'login_screen.dart';

/// Screen displayed immediately after successful account & canteen deletion.
class AccountDeletedScreen extends ConsumerWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppSafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Success Icon Container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Account Deleted',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                'Your Smart-Hisab account, canteen database, and all associated financial & staff records have been permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

              const Spacer(),

              // Back to Login Button
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                label: const Text(
                  'Back to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
