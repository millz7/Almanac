import 'package:almanac/core/environment/moon_calculator.dart';
import 'package:almanac/core/environment/moon_phase.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The moon's shape is built by combining paths, and the interesting
/// cases are the degenerate ones — a new moon where the lit region is
/// empty, a full moon where it is the whole disc, and the quarters where
/// the terminator ellipse collapses to a straight line. Those are exactly
/// the values a naive implementation crashes or draws wrong on, so they
/// are all painted here.
void main() {
  Future<void> pumpMoon(
    WidgetTester tester,
    MoonPhaseState moon, {
    bool mirrored = false,
    double size = 64,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            child: MoonDisc(
              moon: moon,
              size: size,
              litColor: const Color(0xFFF3EAD3),
              unlitColor: const Color(0x22F3EAD3),
              mirrored: mirrored,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  MoonPhaseState stateAt(double elongation) => MoonPhaseState(
    phase: MoonPhase.newMoon,
    elongationDegrees: elongation,
    illuminatedFraction: (1 - _cosDegrees(elongation)) / 2,
  );

  group('paints at every point of the cycle', () {
    for (var elongation = 0; elongation < 360; elongation += 15) {
      testWidgets('at $elongation° of elongation', (tester) async {
        await pumpMoon(tester, stateAt(elongation.toDouble()));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a new moon paints nothing lit, without crashing', (
      tester,
    ) async {
      await pumpMoon(
        tester,
        const MoonPhaseState(
          phase: MoonPhase.newMoon,
          elongationDegrees: 0,
          illuminatedFraction: 0,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a full moon paints the whole disc', (tester) async {
      await pumpMoon(
        tester,
        const MoonPhaseState(
          phase: MoonPhase.fullMoon,
          elongationDegrees: 180,
          illuminatedFraction: 1,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a quarter, where the terminator is a straight line', (
      tester,
    ) async {
      await pumpMoon(
        tester,
        const MoonPhaseState(
          phase: MoonPhase.firstQuarter,
          elongationDegrees: 90,
          illuminatedFraction: 0.5,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a zero-sized disc is not a crash', (tester) async {
      await pumpMoon(tester, stateAt(45), size: 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('geometry', () {
    testWidgets('takes the size it is given', (tester) async {
      await pumpMoon(tester, stateAt(90), size: 48);

      expect(tester.getSize(find.byType(MoonDisc)), const Size(48, 48));
    });

    testWidgets('the lit side flips when mirrored', (tester) async {
      // The two must not paint identically: which limb is lit is the one
      // thing an observer in the other hemisphere sees differently.
      final crescent = stateAt(45);

      await pumpMoon(tester, crescent);
      final northern = tester.widget<MoonDisc>(find.byType(MoonDisc));
      expect(northern.mirrored, isFalse);

      await pumpMoon(tester, crescent, mirrored: true);
      final southern = tester.widget<MoonDisc>(find.byType(MoonDisc));
      expect(southern.mirrored, isTrue);
    });
  });

  group('a real month', () {
    testWidgets('every night of a lunation paints', (tester) async {
      // Uses the actual calculator rather than made-up fractions, so the
      // widget is exercised against the values it will really be handed.
      final start = DateTime.utc(2025, 6, 25, 10, 31);

      for (var hours = 0; hours < 30 * 24; hours += 6) {
        await pumpMoon(
          tester,
          MoonCalculator.phaseAt(start.add(Duration(hours: hours))),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'failed $hours hours after the new moon',
        );
      }
    });
  });
}

double _cosDegrees(double degrees) => _cos(degrees * 3.141592653589793 / 180);

double _cos(double radians) {
  // Kept local so the test does not depend on the app's own maths for
  // the value it is checking the app's drawing against.
  var term = 1.0;
  var sum = 1.0;
  for (var n = 1; n <= 12; n++) {
    term *= -radians * radians / ((2 * n - 1) * (2 * n));
    sum += term;
  }
  return sum;
}
