import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/environment/environment_providers.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock_providers.dart';
import '../data/garden_store.dart';
import '../data/shared_preferences_garden_store.dart';
import '../domain/garden_guide.dart';

export '../../../core/time/calendar_date.dart' show CalendarDate;
export '../../../core/time/clock_providers.dart' show todayProvider;
export '../data/garden_store.dart';
export '../domain/garden_guide.dart';

/// Which gardening guide the Garden is using.
///
/// **The one place location becomes gardening advice.** It reads the
/// environment the rest of the app already resolved — the same location
/// state and the same hemisphere the Environment screen shows — and
/// turns it into a band. It never asks for permission: opening Garden
/// must not make the phone put up a dialog, and there is a test for
/// that.
///
/// A shared position gives a place-based band; a hemisphere alone gives
/// the broader generic guide. Nothing in between is invented.
final gardeningGuideProvider = Provider<GardeningGuide>((ref) {
  final location = ref.watch(locationStateProvider).location;
  if (location != null) {
    return GardeningGuide(
      region: GardeningRegion.forLocation(location),
      source: GuideSource.location,
    );
  }

  return GardeningGuide(
    region: GardeningRegion.forHemisphere(
      ref.watch(resolvedHemisphereProvider).hemisphere,
    ),
    source: GuideSource.hemisphere,
  );
});

/// Where My Garden is kept. Tests override it; the app uses the
/// preferences-backed store, opened lazily on first use.
final gardenStoreProvider = Provider<GardenStore>(
  (ref) => SharedPreferencesGardenStore(),
);

/// What the user grows, and the only way to change it.
final myGardenProvider = AsyncNotifierProvider<GardenController, MyGarden>(
  GardenController.new,
);

class GardenController extends AsyncNotifier<MyGarden> {
  @override
  Future<MyGarden> build() => ref.read(gardenStoreProvider).read();

  MyGarden get _garden => state.value ?? MyGarden.empty;

  /// Adds a plant the user has just sown, from the Sow page.
  ///
  /// Entering through Sow says what state it is in and when it started,
  /// so neither has to be asked.
  Future<void> addSown(String plantId) {
    final today = ref.read(todayProvider);
    return _persist(
      _garden.adding(
        GardenPlant(
          instanceId: plantId,
          plantId: plantId,
          addedOn: today,
          state: EstablishmentState.sown,
          sownOn: today,
        ),
      ),
    );
  }

  /// Adds something the user already has growing.
  ///
  /// [started] is whatever date they knew, and null when they did not —
  /// which is left as null rather than being filled in with today.
  Future<void> addExisting({
    required String plantId,
    required EstablishmentState state,
    CalendarDate? started,
  }) {
    final today = ref.read(todayProvider);
    return _persist(
      _garden.adding(
        GardenPlant(
          instanceId: plantId,
          plantId: plantId,
          addedOn: today,
          state: state,
          // A recently sown plant's date is a sowing date; anything
          // further along is a planting date.
          sownOn: state == EstablishmentState.sown ? started : null,
          plantedOn: state == EstablishmentState.sown ? null : started,
        ),
      ),
    );
  }

  Future<void> setState(String plantId, EstablishmentState state) {
    final entry = _garden.find(plantId);
    if (entry == null) return Future.value();
    return _persist(_garden.updating(entry.copyWith(state: state)));
  }

  /// Records, changes or clears a known sowing date.
  Future<void> setSownOn(String plantId, CalendarDate? date) {
    final entry = _garden.find(plantId);
    if (entry == null) return Future.value();
    return _persist(
      _garden.updating(entry.copyWith(sownOn: date, clearSownOn: date == null)),
    );
  }

  /// Records, changes or clears a known planting date.
  Future<void> setPlantedOn(String plantId, CalendarDate? date) {
    final entry = _garden.find(plantId);
    if (entry == null) return Future.value();
    return _persist(
      _garden.updating(
        entry.copyWith(plantedOn: date, clearPlantedOn: date == null),
      ),
    );
  }

  Future<void> remove(String plantId) => _persist(_garden.removing(plantId));

  /// Removes everything, from memory and from storage.
  Future<void> clear() async {
    await ref.read(gardenStoreProvider).deleteAll();
    state = AsyncData(MyGarden.empty);
  }

  /// Writes first, then updates what the screen shows, so the app never
  /// displays a change that was not stored.
  Future<void> _persist(MyGarden next) async {
    await ref.read(gardenStoreProvider).write(next);
    state = AsyncData(next);
  }
}

/// What the calendar and the region suggest, for anybody: Sow and Plant.
///
/// Depends on where and when, and deliberately not on My Garden.
final generalGuideProvider = Provider<GeneralGuide>(
  (ref) => generalGuideFor(
    guide: ref.watch(gardeningGuideProvider),
    today: ref.watch(todayProvider),
  ),
);

/// What the user's own garden suggests: Tend, Harvest and Prune.
///
/// The layering the whole feature rests on — environment, then region
/// and rules, then My Garden — is visible right here in what this
/// watches.
final personalGuideProvider = Provider<PersonalGuide>(
  (ref) => personalGuideFor(
    guide: ref.watch(gardeningGuideProvider),
    today: ref.watch(todayProvider),
    garden: ref.watch(myGardenProvider).value ?? MyGarden.empty,
  ),
);
