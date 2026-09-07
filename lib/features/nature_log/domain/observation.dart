import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import 'nature_book.dart';

export 'nature_book.dart';

/// One thing the user noticed.
///
/// **Only what they told us.** A date, a category, what they called it,
/// and — if they wanted — a note and a place in their own words. No
/// coordinates, ever. No inferred species, no derived season: a summary
/// of the season is worked out when it is asked for, so it can never go
/// stale in a file.
///
/// **[label] is always present, even for a book entry.** That is the
/// migration policy, chosen deliberately: the display name is written
/// down at the moment of saving, so an observation of an entry this
/// version of the app has never heard of still reads as what the user
/// saw rather than as a missing row. A book that changes underneath the
/// log costs nothing.
@immutable
class NatureObservation {
  const NatureObservation({
    required this.instanceId,
    required this.date,
    required this.category,
    required this.label,
    required this.order,
    this.itemId,
    this.note,
    this.placeLabel,
  });

  /// Stable for the life of the entry.
  final String instanceId;

  /// The day it was noticed. Today by default, and changeable.
  final CalendarDate date;

  final NatureCategory category;

  /// What it is called: the book entry's name as it stood when this was
  /// saved, or the user's own words.
  final String label;

  /// The order it was recorded in, so two things noticed on one day keep
  /// the sequence they were written in.
  final int order;

  /// The book entry this came from, if any. Null for something the user
  /// described themselves — which the app never tries to identify.
  final String? itemId;

  /// One optional note, in their words.
  final String? note;

  /// An optional place, in their words: "Back garden", "On our walk".
  /// Never derived from a coordinate, and never geocoded.
  final String? placeLabel;

  bool get isFromBook => itemId != null;

  /// The book entry, when this version still knows it.
  NatureItem? get item => itemId == null ? null : NatureBook.tryFind(itemId!);

  NatureObservation copyWith({
    CalendarDate? date,
    NatureCategory? category,
    String? label,
    String? note,
    String? placeLabel,
    bool clearNote = false,
    bool clearPlace = false,
  }) => NatureObservation(
    instanceId: instanceId,
    date: date ?? this.date,
    category: category ?? this.category,
    label: label ?? this.label,
    order: order,
    itemId: itemId,
    note: clearNote ? null : note ?? this.note,
    placeLabel: clearPlace ? null : placeLabel ?? this.placeLabel,
  );

  @override
  bool operator ==(Object other) =>
      other is NatureObservation &&
      other.instanceId == instanceId &&
      other.date == date &&
      other.category == category &&
      other.label == label &&
      other.order == order &&
      other.itemId == itemId &&
      other.note == note &&
      other.placeLabel == placeLabel;

  @override
  int get hashCode => Object.hash(
    instanceId,
    date,
    category,
    label,
    order,
    itemId,
    note,
    placeLabel,
  );

  /// Says how it is filed and nothing about what was seen or written.
  @override
  String toString() => 'NatureObservation(${category.name})';
}

/// Everything the user has noticed.
@immutable
class NatureLog {
  NatureLog([Iterable<NatureObservation> observations = const []])
    : observations = List.unmodifiable(observations);

  static final empty = NatureLog();

  /// In the order they were recorded.
  final List<NatureObservation> observations;

  bool get isEmpty => observations.isEmpty;
  bool get isNotEmpty => observations.isNotEmpty;

  int get length => observations.length;

  /// Most recent first, and within a day the most recently written
  /// first.
  List<NatureObservation> get recent {
    final sorted = [...observations];
    sorted.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.order.compareTo(a.order);
    });
    return sorted;
  }

  NatureObservation? find(String instanceId) {
    for (final observation in observations) {
      if (observation.instanceId == instanceId) return observation;
    }
    return null;
  }

  /// The next order number, so a new entry lands after everything else.
  int get nextOrder =>
      observations.fold(0, (top, o) => o.order >= top ? o.order + 1 : top);

  NatureLog adding(NatureObservation observation) =>
      NatureLog([...observations, observation]);

  NatureLog updating(NatureObservation observation) => NatureLog([
    for (final existing in observations)
      if (existing.instanceId == observation.instanceId)
        observation
      else
        existing,
  ]);

  NatureLog removing(String instanceId) =>
      NatureLog(observations.where((o) => o.instanceId != instanceId));

  /// How many things were noticed between two dates, inclusive.
  ///
  /// Informational, and used for one quiet line. Not a total anybody is
  /// being asked to beat.
  int countBetween(CalendarDate from, CalendarDate to) => observations
      .where((o) => !o.date.isBefore(from) && !o.date.isAfter(to))
      .length;

  @override
  bool operator ==(Object other) =>
      other is NatureLog && listEquals(other.observations, observations);

  @override
  int get hashCode => Object.hashAll(observations);

  @override
  String toString() => 'NatureLog(${observations.length} observations)';
}
