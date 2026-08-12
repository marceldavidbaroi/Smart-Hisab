import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/hive_service.dart';
import 'core/services/outbox_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/app_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    const ProviderScope(
      child: SmartHisabApp(),
    ),
  );
}

class SmartHisabApp extends StatelessWidget {
  const SmartHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart-Hisab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppScaffold(),
    );
  }
}
