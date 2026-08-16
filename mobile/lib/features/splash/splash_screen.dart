import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';

/// Animated Splash (Flash) Screen for Smart-Hisab.
/// Initializes app services, checks auth & tenant state,
/// and presents micro-animations with a shimmer loader.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Micro-animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // 2. Trigger Auth Check after initial animation start (AuthGuard will declaratively route)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      ref.read(authNotifierProvider.notifier).initializeAuth();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AppSafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Animated App Logo & Branding Badge
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Container with Emerald Gradient & Subtle Shadow
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.store,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    Text(
                      'Smart-Hisab',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle / Tagline
                    Text(
                      'Your Canteen\'s Digital Hisab',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Skeleton Shimmer Loader (Complies with AGENTS.md Rule 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Shimmer.fromColors(
                baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight,
                highlightColor: isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Footer Version Info
            Text(
              'v1.0.0 (Free Tier)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
