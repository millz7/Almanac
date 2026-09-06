import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The phases of a technique's cycle, in order, as (phase, seconds).
  List<(BreathingPhase, int)> shapeOf(MeditationTechnique technique) => [
    for (final step in technique.pattern.steps)
      (step.phase, step.duration.inSeconds),
  ];

  group('the four practices', () {
    test('are Focus, Sleep, Balance and Release Tension, in that order', () {
      expect(MeditationTechniques.all.map((t) => t.name).toList(), [
        'Focus',
        'Sleep',
        'Balance',
        'Release Tension',
      ]);
    });

    test('each has one short line to choose by', () {
      for (final technique in MeditationTechniques.all) {
        expect(technique.description, isNotEmpty);
        expect(
          technique.description.length,
          lessThan(70),
          reason: '${technique.name} is being explained, not offered',
        );
      }
    });

    test('every id resolves to exactly one practice', () {
      for (final id in TechniqueId.values) {
        expect(MeditationTechniques.byId(id).id, id);
      }
      expect(MeditationTechniques.all.length, TechniqueId.values.length);
    });

    test('every step says what to do', () {
      for (final technique in MeditationTechniques.all) {
        for (final step in technique.pattern.steps) {
          expect(
            step.instruction,
            isNotEmpty,
            reason: '${technique.name} has a step with nothing to say',
          );
        }
      }
    });

    test('no practice claims to treat anything', () {
      // Descriptions say what the breathing is, never what it will do to
      // you.
      const clinical = [
        'cure',
        'treat',
        'heal',
        'anxiety',
        'depression',
        'insomnia',
        'blood pressure',
        'therapy',
        'therapeutic',
      ];
      for (final technique in MeditationTechniques.all) {
        final text = '${technique.name} ${technique.description}'.toLowerCase();
        for (final word in clinical) {
          expect(
            text,
            isNot(contains(word)),
            reason: '${technique.name} makes a claim it should not',
          );
        }
      }
    });
  });

  group('Focus', () {
    final focus = MeditationTechniques.focus;

    test('is a square: four in, four held, four out', () {
      expect(shapeOf(focus), [
        (BreathingPhase.inhale, 4),
        (BreathingPhase.hold, 4),
        (BreathingPhase.exhale, 4),
      ]);
      expect(focus.pattern.cycleLength, const Duration(seconds: 12));
    });

    test('needs no nostrils and no counting', () {
      for (final step in focus.pattern.steps) {
        expect(step.nostril, isNull);
        expect(step.counted, isFalse);
      }
    });

    test('says its timings out loud, because the timing is the practice', () {
      expect(focus.pattern.steps.map((s) => s.spokenInstruction).toList(), [
        'Breathe in, 4 seconds',
        'Hold, 4 seconds',
        'Breathe out, 4 seconds',
      ]);
    });
  });

  group('Sleep', () {
    final sleep = MeditationTechniques.sleep;

    test('is four in, seven held, eight out', () {
      expect(shapeOf(sleep), [
        (BreathingPhase.inhale, 4),
        (BreathingPhase.hold, 7),
        (BreathingPhase.exhale, 8),
      ]);
      expect(sleep.pattern.cycleLength, const Duration(seconds: 19));
    });

    test('breathes out for twice as long as it breathes in', () {
      expect(
        sleep.pattern.steps.last.duration,
        sleep.pattern.steps.first.duration * 2,
      );
    });

    test('announces its holds with their length', () {
      expect(sleep.pattern.steps.map((s) => s.spokenInstruction).toList(), [
        'Breathe in, 4 seconds',
        'Hold, 7 seconds',
        'Breathe out, 8 seconds',
      ]);
    });
  });

  group('Balance', () {
    final balance = MeditationTechniques.balance;

    test('is a full six steps: both sides, not one', () {
      // Reducing this to inhale/hold/exhale would throw away the
      // practice.
      expect(balance.pattern.steps.length, 6);
    });

    test('runs left in, hold, right out, right in, hold, left out', () {
      expect(
        [for (final step in balance.pattern.steps) (step.phase, step.nostril)],
        [
          (BreathingPhase.inhale, Nostril.left),
          (BreathingPhase.hold, Nostril.both),
          (BreathingPhase.exhale, Nostril.right),
          (BreathingPhase.inhale, Nostril.right),
          (BreathingPhase.hold, Nostril.both),
          (BreathingPhase.exhale, Nostril.left),
        ],
      );
    });

    test('holds for four seconds, with both nostrils closed', () {
      final holds = balance.pattern.steps.where(
        (step) => step.phase == BreathingPhase.hold,
      );
      expect(holds.length, 2);
      for (final hold in holds) {
        expect(hold.duration, const Duration(seconds: 4));
        expect(hold.nostril, Nostril.both);
      }
    });

    test('counts the holds down, and nothing else', () {
      for (final step in balance.pattern.steps) {
        expect(
          step.counted,
          step.phase == BreathingPhase.hold,
          reason:
              '${step.instruction} should${step.counted ? ' not' : ''} '
              'be counted',
        );
      }
    });

    test('names the side in every instruction', () {
      expect(balance.pattern.steps.map((s) => s.spokenInstruction).toList(), [
        'Inhale through the left nostril',
        'Hold with both nostrils closed, 4 seconds',
        'Exhale through the right nostril',
        'Inhale through the right nostril',
        'Hold with both nostrils closed, 4 seconds',
        'Exhale through the left nostril',
      ]);
    });

    test('the exhale is longer than the inhale, on both sides', () {
      final steps = balance.pattern.steps;
      expect(steps[2].duration, greaterThan(steps[0].duration));
      expect(steps[5].duration, greaterThan(steps[3].duration));
    });

    test('the two halves mirror each other', () {
      final steps = balance.pattern.steps;
      for (var index = 0; index < 3; index++) {
        expect(steps[index].phase, steps[index + 3].phase);
        expect(steps[index].duration, steps[index + 3].duration);
      }
    });
  });

  group('Release Tension', () {
    final release = MeditationTechniques.releaseTension;

    test('is a deep breath in and a long breath out, with no hold', () {
      expect(release.pattern.steps.length, 2);
      expect(release.pattern.steps.first.phase, BreathingPhase.inhale);
      expect(release.pattern.steps.last.phase, BreathingPhase.exhale);
      expect(
        release.pattern.steps.any((s) => s.phase == BreathingPhase.hold),
        isFalse,
      );
    });

    test('the out-breath is the longer of the two', () {
      expect(
        release.pattern.steps.last.duration,
        greaterThan(release.pattern.steps.first.duration),
      );
    });

    test('says through the nose in, and mouth, tongue and haa out', () {
      expect(
        release.pattern.steps.first.spokenInstruction,
        'Deep inhale through the nose',
      );
      expect(
        release.pattern.steps.last.spokenInstruction,
        'Exhale through the mouth with a haa sound, tongue out',
      );
    });

    test('needs no nostrils and no counting', () {
      for (final step in release.pattern.steps) {
        expect(step.nostril, isNull);
        expect(step.counted, isFalse);
      }
    });
  });

  group('session length', () {
    test('four minutes is the default', () {
      expect(kDefaultSessionMinutes, 4);
    });

    test('the range is wide enough to be useful, narrow enough to step', () {
      expect(kMinSessionMinutes, lessThan(kDefaultSessionMinutes));
      expect(kMaxSessionMinutes, greaterThan(kDefaultSessionMinutes));
      expect(kMaxSessionMinutes - kMinSessionMinutes, lessThanOrEqualTo(30));
    });

    test('the settling pause is exactly one second', () {
      expect(kSettlingPause, const Duration(seconds: 1));
    });
  });
}
