import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';

/// What surrounded a Journal page on the day it was written.
///
/// **Captured once, never recalculated.** The Moon, the season, a
/// festival and a Maramataka night are all things the app can work out
/// for any date — but a page records what the Almanac *said* that day,
/// in the words it used then. A later version with a better Moon model,
/// a festival switched off, or the Maramataka turned on or off must not
/// rewrite an old page. So the snapshot keeps names as text, not as
/// something to look up again.
@immutable
class JournalContext {
  const JournalContext({
    required this.moonPhase,
    required this.illuminatedFraction,
    required this.season,
    this.festivalId,
    this.festivalName,
    this.maramatakaId,
    this.maramatakaName,
    this.maramatakaReference,
  });

  /// The astronomical phase's name, e.g. "Waxing Gibbous".
  final String moonPhase;

  /// How much of the Moon was lit, 0.0–1.0.
  final double illuminatedFraction;

  /// The season's name, e.g. "Autumn".
  final String season;

  /// The festival falling *on* this date — only when the Wheel of the
  /// Year was part of the Almanac, and never one merely approaching.
  final String? festivalId;
  final String? festivalName;

  /// The estimated Maramataka night — only when the user had chosen to
  /// include the Maramataka.
  final String? maramatakaId;
  final String? maramatakaName;

  /// Which published sequence the night came from.
  final String? maramatakaReference;

  /// Illumination as a whole percentage, for display.
  int get illuminatedPercent => (illuminatedFraction * 100).round();

  @override
  bool operator ==(Object other) =>
      other is JournalContext &&
      other.moonPhase == moonPhase &&
      other.illuminatedFraction == illuminatedFraction &&
      other.season == season &&
      other.festivalId == festivalId &&
      other.festivalName == festivalName &&
      other.maramatakaId == maramatakaId &&
      other.maramatakaName == maramatakaName &&
      other.maramatakaReference == maramatakaReference;

  @override
  int get hashCode => Object.hash(
    moonPhase,
    illuminatedFraction,
    season,
    festivalId,
    festivalName,
    maramatakaId,
    maramatakaName,
    maramatakaReference,
  );

  // Deliberately says nothing a log should not hold — there is no
  // writing in here, but keep it that way.
  @override
  String toString() =>
      'JournalContext($moonPhase, $illuminatedPercent%, $season)';
}

/// One page of the Journal: what the user wrote on one local date.
///
/// **At most one per date.** The id *is* the date, so a second page for
/// the same day cannot exist even in a damaged file — saving again
/// replaces the words on the one page.
///
/// **Only a page somebody wrote.** There is no such thing as a blank
/// entry: the controller will not store one, and the store drops one it
/// finds.
@immutable
class JournalEntry {
  const JournalEntry({
    required this.date,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.context,
  });

  /// The local date the page belongs to — the day it was opened as
  /// today, see `JournalController`.
  final CalendarDate date;

  /// Exactly what was written. Never shown anywhere but this page, never
  /// read by any other feature, never logged.
  final String text;

  /// When the page was first saved, and last saved — instants, from the
  /// app's one clock.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// What surrounded the day, as it was at the first save.
  final JournalContext context;

  /// Stable and unique: one page per date.
  String get id => date.iso;

  JournalEntry withText(String text, {required DateTime updatedAt}) =>
      JournalEntry(
        date: date,
        text: text,
        createdAt: createdAt,
        updatedAt: updatedAt,
        context: context,
      );

  @override
  bool operator ==(Object other) =>
      other is JournalEntry &&
      other.date == date &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.context == context;

  @override
  int get hashCode => Object.hash(date, text, createdAt, updatedAt, context);

  // The date and nothing else: a page's words must never reach a log,
  // even by way of an error message that prints an entry.
  @override
  String toString() => 'JournalEntry($id)';
}

/// Every saved page, oldest first.
@immutable
class JournalBook {
  JournalBook(Iterable<JournalEntry> entries)
    : entries = List.unmodifiable(
        [...entries]..sort((a, b) => a.date.compareTo(b.date)),
      );

  static final empty = JournalBook(const []);

  /// Oldest first.
  final List<JournalEntry> entries;

  bool get isEmpty => entries.isEmpty;

  JournalEntry? find(CalendarDate date) {
    for (final entry in entries) {
      if (entry.date == date) return entry;
    }
    return null;
  }

  /// The nearest saved page before [date] — never a blank date.
  JournalEntry? previousBefore(CalendarDate date) {
    JournalEntry? found;
    for (final entry in entries) {
      if (!entry.date.isBefore(date)) break;
      found = entry;
    }
    return found;
  }

  /// The nearest saved page after [date] — never a blank date.
  JournalEntry? nextAfter(CalendarDate date) {
    for (final entry in entries) {
      if (entry.date.isAfter(date)) return entry;
    }
    return null;
  }

  /// This book with [entry] in place of any page for the same date.
  JournalBook putting(JournalEntry entry) => JournalBook([
    for (final existing in entries)
      if (existing.date != entry.date) existing,
    entry,
  ]);

  JournalBook removing(CalendarDate date) => JournalBook([
    for (final existing in entries)
      if (existing.date != date) existing,
  ]);

  /// Saved pages grouped by month, newest month first and newest page
  /// first within it — the order a contents page is read in.
  List<({CalendarDate month, List<JournalEntry> entries})> get byMonth {
    final groups = <CalendarDate, List<JournalEntry>>{};
    for (final entry in entries.reversed) {
      groups.putIfAbsent(entry.date.firstOfMonth, () => []).add(entry);
    }
    return [
      for (final group in groups.entries)
        (month: group.key, entries: List.unmodifiable(group.value)),
    ];
  }
}
