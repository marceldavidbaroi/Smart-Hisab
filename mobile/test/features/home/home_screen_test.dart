import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hisab/features/home/home_screen.dart';
import 'package:smart_hisab/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('HomeScreen renders in English locale', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify English text
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Mark Meals'), findsOneWidget);
    expect(find.text('Collect Baki'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Day Notes'), findsOneWidget);
  });

  testWidgets('HomeScreen renders in Bangla locale', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('bn'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Bangla text
    expect(find.text('কুইক অ্যাকশন'), findsOneWidget);
    expect(find.text('মিল গণনা'), findsOneWidget);
    expect(find.text('বাকি আদায়'), findsOneWidget);
    expect(find.text('খরচ লিখুন'), findsOneWidget);
    expect(find.text('দিনের নোট'), findsOneWidget);
  });
}
