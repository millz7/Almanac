import 'dart:io';

import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:almanac/features/garden/data/shared_preferences_garden_store.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/data/shared_preferences_nature_log_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/test_overrides.dart';

final testNow = DateTime.utc(2026, 9, 7, 12);
const testToday = CalendarDate(2026, 9, 7);

NatureObservation observation(
  String id, {
  CalendarDate? date,
  NatureCategory category = NatureCategory.bird,
  String label = 'Tūī',
  int order = 0,
  String? itemId,
  String? note,
  String? placeLabel,
}) => NatureObservation(
  instanceId: id,
  date: date ?? testToday,
  category: category,
  label: label,
  order: order,
  itemId: itemId,
  note: note,
  placeLabel: placeLabel,
);

void main() {
  group('the dedicated Nature Log store', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('starts empty', () async {
      expect((await SharedPreferencesNatureLogStore().read()).isEmpty, isTrue);
    });

    test('keeps a log across a restart', () async {
      await SharedPreferencesNatureLogStore().write(
        NatureLog([
          observation('a', itemId: 'tui', note: 'In the kōwhai'),
          observation(
            'b',
            category: NatureCategory.insect,
            label: 'Tiny green beetle',
            order: 1,
            placeLabel: 'Back garden',
          ),
        ]),
      );

      // A new store object on the same device: what a restart is.
      final reopened = await SharedPreferencesNatureLogStore().read();

      expect(reopened.length, 2);
      expect(reopened.find('a')!.itemId, 'tui');
      expect(reopened.find('a')!.note, 'In the kōwhai');
      expect(reopened.find('b')!.label, 'Tiny green beetle');
      expect(reopened.find('b')!.category, NatureCategory.insect);
      expect(reopened.find('b')!.placeLabel, 'Back garden');
    });

    test('an optional field left out stays out', () async {
      await SharedPreferencesNatureLogStore().write(
        NatureLog([observation('a')]),
      );

      final reopened = (await SharedPreferencesNatureLogStore().read()).find(
        'a',
      )!;

      // Not filled in with anything: no invented note, no invented
      // place, no book entry it was never matched to.
      expect(reopened.note, isNull);
      expect(reopened.placeLabel, isNull);
      expect(reopened.itemId, isNull);
      expect(reopened.isFromBook, isFalse);
    });

    test('clearing it really removes it', () async {
      final store = SharedPreferencesNatureLogStore();
      await store.write(NatureLog([observation('a')]));

      await store.deleteAll();

      expect((await SharedPreferencesNatureLogStore().read()).isEmpty, isTrue);
    });

    test('writes nothing outside its own key', () async {
      await SharedPreferencesNatureLogStore().write(
        NatureLog([observation('a', itemId: 'tui')]),
      );

      for (final key in SharedPreferencesNatureLogStore.keys) {
        expect(key, startsWith('natureLog.'));
      }
      // Its keys and every other store's keys are disjoint, so "clear
      // my Nature Log" can never take a cycle or a garden with it.
      for (final other in [
        SharedPreferencesCycleStore.keys,
        SharedPreferencesGardenStore.keys,
      ]) {
        expect(
          SharedPreferencesNatureLogStore.keys.intersection(other),
          isEmpty,
        );
      }
    });

    test('and UserSettings knows nothing about it', () {
      // The settings store is the app's preferences. Observations are
      // not a preference, and the two must not meet.
      final settingsSource = File(
        'lib/core/settings/shared_preferences_settings_store.dart',
      ).readAsStringSync();
      expect(settingsSource, isNot(contains('natureLog')));
      expect(settingsSource, isNot(contains('observation')));

      final settingsModel = File('lib/core/settings/user_settings.dart')
          .readAsStringSync();
      expect(settingsModel, isNot(contains('Nature')));
      expect(settingsModel, isNot(contains('observation')));
    });

    test('and neither store writes a coordinate', () {
      // Comments are stripped first: the files say in prose that they
      // store no coordinates, and a check that failed on that sentence
      // would be measuring the wrong thing.
      final storeCode = Directory('lib/features/nature_log/data')
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

  group('the stored form', () {
    test('a round trip through storage changes nothing', () {
      final log = NatureLog([
        observation('a', itemId: 'tui', note: 'In the kōwhai'),
        observation(
          'b',
          date: const CalendarDate(2026, 8, 30),
          category: NatureCategory.fungi,
          label: 'Tūtae whetū',
          order: 1,
          itemId: 'basket-fungus',
          placeLabel: 'Under the hedge',
        ),
        observation(
          'c',
          category: NatureCategory.other,
          label: 'Something in the stream',
          order: 2,
        ),
      ]);

      expect(decodeLog(encodeLog(log)), log);
    });

    test('free text survives being written down', () {
      // The reason the stored form is JSON and not the Garden's
      // pipe-separated line: a note is whatever somebody typed.
      final log = NatureLog([
        observation(
          'a',
          label: 'A "grey" one | maybe',
          note: 'on the fence | by the shed, 3–4 of them\nnot sure',
          placeLabel: "Nan's place, up the back",
        ),
      ]);

      final restored = decodeLog(encodeLog(log)).find('a')!;
      expect(restored.label, 'A "grey" one | maybe');
      expect(
        restored.note,
        'on the fence | by the shed, 3–4 of them\nnot sure',
      );
      expect(restored.placeLabel, "Nan's place, up the back");
    });

    test('a malformed record costs its own line and nothing else', () {
      final log = decodeLog([
        encodeObservation(observation('a', itemId: 'tui')),
        '', // empty
        'not json at all',
        '{"id":"b"}', // missing everything else
        '{"id":"","date":"2026-09-07","category":"bird","label":"x","order":0}',
        '{"id":"c","date":"not-a-date","category":"bird","label":"x","order":0}',
        '{"id":"d","date":"2026-09-07","category":"dragon","label":"x",'
            '"order":0}',
        '{"id":"e","date":"2026-09-07","category":"bird","label":" ","order":0}',
        '{"id":"f","date":"2026-09-07","category":"bird","label":"x",'
            '"order":"first"}',
        '[1,2,3]', // valid JSON, wrong shape
        encodeObservation(observation('z', label: 'Kererū', order: 1)),
      ]);

      // The two good lines survive; the nine broken ones are dropped
      // rather than taking the log with them.
      expect(log.observations.map((o) => o.instanceId), ['a', 'z']);
      expect(log.find('z')!.label, 'Kererū');
    });

    test('an item id this version has never heard of is kept, not lost', () {
      // A log written by a later version, read by an earlier one. The
      // label was written down at save time, so the entry still reads
      // as what the user saw.
      final log = decodeLog([
        '{"id":"a","date":"2026-09-07","category":"bird","label":"Huia",'
            '"order":0,"item":"huia-2027"}',
      ]);

      final restored = log.find('a')!;
      expect(restored.label, 'Huia');
      expect(restored.itemId, 'huia-2027');
      // Unknown to this book, so no entry to show — and nothing thrown.
      expect(restored.item, isNull);
      // And it is still there when this version writes the log back.
      expect(encodeLog(log).single, contains('huia-2027'));
    });

    test('a stored line holds only what the user gave', () {
      final line = encodeObservation(
        observation('a', itemId: 'tui', note: 'Singing'),
      );

      expect(line, contains('"label":"Tūī"'));
      expect(line, contains('"note":"Singing"'));
      // No place, because none was typed — not an empty string, and
      // certainly not a position.
      expect(line, isNot(contains('place')));
      expect(line, isNot(contains('lat')));
      expect(line, isNot(contains('season')));
    });
  });

  group('the controller', () {
    ProviderContainer containerWith(NatureLogStore store) {
      final container = ProviderContainer(
        overrides: environmentOverrides(now: testNow, natureLogStore: store),
      );
      addTearDown(container.dispose);
      return container;
    }

    test('first use is an empty log', () async {
      final container = containerWith(InMemoryNatureLogStore());

      expect((await container.read(natureLogProvider.future)).isEmpty, isTrue);
    });

    test('recording from the book keeps the entry and its name', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      final tui = NatureBook.byId('tui');

      await container
          .read(natureLogProvider.notifier)
          .recordFromBook(item: tui, note: 'In the kōwhai');

      final stored = (await store.read()).recent.single;
      expect(stored.itemId, 'tui');
      // The name as it stands today, written down: the migration policy.
      expect(stored.label, tui.primaryName);
      expect(stored.category, tui.category);
      expect(stored.date, testToday);
      expect(stored.note, 'In the kōwhai');
      expect(stored.placeLabel, isNull);
    });

    test('recording something of their own keeps it as written', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: '  Tiny green beetle  ',
            category: NatureCategory.insect,
            placeLabel: 'Back garden',
          );

      final stored = (await store.read()).recent.single;
      expect(stored.label, 'Tiny green beetle');
      expect(stored.category, NatureCategory.insect);
      // No attempt to match it to anything in the book.
      expect(stored.itemId, isNull);
      expect(stored.isFromBook, isFalse);
      expect(stored.placeLabel, 'Back garden');
    });

    test('blank optional text is stored as nothing, not as spaces', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: 'A moth',
            category: NatureCategory.insect,
            note: '   ',
            placeLabel: '',
          );

      final stored = (await store.read()).recent.single;
      expect(stored.note, isNull);
      expect(stored.placeLabel, isNull);
    });

    test('a date can be given, and is not overwritten by today', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: 'Monarch',
            category: NatureCategory.insect,
            on: const CalendarDate(2026, 8, 30),
          );

      expect(
        (await store.read()).recent.single.date,
        const CalendarDate(2026, 8, 30),
      );
    });

    test('editing changes what was asked and nothing else', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      await container
          .read(natureLogProvider.notifier)
          .recordFromBook(item: NatureBook.byId('tui'), note: 'Singing');
      final id = container
          .read(natureLogProvider)
          .value!
          .recent
          .single
          .instanceId;

      await container
          .read(natureLogProvider.notifier)
          .edit(
            id,
            date: const CalendarDate(2026, 9, 1),
            note: 'Singing at dawn',
            placeLabel: 'The reserve',
          );

      final edited = (await store.read()).find(id)!;
      expect(edited.date, const CalendarDate(2026, 9, 1));
      expect(edited.note, 'Singing at dawn');
      expect(edited.placeLabel, 'The reserve');
      expect(edited.itemId, 'tui');
      expect(edited.label, 'Tūī');
    });

    test('clearing a note by editing really clears it', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      await container
          .read(natureLogProvider.notifier)
          .recordCustom(
            name: 'A moth',
            category: NatureCategory.insect,
            note: 'On the window',
            placeLabel: 'Kitchen',
          );
      final id = container
          .read(natureLogProvider)
          .value!
          .recent
          .single
          .instanceId;

      await container.read(natureLogProvider.notifier).edit(id, note: '');

      final edited = (await store.read()).find(id)!;
      expect(edited.note, isNull);
      expect(edited.placeLabel, isNull);
      expect(edited.label, 'A moth');
    });

    test('editing something that is not there does nothing', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);

      await container
          .read(natureLogProvider.notifier)
          .edit('nobody', note: 'x');

      expect((await store.read()).isEmpty, isTrue);
    });

    test('removing takes one entry and leaves the rest', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      final log = container.read(natureLogProvider.notifier);
      await log.recordCustom(name: 'One', category: NatureCategory.other);
      await log.recordCustom(name: 'Two', category: NatureCategory.other);
      final first = container.read(natureLogProvider).value!.observations.first;

      await log.remove(first.instanceId);

      expect((await store.read()).observations.map((o) => o.label), ['Two']);
    });

    test('clearing empties the log and the storage behind it', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      await container
          .read(natureLogProvider.notifier)
          .recordCustom(name: 'One', category: NatureCategory.other);

      await container.read(natureLogProvider.notifier).clear();

      expect(container.read(natureLogProvider).value!.isEmpty, isTrue);
      expect((await store.read()).isEmpty, isTrue);
    });

    test('the order noticed in is kept, most recent first', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      final log = container.read(natureLogProvider.notifier);

      await log.recordCustom(name: 'First', category: NatureCategory.other);
      await log.recordCustom(name: 'Second', category: NatureCategory.other);
      await log.recordCustom(
        name: 'Yesterday',
        category: NatureCategory.other,
        on: const CalendarDate(2026, 9, 6),
      );

      // Newest day first, and within a day the most recently written
      // first — so two things noticed on one morning keep their order.
      expect((await store.read()).recent.map((o) => o.label), [
        'Second',
        'First',
        'Yesterday',
      ]);
      // Stored in the order they were recorded, whatever the dates.
      expect((await store.read()).observations.map((o) => o.label), [
        'First',
        'Second',
        'Yesterday',
      ]);
    });

    test('two of the same thing on one day are two entries', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      final log = container.read(natureLogProvider.notifier);
      final tui = NatureBook.byId('tui');

      await log.recordFromBook(item: tui, note: 'Morning');
      await log.recordFromBook(item: tui, note: 'Evening');

      final stored = await store.read();
      expect(stored.length, 2);
      expect(
        stored.observations.map((o) => o.instanceId).toSet(),
        hasLength(2),
      );
      expect(stored.recent.map((o) => o.note), ['Evening', 'Morning']);
    });

    test('a new launch still has everything', () async {
      final store = InMemoryNatureLogStore();
      final container = containerWith(store);
      await container.read(natureLogProvider.future);
      await container
          .read(natureLogProvider.notifier)
          .recordFromBook(item: NatureBook.byId('kereru'));

      final relaunched = containerWith(store);
      final log = await relaunched.read(natureLogProvider.future);

      expect(log.recent.single.itemId, 'kereru');
    });

    test('the log is never printed to the debug log', () {
      final source = Directory('lib/features/nature_log')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in source) {
        for (final line in file.readAsLinesSync()) {
          if (!line.contains('debugPrint')) continue;
          // The one permitted case: the store saying that a read
          // failed, by error type, with none of the contents.
          expect(line, contains('runtimeType'), reason: '${file.path}: $line');
        }
      }
    });

    test('an observation says nothing revealing when printed', () {
      // In a stack trace or a debug expression, an object should not
      // repeat what somebody wrote down.
      final printed = observation(
        'a',
        label: 'Tūī',
        note: 'Behind the house',
        placeLabel: 'Home',
      ).toString();

      expect(printed, contains('bird'));
      expect(printed, isNot(contains('Tūī')));
      expect(printed, isNot(contains('Behind the house')));
      expect(printed, isNot(contains('Home')));
    });
  });
}
