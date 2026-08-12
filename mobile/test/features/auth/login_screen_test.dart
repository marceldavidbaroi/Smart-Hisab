import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_hisab/core/theme/app_theme.dart';
import 'package:smart_hisab/features/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders branding, value prop cards, and Google Sign-In button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify header branding
    expect(find.text('Smart-Hisab'), findsOneWidget);
    expect(find.text('Your Canteen\'s Digital Hisab'), findsOneWidget);

    // Verify feature highlight cards
    expect(find.text('Fast Counter Meal Logging'), findsOneWidget);
    expect(find.text('Cashbook & Baki Tracking'), findsOneWidget);
    expect(find.text('Offline Ready Sync'), findsOneWidget);

    // Verify Google Sign-In button and Demo button
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('⚡ Try Demo Mode (Simulator Quick Entry)'), findsOneWidget);
  });
}
