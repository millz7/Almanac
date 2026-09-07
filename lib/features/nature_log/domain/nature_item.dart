import 'package:flutter/foundation.dart';

import '../../../core/time/month_window.dart';

export '../../../core/time/month_window.dart' show MonthWindow;

/// The broad shelves of the Nature Book.
///
/// Five deliberately coarse buckets, not a taxonomy. They exist to
/// organise a page and to let somebody file their own observation
/// somewhere sensible — a spider is not an insect, and nobody noticing
/// one wants to be told so.
enum NatureCategory {
  bird('Bird', 'Birds'),
  plant('Plant', 'Plants'),
  insect('Insect', 'Insects'),
  fungi('Fungus', 'Fungi'),
  other('Other', 'Other');

  const NatureCategory(this.label, this.plural);

  final String label;
  final String plural;

  static NatureCategory? tryParse(String name) {
    for (final category in values) {
      if (category.name == name) return category;
    }
    return null;
  }
}

/// What a seasonal note is about.
///
/// Structured so the wording can be assembled at the edge and checked in
/// one place, and so nothing in the book can quietly become a promise.
enum NatureNoteKind {
  flowering('Often flowering'),
  fruiting('Often fruiting'),
  arrival('Often arriving'),
  activity('Often more active'),
  song('Worth listening for'),
  appearing('Often appearing');

  const NatureNoteKind(this.label);

  final String label;
}

/// One conservative seasonal note: what may be worth noticing, and when.
///
/// The app knows the month and, broadly, the country. It has not seen the
/// tree, the weather or the bird. So a note says what *often* happens
/// around a time of year — never what is happening, and never what
/// anybody will see.
@immutable
class NatureNote {
  const NatureNote({
    required this.kind,
    required this.window,
    required this.text,
  });

  final NatureNoteKind kind;

  /// Which months, as calendar months in New Zealand. Broad on purpose.
  final MonthWindow window;

  /// One short sentence, written as an invitation to look.
  final String text;

  bool isRelevantIn(int month) => window.contains(month);

  @override
  String toString() => 'NatureNote(${kind.name} $window)';
}

/// The small vocabulary of shapes the nature marks are drawn from.
///
/// Four families and a fallback. The drawing is decorative; the **name**
/// is what identifies anything here.
enum NatureMarkForm { bird, leaf, flower, insect, butterfly, fungus, other }

/// One entry in the Nature Book.
@immutable
class NatureItem {
  const NatureItem({
    required this.id,
    required this.primaryName,
    required this.category,
    required this.form,
    required this.description,
    this.alternateName,
    this.scientificName,
    this.notes = const [],
  });

  /// Stable, and never derived from a name: renaming an entry must not
  /// orphan an observation of it.
  final String id;

  /// How it is called first. For many New Zealand species that is the
  /// Māori name, and the model does not force an English one.
  final String primaryName;

  /// The other name it is widely known by, where there is one —
  /// "Fantail" beside "Pīwakawaka".
  final String? alternateName;

  /// Kept for the detail page, and deliberately never used as a title.
  final String? scientificName;

  final NatureCategory category;
  final NatureMarkForm form;

  /// One or two short lines about noticing it. Not an encyclopaedia
  /// entry, and never about handling, keeping or eating anything.
  final String description;

  final List<NatureNote> notes;

  /// "Pīwakawaka · Fantail", or just the primary name.
  String get displayName =>
      alternateName == null ? primaryName : '$primaryName · $alternateName';

  /// The notes worth showing in a given month.
  List<NatureNote> notesFor(int month) => [
    for (final note in notes)
      if (note.isRelevantIn(month)) note,
  ];

  /// "Tūī. Bird." — the start of every spoken label for this entry.
  String get spokenName => alternateName == null
      ? '$primaryName. ${category.label}.'
      : '$primaryName, $alternateName. ${category.label}.';

  @override
  bool operator ==(Object other) => other is NatureItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NatureItem($id)';
}
