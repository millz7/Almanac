import 'dart:io';

import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/garden/data/shared_preferences_garden_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/test_overrides.dart';

final testNow = DateTime.utc(2026, 9, 7, 12);
const testToday = CalendarDate(2026, 9, 7);

GardenPlant plant(
  String id, {
  EstablishmentState state = EstablishmentState.established,
  CalendarDate? sownOn,
  CalendarDate? plantedOn,
}) => GardenPlant(
  instanceId: id,
  plantId: id,
  addedOn: testToday,
  state: state,
  sownOn: sownOn,
  plantedOn: plantedOn,
);

void main() {
  group('the dedicated garden store', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('starts empty', () async {
      expect((await SharedPreferencesGardenStore().read()).isEmpty, isTrue);
    });

    test('keeps a garden across a restart', () async {
      await SharedPreferencesGardenStore().write(
        MyGarden([
          plant('tomato', state: EstablishmentState.sown, sownOn: testToday),
          plant('apple'),
        ]),
      );

      // A new store object on the same device: what a restart is.
      final reopened = await SharedPreferencesGardenStore().read();

      expect(reopened.plants.map((p) => p.plantId), ['tomato', 'apple']);
      expect(reopened.find('tomato')!.state, EstablishmentState.sown);
      expect(reopened.find('tomato')!.sownOn, testToday);
      expect(reopened.find('apple')!.state, EstablishmentState.established);
    });

    test('an unknown date stays unknown across a restart', () async {
      await SharedPreferencesGardenStore().write(MyGarden([plant('apple')]));

      final reopened = await SharedPreferencesGardenStore().read();

      // Not filled in with today, which would be a fabricated date.
      expect(reopened.find('apple')!.sownOn, isNull);
      expect(reopened.find('apple')!.plantedOn, isNull);
      expect(reopened.find('apple')!.startedOn, isNull);
    });

    test('clearing it really removes it', () async {
      final store = SharedPreferencesGardenStore();
      await store.write(MyGarden([plant('tomato')]));

      await store.deleteAll();

      expect((await SharedPreferencesGardenStore().read()).isEmpty, isTrue);
    });

    test('writes nothing outside its own key, and no coordinates', () async {
      await SharedPreferencesGardenStore().write(
        MyGarden([plant('tomato', sownOn: testToday)]),
      );

      for (final key in SharedPreferencesGardenStore.keys) {
        expect(key, startsWith('garden.'));
      }
      // Its keys and the other stores' keys are disjoint.
      expect(
        SharedPreferencesGardenStore.keys.intersection(
          SharedPreferencesCycleStore.keys,
        ),
        isEmpty,
      );
      final settingsSource = File(
        'lib/core/settings/shared_preferences_settings_store.dart',
      ).readAsStringSync();
      expect(settingsSource, isNot(contains('garden')));

      // And nothing in the feature stores a coordinate. Comments are
      // stripped first: the file says in prose that it stores no
      // coordinates, and a check that failed on that sentence would be
      // measuring the wrong thing.
      final storeCode = Directory('lib/features/garden/data')
          .listSync()
          .whereType<File>()
          .expand((file) => file.readAsLinesSync())
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final forbidden in [
        'latitude',
        'longitude',
        'GeoLocation',
        'locationState',
      ]) {
        expect(storeCode, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });

  group('a malformed record', () {
    test('costs its own line and nothing else', () {
      final garden = decodeGarden([
        'tomato|2026-09-07|sown|2026-09-01|',
        '', // empty
        'no-date|not-a-date|established||',
        '|2026-09-07|established||',
        'apple|2026-09-07|not-a-state||',
        'pear|2026-09-07',
        'lemon|2026-09-07|established||',
      ]);

      // The two good lines survive; the five broken ones are dropped
      // rather than taking the garden with them.
      expect(garden.plants.map((p) => p.plantId), ['tomato', 'lemon']);
      expect(garden.find('tomato')!.sownOn, const CalendarDate(2026, 9, 1));
    });

    test('a round trip through storage changes nothing', () {
      final garden = MyGarden([
        plant('tomato', state: EstablishmentState.sown, sownOn: testToday),
        plant('lemon', plantedOn: const CalendarDate(2024, 10, 1)),
        plant('mint'),
      ]);

      expect(decodeGarden(encodeGarden(garden)), garden);
    });

    test('an id this version has never heard of is kept, not deleted', () {
      // A garden written by a later version must not lose entries when
      // it is read by an earlier one: they are preserved in storage and
      // simply left out of what is shown.
      final garden = decodeGarden([
        'triffid|2026-09-07|established||',
        'tomato|2026-09-07|established||',
      ]);

      expect(garden.plants, hasLength(2));
      expect(garden.known.map((p) => p.plantId), ['tomato']);
      expect(encodeGarden(garden).first, startsWith('triffid'));
    });
  });

  group('the controller', () {
    ProviderContainer containerWith(GardenStore store) {
      final container = ProviderContainer(
        overrides: environmentOverrides(now: testNow, gardenStore: store),
      );
      addTearDown(container.dispose);
      return container;
    }

    test('first use is an empty garden', () async {
      final container = containerWith(InMemoryGardenStore());

      expect((await container.read(myGardenProvider.future)).isEmpty, isTrue);
    });

    test('adding from Sow records the plant, the day and the state', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);

      await container.read(myGardenProvider.notifier).addSown('lettuce');

      final entry = (await store.read()).find('lettuce')!;
      expect(entry.state, EstablishmentState.sown);
      expect(entry.sownOn, testToday);
      expect(entry.addedOn, testToday);
    });

    test('and a new launch still has it', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      await container.read(myGardenProvider.notifier).addSown('lettuce');

      final relaunched = containerWith(store);
      final garden = await relaunched.read(myGardenProvider.future);

      expect(garden.contains('lettuce'), isTrue);
      expect(garden.find('lettuce')!.sownOn, testToday);
    });

    test(
      'adding something already growing keeps an unknown date unknown',
      () async {
        final store = InMemoryGardenStore();
        final container = containerWith(store);
        await container.read(myGardenProvider.future);

        await container
            .read(myGardenProvider.notifier)
            .addExisting(
              plantId: 'apple',
              state: EstablishmentState.established,
            );

        final entry = (await store.read()).find('apple')!;
        expect(entry.state, EstablishmentState.established);
        expect(entry.sownOn, isNull);
        expect(entry.plantedOn, isNull);
        expect(entry.addedOn, testToday);
      },
    );

    test('a date the user does know is kept where it belongs', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      final notifier = container.read(myGardenProvider.notifier);

      await notifier.addExisting(
        plantId: 'pea',
        state: EstablishmentState.sown,
        started: const CalendarDate(2026, 8, 20),
      );
      await notifier.addExisting(
        plantId: 'lemon',
        state: EstablishmentState.established,
        started: const CalendarDate(2024, 10, 1),
      );

      // A sown plant's date is a sowing date; anything further along is
      // a planting date.
      expect(
        (await store.read()).find('pea')!.sownOn,
        const CalendarDate(2026, 8, 20),
      );
      expect(
        (await store.read()).find('lemon')!.plantedOn,
        const CalendarDate(2024, 10, 1),
      );
    });

    test('the state can be changed, and it survives a restart', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      await container.read(myGardenProvider.notifier).addSown('tomato');

      await container
          .read(myGardenProvider.notifier)
          .setState('tomato', EstablishmentState.seedling);

      final relaunched = containerWith(store);
      final garden = await relaunched.read(myGardenProvider.future);
      expect(garden.find('tomato')!.state, EstablishmentState.seedling);
    });

    test('a sowing date can be added, changed and forgotten', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      final notifier = container.read(myGardenProvider.notifier);
      await notifier.addExisting(
        plantId: 'carrot',
        state: EstablishmentState.seedling,
      );

      await notifier.setSownOn('carrot', const CalendarDate(2026, 8, 1));
      expect(
        (await store.read()).find('carrot')!.sownOn,
        const CalendarDate(2026, 8, 1),
      );

      await notifier.setSownOn('carrot', const CalendarDate(2026, 8, 10));
      expect(
        (await store.read()).find('carrot')!.sownOn,
        const CalendarDate(2026, 8, 10),
      );

      await notifier.setSownOn('carrot', null);
      expect((await store.read()).find('carrot')!.sownOn, isNull);
    });

    test('one plant can be removed and the rest stay', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      final notifier = container.read(myGardenProvider.notifier);
      await notifier.addSown('tomato');
      await notifier.addSown('lettuce');

      await notifier.remove('tomato');

      expect((await store.read()).plants.map((p) => p.plantId), ['lettuce']);
    });

    test('clearing empties memory and storage together', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      await container.read(myGardenProvider.notifier).addSown('tomato');

      await container.read(myGardenProvider.notifier).clear();

      expect(container.read(myGardenProvider).value!.isEmpty, isTrue);
      expect((await store.read()).isEmpty, isTrue);

      final relaunched = containerWith(store);
      expect((await relaunched.read(myGardenProvider.future)).isEmpty, isTrue);
    });

    test('the same plant twice is one entry', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);
      final notifier = container.read(myGardenProvider.notifier);

      await notifier.addSown('tomato');
      await notifier.addExisting(
        plantId: 'tomato',
        state: EstablishmentState.established,
      );

      final garden = await store.read();
      expect(garden.plants, hasLength(1));
      expect(garden.find('tomato')!.state, EstablishmentState.established);
    });

    test('nothing garden-shaped reaches the general settings store', () async {
      final store = InMemoryGardenStore();
      final container = containerWith(store);
      await container.read(myGardenProvider.future);

      await container.read(myGardenProvider.notifier).addSown('tomato');

      final settings = container.read(settingsStoreProvider).read();
      expect(settings.toString().toLowerCase(), isNot(contains('tomato')));
      expect(settings.toString().toLowerCase(), isNot(contains('garden')));
    });

    test('an entry does not describe itself in a log line', () {
      expect(
        plant('tomato', sownOn: testToday).toString(),
        isNot(contains('tomato')),
      );
      expect(
        plant('tomato', sownOn: testToday).toString(),
        isNot(contains('2026')),
      );
    });
  });
}
