import 'recipe.dart';

/// Summer: as little cooking as the food will allow.
abstract final class SummerRecipes {
  static const tomatoPasta = Recipe(
    id: 'summer-tomato-and-basil-pasta',
    name: 'Tomato and basil pasta',
    season: Season.summer,
    description: 'Ripe tomatoes, barely cooked at all.',
    prepTime: Duration(minutes: 10),
    cookTime: Duration(minutes: 15),
    servings: 4,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient(400, 'g', 'spaghetti or penne'),
      Ingredient(3, 'tbsp', 'olive oil'),
      Ingredient.count(3, 'cloves garlic, thinly sliced'),
      Ingredient(800, 'g', 'ripe tomatoes, roughly chopped'),
      Ingredient(1, 'large handful', 'basil leaves, torn'),
      Ingredient(60, 'g', 'parmesan, grated'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Bring a large pot of well salted water to the boil and cook the '
          'pasta until just tender.',
      'While it cooks, warm the oil in a wide pan and cook the garlic '
          'gently for a minute, without letting it colour.',
      'Add the tomatoes and a good pinch of salt, and cook for six to '
          'eight minutes, until they have slumped into a rough sauce.',
      'Drain the pasta, keeping a cup of the water.',
      'Toss the pasta through the sauce with the basil, loosening it '
          'with a little pasta water.',
      'Serve with the parmesan and plenty of pepper.',
    ],
    note: 'The riper the tomatoes, the less this needs from you.',
  );

  static const grilledVegetables = Recipe(
    id: 'summer-grilled-summer-vegetables',
    name: 'Grilled summer vegetables',
    season: Season.summer,
    description: 'Courgette, capsicum and eggplant, charred and dressed.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 20),
    servings: 4,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient.count(2, 'courgettes, sliced lengthways'),
      Ingredient.count(2, 'capsicums, cut into wide strips'),
      Ingredient.count(1, 'eggplant, sliced into rounds'),
      Ingredient(3, 'tbsp', 'olive oil'),
      Ingredient(1, 'tbsp', 'red wine vinegar'),
      Ingredient(1, 'small handful', 'parsley, chopped'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Heat a barbecue or a heavy pan until properly hot, or the oven '
          'grill to high.',
      'Brush the vegetables with two tablespoons of the oil and season '
          'them.',
      'Cook in batches, turning once, until softened and marked, three '
          'to four minutes a side.',
      'Pile them onto a platter as they come off the heat.',
      'Whisk the remaining oil with the vinegar, spoon it over while '
          'the vegetables are still warm, and scatter the parsley.',
    ],
    note:
        'Better at room temperature than piping hot, so this is a '
        'good thing to cook first.',
  );

  static const cornSalad = Recipe(
    id: 'summer-corn-and-chickpea-salad',
    name: 'Sweetcorn and chickpea salad',
    season: Season.summer,
    description: 'Sweet, sharp and cold, from one pot of water.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 10),
    servings: 4,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient.count(3, 'cobs sweetcorn, husks removed'),
      Ingredient(400, 'g', 'tin chickpeas, drained and rinsed'),
      Ingredient(250, 'g', 'cherry tomatoes, halved'),
      Ingredient.count(1, 'cucumber, diced'),
      Ingredient.count(4, 'spring onions, sliced'),
      Ingredient(2, 'tbsp', 'olive oil'),
      Ingredient.count(1, 'lemon, juiced'),
      Ingredient(1, 'small handful', 'mint and parsley, chopped'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Boil the corn in unsalted water for six to eight minutes, then '
          'lift it out and let it cool enough to handle.',
      'Stand each cob on its end and cut the kernels off downwards.',
      'Tip the corn into a big bowl with the chickpeas, tomatoes, '
          'cucumber and spring onions.',
      'Whisk the oil and lemon juice together, season well, and toss it '
          'through.',
      'Fold in the herbs just before serving.',
    ],
    note:
        'Corn cut straight off the cob is sweeter than anything out '
        'of a tin, and it takes two minutes.',
  );

  static const roastedStoneFruit = Recipe(
    id: 'summer-roasted-stone-fruit',
    name: 'Roasted stone fruit with yoghurt',
    season: Season.summer,
    description: 'Peaches or nectarines, warm, with something cold.',
    prepTime: Duration(minutes: 10),
    cookTime: Duration(minutes: 25),
    servings: 4,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient.count(6, 'peaches or nectarines, halved and stoned'),
      Ingredient(2, 'tbsp', 'honey'),
      Ingredient(1, 'tsp', 'vanilla extract'),
      Ingredient(30, 'g', 'butter, in small pieces'),
      Ingredient(60, 'g', 'rolled oats'),
      Ingredient(400, 'g', 'thick yoghurt'),
    ],
    method: [
      'Heat the oven to 190C.',
      'Sit the fruit cut side up in a baking dish.',
      'Warm the honey with the vanilla and a splash of water, and spoon '
          'it over the fruit.',
      'Dot the butter on top and roast for twenty minutes, until soft '
          'and syrupy.',
      'Toast the oats in a dry pan for three minutes, until they smell '
          'nutty.',
      'Serve the warm fruit and its syrup over the yoghurt, with the '
          'oats scattered on top.',
    ],
  );

  static const all = [
    tomatoPasta,
    grilledVegetables,
    cornSalad,
    roastedStoneFruit,
  ];
}
