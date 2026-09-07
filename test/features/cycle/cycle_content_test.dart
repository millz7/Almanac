import 'dart:io';

import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/domain/cycle_calculator.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the wording', () {
    test('says the things the feature promised to say', () {
      expect(CycleText.introHeading, 'Your cycle, noticed.');
      expect(
        CycleText.introBody,
        'Record the first day of your period to begin noticing your cycle.',
      );
      expect(CycleText.recordToday, 'Record today');
      expect(CycleText.chooseAnotherDate, 'Choose another date');
      expect(CycleText.estimateBasis(28), 'Using a 28-day estimate');
      expect(CycleText.dayLine(12), 'Cycle day 12');
      expect(CycleText.deleteAllTitle, 'Delete your cycle history?');
      expect(
        CycleText.deleteAllBody,
        'Your recorded cycle dates will be removed from this device.',
      );
      expect(CycleText.delete, 'Delete');
      expect(CycleText.keep, 'Keep');
      expect(
        CycleText.experienceMayDiffer,
        'Your experience may be different.',
      );
    });

    test('every phase is named as an approximation', () {
      expect(CyclePhase.values.map((p) => p.label), [
        'Menstrual',
        'Follicular',
        'Ovulatory',
        'Luteal',
      ]);
      for (final phase in CyclePhase.values) {
        expect(phase.heading, startsWith('Approximate '));
        expect(phase.heading, endsWith(' phase'));
      }
      // Never a claim about a day, and never in the present tense about
      // the person reading it.
      expect(CyclePhase.ovulatory.heading, 'Approximate ovulatory phase');
    });

    test('the reflective lines are offered, never asserted', () {
      expect(CyclePhase.menstrual.reflection, 'A quieter beginning.');
      expect(
        CyclePhase.follicular.reflection,
        'Something is beginning to build.',
      );
      expect(
        CyclePhase.ovulatory.reflection,
        'A time often associated with outward energy.',
      );
      expect(
        CyclePhase.luteal.reflection,
        'A time often associated with turning inward.',
      );

      for (final phase in CyclePhase.values) {
        final line = phase.reflection.toLowerCase();
        // Nothing that tells somebody how they feel or how they will be.
        for (final assertion in [
          'you will',
          'you are',
          'you feel',
          'you may feel',
          'more emotional',
          'less productive',
          'energetic',
        ]) {
          expect(line.contains(assertion), isFalse, reason: phase.label);
        }
      }
    });

    test('an estimate is always labelled as one', () {
      expect(
        CycleText.estimatedWindow(DateRange(_july(14), _july(16))),
        'Estimated ovulatory window: 14 July to 16 July',
      );
      expect(
        CycleText.estimatedNextStart(_july(29)),
        'Estimated next start: Wednesday 29 July',
      );
      expect(CycleText.estimatedLegend, 'Estimated');
      expect(
        CycleText.estimatedDateLabel(_july(29), isToday: false),
        contains('Estimated period start'),
      );
      expect(
        CycleText.recordedDateLabel(_july(1), isToday: false),
        contains('Recorded period start'),
      );
    });

    test('makes no medical or clinical claim', () {
      const clinical = [
        'diagnose',
        'diagnosis',
        'disease',
        'cure',
        'heal',
        'treatment',
        'treat ',
        'hormone imbalance',
        'infertility',
        'infertile',
        'pregnancy prediction',
        'pregnant',
        'contraception',
        'contraceptive',
        'guaranteed ovulation',
        'guaranteed',
        'fertile window',
        'fertility',
        'symptom',
        'normal cycle',
        'abnormal',
        'unhealthy',
      ];

      for (final said in CycleText.everythingSaid) {
        final lower = said.toLowerCase();
        for (final word in clinical) {
          expect(
            lower.contains(word),
            isFalse,
            reason: '"$said" contains "$word"',
          );
        }
      }
    });

    test('makes nothing into a game', () {
      const gamified = [
        'score',
        'streak',
        'level',
        'achievement',
        'leaderboard',
        'reward',
        'badge',
        'goal',
        'challenge',
        'rank',
      ];

      for (final said in CycleText.everythingSaid) {
        final lower = said.toLowerCase();
        for (final word in gamified) {
          expect(
            lower.contains(word),
            isFalse,
            reason: '"$said" contains "$word"',
          );
        }
      }
    });

    test('never claims certainty about a body', () {
      for (final said in CycleText.everythingSaid) {
        final lower = said.toLowerCase();
        for (final overclaim in [
          'you are ovulating',
          'you ovulate',
          'will ovulate',
          'certain',
          'definitely',
          'accurate',
          'medically',
        ]) {
          expect(
            lower.contains(overclaim),
            isFalse,
            reason: '"$said" contains "$overclaim"',
          );
        }
      }
    });

    test(
      'says where the data lives, on the screen and not only in a report',
      () {
        expect(CycleText.privacyNote, contains('this device'));
        expect(CycleText.privacyNote, contains('Nothing is sent'));
        expect(CycleText.lengthNote, contains('recorded dates stay'));
        expect(CycleText.estimateCaution, contains('not a prediction'));
      },
    );
  });

  group('the feature as a whole', () {
    test('reaches no network and asks for no new permission', () {
      final sources = Directory('lib/features/cycle')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in sources) {
        final source = file.readAsStringSync();
        for (final forbidden in [
          'http',
          'HttpClient',
          'Socket',
          'geolocator',
          'Geolocator',
          'camera',
          'microphone',
          'Timer.periodic',
          'flutter_local_notifications',
        ]) {
          expect(
            source.contains(forbidden),
            isFalse,
            reason: '${file.path} mentions $forbidden',
          );
        }
      }
    });

    test('never prints a cycle date', () {
      // The only debugPrint in the feature reports the type of a failure
      // and nothing else. This is the test that keeps it that way.
      final sources = Directory('lib/features/cycle')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final interpolation = RegExp(r'\$\{?([A-Za-z0-9_.]+)\}?');

      for (final file in sources) {
        for (final line in file.readAsLinesSync()) {
          if (!line.contains('debugPrint') && !line.contains('print(')) {
            continue;
          }
          // Only what is interpolated matters: a message may contain the
          // word "data", but no value from the feature may be
          // substituted into it. A type name is safe to print; a date, a
          // list of dates, or anything holding them is not.
          for (final match in interpolation.allMatches(line)) {
            final expression = match.group(1)!;
            expect(
              expression.endsWith('runtimeType'),
              isTrue,
              reason: '${file.path} prints "$expression"',
            );
          }
        }
      }
    });
  });
}

CalendarDate _july(int day) => CalendarDate(2026, 7, day);
