import '../domain/recipe_catalogue.dart';

/// Everything the Cookbook says, and the two things it has to work out
/// how to say: a duration, and a list of what a recipe happens to be.
///
/// Gathered here like the Environment's and the Cycle's wording, so the
/// copy can be read as prose — and so `recipe_content_test.dart` can
/// check every line of it for health claims, calorie language and diet
/// talk in one place.
abstract final class CookbookText {
  static const title = 'Cookbook';
  static const introduction = RecipeCatalogue.introduction;
  static const yourSeason = RecipeCatalogue.yourSeason;

  static const ingredients = 'Ingredients';
  static const method = 'Method';
  static const back = 'Back to the collection';

  static const prepLabel = 'Prep';
  static const cookLabel = 'Cook';
  static const servesLabel = 'Serves';

  /// "20 minutes", "1 hour", "1 hour 15 minutes".
  ///
  /// Derived from a [Duration], never stored as a label — which is why a
  /// recipe can say "about an hour and a half" on a card and "1 hour 30
  /// minutes" on its page without the two ever disagreeing.
  static String duration(Duration time) {
    final hours = time.inHours;
    final minutes = time.inMinutes.remainder(60);

    final hourPart = '$hours ${hours == 1 ? 'hour' : 'hours'}';
    final minutePart = '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';

    if (hours == 0) return minutePart;
    if (minutes == 0) return hourPart;
    return '$hourPart $minutePart';
  }

  /// "About 45 minutes" — the one time figure a card shows.
  static String totalTime(Recipe recipe) =>
      'About ${duration(recipe.totalTime)}';

  /// "Preparation 15 minutes" — the spoken form of the short label.
  static String prepSpoken(Duration time) => 'Preparation ${duration(time)}';

  /// "Cooking 30 minutes".
  static String cookSpoken(Duration time) => 'Cooking ${duration(time)}';

  /// "Serves 4".
  static String serves(int servings) => '$servesLabel $servings';

  /// "Vegetarian", or "Vegetarian and vegan" — plain facts about the
  /// ingredients, and nothing about anybody's diet.
  static String? tagLine(Recipe recipe) {
    if (recipe.tags.isEmpty) return null;
    // Vegan implies vegetarian, so saying both would be fussy.
    if (recipe.tags.contains(DietaryTag.vegan)) return DietaryTag.vegan.label;
    return recipe.tags.map((t) => t.label).join(' and ');
  }

  /// A season selector, as a screen reader hears it.
  static String seasonLabel(Season season, {required bool isCurrent}) =>
      isCurrent ? '${season.label}. $yourSeason.' : season.label;

  /// Everything fixed in this file plus every recipe's own words, for
  /// the content test to read.
  static List<String> get everythingSaid => [
    title,
    introduction,
    yourSeason,
    ingredients,
    method,
    back,
    prepLabel,
    cookLabel,
    servesLabel,
    duration(const Duration(minutes: 90)),
    for (final season in Season.values) RecipeCatalogue.collectionNote(season),
    for (final tag in DietaryTag.values) tag.label,
    for (final recipe in RecipeCatalogue.all) ...[
      recipe.name,
      recipe.description,
      ?recipe.note,
      for (final ingredient in recipe.ingredients) ingredient.line,
      ...recipe.method,
    ],
  ];
}
