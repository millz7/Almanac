import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/core/time/date_words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a calendar date', () {
    test('is a day, with no time and no zone', () {
      const date = CalendarDate(2026, 9, 7);
      expect(date.year, 2026);
      expect(date.month, 9);
      expect(date.day, 7);
      expect(date.iso, '2026-09-07');
      expect(date.toString(), '2026-09-07');
    });

    test('comes from the day a moment falls on', () {
      expect(
        CalendarDate.from(DateTime(2026, 9, 7, 23, 59)),
        const CalendarDate(2026, 9, 7),
      );
      expect(
        CalendarDate.from(DateTime(2026, 9, 8, 0, 1)),
        const CalendarDate(2026, 9, 8),
      );
    });

    test('is equal to another of the same day', () {
      expect(const CalendarDate(2026, 9, 7), const CalendarDate(2026, 9, 7));
      expect(
        const CalendarDate(2026, 9, 7).hashCode,
        const CalendarDate(2026, 9, 7).hashCode,
      );
      expect(
        const CalendarDate(2026, 9, 7),
        isNot(const CalendarDate(2026, 9, 8)),
      );
    });

    test('sorts and compares in calendar order', () {
      final dates = [
        const CalendarDate(2026, 1, 2),
        const CalendarDate(2025, 12, 31),
        const CalendarDate(2026, 1, 1),
      ]..sort();

      expect(dates.map((d) => d.iso), [
        '2025-12-31',
        '2026-01-01',
        '2026-01-02',
      ]);
      expect(
        const CalendarDate(
          2025,
          12,
          31,
        ).isBefore(const CalendarDate(2026, 1, 1)),
        isTrue,
      );
      expect(
        const CalendarDate(
          2026,
          1,
          1,
        ).isAfter(const CalendarDate(2025, 12, 31)),
        isTrue,
      );
      expect(
        const CalendarDate(
          2026,
          1,
          1,
        ).isOnOrBefore(const CalendarDate(2026, 1, 1)),
        isTrue,
      );
    });
  });

  group('adding days', () {
    test('rolls over months and years', () {
      expect(const CalendarDate(2026, 1, 31).addDays(1).iso, '2026-02-01');
      expect(const CalendarDate(2026, 12, 31).addDays(1).iso, '2027-01-01');
      expect(const CalendarDate(2026, 3, 1).addDays(-1).iso, '2026-02-28');
    });

    test('handles leap years', () {
      expect(const CalendarDate(2028, 2, 28).addDays(1).iso, '2028-02-29');
      expect(const CalendarDate(2026, 2, 28).addDays(1).iso, '2026-03-01');
      expect(const CalendarDate(2028, 2, 1).daysInMonth, 29);
      expect(const CalendarDate(2100, 2, 1).daysInMonth, 28);
      expect(const CalendarDate(2000, 2, 1).daysInMonth, 29);
    });

    test('is exact across a daylight-saving change', () {
      // The reason this type exists. British clocks go forward on the
      // last Sunday in March; adding a day must still be a day.
      const before = CalendarDate(2026, 3, 28);
      expect(before.addDays(1).iso, '2026-03-29');
      expect(before.addDays(2).iso, '2026-03-30');
      expect(const CalendarDate(2026, 3, 30).daysSince(before), 2);
      // And in the autumn, when a local day is 25 hours long.
      const october = CalendarDate(2026, 10, 24);
      expect(october.addDays(2).daysSince(october), 2);
    });

    test('counts the days between two dates', () {
      expect(
        const CalendarDate(
          2026,
          2,
          12,
        ).daysSince(const CalendarDate(2026, 1, 15)),
        28,
      );
      expect(
        const CalendarDate(
          2026,
          1,
          15,
        ).daysSince(const CalendarDate(2026, 2, 12)),
        -28,
      );
      expect(
        const CalendarDate(
          2026,
          1,
          15,
        ).daysSince(const CalendarDate(2026, 1, 15)),
        0,
      );
    });
  });

  group('adding months', () {
    test('walks the calendar', () {
      expect(const CalendarDate(2026, 9, 7).addMonths(1).iso, '2026-10-07');
      expect(const CalendarDate(2026, 12, 7).addMonths(1).iso, '2027-01-07');
      expect(const CalendarDate(2026, 1, 7).addMonths(-1).iso, '2025-12-07');
    });

    test('clamps rather than spilling into the next month', () {
      expect(const CalendarDate(2026, 1, 31).addMonths(1).iso, '2026-02-28');
      expect(const CalendarDate(2026, 3, 31).addMonths(-1).iso, '2026-02-28');
    });
  });

  group('reading a stored date', () {
    test('accepts YYYY-MM-DD', () {
      expect(
        CalendarDate.tryParse('2026-09-07'),
        const CalendarDate(2026, 9, 7),
      );
      expect(
        CalendarDate.tryParse('2028-02-29'),
        const CalendarDate(2028, 2, 29),
      );
    });

    test('refuses anything else, without throwing', () {
      for (final bad in [
        '',
        'today',
        '2026-9-7',
        '07-09-2026',
        '2026-13-01',
        '2026-00-10',
        '2026-02-30',
        '2026-02-29', // 2026 is not a leap year
        '2026-09-07T12:00:00Z',
      ]) {
        expect(CalendarDate.tryParse(bad), isNull, reason: bad);
      }
    });

    test('survives a round trip', () {
      for (final date in [
        const CalendarDate(2026, 1, 1),
        const CalendarDate(2026, 12, 31),
        const CalendarDate(2028, 2, 29),
      ]) {
        expect(CalendarDate.tryParse(date.iso), date);
      }
    });
  });

  group('the words for a date', () {
    test('name the day, the month and the year', () {
      // 7 September 2026 is a Monday.
      const date = CalendarDate(2026, 9, 7);
      expect(date.weekday, DateTime.monday);
      expect(formatDate(date), 'Monday 7 September');
      expect(formatShortDate(date), '7 September');
      expect(formatMonth(date), 'September 2026');
      expect(weekdayName(DateTime.sunday), 'Sunday');
      expect(monthName(12), 'December');
    });

    test('the first of a month knows where it starts', () {
      expect(const CalendarDate(2026, 9, 7).firstOfMonth.iso, '2026-09-01');
      expect(const CalendarDate(2026, 9, 1).weekday, DateTime.tuesday);
    });
  });
}
