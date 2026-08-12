import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:smart_hisab/core/theme/app_theme.dart';
import 'package:smart_hisab/features/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders branding, title, and shimmer loading bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
        ),
      ),
    );

    // Initial frame verify
    expect(find.text('Smart-Hisab'), findsOneWidget);
    expect(find.text('Your Canteen\'s Digital Hisab'), findsOneWidget);
    expect(find.text('v1.0.0 (Free Tier)'), findsOneWidget);
    expect(find.byType(Shimmer), findsOneWidget);

    // Advance animation and navigation timers
    await tester.pump(const Duration(milliseconds: 2000));
  });
}
