/// Ingredient-aware content checks for the Cookbook's tests.
///
/// The point of these checks is to keep genuinely unsuitable things out
/// of the recipes — alcohol, peanuts, health claims — and a plain
/// substring search is bad at that in both directions. It is too eager
/// on names that merely *contain* a word:
///
/// * **red wine vinegar** is vinegar. It is made from wine, the alcohol
///   is gone, and it sits in every ordinary pantry.
/// * **butter beans** are lima beans. The butter is a description of
///   their texture; there is no dairy in them.
/// * **coconut milk** is not dairy, **eggplant** is not an egg, and
///   **crumbled** feta contains no rum.
///
/// So each check first rewrites the compounds a cook would recognise —
/// `butter beans` becomes `beans`, `red wine vinegar` becomes `vinegar` —
/// and only then looks for whole words. That way the distinction is a
/// culinary one rather than a spelling coincidence, and a real bottle of
/// wine or a real block of butter is still caught.
library;

/// Drinks. Anything on this list, standing on its own, is alcohol.
const alcoholicIngredients = [
  'wine',
  'beer',
  'lager',
  'ale',
  'stout',
  'cider',
  'brandy',
  'cognac',
  'rum',
  'vodka',
  'gin',
  'whisky',
  'whiskey',
  'bourbon',
  'tequila',
  'sherry',
  'port',
  'vermouth',
  'marsala',
  'sake',
  'liqueur',
  'kirsch',
  'schnapps',
  'prosecco',
  'champagne',
  'spirits',
];

/// Meat and fish: what stops something being vegetarian.
const meatAndFish = [
  'chicken',
  'beef',
  'steak',
  'mince',
  'lamb',
  'pork',
  'ham',
  'bacon',
  'prosciutto',
  'sausage',
  'chorizo',
  'duck',
  'venison',
  'fish',
  'salmon',
  'tuna',
  'anchovy',
  'anchovies',
  'prawn',
  'prawns',
  'squid',
  'mussels',
  'gelatine',
  'lard',
  'stock cube',
];

/// Everything from an animal: what stops something being vegan.
const animalProducts = [
  ...meatAndFish,
  'butter',
  'milk',
  'cream',
  'creme',
  'yoghurt',
  'yogurt',
  'cheese',
  'feta',
  'parmesan',
  'mozzarella',
  'halloumi',
  'ricotta',
  'egg',
  'eggs',
  'honey',
  'ghee',
  // Named so that a whole-word search for "butter" or "milk" misses it.
  'buttermilk',
  'creme fraiche',
];

/// Compounds that contain the name of a drink but are not one.
///
/// A vinegar is a vinegar whatever it was made from: the alcohol is
/// fermented away, and "red wine vinegar" is the name on the bottle.
final _notActuallyAlcoholic = <RegExp, String>{
  RegExp(r'\b(?:red |white |rice )?(?:wine|cider|sherry|malt) vinegar\b'):
      'vinegar',
  RegExp(r'\bnon-alcoholic\b'): '',
  // Vanilla extract is a flavouring sold on a supermarket shelf, not a
  // drink, and no recipe here uses it for anything else.
  RegExp(r'\bvanilla extract\b'): 'vanilla',
};

/// Compounds that contain the name of an animal product but are not one.
final _notActuallyAnimal = <RegExp, String>{
  // Beans named for their texture.
  RegExp(r'\bbutter beans?\b'): 'beans',
  RegExp(r'\bbutter ?nut (squash|pumpkin)\b'): 'squash',
  // Plant milks, creams and butters.
  RegExp(r'\bcoconut (milk|cream|butter|yoghurt|yogurt)\b'): 'coconut',
  RegExp(r'\b(oat|soy|soya|almond|cashew|rice|hemp) (milk|cream)\b'): 'plant',
  RegExp(r'\b(almond|cashew|nut|seed|cocoa|shea) butter\b'): 'nut paste',
  RegExp(r'\bpeanut butter\b'): 'nut paste',
  // Vegetables and pastries whose names simply contain one.
  RegExp(r'\begg ?plants?\b'): 'aubergine',
  // A raising agent, despite the name.
  RegExp(r'\bcream of tartar\b'): 'raising agent',
};

String _rewrite(String text, Map<RegExp, String> compounds) {
  var cleaned = text.toLowerCase();
  for (final MapEntry(key: pattern, value: replacement) in compounds.entries) {
    cleaned = cleaned.replaceAll(pattern, replacement);
  }
  return cleaned;
}

/// Whole words only, so "crumbled" is not rum and "carbonara" is not a
/// carb.
bool mentionsWord(String text, String word) =>
    RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false).hasMatch(text);

/// Which of [words] [text] genuinely mentions, after the compounds in
/// [compounds] have been rewritten. Returns the offending words so a
/// failing test can name them.
List<String> _found(
  String text,
  List<String> words,
  Map<RegExp, String> compounds,
) {
  final cleaned = _rewrite(text, compounds);
  return [
    for (final word in words)
      if (mentionsWord(cleaned, word)) word,
  ];
}

/// Any genuinely alcoholic ingredient named in [text].
///
/// Empty for "1 tbsp red wine vinegar"; `['wine']` for "a splash of
/// white wine".
List<String> alcoholIn(String text) =>
    _found(text, alcoholicIngredients, _notActuallyAlcoholic);

/// Any meat or fish named in [text].
List<String> meatOrFishIn(String text) =>
    _found(text, meatAndFish, _notActuallyAnimal);

/// Anything from an animal named in [text].
///
/// Empty for "800 g tins cannellini or butter beans" and for "400 ml
/// tin coconut milk"; `['butter']` for "100 g butter, softened".
List<String> animalProductsIn(String text) =>
    _found(text, animalProducts, _notActuallyAnimal);

/// Which of [phrases] appear in [text] as whole words.
///
/// Used for the copy checks — health claims, calorie counting, food
/// moralising — where the same care applies: `\bcure\b` must not fire on
/// "cured", and `\bdiet\b` must not fire on "dietary".
List<String> phrasesIn(String text, List<String> phrases) => [
  for (final phrase in phrases)
    if (mentionsWord(text, phrase)) phrase,
];
