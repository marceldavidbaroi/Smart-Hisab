import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/error_handler_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/outbox_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_notifier.dart';
import 'core/auth/auth_state.dart';
import 'features/app_scaffold.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Central Error Handler
  ErrorHandlerService.initialize();

  // Initialize Hive Offline Boxes
  await HiveService.initialize();

  // Initialize Offline Outbox Connectivity Listener
  OutboxService().initialize();

  // Initialize Supabase Client with local/env fallback
  try {
    await SupabaseService.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'http://10.0.2.2:54321', // Local Supabase Docker Android Loopback
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // Local dev key
      ),
    );
  } catch (e) {
    debugPrint('Supabase init warning: $e');
  }

  runApp(
    const SmartHisabApp(),
  );
}

class SmartHisabApp extends StatelessWidget {
  const SmartHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Smart-Hisab',
        scaffoldMessengerKey: NotificationService.messengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGuard(),
      ),
    );
  }
}

/// Reactive AuthGuard ensuring unauthenticated users always land on LoginScreen
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    switch (authState.status) {
      case AuthStatus.initial:
        return const SplashScreen();

      case AuthStatus.authenticatedWithTenant:
      case AuthStatus.authenticatedNoTenant:
        return const AppScaffold();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      default:
        return const LoginScreen();
    }
  }
}
