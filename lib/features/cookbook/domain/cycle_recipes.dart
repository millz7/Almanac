import '../../../core/context/cycle_phase.dart';
import 'recipe_catalogue.dart';

export '../../../core/context/cycle_phase.dart' show CyclePhase;

/// Which of the sixteen recipes the Cookbook offers for a cycle phase.
///
/// **The Cookbook owns this, not Cycle.** Cycle knows that it would like
/// recipes for a phase; which recipes those are is a question about
/// recipes, and it is answered here — beside the collection it draws
/// from. Cycle never names an ingredient and never names a recipe id.
///
/// **Chosen for what is actually in them.** Nothing is forced into a
/// phase to fill a collection out, and no recipe is claimed to treat
/// anything. The menstrual list in particular is the recipes that
/// genuinely carry iron-rich foods — lentils, beans, chickpeas, leafy
/// greens, eggs, meat — because menstruation involves blood loss and
/// that is worth knowing, not because anybody is being told they are
/// short of iron.
abstract final class CycleRecipes {
  /// The recipe ids offered for each phase, in catalogue order.
  ///
  /// A recipe may appear in several phases: a bean stew is a sensible
  /// thing to eat at any point in a month. What no phase has is an
  /// arbitrary entry.
  static const byPhase = <CyclePhase, List<String>>{
    // Iron-carrying meals, and warm ones.
    CyclePhase.menstrual: [
      'spring-greens-frittata',
      'spring-lemon-herb-roast-chicken',
      'autumn-roast-roots-and-lentils',
      'winter-vegetable-and-bean-stew',
      'winter-kumara-and-chickpea-curry',
      'summer-corn-and-chickpea-salad',
    ],
    // Balanced, fresh, nothing heavy.
    CyclePhase.follicular: [
      'spring-pea-and-mint-soup',
      'spring-greens-frittata',
      'summer-corn-and-chickpea-salad',
      'summer-tomato-and-basil-pasta',
      'autumn-roast-roots-and-lentils',
    ],
    // Colour on the plate, and things eaten with other people.
    CyclePhase.ovulatory: [
      'summer-grilled-summer-vegetables',
      'summer-corn-and-chickpea-salad',
      'spring-lemon-herb-roast-chicken',
      'summer-roasted-stone-fruit',
      'spring-pea-and-mint-soup',
    ],
    // Satisfying and grounding: whole grains, legumes, nuts and seeds.
    CyclePhase.luteal: [
      'autumn-mushroom-barley-risotto',
      'autumn-roast-roots-and-lentils',
      'winter-vegetable-and-bean-stew',
      'winter-kumara-and-chickpea-curry',
      'autumn-apple-and-oat-bake',
      'winter-warm-pear-and-oat-pudding',
    ],
  };

  /// The recipes for a phase, in catalogue order.
  ///
  /// Total: every [CyclePhase] has a list, and every id in it exists —
  /// `cookbook_cycle_test.dart` proves both.
  static List<Recipe> forPhase(CyclePhase phase) {
    final ids = byPhase[phase] ?? const <String>[];
    return [
      for (final recipe in RecipeCatalogue.all)
        if (ids.contains(recipe.id)) recipe,
    ];
  }

  /// How a cycle collection introduces itself.
  ///
  /// Says what the collection *is* — recipes that suit the time of month
  /// — and not what it does to anybody.
  static String collectionNote(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual =>
      'Meals with iron-carrying foods in them — greens, lentils, beans, '
          'eggs — and a few warm things to eat from a bowl.',
    CyclePhase.follicular =>
      'Balanced, fresh meals for the stretch after a period.',
    CyclePhase.ovulatory =>
      'Colourful, generous meals, several of them easy to share.',
    CyclePhase.luteal =>
      'Satisfying meals with whole grains, legumes, nuts and seeds.',
  };
}
