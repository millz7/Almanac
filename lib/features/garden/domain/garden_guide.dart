import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_words.dart';
import 'my_garden.dart';
import 'plant_book.dart';

export 'my_garden.dart';
export 'plant_book.dart';

/// One recommendation: a plant, the rule that raised it, and why it is
/// showing now.
@immutable
class GardenSuggestion {
  const GardenSuggestion({
    required this.plant,
    required this.rule,
    this.entry,
    this.reason,
  });

  final PlantDefinition plant;
  final GardeningRule rule;

  /// The user's own entry, for the personalised categories. Null for
  /// Sow and Plant, which are open to the whole book.
  final GardenPlant? entry;

  /// Why this is appearing, in the user's words: "October · established
  /// plant". Null where the month alone is the reason.
  final String? reason;

  /// "Peas. Vegetable. Sow outdoors." — the whole of what a list item
  /// says, for a screen reader.
  String get spokenLabel =>
      [plant.spokenName, rule.method?.label ?? rule.guidance].join(' ');

  @override
  String toString() => 'GardenSuggestion(${plant.id}, ${rule.action.name})';
}

/// What the calendar and the region suggest, for anybody.
///
/// This is the **general** guide: sowing and planting are discovery, so
/// the whole plant book is in scope and My Garden is not consulted at
/// all. It depends on exactly two things — where and when.
@immutable
class GeneralGuide {
  const GeneralGuide({
    required this.guide,
    required this.today,
    required this.sow,
    required this.plant,
  });

  final GardeningGuide guide;
  final CalendarDate today;

  final List<GardenSuggestion> sow;
  final List<GardenSuggestion> plant;

  List<GardenSuggestion> forAction(GardenAction action) => switch (action) {
    GardenAction.sow => sow,
    GardenAction.plant => plant,
    _ => const [],
  };
}

/// What the user's own garden suggests.
///
/// This is the **personalised** guide, and the whole point of the
/// feature: tending, harvesting and pruning are drawn from the
/// intersection of My Garden and the rules that are relevant here and
/// now. A plant nobody grows never appears in it.
@immutable
class PersonalGuide {
  const PersonalGuide({
    required this.guide,
    required this.today,
    required this.tend,
    required this.harvest,
    required this.prune,
  });

  final GardeningGuide guide;
  final CalendarDate today;

  final List<GardenSuggestion> tend;
  final List<GardenSuggestion> harvest;
  final List<GardenSuggestion> prune;

  List<GardenSuggestion> forAction(GardenAction action) => switch (action) {
    GardenAction.tend => tend,
    GardenAction.harvest => harvest,
    GardenAction.prune => prune,
    _ => const [],
  };
}

/// Works out the general guide.
///
/// Pure: the same region and the same day always give the same answer,
/// and nothing in here reads a clock or a store.
GeneralGuide generalGuideFor({
  required GardeningGuide guide,
  required CalendarDate today,
}) {
  final month = today.month;

  List<GardenSuggestion> suggestionsFor(GardenAction action) => [
    for (final plant in PlantBook.all)
      for (final rule in plant.rulesFor(action))
        if (rule.isRelevantIn(guide.region, month))
          GardenSuggestion(plant: plant, rule: rule),
  ];

  return GeneralGuide(
    guide: guide,
    today: today,
    sow: suggestionsFor(GardenAction.sow),
    plant: suggestionsFor(GardenAction.plant),
  );
}

/// Works out the personalised guide.
///
/// Also pure, and it takes My Garden as an argument rather than reaching
/// for a store — which is what makes the personalisation testable a
/// month at a time.
///
/// A rule reaches the list only when all of these hold:
///
/// 1. the plant is in My Garden,
/// 2. the rule applies in this region and this month,
/// 3. the plant has reached the state the rule needs, and
/// 4. if the rule has a minimum age **and the user recorded a sowing
///    date**, that many weeks have passed.
///
/// Point four is deliberately conditional. The app cannot see the plant,
/// so with no date recorded the calendar window carries the
/// recommendation on its own — and the reason line says which of the two
/// it is standing on.
PersonalGuide personalGuideFor({
  required GardeningGuide guide,
  required CalendarDate today,
  required MyGarden garden,
}) {
  final month = today.month;

  List<GardenSuggestion> suggestionsFor(GardenAction action) {
    final found = <GardenSuggestion>[];

    for (final entry in garden.known) {
      final plant = PlantBook.byId(entry.plantId);

      for (final rule in plant.rulesFor(action)) {
        if (!rule.isRelevantIn(guide.region, month)) continue;

        final needed = rule.requires;
        if (needed != null && !entry.state.isAtLeast(needed)) continue;

        final minimum = rule.minWeeksFromSowing;
        final age = entry.weeksSinceSowing(today);
        if (minimum != null && age != null && age < minimum) continue;

        found.add(
          GardenSuggestion(
            plant: plant,
            rule: rule,
            entry: entry,
            reason: _reasonFor(entry: entry, today: today, age: age),
          ),
        );
      }
    }

    found.sort((a, b) => a.plant.name.compareTo(b.plant.name));
    return found;
  }

  return PersonalGuide(
    guide: guide,
    today: today,
    tend: suggestionsFor(GardenAction.tend),
    harvest: suggestionsFor(GardenAction.harvest),
    prune: suggestionsFor(GardenAction.prune),
  );
}

/// "October · established plant", or "October · sown 12 weeks ago".
///
/// Plain words about what the app actually knows. No jargon, and no
/// implication that it has seen the plant.
String _reasonFor({
  required GardenPlant entry,
  required CalendarDate today,
  required int? age,
}) {
  final month = monthName(today.month);
  if (age != null) {
    final weeks = age == 1 ? '1 week' : '$age weeks';
    return '$month · sown $weeks ago';
  }
  return '$month · ${entry.state.label.toLowerCase()} in your garden';
}
