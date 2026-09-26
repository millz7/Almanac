import '../../../core/context/cycle_phase.dart';
import '../../../core/widgets/unsaved_changes.dart';
import '../domain/own_recipe.dart';
import '../domain/recipe_catalogue.dart';

/// Everything the Cookbook says, and the two things it has to work out
/// how to say: a duration, and a list of what a recipe happens to be.
///
/// Gathered here like the Environment's and the Cycle's wording, so the
/// copy can be read as prose — and so `recipe_content_test.dart` can
/// check every line of it for health claims, calorie language and diet
/// talk in one place.
abstract final class CookbookText {
  /// The heading over the cycle collection when the user came from
  /// Cycle Syncing: "For your luteal phase".
  static String forYourPhase(CyclePhase phase) => 'For your ${phase.phrase}';

  /// The quieter heading on a direct entry. It mentions the cycle; it
  /// does not announce it.
  static const forYourCycle = 'For your cycle';

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

  // Your recipes: the ones the user keeps themselves.
  static const yourRecipes = 'Your recipes';
  static const yourRecipe = 'Your recipe';
  static const noOwnRecipes = 'Nothing written down yet.';
  static const noOwnRecipesNote =
      'Add a recipe you make often and it will be kept here, alongside '
      'the seasonal ones.';
  static const addRecipe = 'Add a recipe';
  static const editRecipe = 'Edit recipe';
  static const saveRecipe = 'Save recipe';
  static const saveChanges = 'Save changes';
  static const deleteRecipe = 'Delete recipe';
  static const cancel = 'Cancel';
  static const saved = 'Saved to your recipes.';
  static const saveFailed = 'That could not be saved on this device.';
  static const ownPrivacy =
      'Your recipes are kept on this device only. No account, and no '
      'copy anywhere else.';

  static const titleLabel = 'Recipe name';
  static const titleHint = 'Leek and potato soup';
  static const ingredientsLabel = 'Ingredients';
  static const ingredientsHint = 'One per line';
  static const methodLabel = 'Method';
  static const methodHint = 'One step per line';
  static const noteLabel = 'Notes';
  static const noteHint = 'Anything worth remembering next time.';
  static const nameNeeded = 'A recipe needs a name before it can be saved.';

  static const noIngredients = 'No ingredients written down.';
  static const noMethod = 'No method written down.';

  static const deleteTitle = 'Delete this recipe?';
  static const deleteBody =
      'It will be removed from this device. This cannot be undone.';
  static const delete = 'Delete';
  static const keep = 'Keep';

  // The shared unsaved-changes question, in the app's one set of words.
  static const leaveTitle = UnsavedChanges.title;
  static const leaveBody = UnsavedChanges.body;
  static const leave = UnsavedChanges.leave;
  static const keepEditing = UnsavedChanges.keepEditing;

  /// "Leek and potato soup. Your recipe." — a tile, spoken.
  static String ownRecipeLabel(OwnRecipe recipe) =>
      '${recipe.title}. $yourRecipe.';

  /// "3 ingredients · 4 steps" — how much is written down, never a
  /// judgement of it.
  static String ownRecipeSummary(OwnRecipe recipe) {
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
    return [
      count(recipe.ingredients.length, 'ingredient', 'ingredients'),
      count(recipe.method.length, 'step', 'steps'),
    ].join(' · ');
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
    yourRecipes,
    yourRecipe,
    noOwnRecipes,
    noOwnRecipesNote,
    addRecipe,
    editRecipe,
    saveRecipe,
    saveChanges,
    deleteRecipe,
    cancel,
    saved,
    saveFailed,
    ownPrivacy,
    titleLabel,
    titleHint,
    ingredientsLabel,
    ingredientsHint,
    methodLabel,
    methodHint,
    noteLabel,
    noteHint,
    nameNeeded,
    noIngredients,
    noMethod,
    deleteTitle,
    deleteBody,
    delete,
    keep,
    leaveTitle,
    leaveBody,
    leave,
    keepEditing,
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
