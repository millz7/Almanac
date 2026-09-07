import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';
import 'plant_book.dart';

/// One plant the user actually grows.
///
/// **Only what the user told us.** A date is here because they entered
/// it, and is absent when they did not know — never filled in with a
/// guess. Nothing derived is stored: whether something can be harvested
/// today is worked out from the plant, the date and the region every
/// time it is asked, so the answer changes with the year instead of
/// going stale in a file.
///
/// **One entry per plant type, for now.** The same plant twice would
/// need names to tell the two apart, and naming a row of carrots is a
/// bigger question than this first version should answer. The model
/// carries an [instanceId] anyway, so allowing several later is a change
/// to the UI rather than to the file format.
@immutable
class GardenPlant {
  const GardenPlant({
    required this.instanceId,
    required this.plantId,
    required this.addedOn,
    required this.state,
    this.sownOn,
    this.plantedOn,
  });

  /// Stable for the life of this entry. Currently the plant id, since
  /// there is one entry per plant.
  final String instanceId;

  /// Which plant in the book. May name a plant this version has never
  /// heard of — see [PlantBook.tryFind].
  final String plantId;

  /// The day it was added to the Almanac. Always known: it is today.
  final CalendarDate addedOn;

  /// How far along it is, as the user described it.
  final EstablishmentState state;

  /// When it was sown, if the user knew. Null means unknown, and unknown
  /// is a real answer.
  final CalendarDate? sownOn;

  /// When it was planted out, if the user knew.
  final CalendarDate? plantedOn;

  /// The date this plant's life in the garden started, as far as the app
  /// knows. Null when nothing was recorded.
  CalendarDate? get startedOn => sownOn ?? plantedOn;

  /// How many weeks since sowing, or null when the date is unknown.
  ///
  /// Null is not zero. A rule that needs an age simply does not apply
  /// its age check when this is null.
  int? weeksSinceSowing(CalendarDate today) {
    final sown = sownOn;
    if (sown == null) return null;
    return today.daysSince(sown) ~/ 7;
  }

  GardenPlant copyWith({
    EstablishmentState? state,
    CalendarDate? sownOn,
    CalendarDate? plantedOn,
    bool clearSownOn = false,
    bool clearPlantedOn = false,
  }) => GardenPlant(
    instanceId: instanceId,
    plantId: plantId,
    addedOn: addedOn,
    state: state ?? this.state,
    sownOn: clearSownOn ? null : sownOn ?? this.sownOn,
    plantedOn: clearPlantedOn ? null : plantedOn ?? this.plantedOn,
  );

  @override
  bool operator ==(Object other) =>
      other is GardenPlant &&
      other.instanceId == instanceId &&
      other.plantId == plantId &&
      other.addedOn == addedOn &&
      other.state == state &&
      other.sownOn == sownOn &&
      other.plantedOn == plantedOn;

  @override
  int get hashCode =>
      Object.hash(instanceId, plantId, addedOn, state, sownOn, plantedOn);

  /// Says how much, never what. Cycle dates are not the only sensitive
  /// thing an app can leak into a log line.
  @override
  String toString() => 'GardenPlant(${state.name})';
}

/// Everything the user has told the Almanac they grow.
@immutable
class MyGarden {
  MyGarden([Iterable<GardenPlant> plants = const []])
    : plants = List.unmodifiable(plants);

  static final empty = MyGarden();

  /// In the order they were added.
  final List<GardenPlant> plants;

  bool get isEmpty => plants.isEmpty;
  bool get isNotEmpty => plants.isNotEmpty;

  bool contains(String plantId) =>
      plants.any((plant) => plant.plantId == plantId);

  GardenPlant? find(String plantId) {
    for (final plant in plants) {
      if (plant.plantId == plantId) return plant;
    }
    return null;
  }

  /// Only the entries this version of the app can still name.
  ///
  /// An id it does not recognise stays in the file — a future version
  /// may know it again — but is left out of anything shown.
  List<GardenPlant> get known => [
    for (final plant in plants)
      if (PlantBook.contains(plant.plantId)) plant,
  ];

  /// The known entries of one category, alphabetically by plant name.
  List<GardenPlant> ofCategory(PlantCategory category) {
    final matching = [
      for (final plant in known)
        if (PlantBook.byId(plant.plantId).category == category) plant,
    ];
    matching.sort(
      (a, b) =>
          PlantBook.byId(a.plantId).name
              .compareTo(PlantBook.byId(b.plantId).name),
    );
    return matching;
  }

  MyGarden adding(GardenPlant plant) =>
      MyGarden([...plants.where((p) => p.plantId != plant.plantId), plant]);

  MyGarden removing(String plantId) =>
      MyGarden(plants.where((plant) => plant.plantId != plantId));

  MyGarden updating(GardenPlant plant) => MyGarden([
    for (final existing in plants)
      if (existing.plantId == plant.plantId) plant else existing,
  ]);

  @override
  bool operator ==(Object other) =>
      other is MyGarden && listEquals(other.plants, plants);

  @override
  int get hashCode => Object.hashAll(plants);

  @override
  String toString() => 'MyGarden(${plants.length} plants)';
}
