import 'package:almanac/features/meditation/domain/breathing_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the app\'s pattern', () {
    test('is four in, two held, six out', () {
      expect(kAlmanacBreath.steps, const [
        BreathingStep(BreathingPhase.inhale, Duration(seconds: 4)),
        BreathingStep(BreathingPhase.hold, Duration(seconds: 2)),
        BreathingStep(BreathingPhase.exhale, Duration(seconds: 6)),
      ]);
    });

    test('takes twelve seconds a breath', () {
      expect(kAlmanacBreath.cycleLength, const Duration(seconds: 12));
    });

    test('breathes out for longer than it breathes in', () {
      // The part that actually settles you, so it is worth pinning.
      final steps = {
        for (final step in kAlmanacBreath.steps) step.phase: step.duration,
      };
      expect(
        steps[BreathingPhase.exhale],
        greaterThan(steps[BreathingPhase.inhale]!),
      );
    });

    test('a session is a whole number of breaths', () {
      // So it ends at the end of an out-breath rather than halfway
      // through one.
      expect(
        kMeditationSessionLength.inMilliseconds %
            kAlmanacBreath.cycleLength.inMilliseconds,
        0,
      );
      expect(
        kMeditationSessionLength.inMilliseconds ~/
            kAlmanacBreath.cycleLength.inMilliseconds,
        10,
      );
    });

    test('is two minutes long', () {
      expect(kMeditationSessionLength, const Duration(minutes: 2));
    });

    test('every phase says what to do', () {
      expect(BreathingPhase.inhale.instruction, 'Breathe in');
      expect(BreathingPhase.hold.instruction, 'Hold');
      expect(BreathingPhase.exhale.instruction, 'Breathe out');
    });
  });

  group('progression through one breath', () {
    BreathingPhase phaseAt(int seconds) =>
        kAlmanacBreath.momentAt(Duration(seconds: seconds)).phase;

    test('runs inhale, hold, exhale, and round again', () {
      expect(phaseAt(0), BreathingPhase.inhale);
      expect(phaseAt(3), BreathingPhase.inhale);
      expect(phaseAt(4), BreathingPhase.hold);
      expect(phaseAt(5), BreathingPhase.hold);
      expect(phaseAt(6), BreathingPhase.exhale);
      expect(phaseAt(11), BreathingPhase.exhale);
      // Back to the beginning.
      expect(phaseAt(12), BreathingPhase.inhale);
      expect(phaseAt(16), BreathingPhase.hold);
    });

    test('the boundaries land on the right side', () {
      // A phase owns its start and not its end, so no instant belongs to
      // two phases.
      expect(
        kAlmanacBreath.momentAt(const Duration(milliseconds: 3999)).phase,
        BreathingPhase.inhale,
      );
      expect(
        kAlmanacBreath.momentAt(const Duration(seconds: 4)).phase,
        BreathingPhase.hold,
      );
      expect(
        kAlmanacBreath.momentAt(const Duration(milliseconds: 5999)).phase,
        BreathingPhase.hold,
      );
      expect(
        kAlmanacBreath.momentAt(const Duration(seconds: 6)).phase,
        BreathingPhase.exhale,
      );
    });

    test('the same instant always gives the same answer', () {
      // The property the whole screen leans on: the drawn breath and the
      // written instruction come from this, so it cannot be allowed to
      // depend on how it was reached.
      const instant = Duration(milliseconds: 7321);
      expect(
        kAlmanacBreath.momentAt(instant),
        kAlmanacBreath.momentAt(instant),
      );
    });

    test('every breath of a session is the same as the first', () {
      for (var cycle = 0; cycle < 10; cycle++) {
        final offset = kAlmanacBreath.cycleLength * cycle;
        for (final second in [0, 2, 4, 5, 6, 9, 11]) {
          expect(
            kAlmanacBreath.momentAt(offset + Duration(seconds: second)).phase,
            kAlmanacBreath.momentAt(Duration(seconds: second)).phase,
            reason: 'breath $cycle differs at ${second}s',
          );
        }
      }
    });

    test('a negative elapsed is treated as the very start', () {
      final moment = kAlmanacBreath.momentAt(const Duration(seconds: -5));
      expect(moment.phase, BreathingPhase.inhale);
      expect(moment.progress, 0);
    });
  });

  group('the shape of a breath', () {
    double opennessAt(num seconds) => kAlmanacBreath
        .momentAt(Duration(milliseconds: (seconds * 1000).round()))
        .openness;

    test('opens through the in-breath', () {
      expect(opennessAt(0), 0);
      expect(opennessAt(2), closeTo(0.5, 1e-9));
      expect(opennessAt(3.999), closeTo(1, 0.001));
    });

    test('stays open through the hold', () {
      expect(opennessAt(4), 1);
      expect(opennessAt(5), 1);
      expect(opennessAt(5.999), 1);
    });

    test('closes through the out-breath', () {
      expect(opennessAt(6), 1);
      expect(opennessAt(9), closeTo(0.5, 1e-9));
      expect(opennessAt(11.999), closeTo(0, 0.001));
    });

    test('never leaves 0 to 1, and never jumps', () {
      var previous = opennessAt(0);
      for (var ms = 0; ms <= 12000; ms += 50) {
        final openness = opennessAt(ms / 1000);
        expect(openness, inInclusiveRange(0, 1));
        // 50ms of a 4-second in-breath is 1.25% of the range; anything
        // much larger would be a visible jump.
        expect(
          (openness - previous).abs(),
          lessThan(0.02),
          reason: 'openness jumped at ${ms}ms',
        );
        previous = openness;
      }
    });

    test('the breath is continuous across the wrap to the next one', () {
      expect((opennessAt(11.99) - opennessAt(12.01)).abs(), lessThan(0.02));
    });
  });

  group('what a screen reader is told', () {
    test('counts the seconds left in the phase, rounded up', () {
      expect(kAlmanacBreath.momentAt(Duration.zero).secondsRemaining, 4);
      expect(
        kAlmanacBreath
            .momentAt(const Duration(milliseconds: 3500))
            .secondsRemaining,
        1,
      );
      expect(
        kAlmanacBreath.momentAt(const Duration(seconds: 4)).secondsRemaining,
        2,
      );
      expect(
        kAlmanacBreath.momentAt(const Duration(seconds: 6)).secondsRemaining,
        6,
      );
    });

    test('carries the whole phase length, for the spoken label', () {
      expect(
        kAlmanacBreath.momentAt(const Duration(seconds: 1)).phaseLength,
        const Duration(seconds: 4),
      );
      expect(
        kAlmanacBreath.momentAt(const Duration(seconds: 7)).phaseLength,
        const Duration(seconds: 6),
      );
    });
  });

  group('a different pattern', () {
    // The point of the abstraction: the rhythm can change without the
    // screen knowing.
    const evenBreath = BreathingPattern(
      name: 'even',
      steps: [
        BreathingStep(BreathingPhase.inhale, Duration(seconds: 5)),
        BreathingStep(BreathingPhase.exhale, Duration(seconds: 5)),
      ],
    );

    test('need not have a hold at all', () {
      expect(evenBreath.cycleLength, const Duration(seconds: 10));
      expect(
        evenBreath.momentAt(const Duration(seconds: 2)).phase,
        BreathingPhase.inhale,
      );
      expect(
        evenBreath.momentAt(const Duration(seconds: 7)).phase,
        BreathingPhase.exhale,
      );
      expect(
        evenBreath.momentAt(const Duration(seconds: 12)).phase,
        BreathingPhase.inhale,
      );
    });
  });
}
