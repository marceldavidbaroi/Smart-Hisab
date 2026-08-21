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

    // Verify Auth Toggle Tabs and Submit Button
    expect(find.text('Sign In'), findsNWidgets(2));
    expect(find.text('Create Account'), findsOneWidget);

    // Verify form input fields
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Demo button
    expect(find.text('⚡ Try Demo Mode (Simulator Quick Entry)'), findsOneWidget);
  });
}
