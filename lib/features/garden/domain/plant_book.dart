import 'plant.dart';
import 'plants_flowers.dart';
import 'plants_fruit.dart';
import 'plants_herbs.dart';
import 'plants_vegetables.dart';

export 'gardening_region.dart';
export 'gardening_rule.dart';
export 'plant.dart';

/// The plant book: everything the app knows how to grow.
///
/// Static data bundled with the app. There is no network, no plant API
/// and nothing to fetch — the whole book ships in the binary and works
/// on a phone in a paddock with no signal.
///
/// **Where the windows come from.** Each plant's months are the common
/// ground between the standard New Zealand home-gardening references —
/// seed-packet sowing charts, the month-by-month calendars the seed
/// companies publish, and the regional planting guides — reconciled
/// conservatively: where sources disagreed, the narrower window was
/// kept, and where a month was marginal it was left out. They are
/// written for **temperate New Zealand** and read by the other bands
/// through [GardeningRegion.monthOffset]. They are broad on purpose.
/// Nothing here is a day-level claim, and the screens say so.
abstract final class PlantBook {
  /// Every plant, grouped by category and alphabetical within it.
  ///
  /// The order is stable, so a list on screen never reshuffles itself
  /// between builds, and there is a test that says so.
  static final all = <PlantDefinition>[
    for (final category in PlantCategory.values) ...ofCategory(category),
  ];

  /// One shelf of the book, alphabetically.
  static List<PlantDefinition> ofCategory(PlantCategory category) =>
      _byCategory[category]!;

  static final Map<PlantCategory, List<PlantDefinition>> _byCategory = {
    for (final entry in {
      PlantCategory.vegetable: VegetablePlants.all,
      PlantCategory.herb: HerbPlants.all,
      PlantCategory.fruit: FruitPlants.all,
      PlantCategory.flower: FlowerPlants.all,
    }.entries)
      entry.key: List.unmodifiable(
        [...entry.value]..sort((a, b) => a.name.compareTo(b.name)),
      ),
  };

  static final Map<String, PlantDefinition> _byId = {
    for (final plant in all) plant.id: plant,
  };

  /// The plant with this id, or null.
  ///
  /// Null rather than throwing: a garden saved by a future version of
  /// the app may name a plant this one has never heard of, and that
  /// should be quietly ignored rather than fatal.
  static PlantDefinition? tryFind(String id) => _byId[id];

  /// The plant with this id. Only for ids known to exist.
  static PlantDefinition byId(String id) => _byId[id]!;

  static bool contains(String id) => _byId.containsKey(id);
}
