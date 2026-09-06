import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final focus = MeditationTechniques.focus.pattern;
  final sleep = MeditationTechniques.sleep.pattern;
  final balance = MeditationTechniques.balance.pattern;
  final release = MeditationTechniques.releaseTension.pattern;

  BreathingMoment at(BreathingPattern pattern, num seconds) =>
      pattern.momentAt(Duration(milliseconds: (seconds * 1000).round()));

  group('Focus progresses through its square', () {
    test('inhale, hold, exhale, and round again', () {
      expect(at(focus, 0).phase, BreathingPhase.inhale);
      expect(at(focus, 3.9).phase, BreathingPhase.inhale);
      expect(at(focus, 4).phase, BreathingPhase.hold);
      expect(at(focus, 7.9).phase, BreathingPhase.hold);
      expect(at(focus, 8).phase, BreathingPhase.exhale);
      expect(at(focus, 11.9).phase, BreathingPhase.exhale);
      expect(at(focus, 12).phase, BreathingPhase.inhale);
      expect(at(focus, 16).phase, BreathingPhase.hold);
    });

    test('a step owns its start and not its end', () {
      expect(at(focus, 3.999).stepIndex, 0);
      expect(at(focus, 4).stepIndex, 1);
      expect(at(focus, 7.999).stepIndex, 1);
      expect(at(focus, 8).stepIndex, 2);
    });
  });

  group('Sleep progresses through 4-7-8', () {
    test('its unequal phases land where they should', () {
      expect(at(sleep, 0).phase, BreathingPhase.inhale);
      expect(at(sleep, 4).phase, BreathingPhase.hold);
      expect(at(sleep, 10).phase, BreathingPhase.hold);
      expect(at(sleep, 11).phase, BreathingPhase.exhale);
      expect(at(sleep, 18.9).phase, BreathingPhase.exhale);
      // Nineteen seconds is a whole cycle.
      expect(at(sleep, 19).phase, BreathingPhase.inhale);
    });
  });

  group('Balance progresses from side to side', () {
    test('the whole cycle runs left, both, right, right, both, left', () {
      // 4 in, 4 hold, 6 out, 4 in, 4 hold, 6 out — 28 seconds.
      expect(balance.cycleLength, const Duration(seconds: 28));

      const expected = [
        (1.0, Nostril.left, BreathingPhase.inhale),
        (5.0, Nostril.both, BreathingPhase.hold),
        (10.0, Nostril.right, BreathingPhase.exhale),
        (15.0, Nostril.right, BreathingPhase.inhale),
        (19.0, Nostril.both, BreathingPhase.hold),
        (24.0, Nostril.left, BreathingPhase.exhale),
      ];

      for (final (seconds, nostril, phase) in expected) {
        final moment = at(balance, seconds);
        expect(moment.nostril, nostril, reason: 'at ${seconds}s');
        expect(moment.phase, phase, reason: 'at ${seconds}s');
      }
    });

    test('the sides swap over on the second half, not the first', () {
      // The first exhale is on the right; the second is on the left. If
      // the pattern were collapsed to inhale/hold/exhale this would be
      // impossible to express, let alone to check.
      expect(at(balance, 10).nostril, Nostril.right);
      expect(at(balance, 24).nostril, Nostril.left);
    });

    test('the two holds are different moments', () {
      // They read alike, so only the step index tells them apart — which
      // is why the presentation needs it to know a step has changed.
      final first = at(balance, 5);
      final second = at(balance, 19);
      expect(first.instruction, second.instruction);
      expect(first.stepIndex, isNot(second.stepIndex));
    });

    test('a second cycle repeats the first exactly', () {
      for (final seconds in [1, 5, 10, 15, 19, 24]) {
        expect(
          at(balance, seconds + 28).stepIndex,
          at(balance, seconds).stepIndex,
          reason: 'the cycle did not repeat at ${seconds}s',
        );
      }
    });
  });

  group('Balance counts its holds down', () {
    test('four, three, two, one', () {
      expect(at(balance, 4).countdown, 4);
      expect(at(balance, 5).countdown, 3);
      expect(at(balance, 6).countdown, 2);
      expect(at(balance, 7).countdown, 1);
      expect(at(balance, 7.9).countdown, 1);
    });

    test('the second hold counts down too', () {
      expect(at(balance, 18).countdown, 4);
      expect(at(balance, 21).countdown, 1);
    });

    test('nothing else counts', () {
      for (final seconds in [0, 2, 9, 12, 15, 25]) {
        expect(
          at(balance, seconds).countdown,
          isNull,
          reason: 'a countdown appeared at ${seconds}s',
        );
      }
    });
  });

  group('Release Tension alternates without a hold', () {
    test('in for four, out for six', () {
      expect(release.cycleLength, const Duration(seconds: 10));
      expect(at(release, 0).phase, BreathingPhase.inhale);
      expect(at(release, 3.9).phase, BreathingPhase.inhale);
      expect(at(release, 4).phase, BreathingPhase.exhale);
      expect(at(release, 9.9).phase, BreathingPhase.exhale);
      expect(at(release, 10).phase, BreathingPhase.inhale);
    });

    test('the guidance follows the breath', () {
      expect(at(release, 1).instruction, 'Deep inhale through the nose');
      expect(
        at(release, 6).instruction,
        'Exhale through the mouth with a haa sound, tongue out',
      );
    });
  });

  group('the shape of a breath', () {
    test('opens on the inhale, holds, and closes on the exhale', () {
      expect(at(focus, 0).openness, 0);
      expect(at(focus, 2).openness, closeTo(0.5, 1e-9));
      expect(at(focus, 3.999).openness, closeTo(1, 0.001));

      expect(at(focus, 4).openness, 1);
      expect(at(focus, 6).openness, 1);
      expect(at(focus, 7.999).openness, 1);

      expect(at(focus, 8).openness, 1);
      expect(at(focus, 10).openness, closeTo(0.5, 1e-9));
      expect(at(focus, 11.999).openness, closeTo(0, 0.001));
    });

    test('never leaves 0 to 1, and never jumps, in any practice', () {
      for (final (name, pattern) in [
        ('Focus', focus),
        ('Sleep', sleep),
        ('Balance', balance),
        ('Release Tension', release),
      ]) {
        // Two whole cycles, so the wrap is covered too.
        final span = pattern.cycleLength.inMilliseconds * 2;
        var previous = at(pattern, 0).openness;
        for (var ms = 0; ms <= span; ms += 50) {
          final openness = at(pattern, ms / 1000).openness;
          expect(openness, inInclusiveRange(0, 1), reason: '$name at ${ms}ms');
          // 50ms of the shortest phase in any practice is well under
          // this; anything larger would be a visible jump.
          expect(
            (openness - previous).abs(),
            lessThan(0.03),
            reason: '$name jumped at ${ms}ms',
          );
          previous = openness;
        }
      }
    });

    test('the same instant always gives the same answer', () {
      // The property the whole screen leans on: the orb and the words
      // come from this, so it cannot depend on how it was reached.
      const instant = Duration(milliseconds: 7321);
      expect(balance.momentAt(instant), balance.momentAt(instant));
    });

    test('a negative elapsed is the very start, not the middle', () {
      // Which is what the settling second hands it.
      final moment = focus.momentAt(const Duration(milliseconds: -400));
      expect(moment.stepIndex, 0);
      expect(moment.progress, 0);
      expect(moment.openness, 0);
    });
  });

  group('a practice nobody has written yet', () {
    // The architectural promise: the model does not know what the four
    // techniques look like, so a fifth needs no changes anywhere.
    const oneSided = BreathingPattern(
      steps: [
        BreathingStep(
          phase: BreathingPhase.inhale,
          duration: Duration(seconds: 3),
          instruction: 'In',
          nostril: Nostril.right,
        ),
        BreathingStep(
          phase: BreathingPhase.exhale,
          duration: Duration(seconds: 3),
          instruction: 'Out',
          nostril: Nostril.right,
          counted: true,
        ),
      ],
    );

    test('is handled by the same code', () {
      expect(oneSided.cycleLength, const Duration(seconds: 6));
      expect(
        oneSided.momentAt(const Duration(seconds: 1)).nostril,
        Nostril.right,
      );
      expect(oneSided.momentAt(const Duration(seconds: 1)).countdown, isNull);
      expect(oneSided.momentAt(const Duration(seconds: 4)).countdown, 2);
      expect(
        oneSided.momentAt(const Duration(seconds: 4)).spokenInstruction,
        'Out, 3 seconds',
      );
    });
  });
}
