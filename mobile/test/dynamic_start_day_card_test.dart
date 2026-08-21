import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hisab/core/utils/time_phase_helper.dart';
import 'package:smart_hisab/features/home/widgets/animated_celestial_hero.dart';
import 'package:smart_hisab/features/home/widgets/dynamic_start_day_card.dart';

void main() {
  group('Dynamic Start Day & Celestial Hero Widget Tests', () {
    testWidgets('renders AnimatedCelestialHero in daytime phase without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCelestialHero(
                phase: TimePhase.morning,
                size: 100,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCelestialHero), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders AnimatedCelestialHero in nighttime phase without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCelestialHero(
                phase: TimePhase.dinner,
                size: 100,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCelestialHero), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders DynamicStartDayCard with morning time override', (tester) async {
      final morningTime = DateTime(2026, 8, 21, 9, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicStartDayCard(
              overrideTime: morningTime,
            ),
          ),
        ),
      );

      expect(find.text('MORNING RUSH'), findsOneWidget);
      expect(find.text('Good Morning ☀️'), findsOneWidget);
      expect(find.text('Start Business Day'), findsOneWidget);
      expect(find.byType(AnimatedCelestialHero), findsOneWidget);
    });

    testWidgets('renders DynamicStartDayCard with night time override', (tester) async {
      final nightTime = DateTime(2026, 8, 21, 23, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicStartDayCard(
              overrideTime: nightTime,
            ),
          ),
        ),
      );

      expect(find.text('NIGHT HOURS'), findsOneWidget);
      expect(find.text('Night Ledger 🌌'), findsOneWidget);
      expect(find.text('Start Business Day'), findsOneWidget);
    });
  });
}
