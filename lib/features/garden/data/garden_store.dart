import '../../../core/time/calendar_date.dart';
import '../domain/gardening_rule.dart';
import '../domain/my_garden.dart';

/// Keeps My Garden on this device.
///
/// Its own store, its own keys, its own delete-everything — the same
/// shape as the Cycle's, and for a related reason: what somebody grows
/// is theirs, it has nothing to do with app preferences, and "clear my
/// garden" has to mean exactly that.
///
/// Local only. There is no remote implementation and nothing here
/// touches the network. **No coordinates are ever stored**: the garden
/// holds plants, and the region is worked out afresh from the
/// environment every time.
abstract interface class GardenStore {
  /// Reads what is stored. Returns an empty garden rather than throwing:
  /// a device that cannot read its own preferences should still show the
  /// feature.
  Future<MyGarden> read();

  /// Persists [garden]. Throws if it could not be written, so a caller
  /// never reports a save that did not happen.
  Future<void> write(MyGarden garden);

  /// Removes every trace of the garden from storage.
  Future<void> deleteAll();
}

/// A store that keeps the garden only for the lifetime of the process.
class InMemoryGardenStore implements GardenStore {
  InMemoryGardenStore([MyGarden? garden]) : _garden = garden ?? MyGarden.empty;

  MyGarden _garden;

  @override
  Future<MyGarden> read() async => _garden;

  @override
  Future<void> write(MyGarden garden) async => _garden = garden;

  @override
  Future<void> deleteAll() async => _garden = MyGarden.empty;
}

/// One entry, as a single stored line.
///
/// `plantId|addedOn|state|sownOn|plantedOn`, with an empty field for a
/// date the user did not know. Chosen over JSON because it is one line
/// per plant, it is readable if anybody ever looks, and an unparseable
/// line can be dropped on its own without taking the rest of the garden
/// with it.
String encodeGardenPlant(GardenPlant plant) => [
  plant.plantId,
  plant.addedOn.iso,
  plant.state.name,
  plant.sownOn?.iso ?? '',
  plant.plantedOn?.iso ?? '',
].join('|');

/// Reads one stored line, or null if it cannot be trusted.
///
/// Everything optional is allowed to be missing; everything required has
/// to parse. A line that does not is dropped — a corrupt file should
/// cost the entry it damaged and nothing more.
GardenPlant? decodeGardenPlant(String line) {
  final parts = line.split('|');
  if (parts.length < 3) return null;

  final plantId = parts[0].trim();
  if (plantId.isEmpty) return null;

  final addedOn = CalendarDate.tryParse(parts[1]);
  if (addedOn == null) return null;

  final state = EstablishmentState.values
      .where((value) => value.name == parts[2])
      .firstOrNull;
  if (state == null) return null;

  return GardenPlant(
    // One entry per plant type, so the plant's own id is the identity.
    instanceId: plantId,
    plantId: plantId,
    addedOn: addedOn,
    state: state,
    sownOn: parts.length > 3 ? CalendarDate.tryParse(parts[3]) : null,
    plantedOn: parts.length > 4 ? CalendarDate.tryParse(parts[4]) : null,
  );
}

/// Reads a whole stored garden, dropping any line that will not parse.
///
/// **Unknown plant ids are kept, not dropped.** A garden written by a
/// later version of the app may name a plant this one has never heard
/// of; deleting it would quietly destroy the user's record, so it is
/// preserved in storage and simply left out of anything shown (see
/// [MyGarden.known]). Downgrading the app therefore loses nothing.
MyGarden decodeGarden(List<String> lines) =>
    MyGarden([for (final line in lines) ?decodeGardenPlant(line)]);

List<String> encodeGarden(MyGarden garden) => [
  for (final plant in garden.plants) encodeGardenPlant(plant),
];
