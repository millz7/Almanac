import 'recipe.dart';

/// Spring: the first green things, and something sweet from the first
/// fruit.
abstract final class SpringRecipes {
  static const peaSoup = Recipe(
    id: 'spring-pea-and-mint-soup',
    name: 'Pea and mint soup',
    season: Season.spring,
    description: 'Bright green, and ready in half an hour.',
    prepTime: Duration(minutes: 10),
    cookTime: Duration(minutes: 20),
    servings: 4,
    tags: [DietaryTag.vegan, DietaryTag.vegetarian],
    ingredients: [
      Ingredient(1, 'tbsp', 'olive oil'),
      Ingredient.count(1, 'onion, chopped'),
      Ingredient.count(2, 'cloves garlic, sliced'),
      Ingredient(1, 'medium', 'potato, peeled and diced'),
      Ingredient(1, 'litre', 'vegetable stock'),
      Ingredient(600, 'g', 'peas, fresh or frozen'),
      Ingredient(1, 'small handful', 'mint leaves'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Warm the oil in a large pot over a medium heat.',
      'Add the onion and garlic and cook until soft, about five minutes.',
      'Add the potato and the stock, and simmer until the potato is '
          'tender, about ten minutes.',
      'Add the peas and cook for three minutes more, no longer.',
      'Take off the heat, add the mint, and blend until smooth. Mash '
          'well if you have nothing to blend with.',
      'Season, and loosen with a little more stock if it is thicker '
          'than you want.',
    ],
    note:
        'Frozen peas are picked and frozen quickly, so they are a '
        'good stand-in all year.',
  );

  static const greensFrittata = Recipe(
    id: 'spring-greens-frittata',
    name: 'Spring greens frittata',
    season: Season.spring,
    description: 'Whatever greens are about, baked with eggs.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 30),
    servings: 4,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient(1, 'tbsp', 'olive oil'),
      Ingredient.count(1, 'leek, washed and sliced'),
      Ingredient(200, 'g', 'silverbeet or spinach, chopped'),
      Ingredient(150, 'g', 'asparagus, cut into short lengths'),
      Ingredient.count(8, 'eggs'),
      Ingredient(100, 'ml', 'milk'),
      Ingredient(80, 'g', 'feta, crumbled'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Heat the oven to 180C and oil a medium baking dish.',
      'Warm the oil in a pan and cook the leek gently until soft.',
      'Add the greens and asparagus and cook for two minutes, until '
          'just wilted. Tip into the dish.',
      'Beat the eggs with the milk, season, and pour over the '
          'vegetables.',
      'Scatter the feta on top and bake for 25 to 30 minutes, until set '
          'in the middle.',
      'Rest for five minutes before cutting.',
    ],
    note: 'Good hot, and just as good cold the next day.',
  );

  static const lemonRoastChicken = Recipe(
    id: 'spring-lemon-herb-roast-chicken',
    name: 'Lemon and herb roast chicken',
    season: Season.spring,
    description: 'One tray, with the first of the new vegetables.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 75),
    servings: 4,
    ingredients: [
      Ingredient(1.5, 'kg', 'whole chicken'),
      Ingredient.count(1, 'lemon, halved'),
      Ingredient(2, 'tbsp', 'olive oil'),
      Ingredient(2, 'tbsp', 'chopped parsley and thyme'),
      Ingredient(500, 'g', 'new potatoes, halved'),
      Ingredient.count(2, 'carrots, cut into batons'),
      Ingredient(150, 'g', 'asparagus, trimmed'),
      Ingredient.toTaste('Salt and pepper'),
    ],
    method: [
      'Heat the oven to 200C.',
      'Sit the chicken in a large roasting tray, put the lemon halves '
          'inside it, and rub it with half the oil, the herbs, salt and '
          'pepper.',
      'Toss the potatoes and carrots in the rest of the oil and tuck '
          'them around the chicken.',
      'Roast for one hour, turning the vegetables once.',
      'Add the asparagus and roast for ten to fifteen minutes more, '
          'until the juices from the thickest part of the thigh run '
          'clear.',
      'Rest the chicken for ten minutes before carving, and spoon the '
          'pan juices over everything.',
    ],
  );

  static const strawberryCrumble = Recipe(
    id: 'spring-strawberry-rhubarb-crumble',
    name: 'Strawberry and rhubarb crumble',
    season: Season.spring,
    description: 'Sharp fruit under a soft oat lid.',
    prepTime: Duration(minutes: 15),
    cookTime: Duration(minutes: 35),
    servings: 6,
    tags: [DietaryTag.vegetarian],
    ingredients: [
      Ingredient(400, 'g', 'rhubarb, cut into short lengths'),
      Ingredient(300, 'g', 'strawberries, hulled and halved'),
      Ingredient(3, 'tbsp', 'sugar'),
      Ingredient(120, 'g', 'rolled oats'),
      Ingredient(80, 'g', 'flour'),
      Ingredient(60, 'g', 'brown sugar'),
      Ingredient(100, 'g', 'butter, softened'),
    ],
    method: [
      'Heat the oven to 180C.',
      'Toss the rhubarb and strawberries with the sugar and spread them '
          'in a baking dish.',
      'Rub the oats, flour, brown sugar and butter together with your '
          'fingers until it clumps.',
      'Scatter the topping over the fruit without pressing it down.',
      'Bake for 35 minutes, until the topping is golden and the fruit '
          'is bubbling at the edges.',
    ],
    note:
        'Rhubarb varies a lot in sharpness. Taste the fruit and add a '
        'little more sugar if it makes you wince.',
  );

  static const all = [
    peaSoup,
    greensFrittata,
    lemonRoastChicken,
    strawberryCrumble,
  ];
}
