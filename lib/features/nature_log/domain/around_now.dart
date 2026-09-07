import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import 'nature_book.dart';
import 'nature_coverage.dart';

export 'nature_book.dart';
export 'nature_coverage.dart';

/// One thing the guide suggests looking for, and why.
@immutable
class NatureSuggestion {
  const NatureSuggestion({required this.item, required this.note});

  final NatureItem item;
  final NatureNote note;

  /// "Tūī. Bird. Often busy around flowering kōwhai in spring." — the
  /// whole of what a row says, for a screen reader.
  String get spokenLabel => '${item.spokenName} ${note.text}';

  @override
  String toString() => 'NatureSuggestion(${item.id})';
}

/// What the guide says may be worth noticing, here and now.
@immutable
class AroundNow {
  const AroundNow({
    required this.guide,
    required this.today,
    required this.suggestions,
  });

  final NatureGuide guide;
  final CalendarDate today;

  /// In book order: birds, plants, insects, fungi, other.
  final List<NatureSuggestion> suggestions;

  bool get isEmpty => suggestions.isEmpty;

  /// One category's suggestions, for a heading that is only drawn when
  /// it has something under it.
  List<NatureSuggestion> ofCategory(NatureCategory category) => [
    for (final suggestion in suggestions)
      if (suggestion.item.category == category) suggestion,
  ];
}

/// Works out what the guide suggests.
///
/// Pure: the same guide and the same day always give the same answer,
/// and nothing here reads a clock, a store or a position.
///
/// **Nothing is suggested at all outside the guide's coverage.** An
/// empty list is the honest answer for somewhere the book has no content
/// for — the screen says so in words, and recording an observation stays
/// available everywhere.
AroundNow aroundNow({required NatureGuide guide, required CalendarDate today}) {
  if (!guide.isSupported) {
    return AroundNow(guide: guide, today: today, suggestions: const []);
  }

  final month = today.month;

  return AroundNow(
    guide: guide,
    today: today,
    suggestions: [
      for (final item in NatureBook.all)
        // One suggestion per entry: the first note that fits the month.
        // A row saying two things about the same bird is a row nobody
        // reads.
        if (item.notesFor(month).firstOrNull case final note?)
          NatureSuggestion(item: item, note: note),
    ],
  );
}
