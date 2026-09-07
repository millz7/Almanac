import 'dart:io';

import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/test_overrides.dart';

const today = CalendarDate(2026, 9, 7);

void main() {
  group('the dedicated cycle store', () {
    setUp(() {
      // The plugin's own in-memory implementation, so the real store's
      // serialisation and deletion are exercised rather than mocked.
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('starts empty', () async {
      final data = await SharedPreferencesCycleStore().read();

      expect(data.periodStarts, isEmpty);
      expect(data.assumedCycleLength, kDefaultCycleLength);
    });

    test('keeps dates across a restart, in a date-only format', () async {
      await SharedPreferencesCycleStore().write(
        CycleData(
          periodStarts: [
            const CalendarDate(2026, 8, 3),
            const CalendarDate(2026, 8, 31),
          ],
          assumedCycleLength: 30,
        ),
      );

      // A new store object on the same device: what a restart is.
      final reopened = await SharedPreferencesCycleStore().read();

      expect(reopened.periodStarts.map((d) => d.iso), [
        '2026-08-03',
        '2026-08-31',
      ]);
      expect(reopened.assumedCycleLength, 30);
    });

    test('deleting everything really removes it', () async {
      final store = SharedPreferencesCycleStore();
      await store.write(
        CycleData(periodStarts: [today], assumedCycleLength: 33),
      );

      await store.deleteAll();

      // Not just the dates: the length chosen to estimate them with is
      // gone too, so nothing is left to say anybody ever used this.
      final reopened = await SharedPreferencesCycleStore().read();
      expect(reopened.periodStarts, isEmpty);
      expect(reopened.assumedCycleLength, kDefaultCycleLength);
    });

    test('drops a stored value it cannot read, rather than failing', () async {
      final store = SharedPreferencesCycleStore();
      await store.write(CycleData(periodStarts: [today]));

      expect(parseStoredStarts(['2026-09-07', 'yesterday', '', '2026-13-40']), [
        today,
      ]);
    });

    test('writes nothing outside its own two keys', () async {
      await SharedPreferencesCycleStore().write(
        CycleData(periodStarts: [today]),
      );

      // Every cycle key is under its own prefix, and the app's general
      // settings store neither names nor allow-lists any of them — so
      // cycle data cannot end up in the app's ordinary preferences and
      // the settings store could not read it if it did.
      for (final key in SharedPreferencesCycleStore.keys) {
        expect(key, startsWith('cycle.'));
      }
      final settingsSource = File(
        'lib/core/settings/shared_preferences_settings_store.dart',
      ).readAsStringSync();
      expect(settingsSource, isNot(contains('cycle')));
    });
  });

  group('the controller', () {
    ProviderContainer containerWith(CycleStore store) {
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 7, 12),
          cycleStore: store,
        ),
      );
      addTearDown(container.dispose);
      return container;
    }

    test('reads what is already stored', () async {
      final store = InMemoryCycleStore(
        CycleData(periodStarts: [today.addDays(-4)], assumedCycleLength: 26),
      );
      final container = containerWith(store);

      final data = await container.read(cycleDataProvider.future);

      expect(data.periodStarts, [today.addDays(-4)]);
      expect(data.assumedCycleLength, 26);
      expect(container.read(cycleMomentProvider).currentDay, 5);
    });

    test('records a date, and a new launch still has it', () async {
      final store = InMemoryCycleStore();
      final container = containerWith(store);
      await container.read(cycleDataProvider.future);

      await container.read(cycleDataProvider.notifier).recordStart(today);

      // A second container over the same store is the next launch.
      final relaunched = containerWith(store);
      final data = await relaunched.read(cycleDataProvider.future);
      expect(data.periodStarts, [today]);
    });

    test('refuses a date in the future', () async {
      final container = containerWith(InMemoryCycleStore());
      await container.read(cycleDataProvider.future);

      await container
          .read(cycleDataProvider.notifier)
          .recordStart(today.addDays(1));

      expect(container.read(cycleDataProvider).value!.periodStarts, isEmpty);
    });

    test('refuses to edit a date into the future', () async {
      final container = containerWith(
        InMemoryCycleStore(CycleData(periodStarts: [today.addDays(-2)])),
      );
      await container.read(cycleDataProvider.future);

      await container
          .read(cycleDataProvider.notifier)
          .editStart(today.addDays(-2), today.addDays(5));

      expect(container.read(cycleDataProvider).value!.periodStarts, [
        today.addDays(-2),
      ]);
    });

    test('edits a date in place', () async {
      final store = InMemoryCycleStore(
        CycleData(periodStarts: [today.addDays(-6)]),
      );
      final container = containerWith(store);
      await container.read(cycleDataProvider.future);

      await container
          .read(cycleDataProvider.notifier)
          .editStart(today.addDays(-6), today.addDays(-5));

      expect(container.read(cycleDataProvider).value!.periodStarts, [
        today.addDays(-5),
      ]);
      expect((await store.read()).periodStarts, [today.addDays(-5)]);
    });

    test('deletes one date and leaves the rest', () async {
      final store = InMemoryCycleStore(
        CycleData(periodStarts: [today.addDays(-30), today]),
      );
      final container = containerWith(store);
      await container.read(cycleDataProvider.future);

      await container.read(cycleDataProvider.notifier).deleteStart(today);

      expect((await store.read()).periodStarts, [today.addDays(-30)]);
    });

    test('deleting everything clears memory and storage together', () async {
      final store = InMemoryCycleStore(
        CycleData(periodStarts: [today], assumedCycleLength: 31),
      );
      final container = containerWith(store);
      await container.read(cycleDataProvider.future);

      await container.read(cycleDataProvider.notifier).deleteEverything();

      expect(container.read(cycleDataProvider).value!.periodStarts, isEmpty);
      expect((await store.read()).periodStarts, isEmpty);
      expect((await store.read()).assumedCycleLength, kDefaultCycleLength);

      // And the next launch is genuinely a first use.
      final relaunched = containerWith(store);
      expect((await relaunched.read(cycleDataProvider.future)).isEmpty, isTrue);
      expect(relaunched.read(cycleMomentProvider).hasRecords, isFalse);
    });

    test('a changed length is stored, and changes no dates', () async {
      final store = InMemoryCycleStore(
        CycleData(periodStarts: [today.addDays(-10)]),
      );
      final container = containerWith(store);
      await container.read(cycleDataProvider.future);

      await container.read(cycleDataProvider.notifier).setAssumedLength(31);

      final stored = await store.read();
      expect(stored.assumedCycleLength, 31);
      expect(stored.periodStarts, [today.addDays(-10)]);
    });

    test('nothing cycle-shaped reaches the general settings store', () async {
      final store = InMemoryCycleStore();
      final container = containerWith(store);
      await container.read(cycleDataProvider.future);

      await container.read(cycleDataProvider.notifier).recordStart(today);

      // The app's settings object has no room for a cycle date, and this
      // is the test that says so out loud.
      final settings = container.read(settingsStoreProvider).read();
      expect(settings.toString(), isNot(contains('2026')));
      expect(settings.toString().toLowerCase(), isNot(contains('cycle')));
    });

    test('cycle data never describes itself in a log line', () async {
      // A toString is how sensitive data ends up in a crash report.
      final data = CycleData(
        periodStarts: [const CalendarDate(2026, 8, 3)],
        assumedCycleLength: 29,
      );

      expect(data.toString(), isNot(contains('2026-08-03')));
      expect(data.toString(), 'CycleData(1 recorded, 29-day estimate)');
    });
  });
}
