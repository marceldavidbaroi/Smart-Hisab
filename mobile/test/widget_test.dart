import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hisab/main.dart';

void main() {
  testWidgets('SmartHisabApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHisabApp());
    expect(find.byType(SmartHisabApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  });
}
