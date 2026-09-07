import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';

/// The shortest and longest assumed cycle length the estimate allows, and
/// where it starts.
///
/// The bounds are there to keep the arithmetic sensible, not to say
/// anything about what a cycle should be: nothing in this feature judges
/// a length, and there is no "normal" anywhere in it.
const kMinCycleLength = 21;
const kMaxCycleLength = 40;
const kDefaultCycleLength = 28;

/// Everything the Cycle feature stores: the dates the user recorded, and
/// the cycle length they chose to estimate with.
///
/// **A recorded period start is identified by its date.** There is no
/// separate id, because the date already is one — two records for the
/// same day are the same record, editing one is replacing a date, and
/// deleting one is removing a date. Anything more would be a second way
/// of saying the same thing, and a second way for the two to disagree.
///
/// The constructor normalises rather than validating loudly: dates are
/// sorted and de-duplicated, and the length is clamped into range. That
/// means nothing downstream — the calculator, the calendar, the store —
/// ever has to cope with an unsorted list, a duplicate, or a 3-day
/// cycle.
@immutable
class CycleData {
  CycleData({
    Iterable<CalendarDate> periodStarts = const [],
    int assumedCycleLength = kDefaultCycleLength,
  }) : periodStarts = List.unmodifiable(periodStarts.toSet().toList()..sort()),
       assumedCycleLength = assumedCycleLength.clamp(
         kMinCycleLength,
         kMaxCycleLength,
       );

  static final empty = CycleData();

  /// Recorded first days of a period, earliest first. Actual, not
  /// estimated: everything in here was put there by the user.
  final List<CalendarDate> periodStarts;

  /// The length the estimates are drawn with. Changing it changes only
  /// what is estimated — it never touches [periodStarts].
  final int assumedCycleLength;

  bool get isEmpty => periodStarts.isEmpty;
  bool get isNotEmpty => periodStarts.isNotEmpty;

  /// The gaps between consecutive recorded starts, earliest first.
  ///
  /// These are observations, not a target and not an average to replace
  /// the user's own estimate with. Nothing in the app compares them to
  /// anything.
  List<int> get recordedLengths => [
    for (var i = 1; i < periodStarts.length; i++)
      periodStarts[i].daysSince(periodStarts[i - 1]),
  ];

  CycleData withStart(CalendarDate date) => CycleData(
    periodStarts: [...periodStarts, date],
    assumedCycleLength: assumedCycleLength,
  );

  CycleData withoutStart(CalendarDate date) => CycleData(
    periodStarts: periodStarts.where((d) => d != date),
    assumedCycleLength: assumedCycleLength,
  );

  /// Replaces one recorded date with another, keeping everything else.
  CycleData replacingStart(CalendarDate from, CalendarDate to) =>
      withoutStart(from).withStart(to);

  CycleData withAssumedLength(int length) =>
      CycleData(periodStarts: periodStarts, assumedCycleLength: length);

  /// Everything gone, back to the length the app starts with.
  CycleData get cleared => CycleData();

  @override
  bool operator ==(Object other) =>
      other is CycleData &&
      other.assumedCycleLength == assumedCycleLength &&
      listEquals(other.periodStarts, periodStarts);

  @override
  int get hashCode =>
      Object.hash(assumedCycleLength, Object.hashAll(periodStarts));

  /// Deliberately says how much is here and nothing about what.
  ///
  /// Cycle dates are sensitive, and a `toString` is exactly how sensitive
  /// data ends up in a log line by accident.
  @override
  String toString() =>
      'CycleData(${periodStarts.length} recorded, '
      '$assumedCycleLength-day estimate)';
}
