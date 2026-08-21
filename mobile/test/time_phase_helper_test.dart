import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hisab/core/utils/time_phase_helper.dart';

void main() {
  group('TimePhaseHelper Tests', () {
    test('resolves Dawn phase correctly (05:00 - 07:59)', () {
      final t1 = DateTime(2026, 8, 21, 5, 0);
      final t2 = DateTime(2026, 8, 21, 7, 59);

      expect(TimePhaseHelper.getPhase(t1), TimePhase.dawn);
      expect(TimePhaseHelper.getPhase(t2), TimePhase.dawn);
      expect(TimePhaseHelper.isDaytime(TimePhase.dawn), isTrue);
      expect(TimePhaseHelper.getBadgeLabel(TimePhase.dawn), 'Sunrise Dawn');
    });

    test('resolves Morning phase correctly (08:00 - 11:29)', () {
      final t1 = DateTime(2026, 8, 21, 8, 0);
      final t2 = DateTime(2026, 8, 21, 11, 29);

      expect(TimePhaseHelper.getPhase(t1), TimePhase.morning);
      expect(TimePhaseHelper.getPhase(t2), TimePhase.morning);
      expect(TimePhaseHelper.isDaytime(TimePhase.morning), isTrue);
      expect(TimePhaseHelper.getBadgeLabel(TimePhase.morning), 'Morning Rush');
    });

    test('resolves Midday phase correctly (11:30 - 15:29)', () {
      final t1 = DateTime(2026, 8, 21, 11, 30);
      final t2 = DateTime(2026, 8, 21, 15, 29);

      expect(TimePhaseHelper.getPhase(t1), TimePhase.midday);
      expect(TimePhaseHelper.getPhase(t2), TimePhase.midday);
      expect(TimePhaseHelper.isDaytime(TimePhase.midday), isTrue);
      expect(TimePhaseHelper.getBadgeLabel(TimePhase.midday), 'Midday Peak');
    });

    test('resolves Afternoon phase correctly (15:30 - 19:29)', () {
      final t1 = DateTime(2026, 8, 21, 15, 30);
      final t2 = DateTime(2026, 8, 21, 19, 29);

      expect(TimePhaseHelper.getPhase(t1), TimePhase.afternoon);
      expect(TimePhaseHelper.getPhase(t2), TimePhase.afternoon);
      expect(TimePhaseHelper.isDaytime(TimePhase.afternoon), isTrue);
      expect(TimePhaseHelper.getBadgeLabel(TimePhase.afternoon), 'Golden Hour');
    });

    test('resolves Dinner phase correctly (19:30 - 22:59)', () {
      final t1 = DateTime(2026, 8, 21, 19, 30);
      final t2 = DateTime(2026, 8, 21, 22, 59);

      expect(TimePhaseHelper.getPhase(t1), TimePhase.dinner);
      expect(TimePhaseHelper.getPhase(t2), TimePhase.dinner);
      expect(TimePhaseHelper.isDaytime(TimePhase.dinner), isFalse);
      expect(TimePhaseHelper.getBadgeLabel(TimePhase.dinner), 'Dinner Shift');
    });

    test('resolves Night phase correctly (23:00 - 04:59)', () {
      final t1 = DateTime(2026, 8, 21, 23, 0);
      final t2 = DateTime(2026, 8, 21, 23, 59);
      final t3 = DateTime(2026, 8, 21, 0, 0);
      final t4 = DateTime(2026, 8, 21, 4, 59);

      expect(TimePhaseHelper.getPhase(t1), TimePhase.night);
      expect(TimePhaseHelper.getPhase(t2), TimePhase.night);
      expect(TimePhaseHelper.getPhase(t3), TimePhase.night);
      expect(TimePhaseHelper.getPhase(t4), TimePhase.night);
      expect(TimePhaseHelper.isDaytime(TimePhase.night), isFalse);
      expect(TimePhaseHelper.getBadgeLabel(TimePhase.night), 'Night Hours');
    });

    test('provides valid gradients and accents for all phases', () {
      for (final phase in TimePhase.values) {
        final darkGrad = TimePhaseHelper.getCardGradient(phase, true);
        final lightGrad = TimePhaseHelper.getCardGradient(phase, false);
        final primaryAccent = TimePhaseHelper.getPrimaryAccent(phase);
        final secondaryAccent = TimePhaseHelper.getSecondaryAccent(phase);
        final greeting = TimePhaseHelper.getGreeting(phase);
        final subtitle = TimePhaseHelper.getSubtitle(phase);

        expect(darkGrad.length, 2);
        expect(lightGrad.length, 2);
        expect(primaryAccent, isNotNull);
        expect(secondaryAccent, isNotNull);
        expect(greeting.isNotEmpty, isTrue);
        expect(subtitle.isNotEmpty, isTrue);
      }
    });
  });
}
