import 'recipe.dart';
import 'recipes_autumn.dart';
import 'recipes_spring.dart';
import 'recipes_summer.dart';
import 'recipes_winter.dart';

export 'recipe.dart';

/// The whole cookbook: sixteen recipes, four to a season.
///
/// Static data, bundled with the app. There is no network, no recipe
/// service and nothing to fetch — the collection is small on purpose, and
/// the screens read it rather than each recipe being a page of its own.
abstract final class RecipeCatalogue {
  /// How the Cookbook introduces itself.
  static const introduction = 'Recipes to follow the seasons.';

  /// What a collection is, said carefully.
  ///
  /// The app knows which season the user is in. It does not know what is
  /// growing near them, what their shops have, or what the weather did
  /// to the crop this year — so a collection is offered as *inspired by*
  /// a season, never as a claim about what is locally available.
  static String collectionNote(Season season) =>
      'A seasonal collection for ${season.label.toLowerCase()}. '
      'Recipes inspired by ${season.label.toLowerCase()} ingredients, '
      'wherever you are.';

  /// The marker on the season the Environment has resolved.
  static const yourSeason = 'Your season';

  /// In seasonal order, and stable: spring, summer, autumn, winter, four
  /// at a time.
  static const all = <Recipe>[
    ...SpringRecipes.all,
    ...SummerRecipes.all,
    ...AutumnRecipes.all,
    ...WinterRecipes.all,
  ];

  /// The four recipes of one season, in catalogue order.
  static List<Recipe> forSeason(Season season) => [
    for (final recipe in all)
      if (recipe.season == season) recipe,
  ];

  /// Looks a recipe up by its stable id.
  static Recipe byId(String id) => all.firstWhere((r) => r.id == id);
}
