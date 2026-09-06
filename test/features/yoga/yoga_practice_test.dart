import 'package:almanac/features/yoga/domain/yoga_practices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final morning = YogaPractices.morning;

  YogaMoment at(YogaPractice practice, num seconds) =>
      practice.momentAt(Duration(milliseconds: (seconds * 1000).round()));

  group('progressing through a sequence', () {
    test('starts on the first movement', () {
      final moment = at(morning, 0);
      expect(moment.stepNumber, 1);
      expect(moment.totalSteps, morning.sequence.length);
      expect(moment.name, 'Seated breathing');
      expect(moment.elapsedInStep, Duration.zero);
    });

    test('moves on when a movement\'s time is up', () {
      // Morning: 45, 30, 30, 60, 30, 45, 30, 30.
      expect(at(morning, 44).stepNumber, 1);
      expect(at(morning, 45).stepNumber, 2);
      expect(at(morning, 74).stepNumber, 2);
      expect(at(morning, 75).stepNumber, 3);
      expect(at(morning, 105).stepNumber, 4);
      expect(at(morning, 165).stepNumber, 5);
      expect(at(morning, 195).stepNumber, 6);
      expect(at(morning, 240).stepNumber, 7);
      expect(at(morning, 270).stepNumber, 8);
    });

    test('a movement owns its start and not its end', () {
      expect(at(morning, 44.999).stepNumber, 1);
      expect(at(morning, 45).stepNumber, 2);
    });

    test('walks the whole sequence in order, once each', () {
      final seen = <int>[];
      for (var second = 0; second < morning.length.inSeconds; second++) {
        final number = at(morning, second).stepNumber;
        if (seen.isEmpty || seen.last != number) seen.add(number);
      }
      expect(seen, [1, 2, 3, 4, 5, 6, 7, 8]);
    });

    test('holds on the last movement past the end', () {
      // So the final frame of a practice looks like the end of it rather
      // than like the beginning.
      final last = morning.sequence.length;
      expect(at(morning, morning.length.inSeconds).stepNumber, last);
      expect(at(morning, morning.length.inSeconds + 30).stepNumber, last);
    });

    test('a negative elapsed is the very start', () {
      final moment = at(morning, -5);
      expect(moment.stepNumber, 1);
      expect(moment.progress, 0);
    });

    test('the same instant always gives the same answer', () {
      const instant = Duration(milliseconds: 91_337);
      expect(morning.momentAt(instant), morning.momentAt(instant));
    });

    test('every practice can be walked end to end', () {
      for (final practice in YogaPractices.all) {
        for (var second = 0; second <= practice.length.inSeconds; second++) {
          final moment = at(practice, second);
          expect(moment.stepNumber, inInclusiveRange(1, moment.totalSteps));
          expect(moment.progress, inInclusiveRange(0, 1));
          expect(moment.secondsRemaining, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('the time left in a movement', () {
    test('counts down and stops at zero', () {
      // The first movement is 45 seconds long.
      expect(at(morning, 0).secondsRemaining, 45);
      expect(at(morning, 1).secondsRemaining, 44);
      expect(at(morning, 44.5).secondsRemaining, 1);
      expect(at(morning, 44.999).secondsRemaining, 1);
    });

    test('restarts with the next movement', () {
      // The second movement is 30 seconds long.
      expect(at(morning, 45).secondsRemaining, 30);
      expect(at(morning, 60).secondsRemaining, 15);
    });

    test('never goes negative, even past the end', () {
      expect(at(morning, morning.length.inSeconds + 60).secondsRemaining, 0);
      expect(
        at(morning, morning.length.inSeconds + 60).remainingInStep,
        Duration.zero,
      );
    });
  });

  group('the breath cue', () {
    test('follows the rhythm on a paced movement', () {
      // Seated breathing: four in, six out, from the start of the step.
      expect(at(morning, 0).breathCue, 'Breathe in');
      expect(at(morning, 3).breathCue, 'Breathe in');
      expect(at(morning, 4).breathCue, 'Breathe out');
      expect(at(morning, 9).breathCue, 'Breathe out');
      // And round again, ten seconds into the step.
      expect(at(morning, 10).breathCue, 'Breathe in');
    });

    test('is measured from the start of the step, not of the practice', () {
      // Cat cow begins 105 seconds in and flows four and four.
      expect(at(morning, 105).breathCue, 'Breathe in and lengthen');
      expect(at(morning, 109).breathCue, 'Breathe out and round');
      expect(at(morning, 113).breathCue, 'Breathe in and lengthen');
    });

    test('is the step\'s own note on a held movement', () {
      // The side stretch is held, with a note rather than a count.
      expect(at(morning, 50).breathCue, 'Slow and even.');
      expect(at(morning, 50).breath, isNull);
    });

    test(
      'openness moves on a flowing movement and is absent on a held one',
      () {
        // Cat cow: the figure follows the breath.
        expect(at(morning, 105).openness, 0);
        expect(at(morning, 107).openness, closeTo(0.5, 1e-9));
        expect(at(morning, 108.999).openness, closeTo(1, 0.001));

        // A side stretch is held, so there is nothing for the figure to
        // follow.
        expect(at(morning, 50).openness, isNull);
      },
    );
  });

  group('what a screen reader is told', () {
    test('names the pose, then says what to do', () {
      final moment = at(morning, 50);
      expect(
        moment.spokenInstruction,
        startsWith('Seated side stretch, left.'),
      );
      expect(moment.spokenInstruction, contains('Reach your left arm'));
      expect(moment.spokenInstruction, endsWith('Slow and even.'));
    });

    test('a pose with a side says which side, in its name', () {
      expect(at(morning, 50).name, 'Seated side stretch, left');
      expect(at(morning, 80).name, 'Seated side stretch, right');
      expect(at(morning, 240).name, 'Low lunge, left');
      expect(at(morning, 275).name, 'Low lunge, right');
    });

    test('a pose without a side is just its name', () {
      expect(at(morning, 0).name, 'Seated breathing');
      expect(at(morning, 120).name, 'Cat cow');
    });

    test('every step of every practice can be read out', () {
      for (final practice in YogaPractices.all) {
        var start = Duration.zero;
        for (final step in practice.sequence) {
          final spoken = practice.momentAt(start).spokenInstruction;
          expect(spoken, contains(step.pose));
          expect(spoken, contains(step.instruction));
          expect(spoken.length, greaterThan(30));
          start += step.duration;
        }
      }
    });
  });

  group('a practice nobody has written yet', () {
    // The architectural promise: the model does not know what the three
    // practices look like, so a fourth needs no changes anywhere.
    const invented = YogaPractice(
      id: YogaPracticeId.morning,
      name: 'Invented',
      description: 'Two movements.',
      sequence: [
        YogaStep(
          pose: 'Stand',
          duration: Duration(seconds: 10),
          instruction: 'Stand there.',
          shape: PoseShape.standing,
          breathNote: 'Whatever you like.',
        ),
        YogaStep(
          pose: 'Sit',
          duration: Duration(seconds: 20),
          instruction: 'Sit down.',
          shape: PoseShape.seated,
          breathNote: 'Still whatever you like.',
        ),
      ],
    );

    test('is handled by the same code', () {
      expect(invented.length, const Duration(seconds: 30));
      expect(invented.approximateMinutes, 1);
      expect(invented.momentAt(const Duration(seconds: 5)).stepNumber, 1);
      expect(invented.momentAt(const Duration(seconds: 15)).stepNumber, 2);
      expect(invented.momentAt(const Duration(seconds: 15)).totalSteps, 2);
      expect(
        invented.momentAt(const Duration(seconds: 15)).secondsRemaining,
        15,
      );
      expect(
        invented.momentAt(const Duration(seconds: 5)).spokenInstruction,
        'Stand. Stand there. Whatever you like.',
      );
    });
  });
}
