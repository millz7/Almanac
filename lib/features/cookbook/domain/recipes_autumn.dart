import 'recipe.dart';

/// Autumn: the oven back on, and everything that stores well.
abstract final class AutumnRecipes {
  static const pumpkinSoup = Recipe(
    id: 'autumn-pumpkin-soup',
    name: 'Pumpkin soup',
    season: Season.autumn,
    description: 'A simple warming soup, smooth and golden.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 30),
    servings: 4,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient(1, 'tbsp', 'olive oil'),
      Ingredient.count(1, 'onion, chopped'),
      Ingredient.count(2, 'cloves garlic, chopped'),
      Ingredient(1, 'tsp', 'ground cumin'),
      Ingredient(1, 'kg', 'pumpkin, peeled and cut into chunks'),
      Ingredient(1, 'litre', 'vegetable stock'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Warm the oil in a large pot over a medium heat.',
      'Add the onion and cook until soft, about six minutes, then add '
          'the garlic and cumin and cook for one minute more.',
      'Add the pumpkin and the stock, and bring to a simmer.',
      'Simmer for twenty minutes, until the pumpkin gives way easily '
          'to a spoon.',
      'Blend until smooth, or mash well for a rougher soup.',
      'Season, and thin with a little water if it is too thick.',
    ],
    note:
        'Crown pumpkin holds its flavour well. Roasting the chunks '
        'first, at 200C for half an hour, makes it sweeter again.',
  );

  static const roastRootsAndLentils = Recipe(
    id: 'autumn-roast-roots-and-lentils',
    name: 'Roasted root vegetables with lentils',
    season: Season.autumn,
    description: 'Sweet roasted roots, with lentils underneath.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 45),
    servings: 4,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient.count(2, 'kumara, cut into chunks'),
      Ingredient.count(3, 'carrots, cut into batons'),
      Ingredient.count(2, 'parsnips, cut into chunks'),
      Ingredient(2, 'tbsp', 'olive oil'),
      Ingredient(1, 'tsp', 'ground coriander'),
      Ingredient(200, 'g', 'brown or green lentils'),
      Ingredient.count(1, 'lemon, juiced'),
      Ingredient(1, 'small handful', 'parsley, chopped'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Heat the oven to 200C.',
      'Toss the vegetables with the oil, coriander, salt and pepper, '
          'and spread them out on a large tray.',
      'Roast for 40 to 45 minutes, turning once, until tender and '
          'browned at the edges.',
      'Meanwhile simmer the lentils in plenty of unsalted water for 25 '
          'minutes, until tender, then drain.',
      'Dress the warm lentils with the lemon juice, a little oil and '
          'salt.',
      'Spread the lentils on a platter, pile the roasted vegetables on '
          'top, and scatter the parsley.',
    ],
  );

  static const mushroomBarley = Recipe(
    id: 'autumn-mushroom-barley-risotto',
    name: 'Mushroom and barley risotto',
    season: Season.autumn,
    description: 'Chewier than rice, and it looks after itself.',
    prepTime: Duration(minutes: 10),
    cookTime: Duration(minutes: 45),
    servings: 4,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient(2, 'tbsp', 'olive oil'),
      Ingredient.count(1, 'onion, finely chopped'),
      Ingredient.count(2, 'cloves garlic, chopped'),
      Ingredient(400, 'g', 'mushrooms, sliced'),
      Ingredient(1, 'tsp', 'chopped thyme'),
      Ingredient(250, 'g', 'pearl barley'),
      Ingredient(1.2, 'litres', 'vegetable stock, hot'),
      Ingredient(40, 'g', 'parmesan, grated'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Warm the oil in a wide pot and cook the onion gently until soft.',
      'Turn the heat up, add the mushrooms and thyme, and cook until '
          'they have browned and given up their liquid, about eight '
          'minutes. Add the garlic near the end.',
      'Stir in the barley and let it toast for a minute.',
      'Add the hot stock a few ladles at a time, stirring now and then '
          'and waiting until each addition is absorbed.',
      'Carry on for 35 to 40 minutes, until the barley is tender but '
          'still has some bite.',
      'Stir in the parmesan, season, and let it sit for two minutes '
          'before serving.',
    ],
    note:
        'Barley is far more forgiving than risotto rice, so it does '
        'not need constant stirring.',
  );

  static const appleOatBake = Recipe(
    id: 'autumn-apple-and-oat-bake',
    name: 'Apple and oat bake',
    season: Season.autumn,
    description: 'Soft apples, cinnamon, a crisp oat top.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 40),
    servings: 6,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient.count(6, 'apples, peeled and sliced'),
      Ingredient(2, 'tbsp', 'sugar'),
      Ingredient(1, 'tsp', 'ground cinnamon'),
      Ingredient(2, 'tbsp', 'water'),
      Ingredient(150, 'g', 'rolled oats'),
      Ingredient(70, 'g', 'flour'),
      Ingredient(70, 'g', 'brown sugar'),
      Ingredient(110, 'g', 'butter, melted'),
    ],
    method: [
      'Heat the oven to 180C.',
      'Toss the apples with the sugar, cinnamon and water, and spread '
          'them in a baking dish.',
      'Stir the oats, flour and brown sugar together, then pour in the '
          'melted butter and mix to rough clumps.',
      'Spoon the topping over the apples.',
      'Bake for 40 minutes, until the top is crisp and the fruit is '
          'soft when you push a knife in.',
    ],
    note:
        'Any eating apple works. Cooking apples collapse more, which '
        'some people prefer.',
  );

  static const all = [
    pumpkinSoup,
    roastRootsAndLentils,
    mushroomBarley,
    appleOatBake,
  ];
}
