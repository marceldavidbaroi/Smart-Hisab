import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env.dart';
import 'core/services/error_handler_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_notifier.dart';
import 'core/auth/auth_state.dart';
import 'features/app_scaffold.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_choice_screen.dart';
import 'features/auth/login_select_canteen_screen.dart';
import 'features/splash/splash_screen.dart';

import 'core/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Central Error Handler
  ErrorHandlerService.initialize();

  // Initialize Hive Offline Boxes
  await HiveService.initialize();

  // Initialize Supabase Client with local/env fallback
  try {
    await SupabaseService.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init warning: $e');
  }

  runApp(
    const ProviderScope(
      child: SmartHisabApp(),
    ),
  );
}

class SmartHisabApp extends ConsumerWidget {
  const SmartHisabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Smart-Hisab',
      navigatorKey: ErrorHandlerService.navigatorKey,
      scaffoldMessengerKey: NotificationService.messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGuard(),
    );
  }
}

/// Reactive AuthGuard ensuring correct flow routing
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashScreen();

      case AuthStatus.authenticatedWithTenant:
        return const AppScaffold();

      case AuthStatus.authenticatedNoTenant:
        return const OnboardingChoiceScreen();

      case AuthStatus.authenticatedSelectTenant:
        return const LoginSelectCanteenScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}
