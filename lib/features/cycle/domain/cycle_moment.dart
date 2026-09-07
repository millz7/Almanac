import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import 'cycle_data.dart';
import 'cycle_phase.dart';

/// A span of dates, inclusive at both ends.
@immutable
class DateRange {
  const DateRange(this.from, this.to);

  final CalendarDate from;
  final CalendarDate to;

  bool contains(CalendarDate date) => !date.isBefore(from) && !date.isAfter(to);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => '${from.iso}..${to.iso}';
}

/// Which cycle days a phase covers, under one assumed length.
@immutable
class CyclePhaseSpan {
  const CyclePhaseSpan(this.phase, this.firstDay, this.lastDay);

  final CyclePhase phase;
  final int firstDay;
  final int lastDay;

  int get days => lastDay - firstDay + 1;
  bool contains(int day) => day >= firstDay && day <= lastDay;

  /// "days 6 to 13", or "day 6" when it is only one.
  String get dayRange =>
      firstDay == lastDay ? 'day $firstDay' : 'days $firstDay to $lastDay';

  @override
  bool operator ==(Object other) =>
      other is CyclePhaseSpan &&
      other.phase == phase &&
      other.firstDay == firstDay &&
      other.lastDay == lastDay;

  @override
  int get hashCode => Object.hash(phase, firstDay, lastDay);

  @override
  String toString() => '${phase.name} $dayRange';
}

/// Where a cycle has got to on one particular day.
///
/// Everything here is derived — see `cycle_calculator.dart` — and split
/// cleanly into what was **recorded** ([recordedStart], [currentDay],
/// [recordedLengths]) and what is only **estimated** ([phase],
/// [estimatedNextStart], [estimatedOvulatoryWindow]). The screens lean on
/// that split: recorded things are stated, estimated things are labelled.
@immutable
class CycleMoment {
  const CycleMoment({
    required this.today,
    required this.assumedCycleLength,
    required this.recordedStart,
    required this.currentDay,
    required this.phase,
    required this.estimatedNextStart,
    required this.estimatedOvulatoryWindow,
    required this.recordedLengths,
    required this.hasRecords,
  });

  /// The day this was worked out for. Injected, never read from a clock.
  final CalendarDate today;

  final int assumedCycleLength;

  /// The recorded start the current cycle is counted from: the most
  /// recent one on or before [today]. Null when there is nothing to count
  /// from yet.
  final CalendarDate? recordedStart;

  /// Day 1 is the recorded start itself. Null when there is no cycle to
  /// be on — nothing recorded, or every recorded date still in the
  /// future.
  final int? currentDay;

  /// The approximate phase, or null when there is no current cycle.
  final CyclePhase? phase;

  /// When the next period would begin if this cycle ran exactly as long
  /// as the estimate. It very often will not.
  final CalendarDate? estimatedNextStart;

  /// A three-day window, not a claimed day. The app does not know when
  /// or whether anybody ovulates.
  final DateRange? estimatedOvulatoryWindow;

  /// Gaps between consecutive recorded starts, earliest first.
  final List<int> recordedLengths;

  /// Whether anything at all has been recorded, including dates in the
  /// future that no current cycle can be counted from.
  final bool hasRecords;

  bool get hasCurrentCycle => currentDay != null;

  /// True when today is further into the cycle than the estimate
  /// allowed for. Not a problem, and never presented as one.
  bool get pastEstimate =>
      currentDay != null && currentDay! > assumedCycleLength;

  /// Whether the chosen length is far enough from the middle of the
  /// allowed range that this simple model is stretching.
  ///
  /// Not a judgement about the cycle — nothing in this feature judges a
  /// cycle — but a reason for the screen to be even more careful about
  /// how it words an estimate. The bounds are the two ends of the range
  /// the model was described for.
  bool get unusualForModel =>
      assumedCycleLength < 24 || assumedCycleLength > 34;

  /// How far through the estimated cycle today is, 0 to 1, for the
  /// drawing. Holds at 1 once the estimate has been passed.
  double get progress => currentDay == null
      ? 0
      : ((currentDay! - 1) / assumedCycleLength).clamp(0.0, 1.0);

  /// "Cycle day 12" — the one number this screen is really about.
  String get dayLine =>
      currentDay == null ? 'No cycle recorded' : 'Cycle day $currentDay';

  /// The whole of the estimate's basis, said plainly.
  String get estimateLine => 'Using a $assumedCycleLength-day estimate';

  /// The phases of a cycle of this length, in order.
  List<CyclePhaseSpan> get phases => phaseSpansFor(assumedCycleLength);

  /// The next few estimated period starts, after the recorded one.
  ///
  /// Never before it: with one recorded date there is no history to
  /// invent, and the app does not invent any.
  List<CalendarDate> estimatedStarts(int count) {
    final start = recordedStart;
    if (start == null) return const [];
    return [
      for (var i = 1; i <= count; i++) start.addDays(assumedCycleLength * i),
    ];
  }

  @override
  String toString() =>
      'CycleMoment(day $currentDay of $assumedCycleLength, '
      '${phase?.name ?? 'no phase'})';
}

/// Where each phase falls in a cycle of [length] days.
///
/// **The model, in full.** It is deliberately simple arithmetic and it is
/// an educational approximation, not a biological prediction:
///
/// * **Menstrual** is days 1 to 5, always. Bleeding length is not
///   recorded, so this is a flat assumption rather than an observation.
/// * The **estimated ovulatory window** is three days beginning at
///   `length - 14`, which puts it at days 14 to 16 of a 28-day cycle.
///   The fourteen comes from the luteal phase being the more consistent
///   half in the literature; the window is three days wide rather than
///   one because a single claimed day would be a claim this app cannot
///   make.
/// * **Follicular** fills whatever is left between menstruation and that
///   window — days 6 to 13 of a 28-day cycle. In a short cycle that can
///   be a single day, which is what the arithmetic gives and is not
///   dressed up as anything else.
/// * **Luteal** runs from the day after the window to the end.
///
/// Nothing here calculates fertility, conception or pregnancy, and there
/// is a test that asserts this file contains no such arithmetic.
List<CyclePhaseSpan> phaseSpansFor(int length) {
  final cycle = length.clamp(kMinCycleLength, kMaxCycleLength);
  const menstrualEnd = 5;
  // Never allowed to collide with menstruation, whatever the length.
  final windowStart = (cycle - 14).clamp(menstrualEnd + 1, cycle);
  final windowEnd = (windowStart + 2).clamp(windowStart, cycle);

  return [
    const CyclePhaseSpan(CyclePhase.menstrual, 1, menstrualEnd),
    if (windowStart > menstrualEnd + 1)
      CyclePhaseSpan(CyclePhase.follicular, menstrualEnd + 1, windowStart - 1),
    CyclePhaseSpan(CyclePhase.ovulatory, windowStart, windowEnd),
    if (windowEnd < cycle)
      CyclePhaseSpan(CyclePhase.luteal, windowEnd + 1, cycle),
  ];
}
