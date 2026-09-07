import 'package:flutter/foundation.dart';

import 'gardening_rule.dart';

/// The four shelves of the plant book.
enum PlantCategory {
  vegetable('Vegetable', 'Vegetables'),
  herb('Herb', 'Herbs'),
  fruit('Fruit', 'Fruit'),
  flower('Flower', 'Flowers');

  const PlantCategory(this.label, this.plural);

  /// "Vegetable", for a single plant.
  final String label;

  /// "Vegetables", for a heading.
  final String plural;
}

/// How long a plant lives, which is what decides whether it is sown
/// every year or pruned every year.
enum Lifecycle {
  annual('Annual'),
  biennial('Biennial'),
  perennial('Perennial');

  const Lifecycle(this.label);

  final String label;
}

/// The small vocabulary of shapes the plant marks are drawn from.
///
/// Eight forms rather than sixty portraits: a leafy green is a leafy
/// green, and the plant's *name* is what identifies it. Species get
/// small variations within their form — see `PlantMark`.
enum PlantForm {
  leafyGreen,
  root,
  climber,
  fruiting,
  bulb,
  herb,
  shrub,
  tree,
  flower,
  vine,
}

/// One plant in the book.
///
/// The rules are the point. Everything the app recommends comes from
/// [rules] — structured windows, methods and cautions — rather than from
/// sentences assembled in a widget, so the same data drives the Sow
/// page, the personalised Harvest list, the plant's own page and the
/// tests.
@immutable
class PlantDefinition {
  const PlantDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.form,
    required this.lifecycle,
    required this.description,
    required this.rules,
  });

  /// Stable, lower-case, and never derived from the name: renaming a
  /// plant must not orphan it in somebody's garden.
  final String id;

  final String name;
  final PlantCategory category;

  /// Which drawn shape stands for it.
  final PlantForm form;

  final Lifecycle lifecycle;

  /// One or two short practical lines. Not an encyclopaedia entry.
  final String description;

  final List<GardeningRule> rules;

  /// The rules for one action, in the order they were written.
  List<GardeningRule> rulesFor(GardenAction action) => [
    for (final rule in rules)
      if (rule.action == action) rule,
  ];

  bool get isPerennial => lifecycle == Lifecycle.perennial;

  /// "Peas. Vegetable." — the start of every spoken label for this
  /// plant. Callers add the part about right now.
  String get spokenName => '$name. ${category.label}.';

  @override
  bool operator ==(Object other) => other is PlantDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlantDefinition($id)';
}
