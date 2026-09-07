import 'nature_birds.dart';
import 'nature_fungi.dart';
import 'nature_insects.dart';
import 'nature_item.dart';
import 'nature_plants.dart';

export 'nature_item.dart';

/// The Nature Book: a modest, offline guide to what is around.
///
/// Static data bundled with the app — no species API, no uploads, no
/// identification. It is a small shelf of things people in New Zealand
/// are genuinely likely to meet, native and introduced side by side and
/// without comment on which is which.
///
/// **Where the seasonal notes come from.** Each is the uncontroversial
/// middle of what the standard New Zealand sources say — the Department
/// of Conservation's species pages, New Zealand Birds Online, and the
/// month-by-month observations in general field guides — reduced to a
/// broad window and phrased as an invitation to look. Where sources
/// disagreed the narrower window was kept. Nothing here is a claim that
/// anything will be seen.
abstract final class NatureBook {
  /// Everything, grouped by category and alphabetical within it.
  static final all = <NatureItem>[
    for (final category in NatureCategory.values) ...ofCategory(category),
  ];

  /// One shelf, alphabetically by the name it leads with.
  static List<NatureItem> ofCategory(NatureCategory category) =>
      _byCategory[category] ?? const [];

  static final Map<NatureCategory, List<NatureItem>> _byCategory = {
    for (final entry in <NatureCategory, List<NatureItem>>{
      NatureCategory.bird: NatureBirds.all,
      NatureCategory.plant: NaturePlants.all,
      NatureCategory.insect: NatureInsects.all,
      NatureCategory.fungi: [
        for (final item in NatureFungiAndOther.all)
          if (item.category == NatureCategory.fungi) item,
      ],
      NatureCategory.other: [
        for (final item in NatureFungiAndOther.all)
          if (item.category == NatureCategory.other) item,
      ],
    }.entries)
      entry.key: List.unmodifiable(
        [...entry.value]
          ..sort((a, b) => a.primaryName.compareTo(b.primaryName)),
      ),
  };

  static final Map<String, NatureItem> _byId = {
    for (final item in all) item.id: item,
  };

  /// The entry with this id, or null.
  ///
  /// Null rather than throwing: an observation saved by a later version
  /// of the app may name an entry this one has never heard of, and that
  /// must not be fatal — see [NatureObservation.label].
  static NatureItem? tryFind(String id) => _byId[id];

  static NatureItem byId(String id) => _byId[id]!;

  static bool contains(String id) => _byId.containsKey(id);
}
