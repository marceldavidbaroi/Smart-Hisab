import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_hisab/core/theme/app_theme.dart';
import 'package:smart_hisab/features/auth/login_select_canteen_screen.dart';

void main() {
  testWidgets('LoginSelectCanteenScreen renders title and header banner', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginSelectCanteenScreen(),
        ),
      ),
    );

    // Verify title and header banner
    expect(find.text('Select Canteen'), findsOneWidget);
    expect(find.text('Your Canteens'), findsOneWidget);
    expect(find.text('Select a canteen to open its dashboard:'), findsOneWidget);
  });
}
