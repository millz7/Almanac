import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import 'bleeding_record.dart';
import 'cycle_phase.dart';

export 'bleeding_record.dart';

/// The shortest and longest assumed cycle length the estimate allows, and
/// where it starts.
///
/// The bounds are there to keep the arithmetic sensible, not to say
/// anything about what a cycle should be: nothing in this feature judges
/// a length, and there is no "normal" anywhere in it.
const kMinCycleLength = 21;
const kMaxCycleLength = 40;
const kDefaultCycleLength = 28;

/// How many days of quiet before a new bleeding day is *offered* as the
/// start of a new period.
///
/// **A default, and only a default.** It decides what the editor
/// pre-selects when somebody records bleeding after a gap; it decides
/// nothing about what is stored. The toggle stays visible and the user
/// can always say otherwise, because a rule like this is a convenience
/// and not a medical fact.
const kNewEpisodeGapDays = 3;

/// Everything the Cycle feature stores: what the user recorded day by
/// day, the cycle length they estimate with, and a displayed-phase
/// override if they set one.
///
/// **Records are keyed by date.** The date is the id, so there is no
/// second way of naming a day and no second way for two names to
/// disagree.
///
/// The constructor normalises rather than validating loudly: records are
/// sorted by date and de-duplicated (the last one wins), the length is
/// clamped into range, and a period start on a spotting day is dropped —
/// spotting never begins a cycle, and enforcing that here means nothing
/// downstream has to remember it.
@immutable
class CycleData {
  CycleData({
    Iterable<CycleDayRecord> records = const [],
    int assumedCycleLength = kDefaultCycleLength,
    this.manualPhase,
  }) : records = _normalise(records),
       assumedCycleLength = assumedCycleLength.clamp(
         kMinCycleLength,
         kMaxCycleLength,
       );

  static final empty = CycleData();

  /// What the user recorded, earliest first. Actual, not estimated:
  /// everything in here was put there by them.
  final List<CycleDayRecord> records;

  /// The length the estimates are drawn with. Changing it changes only
  /// what is estimated — it never touches [records].
  final int assumedCycleLength;

  /// The phase the user said they are actually in, overriding the
  /// estimate for what is *displayed*.
  ///
  /// Never rewrites a record, a date or a day 1. Null means "use the
  /// automatic estimate".
  final CyclePhase? manualPhase;

  static List<CycleDayRecord> _normalise(Iterable<CycleDayRecord> records) {
    final byDate = <CalendarDate, CycleDayRecord>{};
    for (final record in records) {
      byDate[record.date] = record.level.canStartPeriod
          ? record
          // Spotting cannot be a day 1, whatever a caller or an old
          // stored line claims.
          : record.copyWith(isPeriodStart: false);
    }
    final sorted = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(sorted);
  }

  bool get isEmpty => records.isEmpty;
  bool get isNotEmpty => records.isNotEmpty;

  /// The days marked as the first day of a period, earliest first.
  ///
  /// Derived, not stored twice: a period start is a property of a
  /// bleeding day, so there is one list of days and no separate list of
  /// starts that could fall out of step with it.
  List<CalendarDate> get periodStarts => [
    for (final record in records)
      if (record.isPeriodStart) record.date,
  ];

  CycleDayRecord? recordOn(CalendarDate date) {
    for (final record in records) {
      if (record.date == date) return record;
    }
    return null;
  }

  BleedingLevel? levelOn(CalendarDate date) => recordOn(date)?.level;

  bool isPeriodStart(CalendarDate date) =>
      recordOn(date)?.isPeriodStart ?? false;

  /// The gaps between consecutive recorded period starts, earliest
  /// first.
  ///
  /// Observations, not a target and not an average to replace the user's
  /// own estimate with. Nothing in the app compares them to anything.
  List<int> get recordedLengths {
    final starts = periodStarts;
    return [
      for (var i = 1; i < starts.length; i++)
        starts[i].daysSince(starts[i - 1]),
    ];
  }

  /// Whether recording bleeding on [date] would read as the beginning of
  /// a new episode rather than a continuation of one.
  ///
  /// Used only to pre-select the toggle in the editor. True when nothing
  /// was recorded in the few days before, so the first day of a period
  /// is offered as a start and the second day of one is not.
  bool looksLikeNewEpisode(CalendarDate date) {
    for (var back = 1; back <= kNewEpisodeGapDays; back++) {
      if (recordOn(date.addDays(-back)) != null) return false;
    }
    return true;
  }

  /// Records or replaces one day.
  ///
  /// [isPeriodStart] is passed through as given — the caller has already
  /// asked the user, or taken [looksLikeNewEpisode] as its default. A
  /// spotting day's flag is dropped by the constructor.
  CycleData recording(
    CalendarDate date,
    BleedingLevel level, {
    bool isPeriodStart = false,
  }) => _with([
    ...records.where((record) => record.date != date),
    CycleDayRecord(date: date, level: level, isPeriodStart: isPeriodStart),
  ]);

  /// Removes a day's record entirely. "Nothing recorded" is the absence
  /// of a record, not a level of its own.
  CycleData clearing(CalendarDate date) =>
      _with(records.where((record) => record.date != date));

  /// Changes which bleeding day counts as cycle day 1.
  ///
  /// Only the flag moves; the bleeding records themselves are left
  /// exactly as the user entered them. Turning it off on a day simply
  /// leaves that day as recorded bleeding with no cycle counted from it.
  CycleData markingPeriodStart(CalendarDate date, {required bool isStart}) {
    final existing = recordOn(date);
    if (existing == null || !existing.level.canStartPeriod) return this;
    return _with([
      for (final record in records)
        if (record.date == date)
          record.copyWith(isPeriodStart: isStart)
        else
          record,
    ]);
  }

  CycleData withAssumedLength(int length) => CycleData(
    records: records,
    assumedCycleLength: length,
    manualPhase: manualPhase,
  );

  /// Sets or clears the displayed-phase override. Null means "use the
  /// automatic estimate".
  CycleData withManualPhase(CyclePhase? phase) => CycleData(
    records: records,
    assumedCycleLength: assumedCycleLength,
    manualPhase: phase,
  );

  /// Everything gone, back to the length the app starts with.
  CycleData get cleared => CycleData();

  /// A new period start clears a stale override: a new cycle has begun,
  /// so a phase the user chose during the last one is no longer about
  /// anything. Applied by the controller, not silently in here.
  CycleData _with(Iterable<CycleDayRecord> next) => CycleData(
    records: next,
    assumedCycleLength: assumedCycleLength,
    manualPhase: manualPhase,
  );

  @override
  bool operator ==(Object other) =>
      other is CycleData &&
      other.assumedCycleLength == assumedCycleLength &&
      other.manualPhase == manualPhase &&
      listEquals(other.records, records);

  @override
  int get hashCode =>
      Object.hash(assumedCycleLength, manualPhase, Object.hashAll(records));

  /// Deliberately says how much is here and nothing about what.
  @override
  String toString() =>
      'CycleData(${records.length} recorded, '
      '$assumedCycleLength-day estimate)';
}
