import 'package:flutter/foundation.dart';

import '../../../core/environment/season.dart';

export '../../../core/environment/season.dart' show Season;

/// One line of a recipe's ingredient list.
///
/// Structured rather than a sentence, so the app can lay the list out,
/// read it aloud sensibly, and — one day, if it is ever useful — scale
/// it. There is no scaling in this version: quantities are fixed.
///
/// [quantity] and [unit] are both optional because real recipes are:
/// "2 eggs" has no unit, and "salt and pepper, to taste" has neither.
/// The one rule, held by `recipe_content_test.dart`, is that an
/// ingredient either says how much or says [toTaste] — never nothing at
/// all, which is how ambiguous measurements get in.
@immutable
class Ingredient {
  const Ingredient(num quantity, this.unit, this.name)
    : quantity = quantity,
      toTaste = false,
      assert(quantity > 0, 'a quantity is a real amount');

  /// An ingredient counted rather than measured: "2 eggs", or "3 cloves
  /// garlic" with the counting word spelled into the name.
  const Ingredient.count(num quantity, this.name)
    : quantity = quantity,
      unit = null,
      toTaste = false,
      assert(quantity > 0, 'a quantity is a real amount');

  /// Salt, pepper, a squeeze of lemon: things a cook judges.
  const Ingredient.toTaste(this.name)
    : quantity = null,
      unit = null,
      toTaste = true;

  /// How much. Null only when [toTaste].
  final num? quantity;

  /// Grams, tablespoons, cups. Null for things that are simply counted.
  final String? unit;

  final String name;

  /// Whether the amount is left to the cook.
  final bool toTaste;

  /// "1 tbsp olive oil", "500 g pumpkin", "2 eggs",
  /// "Salt and pepper, to taste".
  String get line {
    if (toTaste) return '$name, to taste';
    final amount = formatQuantity(quantity!);
    return unit == null ? '$amount $name' : '$amount $unit $name';
  }

  @override
  String toString() => line;
}

/// "2", "1/2", "1 1/2" — cookbook fractions rather than decimals, since
/// half a teaspoon is a half and not a 0.5.
String formatQuantity(num quantity) {
  final whole = quantity.floor();
  final part = quantity - whole;

  final fraction = switch (part) {
    0.25 => '1/4',
    0.5 => '1/2',
    0.75 => '3/4',
    // Anything else keeps its decimal, trimmed of a pointless ".0".
    _ => null,
  };

  if (fraction == null) {
    return quantity == whole ? '$whole' : '$quantity';
  }
  return whole == 0 ? fraction : '$whole $fraction';
}

/// A numbered step of a method.
///
/// Derived rather than stored: a recipe holds its method as an ordered
/// list of instructions, and the numbers come from that order, so they
/// cannot drift out of step with it.
@immutable
class MethodStep {
  const MethodStep(this.number, this.instruction);

  final int number;
  final String instruction;

  /// "Step 3. Add the pumpkin and the stock." — what a screen reader
  /// hears, so a step is understandable on its own.
  String get spoken => 'Step $number. $instruction';

  @override
  String toString() => '$number. $instruction';
}

/// Something a recipe happens to be, from its ingredients alone.
///
/// Deliberately only these two. "Gluten free" and "dairy free" are
/// claims about safety that this app is in no position to make — a
/// listed ingredient can hide a dozen others — so the ingredient list is
/// the whole of what Cookbook says about what is in a dish.
enum DietaryTag {
  vegetarian('Vegetarian'),
  vegan('Vegan');

  const DietaryTag(this.label);

  final String label;
}

/// One recipe.
///
/// Static data. The screens consume it, so adding a recipe is an entry in
/// [RecipeCatalogue] and no change to any widget.
///
/// Times are [Duration]s, not strings: the UI decides how to say "1 hour
/// 10 minutes", and nothing has to parse a label back into a number.
@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.season,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.ingredients,
    required this.method,
    this.note,
    this.tags = const [],
  });

  /// Stable, and never derived from the name — renaming a recipe must
  /// not change which recipe it is.
  final String id;

  final String name;

  /// The seasonal collection it belongs to. The app's own [Season], not
  /// a second vocabulary: the Cookbook shows the same four seasons the
  /// Environment resolves.
  final Season season;

  /// One short line. Flavour and warmth, never a health claim.
  final String description;

  final Duration prepTime;
  final Duration cookTime;

  /// How many it is written for. Fixed — there is no multiplier.
  final int servings;

  final List<Ingredient> ingredients;

  /// The method, in order. Numbers come from the order; see
  /// [MethodStep].
  final List<String> method;

  /// An optional aside: a swap, or what to do with the leftovers.
  final String? note;

  final List<DietaryTag> tags;

  Duration get totalTime => prepTime + cookTime;

  /// The method as numbered steps.
  List<MethodStep> get steps => [
    for (var i = 0; i < method.length; i++) MethodStep(i + 1, method[i]),
  ];

  /// "Pumpkin soup. Winter recipe. A simple warming soup." — what a
  /// screen reader hears in place of the card.
  String get cardLabel => '$name. ${season.label} recipe. $description';

  @override
  String toString() => 'Recipe($id)';
}
