import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';

/// How much bleeding the user recorded on a day.
///
/// Three levels and no fourth. There is deliberately no `none`: absence
/// of a record *is* "nothing recorded", so an empty day needs nothing
/// stored and clearing a day means removing its record rather than
/// writing a zero.
///
/// **Spotting is not bleeding.** It is stored as its own level, drawn as
/// its own smaller mark, and — the part that matters — it never begins a
/// cycle. See [CycleDayRecord.canStartPeriod].
enum BleedingLevel {
  spotting('Spotting'),
  bleeding('Bleeding'),
  heavy('Heavy bleeding');

  const BleedingLevel(this.label);

  final String label;

  /// Whether a day at this level may be marked as the first day of a
  /// period.
  ///
  /// Spotting cannot. Somebody may spot at any point in a month, and
  /// treating that as day 1 would silently restart their cycle — so the
  /// control is not offered for it, and the model refuses it even if it
  /// were.
  bool get canStartPeriod => this != BleedingLevel.spotting;

  static BleedingLevel? tryParse(String stored) {
    for (final level in BleedingLevel.values) {
      if (level.name == stored) return level;
    }
    return null;
  }
}

/// One day the user recorded something on.
///
/// Identified by its date, because the date already is an id: two
/// records for the same day are the same record, and changing one is
/// replacing it.
///
/// [isPeriodStart] is what the cycle is counted from, and it is the
/// user's to set. The app may offer a sensible default when a new
/// episode of bleeding begins, but it never hides the choice and never
/// claims its guess is authoritative — see `CycleData.recording`.
@immutable
class CycleDayRecord {
  const CycleDayRecord({
    required this.date,
    required this.level,
    this.isPeriodStart = false,
  });

  final CalendarDate date;
  final BleedingLevel level;

  /// Whether this day is the first day of a period — cycle day 1.
  ///
  /// Only ever true for a level that [BleedingLevel.canStartPeriod]
  /// allows; the constructor of [CycleData] enforces that rather than
  /// trusting callers.
  final bool isPeriodStart;

  CycleDayRecord copyWith({BleedingLevel? level, bool? isPeriodStart}) =>
      CycleDayRecord(
        date: date,
        level: level ?? this.level,
        isPeriodStart: isPeriodStart ?? this.isPeriodStart,
      );

  @override
  bool operator ==(Object other) =>
      other is CycleDayRecord &&
      other.date == date &&
      other.level == level &&
      other.isPeriodStart == isPeriodStart;

  @override
  int get hashCode => Object.hash(date, level, isPeriodStart);

  /// Says nothing about the date or the level.
  ///
  /// Cycle records are sensitive, and a `toString` is exactly how
  /// sensitive data ends up in a log line by accident.
  @override
  String toString() => 'CycleDayRecord()';
}
