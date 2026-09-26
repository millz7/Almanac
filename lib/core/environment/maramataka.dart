import 'package:flutter/foundation.dart';

/// Where a piece of Maramataka content comes from.
///
/// Every night carries one of these, and the Moon page names the sources
/// in words, so nothing here can be mistaken for the app's own account.
enum MaramatakaSource {
  /// Te Ara — The Encyclopedia of New Zealand, "Maramataka – the lunar
  /// calendar" by Paul Meredith (Manatū Taonga, first published 2006),
  /// page 2, "Nights of the month". The list there is "adapted from the
  /// names and observations made by members of Ngāti Kahungunu", and Te
  /// Ara in turn cites Elsdon Best, *The Maori division of time*
  /// (Dominion Museum monograph no. 4), pp. 34–35. Page 3, "Planting and
  /// fishing", names the kūmara planting nights and the Korekore nights.
  ///
  /// Te Ara text is licensed CC BY-NC 3.0 NZ.
  teAra(
    'Te Ara — The Encyclopedia of New Zealand',
    '"Maramataka – the lunar calendar", Paul Meredith. The night names '
        'and notes are Te Ara\'s list, adapted from names and observations '
        'made by members of Ngāti Kahungunu, recorded by Elsdon Best.',
  ),

  /// Museum of New Zealand Te Papa Tongarewa, "What is the Maramataka |
  /// the Māori lunar calendar?" and "Nights in the Maramataka | the Māori
  /// lunar month". Used for the general background only — the length of
  /// the month, where it begins for different iwi, and what it guided —
  /// never mixed into the night-by-night sequence, which is Te Ara's
  /// alone.
  tePapa(
    'Museum of New Zealand Te Papa Tongarewa',
    '"What is the Maramataka | the Māori lunar calendar?" and "Nights in '
        'the Maramataka | the Māori lunar month".',
  );

  const MaramatakaSource(this.name, this.detail);

  /// The source's own name, as a person would say it.
  final String name;

  /// Which pages, in a sentence.
  final String detail;
}

/// One named night of the lunar month in the reference sequence.
///
/// Content, not calculation: the name exactly as the source prints it,
/// macrons and all, and the source's own words about it. Nothing here is
/// a translation or a story the source does not tell.
@immutable
class MaramatakaNight {
  const MaramatakaNight({
    required this.id,
    required this.order,
    required this.name,
    required this.about,
    this.associations = const [],
    this.source = MaramatakaSource.teAra,
  });

  /// Stable, never shown: what a saved Journal page records.
  final String id;

  /// Its place in the month, 1 to 30.
  final int order;

  /// The night's name, exactly as published.
  final String name;

  /// The source's note on this night, quoted.
  final String about;

  /// What the source explicitly says this night was used, or not used,
  /// for — beyond the note itself. Empty when the source says nothing
  /// more, and then nothing more is shown.
  final List<String> associations;

  final MaramatakaSource source;
}

/// The Māori lunar calendar, as one published reference sequence.
///
/// **One sequence, not "the" Maramataka.** Traditions vary between iwi
/// and rohe — in the order of nights, their names, and where the month
/// begins. This is Te Ara's published list (see [MaramatakaSource.teAra]),
/// used whole and unaltered. It is not merged with any other list, and
/// the Moon page says so.
///
/// **Estimated, from the astronomy the app already does.** The night is
/// worked out from the Moon's age in the existing astronomical model —
/// there is no second Moon calculation — by dividing the synodic month
/// evenly between the 30 named nights, starting from the new moon. The
/// traditional way was to watch the Moon, and it varied; the app says
/// "estimated" wherever it shows the result.
abstract final class Maramataka {
  /// Which sequence a saved Journal page used.
  static const referenceId = 'te-ara-ngati-kahungunu';

  /// The average synodic month, the same figure the Moon model uses.
  static const synodicMonthDays = 29.530588861;

  static const variationNote =
      'Maramataka traditions vary between iwi and rohe. This view uses a '
      'published reference sequence and should not be read as universal.';

  static const estimateNote =
      'The current night is estimated from the Moon\'s astronomical age. '
      'Traditionally the nights were read by watching the Moon itself.';

  /// Te Papa's general background, in the app's own words and attributed.
  static const background = [
    'A lunar month lasts about 29.5 days, and each night has its own name.',
    'For most iwi the lunar month begins with the new moon (Whiro); for '
        'some it begins with the full moon (Rākaunui).',
    'The Maramataka was consulted for planting, harvesting and fishing, '
        'and many other activities of the natural world.',
  ];

  /// What the kūmara note says, for the six nights Te Ara names.
  static const _kumara =
      'Te Ara notes that kūmara were traditionally planted on this night.';

  /// What the Korekore note says, for the three nights Te Ara names.
  static const _noPlanting =
      'Te Ara notes that no planting was traditionally done on the '
      'Korekore nights.';

  /// The 30 nights, in order, from Te Ara's list. Names and notes are
  /// quoted; Te Ara prints the sixth as "Tamat[e]a-ngana", marking an
  /// editorial letter, which is written here as the restored name.
  static const nights = <MaramatakaNight>[
    MaramatakaNight(
      id: 'whiro',
      order: 1,
      name: 'Whiro',
      about: 'An unpleasant day, the new moon appears.',
    ),
    MaramatakaNight(
      id: 'tirea',
      order: 2,
      name: 'Tirea',
      about: 'The moon is very small.',
    ),
    MaramatakaNight(
      id: 'hoata',
      order: 3,
      name: 'Hoata',
      about: 'A pleasing day, the moon is still small.',
    ),
    MaramatakaNight(
      id: 'ouenuku',
      order: 4,
      name: 'Ōuenuku',
      about: 'Get to work! A good night for eeling.',
      associations: [_kumara],
    ),
    MaramatakaNight(
      id: 'okoro',
      order: 5,
      name: 'Okoro',
      about: 'A pleasing day in the afternoon, good for eeling at night.',
    ),
    MaramatakaNight(
      id: 'tamatea-ngana',
      order: 6,
      name: 'Tamatea-ngana',
      about: 'Unpleasant weather, the sea is rough.',
    ),
    MaramatakaNight(
      id: 'tamatea-kai-ariki',
      order: 7,
      name: 'Tamatea-kai-ariki',
      about: 'The weather improves.',
    ),
    MaramatakaNight(
      id: 'huna',
      order: 8,
      name: 'Huna',
      about: 'Bad weather, food products suffer.',
    ),
    MaramatakaNight(
      id: 'ari-roa',
      order: 9,
      name: 'Ari-roa',
      about: 'Favourable for spearing eels.',
      associations: [_kumara],
    ),
    MaramatakaNight(
      id: 'maure',
      order: 10,
      name: 'Maure',
      about: 'A fine, desirable day.',
    ),
    MaramatakaNight(
      id: 'mawharu',
      order: 11,
      name: 'Māwharu',
      about: 'Crayfish are taken on this day.',
    ),
    MaramatakaNight(
      id: 'ohua',
      order: 12,
      name: 'Ohua',
      about: 'A good day for working.',
    ),
    MaramatakaNight(
      id: 'hotu',
      order: 13,
      name: 'Hotu',
      about: 'An unpleasant day, the sea is rough.',
    ),
    MaramatakaNight(
      id: 'atua',
      order: 14,
      name: 'Atua',
      about: 'An abominable day.',
    ),
    MaramatakaNight(
      id: 'turu',
      order: 15,
      name: 'Turu',
      about: 'A day to collect food from the sea.',
    ),
    MaramatakaNight(
      id: 'rakau-nui',
      order: 16,
      name: 'Rākau-nui',
      about:
          'The moon is filled out, produce from the sea is the staple '
          'food.',
      associations: [_kumara],
    ),
    MaramatakaNight(
      id: 'rakau-matohi',
      order: 17,
      name: 'Rākau-matohi',
      about: 'A fine day, the moon now wanes.',
      associations: [_kumara],
    ),
    MaramatakaNight(
      id: 'takirau',
      order: 18,
      name: 'Takirau',
      about: 'Fine weather during the morning.',
      associations: [_kumara],
    ),
    MaramatakaNight(
      id: 'oike',
      order: 19,
      name: 'Oike',
      about: 'The afternoon is favourable.',
    ),
    MaramatakaNight(
      id: 'korekore-te-whiwhia',
      order: 20,
      name: 'Korekore-te-whiwhia',
      about: 'A bad day.',
      associations: [_noPlanting],
    ),
    MaramatakaNight(
      id: 'korekore-te-rawea',
      order: 21,
      name: 'Korekore-te-rawea',
      about: 'A bad day.',
      associations: [_noPlanting],
    ),
    MaramatakaNight(
      id: 'korekore-hahani',
      order: 22,
      name: 'Korekore-hahani',
      about: 'A fairly good day.',
      associations: [_noPlanting],
    ),
    MaramatakaNight(
      id: 'tangaroa-a-mua',
      order: 23,
      name: 'Tangaroa-ā-mua',
      about: 'A good day for fishing.',
    ),
    MaramatakaNight(
      id: 'tangaroa-a-roto',
      order: 24,
      name: 'Tangaroa-ā-roto',
      about: 'A good day for fishing.',
    ),
    MaramatakaNight(
      id: 'tangaroa-kiokio',
      order: 25,
      name: 'Tangaroa-kiokio',
      about: 'An excellent day for fishing, a misty aspect prevails on land.',
    ),
    MaramatakaNight(
      id: 'otane',
      order: 26,
      name: 'Ōtāne',
      about: 'A good day, and a good night for eeling.',
    ),
    MaramatakaNight(
      id: 'orongonui',
      order: 27,
      name: 'Ōrongonui',
      about: 'A desirable day, the īnanga (whitebait) migrate.',
      associations: [_kumara],
    ),
    MaramatakaNight(
      id: 'mauri',
      order: 28,
      name: 'Mauri',
      about: 'The morning is fine, the moon has now darkened.',
    ),
    MaramatakaNight(id: 'omutu', order: 29, name: 'Ōmutu', about: 'A bad day.'),
    MaramatakaNight(
      id: 'mutuwhenua',
      order: 30,
      name: 'Mutuwhenua',
      about: 'An exceedingly bad day, the moon has expired.',
    ),
  ];

  /// The night with this id, or null for one this version does not know.
  static MaramatakaNight? tryById(String id) {
    for (final night in nights) {
      if (night.id == id) return night;
    }
    return null;
  }

  /// The estimated night for a Moon [ageInDays] old.
  ///
  /// The month is divided evenly: night n covers ages from (n − 1) to n
  /// thirtieths of a synodic month. An age outside one month — negative,
  /// or past the end — is wrapped into it first, so the answer is always
  /// one of the 30 nights and the new moon always reads Whiro.
  static MaramatakaNight nightForAge(double ageInDays) {
    if (!ageInDays.isFinite) return nights.first;
    final wrapped = ageInDays % synodicMonthDays;
    final index = (wrapped / synodicMonthDays * nights.length).floor();
    return nights[index.clamp(0, nights.length - 1)];
  }

  /// The span of Moon ages, in days, a night is estimated to cover.
  static ({double from, double to}) ageRangeOf(MaramatakaNight night) {
    const each = synodicMonthDays / 30;
    return (from: (night.order - 1) * each, to: night.order * each);
  }
}
