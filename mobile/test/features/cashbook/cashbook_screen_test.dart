import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hisab/features/cashbook/cashbook_screen.dart';

void main() {
  testWidgets('CashbookScreen renders summary header and transaction list',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CashbookScreen(),
          ),
        ),
      ),
    );

    // Pump to settle riverpod initial state loading
    await tester.pumpAndSettle();

    // Verify main titles and cashbook header render properly
    expect(find.text('Canteen Cashbook'), findsOneWidget);
    expect(find.text('Net Day Cashflow'), findsOneWidget);
    expect(find.text('Day Transactions History'), findsOneWidget);
  });
}
