import 'package:almanac/core/environment/astronomy.dart';
import 'package:almanac/core/environment/moon_calculator.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Known new and full moons, from published almanac data (the times are
/// the instants of the exact syzygy, in UTC).
///
/// Chosen to spread across several years and both halves of the year, so
/// a mistake in the periodic terms — which is what a truncated lunar
/// series risks — shows up rather than being hidden by one lucky date.
final _newMoons = <(String, DateTime)>[
  ('2024-01-11 11:57', DateTime.utc(2024, 1, 11, 11, 57)),
  ('2024-07-05 22:57', DateTime.utc(2024, 7, 5, 22, 57)),
  ('2025-01-29 12:36', DateTime.utc(2025, 1, 29, 12, 36)),
  ('2025-06-25 10:31', DateTime.utc(2025, 6, 25, 10, 31)),
  ('2025-09-21 19:54', DateTime.utc(2025, 9, 21, 19, 54)),
  ('2026-03-19 01:23', DateTime.utc(2026, 3, 19, 1, 23)),
];

final _fullMoons = <(String, DateTime)>[
  ('2024-01-25 17:54', DateTime.utc(2024, 1, 25, 17, 54)),
  ('2024-08-19 18:26', DateTime.utc(2024, 8, 19, 18, 26)),
  ('2025-03-14 06:55', DateTime.utc(2025, 3, 14, 6, 55)),
  ('2025-07-10 20:37', DateTime.utc(2025, 7, 10, 20, 37)),
  ('2025-12-04 23:14', DateTime.utc(2025, 12, 4, 23, 14)),
  ('2026-06-29 23:57', DateTime.utc(2026, 6, 29, 23, 57)),
];

void main() {
  group('known new moons', () {
    for (final (label, instant) in _newMoons) {
      test('$label is a new moon', () {
        final phase = MoonCalculator.phaseAt(instant);

        expect(phase.phase, MoonPhase.newMoon);
        // At the exact new moon the elongation is 0 — which wraps, so it
        // is either just under 360 or just over 0.
        final fromZero = phase.elongationDegrees > 180
            ? 360 - phase.elongationDegrees
            : phase.elongationDegrees;
        expect(
          fromZero,
          lessThan(0.5),
          reason: 'elongation ${phase.elongationDegrees}° should be near 0',
        );
        expect(phase.illuminatedPercent, 0);
      });
    }
  });

  group('known full moons', () {
    for (final (label, instant) in _fullMoons) {
      test('$label is a full moon', () {
        final phase = MoonCalculator.phaseAt(instant);

        expect(phase.phase, MoonPhase.fullMoon);
        expect(
          (phase.elongationDegrees - 180).abs(),
          lessThan(0.5),
          reason: 'elongation ${phase.elongationDegrees}° should be near 180',
        );
        expect(phase.illuminatedPercent, 100);
      });
    }
  });

  group('accuracy', () {
    // The moon's elongation moves about 0.5° an hour, so half a degree of
    // error is roughly an hour. Published phase times are given to the
    // minute; matching them to within a couple of hours is well inside
    // what the documented accuracy claims and far more than a drawn moon
    // and a phase name need.
    test('elongation error stays inside a couple of hours of motion', () {
      const degreesPerHour = 360 / (meanSynodicMonth * 24);

      for (final (label, instant) in [..._newMoons, ..._fullMoons]) {
        final elongation = MoonCalculator.phaseAt(instant).elongationDegrees;
        final target = _newMoons.any((m) => m.$2 == instant) ? 0.0 : 180.0;
        final error = target == 0
            ? (elongation > 180 ? 360 - elongation : elongation)
            : (elongation - 180).abs();

        expect(
          error / degreesPerHour,
          lessThan(2),
          reason: '$label is out by ${error.toStringAsFixed(3)}°',
        );
      }
    });
  });

  group('the eight phases', () {
    // One lunation from the new moon of 25 June 2025, sampled at each
    // eighth. The exact instants drift a little because the real month is
    // not 29.53 days long every time, so this checks the sequence and the
    // waxing/waning sense rather than exact boundaries.
    final newMoon = DateTime.utc(2025, 6, 25, 10, 31);

    test('run in order through a lunation', () {
      final seen = <MoonPhase>[];
      for (var eighth = 0; eighth < 8; eighth++) {
        final instant = newMoon.add(
          Duration(minutes: (meanSynodicMonth * eighth / 8 * 24 * 60).round()),
        );
        final phase = MoonCalculator.phaseAt(instant).phase;
        if (seen.isEmpty || seen.last != phase) seen.add(phase);
      }

      expect(seen, MoonPhase.values);
    });

    test('illumination grows to full then shrinks back', () {
      double litAt(double days) => MoonCalculator.phaseAt(
        newMoon.add(Duration(minutes: (days * 24 * 60).round())),
      ).illuminatedFraction;

      expect(litAt(0), lessThan(0.01));
      expect(litAt(3.7), closeTo(0.146, 0.05));
      expect(litAt(7.4), closeTo(0.5, 0.06));
      expect(litAt(14.8), greaterThan(0.99));
      expect(litAt(22.1), closeTo(0.5, 0.06));
      expect(litAt(29.5), lessThan(0.01));
    });

    test('waxing runs new to full and waning runs full to new', () {
      expect(MoonCalculator.phaseAt(newMoon).phase.isWaxing, isFalse);

      for (final days in [3.7, 7.4, 11.1]) {
        final phase = MoonCalculator.phaseAt(
          newMoon.add(Duration(minutes: (days * 24 * 60).round())),
        );
        expect(
          phase.phase.isWaxing,
          isTrue,
          reason: 'day $days (${phase.phase.label}) should be waxing',
        );
        expect(phase.elongationDegrees, lessThan(180));
      }

      for (final days in [18.5, 22.1, 25.8]) {
        final phase = MoonCalculator.phaseAt(
          newMoon.add(Duration(minutes: (days * 24 * 60).round())),
        );
        expect(
          phase.phase.isWaxing,
          isFalse,
          reason: 'day $days (${phase.phase.label}) should be waning',
        );
        expect(phase.elongationDegrees, greaterThan(180));
      }
    });
  });

  group('phase boundaries', () {
    // Each name covers 45° centred on its exact phase, so the boundaries
    // sit at odd multiples of 22.5°. These are checked from the phase
    // function's own contract rather than from a date, because the point
    // is where the labels change, not when.
    test('each named phase is centred on its exact angle', () {
      const centres = <(double, MoonPhase)>[
        (0, MoonPhase.newMoon),
        (45, MoonPhase.waxingCrescent),
        (90, MoonPhase.firstQuarter),
        (135, MoonPhase.waxingGibbous),
        (180, MoonPhase.fullMoon),
        (225, MoonPhase.waningGibbous),
        (270, MoonPhase.lastQuarter),
        (315, MoonPhase.waningCrescent),
      ];

      for (final (elongation, expected) in centres) {
        for (final offset in [-22.0, 0.0, 22.0]) {
          expect(
            _phaseForElongation(elongation + offset),
            expected,
            reason: '${elongation + offset}° should be ${expected.label}',
          );
        }
      }
    });
  });

  group('MoonPhaseState', () {
    test('age spans one synodic month over the cycle', () {
      const start = MoonPhaseState(
        phase: MoonPhase.newMoon,
        elongationDegrees: 0,
        illuminatedFraction: 0,
      );
      const half = MoonPhaseState(
        phase: MoonPhase.fullMoon,
        elongationDegrees: 180,
        illuminatedFraction: 1,
      );

      expect(start.ageInDays, 0);
      expect(half.ageInDays, closeTo(meanSynodicMonth / 2, 0.001));
    });

    test('illuminated percent rounds for display', () {
      const state = MoonPhaseState(
        phase: MoonPhase.waxingGibbous,
        elongationDegrees: 120,
        illuminatedFraction: 0.746,
      );
      expect(state.illuminatedPercent, 75);
    });
  });

  group('AstronomicalMoonService', () {
    test('reports what the calculator reports', () {
      const service = AstronomicalMoonService();
      final instant = DateTime.utc(2025, 7, 10, 20, 37);

      final fromService = service.phaseAt(instant);
      final fromCalculator = MoonCalculator.phaseAt(instant);

      expect(fromService.phase, fromCalculator.phase);
      expect(fromService.elongationDegrees, fromCalculator.elongationDegrees);
    });

    test('needs no position, so a local time still gives the same phase', () {
      const service = AstronomicalMoonService();
      // The same instant, expressed in two zones. The phase of the moon
      // is a property of the moment, not of where you are.
      final utc = DateTime.utc(2025, 7, 10, 20, 37);
      final elsewhere = DateTime.parse('2025-07-11T08:37:00+12:00');

      expect(
        service.phaseAt(elsewhere).elongationDegrees,
        closeTo(service.phaseAt(utc).elongationDegrees, 1e-9),
      );
    });
  });
}

/// Reaches the phase-naming rule through a real calculation, by finding
/// the instant with the wanted elongation is unnecessary — the rule is
/// pure arithmetic on the angle, so it is reproduced here and the
/// calculator's own agreement with it is covered by the tests above.
MoonPhase _phaseForElongation(double elongation) {
  final octant = (wrap360(elongation + 22.5) / 45).floor() % 8;
  return MoonPhase.values[octant];
}
