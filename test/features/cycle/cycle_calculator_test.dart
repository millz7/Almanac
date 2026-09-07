import 'dart:io';

import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/domain/cycle_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed "today" for every test in this file. Nothing here reads a
/// clock, which is the whole point of the model.
const today = CalendarDate(2026, 9, 7);

CycleMoment momentWith({
  List<CalendarDate> starts = const [],
  int length = kDefaultCycleLength,
  CalendarDate on = today,
}) => cycleMomentAt(
  today: on,
  data: CycleData(periodStarts: starts, assumedCycleLength: length),
);

void main() {
  group('with nothing recorded', () {
    test('there is no cycle, and nothing pretends otherwise', () {
      final moment = momentWith();

      expect(moment.hasRecords, isFalse);
      expect(moment.hasCurrentCycle, isFalse);
      expect(moment.currentDay, isNull);
      expect(moment.phase, isNull);
      expect(moment.recordedStart, isNull);
      expect(moment.estimatedNextStart, isNull);
      expect(moment.estimatedOvulatoryWindow, isNull);
      expect(moment.recordedLengths, isEmpty);
      expect(moment.progress, 0);
      expect(moment.estimatedStarts(3), isEmpty);
    });
  });

  group('with one recorded start', () {
    test('the day it was recorded is day one', () {
      final moment = momentWith(starts: [today]);

      expect(moment.currentDay, 1);
      expect(moment.recordedStart, today);
      expect(moment.phase, CyclePhase.menstrual);
      expect(moment.dayLine, 'Cycle day 1');
    });

    test('the day after is day two', () {
      final moment = momentWith(starts: [today.addDays(-1)]);
      expect(moment.currentDay, 2);
    });

    test('counts on through the cycle', () {
      for (final day in [3, 6, 14, 16, 28, 29, 40]) {
        final moment = momentWith(starts: [today.addDays(-(day - 1))]);
        expect(moment.currentDay, day);
      }
    });

    test('there is no history to show from a single date', () {
      // One date is one date. No cycle length can be observed from it,
      // and none is invented.
      expect(momentWith(starts: [today]).recordedLengths, isEmpty);
    });

    test('estimates run forwards only', () {
      final moment = momentWith(starts: [const CalendarDate(2026, 9, 1)]);

      expect(moment.estimatedNextStart, const CalendarDate(2026, 9, 29));
      expect(moment.estimatedStarts(3).map((d) => d.iso), [
        '2026-09-29',
        '2026-10-27',
        '2026-11-24',
      ]);
    });
  });

  group('with several recorded starts', () {
    final starts = [
      const CalendarDate(2026, 6, 3),
      const CalendarDate(2026, 7, 1),
      const CalendarDate(2026, 8, 1),
      const CalendarDate(2026, 8, 28),
    ];

    test('the current cycle is counted from the most recent one', () {
      final moment = momentWith(starts: starts);

      expect(moment.recordedStart, const CalendarDate(2026, 8, 28));
      expect(moment.currentDay, 11);
      expect(moment.phase, CyclePhase.follicular);
    });

    test('observed lengths are the gaps between them', () {
      expect(momentWith(starts: starts).recordedLengths, [28, 31, 27]);
    });

    test('the observed lengths never become the estimate', () {
      // The user's chosen length stays the basis, whatever was
      // observed. Nothing averages anything behind their back.
      final moment = momentWith(starts: starts, length: 30);

      expect(moment.recordedLengths, [28, 31, 27]);
      expect(moment.assumedCycleLength, 30);
      expect(moment.estimatedNextStart, const CalendarDate(2026, 9, 27));
    });

    test('the order they were entered in makes no difference', () {
      final shuffled = momentWith(starts: starts.reversed.toList());
      expect(shuffled.recordedStart, const CalendarDate(2026, 8, 28));
      expect(shuffled.recordedLengths, [28, 31, 27]);
    });

    test('the same date twice is one date', () {
      final moment = momentWith(starts: [today, today, today.addDays(-28)]);
      expect(moment.recordedLengths, [28]);
    });
  });

  group('dates the current cycle cannot use', () {
    test('a start later than today is not counted from', () {
      final moment = momentWith(starts: [today.addDays(-4), today.addDays(3)]);

      // The later date is still recorded — the user put it there — but
      // a cycle cannot be counted from a day that has not happened.
      expect(moment.recordedStart, today.addDays(-4));
      expect(moment.currentDay, 5);
      expect(moment.recordedLengths, [7]);
    });

    test('a today before everything recorded has no current cycle', () {
      final moment = momentWith(
        starts: [const CalendarDate(2026, 9, 20)],
        on: const CalendarDate(2026, 9, 1),
      );

      expect(moment.hasRecords, isTrue);
      expect(moment.hasCurrentCycle, isFalse);
      expect(moment.currentDay, isNull);
      expect(moment.phase, isNull);
      expect(moment.dayLine, 'No cycle recorded');
    });
  });

  group('the assumed cycle length', () {
    test('starts at 28 days', () {
      expect(CycleData().assumedCycleLength, 28);
      expect(kDefaultCycleLength, 28);
    });

    test('cannot be set outside 21 to 40 days', () {
      expect(CycleData(assumedCycleLength: 3).assumedCycleLength, 21);
      expect(CycleData(assumedCycleLength: 20).assumedCycleLength, 21);
      expect(CycleData(assumedCycleLength: 41).assumedCycleLength, 40);
      expect(CycleData(assumedCycleLength: 400).assumedCycleLength, 40);
      expect(CycleData(assumedCycleLength: -7).assumedCycleLength, 21);
    });

    test('changing it leaves the recorded dates exactly as they were', () {
      final data = CycleData(periodStarts: [today.addDays(-30), today]);
      final relengthed = data.withAssumedLength(35);

      expect(relengthed.periodStarts, data.periodStarts);
      expect(relengthed.assumedCycleLength, 35);
      expect(data.assumedCycleLength, 28);
    });
  });

  group('the phase model', () {
    test('a 28-day cycle falls where the model says', () {
      expect(phaseSpansFor(28).map((s) => s.toString()), [
        'menstrual days 1 to 5',
        'follicular days 6 to 13',
        'ovulatory days 14 to 16',
        'luteal days 17 to 28',
      ]);
    });

    test('menstrual is days 1 to 5, whatever the length', () {
      for (final length in [21, 28, 34, 40]) {
        for (final day in [1, 2, 5]) {
          expect(phaseForDay(day, length), CyclePhase.menstrual);
        }
        expect(phaseForDay(6, length), isNot(CyclePhase.menstrual));
      }
    });

    test('the ovulatory window is three days, centred on length minus 14', () {
      for (final length in [21, 24, 28, 33, 40]) {
        final window = phaseSpansFor(length)
            .firstWhere((s) => s.phase == CyclePhase.ovulatory);

        expect(window.firstDay, length - 14, reason: '$length');
        expect(window.days, 3, reason: '$length');
        // Never a single claimed day, and never colliding with
        // menstruation.
        expect(window.firstDay, greaterThan(5));
      }
    });

    test('a 21-day cycle leaves a single follicular day', () {
      expect(phaseSpansFor(21).map((s) => s.toString()), [
        'menstrual days 1 to 5',
        'follicular day 6',
        'ovulatory days 7 to 9',
        'luteal days 10 to 21',
      ]);
      expect(phaseForDay(6, 21), CyclePhase.follicular);
      expect(phaseForDay(8, 21), CyclePhase.ovulatory);
      expect(phaseForDay(21, 21), CyclePhase.luteal);
    });

    test('a 40-day cycle stretches the follicular phase, not the window', () {
      expect(phaseSpansFor(40).map((s) => s.toString()), [
        'menstrual days 1 to 5',
        'follicular days 6 to 25',
        'ovulatory days 26 to 28',
        'luteal days 29 to 40',
      ]);
    });

    test('every day of every allowed length has exactly one phase', () {
      for (var length = kMinCycleLength; length <= kMaxCycleLength; length++) {
        final spans = phaseSpansFor(length);
        for (var day = 1; day <= length; day++) {
          final containing = spans.where((s) => s.contains(day));
          expect(containing, hasLength(1), reason: 'day $day of $length');
        }
        // And they cover the whole cycle with no gaps.
        expect(spans.fold(0, (sum, s) => sum + s.days), length);
      }
    });

    test('a day past the estimate stays luteal, and says so', () {
      final moment = momentWith(starts: [today.addDays(-30)]);

      expect(moment.currentDay, 31);
      expect(moment.phase, CyclePhase.luteal);
      expect(moment.pastEstimate, isTrue);
      expect(moment.progress, 1);
    });

    test('the wording is cautious at the edges of the model', () {
      expect(momentWith(starts: [today], length: 28).unusualForModel, isFalse);
      expect(momentWith(starts: [today], length: 21).unusualForModel, isTrue);
      expect(momentWith(starts: [today], length: 40).unusualForModel, isTrue);
    });
  });

  group('the estimated ovulatory window as dates', () {
    test('sits on the cycle days the model gives', () {
      final start = const CalendarDate(2026, 9, 1);
      final moment = momentWith(starts: [start], on: start);

      // Days 14 to 16 of a cycle beginning on 1 September.
      expect(
        moment.estimatedOvulatoryWindow,
        DateRange(
          const CalendarDate(2026, 9, 14),
          const CalendarDate(2026, 9, 16),
        ),
      );
      expect(
        moment.estimatedOvulatoryWindow!.contains(
          const CalendarDate(2026, 9, 15),
        ),
        isTrue,
      );
      expect(
        moment.estimatedOvulatoryWindow!.contains(
          const CalendarDate(2026, 9, 17),
        ),
        isFalse,
      );
    });

    test('moves with the assumed length', () {
      final start = const CalendarDate(2026, 9, 1);
      final moment = momentWith(starts: [start], on: start, length: 35);

      expect(
        moment.estimatedOvulatoryWindow,
        DateRange(
          const CalendarDate(2026, 9, 21),
          const CalendarDate(2026, 9, 23),
        ),
      );
    });
  });

  group('the calculation itself', () {
    test('is deterministic', () {
      final starts = [
        today.addDays(-56),
        today.addDays(-28),
        today.addDays(-3),
      ];

      final first = momentWith(starts: starts);
      final second = momentWith(starts: starts);

      expect(first.currentDay, second.currentDay);
      expect(first.phase, second.phase);
      expect(first.estimatedNextStart, second.estimatedNextStart);
      expect(first.estimatedOvulatoryWindow, second.estimatedOvulatoryWindow);
      expect(first.recordedLengths, second.recordedLengths);
      expect(first.progress, second.progress);
    });

    test('walks a whole cycle a day at a time', () {
      final start = const CalendarDate(2026, 9, 1);
      final phases = <CyclePhase>[];

      for (var day = 1; day <= 28; day++) {
        final moment = momentWith(starts: [start], on: start.addDays(day - 1));
        expect(moment.currentDay, day);
        phases.add(moment.phase!);
      }

      expect(phases.where((p) => p == CyclePhase.menstrual), hasLength(5));
      expect(phases.where((p) => p == CyclePhase.follicular), hasLength(8));
      expect(phases.where((p) => p == CyclePhase.ovulatory), hasLength(3));
      expect(phases.where((p) => p == CyclePhase.luteal), hasLength(12));
    });

    test('never reads a clock', () {
      // The model is a pure function of the day it is given. If this
      // ever fails, a test that walks a cycle stops being possible.
      final source = File('lib/features/cycle/domain/cycle_calculator.dart')
          .readAsStringSync();
      final moment = File('lib/features/cycle/domain/cycle_moment.dart')
          .readAsStringSync();

      for (final file in [source, moment]) {
        expect(file, isNot(contains('DateTime.now')));
        expect(file, isNot(contains('Random')));
        expect(file, isNot(contains('clockProvider')));
      }
    });

    test('predicts nothing about fertility, conception or pregnancy', () {
      // The line this feature does not cross, checked in the code
      // itself rather than only in the copy.
      for (final path in [
        'lib/features/cycle/domain/cycle_calculator.dart',
        'lib/features/cycle/domain/cycle_moment.dart',
        'lib/features/cycle/domain/cycle_phase.dart',
        'lib/features/cycle/domain/cycle_data.dart',
      ]) {
        final source = File(path).readAsStringSync().toLowerCase();
        for (final forbidden in [
          'fertile',
          'fertility',
          'conception',
          'conceive',
          'pregnan',
          'probability',
          'chance of',
          'contracept',
        ]) {
          // Mentioned in a comment saying it is not done is fine; a
          // field, getter or calculation is not. Nothing in these files
          // computes any of it, so the word appears only in prose.
          final offending = RegExp(
            '(double|int|bool|num)\\s+\\w*$forbidden',
            caseSensitive: false,
          );
          expect(
            offending.hasMatch(source),
            isFalse,
            reason: '$path declares something about "$forbidden"',
          );
        }
      }
    });
  });
}
