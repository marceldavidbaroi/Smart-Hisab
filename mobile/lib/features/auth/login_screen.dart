import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../app_scaffold.dart';

/// Login Screen for Smart-Hisab.
/// Features Google Sign-In primary auth, value proposition cards,
/// and responsive dark mode styling.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSigningIn = false;

  void _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    setState(() => _isSigningIn = false);

    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppScaffold()),
      );
    }
  }

  void _handleDemoSignIn() async {
    setState(() => _isSigningIn = true);
    await ref.read(authNotifierProvider.notifier).signInDemoUser();

    if (!mounted) return;
    setState(() => _isSigningIn = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: AppSafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Header Branding
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.store,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smart-Hisab',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Canteen\'s Digital Hisab',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Value Proposition Cards
              Column(
                children: const [
                  _FeatureCard(
                    icon: LucideIcons.utensils,
                    title: 'Fast Counter Meal Logging',
                    description: 'Log daily meals and member attendance in seconds',
                  ),
                  SizedBox(height: 10),
                  _FeatureCard(
                    icon: LucideIcons.bookOpen,
                    title: 'Cashbook & Baki Tracking',
                    description: 'Keep accurate record of customer credit & daily totals',
                  ),
                  SizedBox(height: 10),
                  _FeatureCard(
                    icon: LucideIcons.cloud,
                    title: 'Offline Ready Sync',
                    description: 'Works uninterrupted even with unstable internet connection',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Error Banner if present
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 20, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Loading Shimmer or Action Buttons
              if (_isSigningIn || authState.status == AuthStatus.loading)
                Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              else ...[
                // Google Sign-In Primary Button
                ElevatedButton(
                  onPressed: _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.logIn, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Demo / Simulator Quick Sign-In Option
                TextButton(
                  onPressed: _handleDemoSignIn,
                  child: Text(
                    '⚡ Try Demo Mode (Simulator Quick Entry)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16, // Main item title >= 16 bold
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13, // Secondary metadata
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
