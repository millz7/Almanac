import 'recipe.dart';

/// Winter: long cooking, and one pot wherever possible.
abstract final class WinterRecipes {
  static const leekPotatoSoup = Recipe(
    id: 'winter-leek-and-potato-soup',
    name: 'Leek and potato soup',
    season: Season.winter,
    description: 'Three ingredients doing most of the work.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 30),
    servings: 4,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient(30, 'g', 'butter'),
      Ingredient.count(3, 'leeks, washed well and sliced'),
      Ingredient(700, 'g', 'potatoes, peeled and diced'),
      Ingredient(1, 'litre', 'vegetable stock'),
      Ingredient(100, 'ml', 'milk'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Melt the butter in a large pot over a low heat.',
      'Add the leeks with a pinch of salt and cook slowly for ten '
          'minutes, until soft and sweet but not browned.',
      'Add the potatoes and the stock, and simmer for twenty minutes.',
      'Blend until smooth, or leave it chunky and mash a little.',
      'Stir in the milk, season well, and warm through without letting '
          'it boil.',
    ],
    note:
        'Leeks hold grit between their layers. Slice them first, then '
        'wash them in a bowl of water.',
  );

  static const beanStew = Recipe(
    id: 'winter-vegetable-and-bean-stew',
    name: 'Slow vegetable and bean stew',
    season: Season.winter,
    description: 'A pot that improves the longer you leave it.',
    prepTime: Duration(minutes: 20),
    cookTime: Duration(minutes: 60),
    servings: 6,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient(2, 'tbsp', 'olive oil'),
      Ingredient.count(1, 'onion, chopped'),
      Ingredient.count(3, 'cloves garlic, chopped'),
      Ingredient.count(2, 'carrots, diced'),
      Ingredient.count(2, 'sticks celery, diced'),
      Ingredient(1, 'tsp', 'smoked paprika'),
      Ingredient(1, 'tsp', 'dried oregano'),
      Ingredient(400, 'g', 'tin chopped tomatoes'),
      Ingredient(800, 'g', 'tins cannellini or butter beans, drained'),
      Ingredient(600, 'ml', 'vegetable stock'),
      Ingredient(150, 'g', 'silverbeet, shredded'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Warm the oil in a heavy pot and cook the onion, carrot and '
          'celery gently for ten minutes.',
      'Add the garlic, paprika and oregano and cook for one minute.',
      'Add the tomatoes, beans and stock, and bring to a simmer.',
      'Simmer uncovered for 45 minutes, stirring now and then, until '
          'thick.',
      'Stir the silverbeet through and cook for five minutes more.',
      'Season, and let it stand for ten minutes before serving.',
    ],
    note: 'Better the next day, and it freezes well.',
  );

  static const kumaraCurry = Recipe(
    id: 'winter-kumara-and-chickpea-curry',
    name: 'Kumara and chickpea curry',
    season: Season.winter,
    description: 'Mild, sweet and thick, on one burner.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 35),
    servings: 4,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient(1, 'tbsp', 'oil'),
      Ingredient.count(1, 'onion, chopped'),
      Ingredient(1, 'tbsp', 'grated ginger'),
      Ingredient.count(2, 'cloves garlic, chopped'),
      Ingredient(2, 'tsp', 'curry powder'),
      Ingredient(800, 'g', 'kumara, peeled and cut into chunks'),
      Ingredient(400, 'ml', 'tin coconut milk'),
      Ingredient(400, 'g', 'tin chickpeas, drained'),
      Ingredient(200, 'ml', 'water'),
      Ingredient(100, 'g', 'spinach'),
      Ingredient.toTaste('Salt'),
    ],
    method: [
      'Warm the oil in a large pot and cook the onion until soft.',
      'Add the ginger, garlic and curry powder and cook for one minute, '
          'stirring.',
      'Add the kumara, coconut milk, chickpeas and water.',
      'Simmer gently for 25 minutes, until the kumara is tender and the '
          'sauce has thickened.',
      'Stir the spinach through until it wilts, and season with salt.',
    ],
    note: 'Serve with rice, or with bread for mopping.',
  );

  static const pearOatPudding = Recipe(
    id: 'winter-warm-pear-and-oat-pudding',
    name: 'Warm pear and oat pudding',
    season: Season.winter,
    description: 'Pears baked soft under oats and spice.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 40),
    servings: 6,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient.count(6, 'pears, peeled and sliced'),
      Ingredient(2, 'tbsp', 'honey'),
      Ingredient(0.5, 'tsp', 'ground ginger'),
      Ingredient(0.5, 'tsp', 'ground cinnamon'),
      Ingredient(140, 'g', 'rolled oats'),
      Ingredient(60, 'g', 'flour'),
      Ingredient(60, 'g', 'brown sugar'),
      Ingredient(100, 'g', 'butter, softened'),
    ],
    method: [
      'Heat the oven to 180C.',
      'Toss the pears with the honey, ginger and cinnamon, and spread '
          'them in a baking dish.',
      'Rub the oats, flour, sugar and butter together until it holds in '
          'loose clumps.',
      'Scatter it over the pears.',
      'Bake for 40 minutes, until golden on top and soft underneath.',
      'Let it settle for five minutes, then serve warm.',
    ],
  );

  static const all = [leekPotatoSoup, beanStew, kumaraCurry, pearOatPudding];
}
