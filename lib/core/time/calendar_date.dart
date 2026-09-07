import 'package:flutter/foundation.dart';

/// A day on the calendar, with no time and no time zone.
///
/// Some things the app records are instants — a sunrise is a moment, and
/// it belongs in a [DateTime]. Other things are *dates*: the day a period
/// began is the fifteenth of July wherever the phone happens to be, and
/// storing it as an instant is how a date ends up shifting to the day
/// before because somebody flew west or the clocks went back. This type
/// exists so those two ideas cannot be confused.
///
/// Arithmetic goes through UTC internally — never local time — so adding
/// a day is always exactly a day and no daylight-saving change can make
/// it 23 hours or 25. Nothing here reads the clock, and nothing here
/// knows about location or time zones: turning "now" into a date is the
/// caller's job, done once, at the edge.
@immutable
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  /// The calendar date [moment] falls on, as that moment's own clock sees
  /// it. Callers holding a UTC instant should convert with `toLocal()`
  /// first, deliberately, rather than leaving it to chance.
  factory CalendarDate.from(DateTime moment) =>
      CalendarDate(moment.year, moment.month, moment.day);

  /// Reads `YYYY-MM-DD`, and nothing else. Returns null rather than
  /// throwing: a stored value that has been corrupted or hand-edited
  /// should be dropped, not crash the feature that reads it.
  static CalendarDate? tryParse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1) return null;
    if (day > _daysIn(year, month)) return null;

    return CalendarDate(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  /// `YYYY-MM-DD`. The one format anything stored on disk uses, because
  /// it is unambiguous, sorts correctly as text, and cannot be mistaken
  /// for an American date.
  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Midnight on this date in the device's own time zone.
  ///
  /// Only for handing a date to something that insists on a [DateTime] —
  /// Material's date picker, for instance. Never for arithmetic.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  /// This date at midnight UTC, which is how all the arithmetic below is
  /// done.
  DateTime get _utc => DateTime.utc(year, month, day);

  /// Day of the week, 1 (Monday) to 7 (Sunday), matching [DateTime].
  int get weekday => _utc.weekday;

  int get daysInMonth => _daysIn(year, month);

  CalendarDate get firstOfMonth => CalendarDate(year, month, 1);

  /// The same date [days] later, or earlier for a negative number.
  /// Rolls over months and years, and handles leap years.
  CalendarDate addDays(int days) =>
      CalendarDate.from(_utc.add(Duration(days: days)));

  CalendarDate addMonths(int months) {
    final total = (year * 12 + month - 1) + months;
    final nextYear = total ~/ 12;
    final nextMonth = total % 12 + 1;
    // Clamped, so a month away from the 31st lands on the 30th rather
    // than spilling into the following month.
    final nextDay = day.clamp(1, _daysIn(nextYear, nextMonth));
    return CalendarDate(nextYear, nextMonth, nextDay);
  }

  /// How many days from [other] to this date. Positive when this date is
  /// the later one.
  int daysSince(CalendarDate other) => _utc.difference(other._utc).inDays;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;
  bool isAfter(CalendarDate other) => compareTo(other) > 0;
  bool isOnOrBefore(CalendarDate other) => compareTo(other) <= 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}

int _daysIn(int year, int month) {
  const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month == 2 && _isLeapYear(year)) return 29;
  return lengths[month - 1];
}

bool _isLeapYear(int year) =>
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
