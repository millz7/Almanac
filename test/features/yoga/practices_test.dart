import 'package:almanac/features/yoga/domain/yoga_practices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the three practices', () {
    test('are Morning, Ground and Unwind, in that order', () {
      expect(YogaPractices.all.map((p) => p.name).toList(), [
        'Morning',
        'Ground',
        'Unwind',
      ]);
    });

    test('have distinct ids, and every id resolves', () {
      final ids = YogaPractices.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final id in YogaPracticeId.values) {
        expect(YogaPractices.byId(id).id, id);
      }
      expect(YogaPractices.all.length, YogaPracticeId.values.length);
    });

    test('each has one short line to choose by', () {
      for (final practice in YogaPractices.all) {
        expect(practice.description, isNotEmpty);
        expect(
          practice.description.length,
          lessThan(70),
          reason: '${practice.name} is being explained, not offered',
        );
      }
    });

    test('each has a sequence, and none is empty', () {
      for (final practice in YogaPractices.all) {
        expect(
          practice.sequence,
          isNotEmpty,
          reason: '${practice.name} has nothing to do',
        );
      }
    });

    test('each is five or six minutes — short enough to actually do', () {
      for (final practice in YogaPractices.all) {
        expect(
          practice.approximateMinutes,
          inInclusiveRange(5, 6),
          reason: '${practice.name} is ${practice.approximateMinutes} minutes',
        );
        // The advertised length is the real one.
        expect(
          practice.approximateMinutes,
          (practice.length.inSeconds / 60).round(),
        );
      }
    });

    test('no practice claims to treat anything', () {
      const clinical = [
        'cure',
        'treat',
        'heal',
        'anxiety',
        'depression',
        'insomnia',
        'back pain',
        'therapy',
        'therapeutic',
        'detox',
      ];
      for (final practice in YogaPractices.all) {
        final text = [
          practice.name,
          practice.description,
          for (final step in practice.sequence) step.instruction,
          for (final step in practice.sequence) step.breathNote ?? '',
        ].join(' ').toLowerCase();

        for (final word in clinical) {
          expect(
            text,
            isNot(contains(word)),
            reason: '${practice.name} makes a claim it should not',
          );
        }
      }
    });

    test('nothing competitive or gamified is said anywhere', () {
      const wrong = [
        'workout',
        'burn',
        'calorie',
        'streak',
        'score',
        'goal',
        'challenge',
        'level',
        'reps',
      ];
      for (final practice in YogaPractices.all) {
        final text = [
          practice.description,
          for (final step in practice.sequence) step.instruction,
        ].join(' ').toLowerCase();

        for (final word in wrong) {
          expect(text, isNot(contains(word)), reason: '"$word" in $text');
        }
      }
    });
  });

  group('every step of every practice', () {
    test('lasts a sensible, positive length of time', () {
      for (final practice in YogaPractices.all) {
        for (final step in practice.sequence) {
          expect(
            step.duration,
            greaterThan(Duration.zero),
            reason: '${practice.name}: ${step.name} has no duration',
          );
          expect(
            step.duration,
            greaterThanOrEqualTo(const Duration(seconds: 20)),
            reason: '${practice.name}: ${step.name} is too brief to settle',
          );
          expect(
            step.duration,
            lessThanOrEqualTo(const Duration(minutes: 2)),
            reason: '${practice.name}: ${step.name} is a very long hold',
          );
        }
      }
    });

    test('says what to do, in a whole sentence', () {
      for (final practice in YogaPractices.all) {
        for (final step in practice.sequence) {
          expect(step.pose, isNotEmpty);
          expect(
            step.instruction.length,
            greaterThan(20),
            reason: '${step.name} needs more than a label',
          );
          expect(
            step.instruction,
            endsWith('.'),
            reason: '${step.name} should read as a sentence',
          );
        }
      }
    });

    test('is either paced by a breath or has a note about it', () {
      // Never both: a step is counted or it is described.
      for (final practice in YogaPractices.all) {
        for (final step in practice.sequence) {
          expect(
            step.breathing == null || step.breathNote == null,
            isTrue,
            reason: '${step.name} tries to do both',
          );
          expect(
            step.breathing != null || step.breathNote != null,
            isTrue,
            reason: '${step.name} says nothing about the breath',
          );
        }
      }
    });

    test('a paced step reuses Meditation\'s own rhythm engine', () {
      final paced = [
        for (final practice in YogaPractices.all)
          for (final step in practice.sequence)
            if (step.breathing != null) step,
      ];
      expect(paced, isNotEmpty);

      for (final step in paced) {
        final pattern = step.breathing!;
        expect(pattern.steps, isNotEmpty);
        // Simple in-and-out only: no holds, no nostrils, no pranayama.
        expect(
          pattern.steps.any((s) => s.phase == BreathingPhase.hold),
          isFalse,
          reason: '${step.name} has a hold in it',
        );
        expect(pattern.cycleLength, lessThanOrEqualTo(step.duration));
      }
    });

    test('a pose with a side appears once each way', () {
      for (final practice in YogaPractices.all) {
        final sided = practice.sequence.where((step) => step.side != null);
        final byPose = <String, Set<BodySide>>{};
        for (final step in sided) {
          byPose.putIfAbsent(step.pose, () => {}).add(step.side!);
        }
        byPose.forEach((pose, sides) {
          expect(sides, {
            BodySide.left,
            BodySide.right,
          }, reason: '${practice.name}: $pose is only done one way');
        });
      }
    });

    test('nothing needs to be upside down or balanced on one leg', () {
      // The shape vocabulary is the guard: there is no shape for a
      // headstand or a one-legged balance, so a sequence cannot ask for
      // one by accident.
      const gentle = {
        PoseShape.seated,
        PoseShape.standing,
        PoseShape.folded,
        PoseShape.allFours,
        PoseShape.curled,
        PoseShape.sideBend,
        PoseShape.lunge,
        PoseShape.twist,
        PoseShape.lying,
      };
      expect(PoseShape.values.toSet(), gentle);

      for (final practice in YogaPractices.all) {
        for (final step in practice.sequence) {
          expect(gentle, contains(step.shape));
        }
      }
    });
  });

  group('the moods are different', () {
    test('Morning gets up off the floor; Unwind ends on it', () {
      expect(
        YogaPractices.morning.sequence.last.shape,
        PoseShape.lunge,
        reason: 'Morning should finish on its feet',
      );
      expect(
        YogaPractices.unwind.sequence.last.shape,
        PoseShape.lying,
        reason: 'Unwind should finish lying down',
      );
    });

    test('Ground is the longest and slowest', () {
      for (final other in [YogaPractices.morning, YogaPractices.unwind]) {
        expect(
          YogaPractices.ground.length,
          greaterThan(other.length),
          reason: 'Ground should be the longest',
        );
      }
    });

    test('every practice begins by sitting and breathing', () {
      for (final practice in YogaPractices.all) {
        final first = practice.sequence.first;
        expect(first.shape, PoseShape.seated);
        expect(
          first.breathing,
          isNotNull,
          reason: '${practice.name} should start with the breath',
        );
      }
    });
  });
}
