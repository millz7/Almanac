import 'package:flutter/foundation.dart';

import '../../../core/context/festival_id.dart';

export '../../../core/context/festival_id.dart' show FestivalId;

/// A festival's small thematic set of food and drink ideas.
///
/// **Suggestions, not recipes.** The Wheel owns this content — it is
/// about what a festival means, not about how to cook — so it is three
/// short lines rather than a method and an ingredient list. Where the
/// Cookbook shows these, it says plainly that they are suggestions, not
/// full recipes.
///
/// Written in terms of the season each festival actually falls in
/// (winter, early harvest, and so on) rather than named produce tied to
/// a calendar month, so the same words are honestly true in both
/// hemispheres: a Southern Hemisphere Yule is midwinter exactly as a
/// Northern one is, even though the date on the wall is different.
@immutable
class FestivalFoodTheme {
  const FestivalFoodTheme({
    required this.meal,
    required this.treat,
    required this.drink,
  });

  final String meal;
  final String treat;
  final String drink;
}

/// One festival of the Wheel of the Year: what it is, and what it might
/// mean to prepare for, celebrate, cook for, reflect on and notice
/// outside.
///
/// **Modern Pagan, not ancient-and-unbroken.** The copy throughout is
/// deliberately modest about history — "in many modern Pagan
/// traditions", "some people mark this by" — because the eight-festival
/// wheel as observed today is a twentieth-century synthesis drawing on
/// varied older folk customs, not one continuous, universal tradition.
///
/// **No claims beyond the reflective.** Nothing here says a practice
/// changes a hormone, heals anything, or guarantees an outcome. Where a
/// festival touches remembrance or intention, it is framed as personal
/// meaning, never as a prescription.
@immutable
class Festival {
  const Festival({
    required this.id,
    required this.seasonalPosition,
    required this.theme,
    required this.about,
    required this.prepare,
    required this.celebrate,
    required this.food,
    required this.reflection,
    required this.nature,
  });

  final FestivalId id;

  /// "Yule".
  String get name => id.label;

  /// "Winter solstice — the longest night of the year".
  final String seasonalPosition;

  /// A short theme: "Returning light".
  final String theme;

  /// One or two paragraphs of context — where it sits in the wheel, and
  /// its common modern themes.
  final List<String> about;

  /// A handful of optional, practical ideas for preparing.
  final List<String> prepare;

  /// A handful of accessible ways someone might mark the day.
  final List<String> celebrate;

  final FestivalFoodTheme food;

  /// A short reflective prompt, offered rather than assigned.
  final String reflection;

  /// What to notice outside around this point in the year.
  final String nature;

  @override
  String toString() => 'Festival(${id.name})';
}

/// The eight festivals, in wheel order.
///
/// Static content, the same shape as the Cookbook's own recipe
/// catalogue: the screens consume it, so changing a festival's words is
/// an entry here and no change to any widget.
abstract final class WheelOfYear {
  static const festivals = <Festival>[
    Festival(
      id: FestivalId.yule,
      seasonalPosition: 'Winter solstice — the longest night of the year',
      theme: 'Returning light',
      about: [
        "Yule falls on the winter solstice, the year's longest night, "
            'when the sun is at its lowest and daylight begins — almost '
            'imperceptibly at first — to lengthen again.',
        'In many modern Pagan traditions, Yule is read as a turning '
            'point rather than an ending: the dark has reached its '
            'depth, and from here the light returns. Themes of rest, '
            'warmth and the slow return of the sun run through most '
            'modern observances, echoing older midwinter customs found '
            'across many cultures without claiming one unbroken line '
            'back to them.',
      ],
      prepare: [
        'You might bring evergreen branches or a few sprigs of '
            'something green indoors, echoing the old idea that some '
            'green endures through winter.',
        'Some people set aside a little time to slow down before the '
            'solstice itself, rather than treating midwinter as just '
            'another busy week.',
        'Preparing a warm meal or a batch of something spiced ahead of '
            'time is one way to mark the date without much ceremony.',
      ],
      celebrate: [
        'A quiet evening with candles or firelight, marking the return '
            'of the light.',
        'A walk at dusk on the shortest day, noticing how early it '
            'falls.',
        'Sharing a meal with people who matter to you.',
        'Writing down what you would like to grow, ready for the year '
            'ahead.',
        'A solitary hour with a warm drink and no particular agenda.',
      ],
      food: FestivalFoodTheme(
        meal: 'A slow-roasted, warming main with root vegetables',
        treat: 'Spiced biscuits or a rich fruit cake',
        drink:
            'Mulled wine or spiced cider — the non-alcoholic version works '
            'just as well',
      ),
      reflection:
          'What in your life is ready to rest, and what are you waiting '
          'to see return?',
      nature:
          'Outside, growth has mostly stopped for the season; look instead '
          'for what still holds colour — berries, bark, evergreen '
          'needles — against the bare branches.',
    ),
    Festival(
      id: FestivalId.imbolc,
      seasonalPosition:
          'Cross-quarter — the first stirrings between winter and spring',
      theme: 'First stirrings',
      about: [
        'Imbolc sits roughly midway between the winter solstice and the '
            'spring equinox, at the point in the year when the worst of '
            'winter is behind but spring has not yet properly arrived.',
        'In many modern Pagan traditions, Imbolc is associated with '
            'early signs of life returning — the first shoots, longer '
            'afternoons — and with clearing space, physically and '
            'otherwise, for what is about to begin. It is often linked '
            'to hearth and home, and to Brigid in traditions that draw '
            'on that association, though practices here vary '
            'considerably.',
      ],
      prepare: [
        'You might use the day to tidy or freshen a room that has felt '
            'closed-up over winter.',
        'Some people light a candle in a window as a small, deliberate '
            'gesture toward the returning light.',
        'It can be a good moment to plan what you would like to grow '
            'or start in the months ahead, even if nothing is planted '
            'yet.',
      ],
      celebrate: [
        'A thorough clean of one room, done as a small ritual rather '
            'than a chore.',
        'Lighting candles through the evening.',
        'A walk to look for the first signs of anything growing.',
        'Making a simple hearth-side meal.',
        'Setting an intention for the season ahead, spoken aloud or '
            'written down.',
      ],
      food: FestivalFoodTheme(
        meal:
            'Something simple and warming made with early dairy or fresh '
            "greens where they're available",
        treat: 'Plain seed cake or shortbread',
        drink: 'Warm milk with honey, or a milky tea',
      ),
      reflection:
          'What small, unglamorous groundwork could you lay now for '
          'something you want later in the year?',
      nature:
          'Look for the earliest signs of change: lengthening light, the '
          'first buds, or birds beginning to call differently as the '
          'season turns.',
    ),
    Festival(
      id: FestivalId.ostara,
      seasonalPosition: 'Spring equinox — day and night in balance',
      theme: 'Balance and beginnings',
      about: [
        'Ostara falls on the spring equinox, when day and night are '
            'close to equal in length before the balance tips toward '
            'longer days.',
        'In many modern Pagan traditions, Ostara is a festival of new '
            'growth and beginnings — eggs, seeds and hares are common '
            'modern symbols of fertility and new life, borrowed and '
            'adapted from various folk traditions rather than drawn '
            'from a single ancient source.',
      ],
      prepare: [
        'You might start seeds indoors, or plan out what you would '
            'like to grow this year.',
        'Some people use the equinox to declutter, treating the '
            'balance of the day as an invitation to clear out what is '
            'no longer needed.',
        'Decorating eggs is a widely adopted modern custom around this '
            'time, whether or not it holds any particular meaning for '
            'you.',
      ],
      celebrate: [
        'Planting seeds, indoors or out.',
        'A balance-themed meal, half light and half hearty.',
        'Time outdoors at sunrise or sunset, when day and night '
            'briefly meet.',
        'Decorating eggs or another small craft with the people around '
            'you.',
        'A quiet moment naming one thing you would like to begin.',
      ],
      food: FestivalFoodTheme(
        meal: 'A fresh, light meal with the first spring vegetables',
        treat: 'Decorated eggs, or a simple lemon cake',
        drink: 'A herbal tea with something new-season in it, like mint',
      ),
      reflection:
          'Where in your life is there an imbalance you would like to '
          'even out?',
      nature:
          'Watch for the visible turn toward spring — buds opening, birds '
          'nesting, the first consistently warmer days.',
    ),
    Festival(
      id: FestivalId.beltane,
      seasonalPosition: "Cross-quarter — early summer's approach",
      theme: 'Vitality and connection',
      about: [
        'Beltane sits roughly midway between the spring equinox and '
            'the summer solstice, traditionally marking the start of '
            'the light half of the year in many older European '
            'calendars.',
        'In many modern Pagan traditions, Beltane is associated with '
            'vitality, fertility in a broad sense, and connection — to '
            'other people, to creativity, and to the outdoors as the '
            'weather warms. May Day customs such as flowers and '
            'maypoles are commonly folded into modern observance, '
            'again drawn from a range of folk practices rather than '
            'one continuous tradition.',
      ],
      prepare: [
        'You might gather flowers or greenery to bring indoors or '
            'wear.',
        'Some people plan a gathering, however small, around this '
            'time of year.',
        'It can be a good point to start or recommit to a creative '
            'project.',
      ],
      celebrate: [
        'A gathering with friends, outdoors if the weather allows.',
        'Making flower crowns or simple decorations from what is in '
            'season.',
        'An evening fire, where that is possible and safe.',
        'Dancing, or simply putting on music and moving.',
        'A quiet expression of gratitude for a relationship or '
            'connection that matters to you.',
      ],
      food: FestivalFoodTheme(
        meal:
            'Something bright and shared — a spread rather than a single '
            'dish',
        treat: 'Fresh fruit, or a simple flower-flavoured cake',
        drink: 'A light, fruity drink, chilled if the weather is warm',
      ),
      reflection:
          'What relationship or creative spark would you like to give '
          'more attention to right now?',
      nature:
          'Look for abundance building — full blossom, insects returning, '
          'the garden visibly filling in.',
    ),
    Festival(
      id: FestivalId.litha,
      seasonalPosition: 'Summer solstice — the longest day of the year',
      theme: 'Fullness and light',
      about: [
        "Litha falls on the summer solstice, the year's longest day, "
            'when the sun reaches its highest point before daylight '
            'slowly begins to shorten again.',
        'In many modern Pagan traditions, Litha is celebrated as a '
            'festival of abundance and fullness — the height of the '
            'light half of the year — and is often marked outdoors, '
            'making the most of the long day itself.',
      ],
      prepare: [
        'You might plan an early start to catch sunrise, or a late one '
            'for sunset, on the longest day.',
        'Some people gather herbs or flowers at their peak around this '
            'time.',
        "It's a natural point to plan time outdoors, if you haven't "
            'already.',
      ],
      celebrate: [
        'Watching sunrise or sunset on the solstice itself.',
        'A day spent mostly outdoors.',
        'A bonfire or barbecue with the people around you.',
        'Gathering flowers or herbs at their fullest.',
        'A moment of simple gratitude for whatever is currently '
            'flourishing in your life.',
      ],
      food: FestivalFoodTheme(
        meal:
            'A meal built around whatever is at its height in the garden '
            'or the market',
        treat: 'Fresh berries, simply served',
        drink:
            'Something cold and refreshing — iced tea or fruit-infused '
            'water',
      ),
      reflection:
          'What in your life is currently at its fullest, and how might '
          'you enjoy it before it changes?',
      nature:
          'The height of growth: gardens full, days long, and — where you '
          'are — the natural world at its most active.',
    ),
    Festival(
      id: FestivalId.lughnasadh,
      seasonalPosition: 'Cross-quarter — the first harvest',
      theme: 'Early harvest and gratitude',
      about: [
        'Lughnasadh sits roughly midway between the summer solstice '
            'and the autumn equinox, at the point many older '
            'agricultural calendars marked as the first harvest.',
        'In many modern Pagan traditions, Lughnasadh centres on grain, '
            'bread and the first gathering-in of a season of work — '
            'practical and grateful rather than solemn. Some '
            'traditions call it Lammas, from an Old English "loaf '
            'mass", reflecting the same early-harvest theme.',
      ],
      prepare: [
        'You might bake bread, or try a grain-based dish, as a simple '
            'nod to the theme.',
        'Some people use this point in the year to take stock of what '
            "they've been working on since spring.",
        "It's a natural moment to share something you've made or "
            'grown with others.',
      ],
      celebrate: [
        'Baking bread, alone or with others.',
        'A shared meal celebrating whatever is first ready to harvest '
            'where you are.',
        'A gathering to mark the halfway point of the working year.',
        'Games or friendly competition, echoing older harvest fair '
            'customs.',
        'A moment of thanks for effort that is starting to show '
            'results.',
      ],
      food: FestivalFoodTheme(
        meal:
            'Something built around bread or grain — a hearty loaf, a '
            'grain salad',
        treat: 'Fresh-baked bread with honey or jam',
        drink: 'A simple grain-based drink, or a warm grain-based tea',
      ),
      reflection:
          "What have you been quietly working toward, and what's the "
          "first sign it's paying off?",
      nature:
          'The first real harvest signs — grain fields turning gold, '
          'early fruit ripening, gardens starting to give back what was '
          'planted.',
    ),
    Festival(
      id: FestivalId.mabon,
      seasonalPosition: 'Autumn equinox — day and night in balance',
      theme: 'Balance and gathering in',
      about: [
        'Mabon falls on the autumn equinox, when day and night are '
            'close to equal again before the balance tips toward '
            'darker days.',
        'In many modern Pagan traditions, Mabon is a festival of the '
            'main harvest and of gratitude — a pause to gather in and '
            'take stock before the year turns toward winter. The name '
            'itself is a relatively modern coinage, adopted in the '
            '1970s for what earlier harvest customs had marked without '
            'this particular label.',
      ],
      prepare: [
        'You might use the equinox to take stock of the year so far, '
            'in a practical or reflective way.',
        'Some people preserve or store food around this time, echoing '
            'the older harvest-storing rhythm.',
        'It can be a good point to prepare your home for the colder '
            'months ahead.',
      ],
      celebrate: [
        'A shared harvest-style meal with seasonal produce.',
        'Preserving something — jam, pickles, dried herbs — for later '
            'in the year.',
        'A walk to notice the turning colours.',
        'A moment of gratitude for what the year has brought so far.',
        'Tidying and preparing your space for the darker months.',
      ],
      food: FestivalFoodTheme(
        meal:
            'A hearty harvest meal with root vegetables and whatever is '
            'freshly gathered',
        treat: 'Baked apples or a spiced fruit dessert',
        drink: 'Warm spiced cider or a robust tea',
      ),
      reflection:
          'What are you grateful for from this year so far, and what '
          'would you like to let go of as the days shorten?',
      nature:
          'The visible turn toward autumn — changing leaf colour, the '
          'last of the harvest, animals preparing for the colder months.',
    ),
    Festival(
      id: FestivalId.samhain,
      seasonalPosition: 'Cross-quarter — the descent into winter',
      theme: 'Remembrance and endings',
      about: [
        'Samhain sits roughly midway between the autumn equinox and '
            'the winter solstice, traditionally marking the start of '
            'the dark half of the year in many older European '
            'calendars and, for many modern Pagans, the start of a new '
            'year.',
        'In many modern Pagan traditions, Samhain is a time for '
            'remembrance — of the year now ending, and of people no '
            'longer here — and for quiet reflection as the natural '
            'world visibly withdraws into winter. Its popular modern '
            'association with Halloween shares some roots but has '
            'become its own, largely separate, secular observance.',
      ],
      prepare: [
        'You might set aside a quiet moment to think of people or '
            'things you have lost this year, or in years past.',
        'Some people use this point to reflect honestly on what the '
            'past year has held.',
        "It's a natural time to prepare your home, and yourself, for "
            "winter's slower pace.",
      ],
      celebrate: [
        'A quiet evening with candles, thinking of those who are no '
            'longer here.',
        'A simple meal shared with the people close to you now.',
        'A walk as the light fades early, noticing the season shift.',
        "Writing down what you're ready to let go of as the year "
            'turns.',
        'A moment of stillness rather than activity.',
      ],
      food: FestivalFoodTheme(
        meal:
            'A warming, simple meal — root vegetables, slow-cooked '
            'dishes',
        treat: 'Spiced apple dishes or a simple fruit-filled pastry',
        drink: 'A dark, warming drink — mulled cider or a rich tea',
      ),
      reflection:
          'Who or what from this year do you want to remember, and what '
          'are you ready to release as it ends?',
      nature:
          'The natural world visibly withdrawing — bare trees, shorter '
          'days, the last of the leaves falling.',
    ),
  ];

  /// The content for a festival. Total: every [FestivalId] has an entry
  /// — `wheel_catalogue_test.dart` proves it.
  static Festival byId(FestivalId id) =>
      festivals.firstWhere((festival) => festival.id == id);
}
