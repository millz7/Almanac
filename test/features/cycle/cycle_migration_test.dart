import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/data/cycle_store.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:almanac/features/cycle/domain/cycle_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const dateA = CalendarDate(2026, 7, 3);
const dateB = CalendarDate(2026, 8, 1);

/// Step 11's keys, written the way that version wrote them.
Future<void> seedLegacy({
  List<CalendarDate> starts = const [dateA, dateB],
  int? length = 28,
}) async {
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'cycle.periodStarts', 'cycle.assumedCycleLength'},
    ),
  );
  await preferences.setStringList('cycle.periodStarts', [
    for (final date in starts) date.iso,
  ]);
  if (length != null) {
    await preferences.setInt('cycle.assumedCycleLength', length);
  }
}

Future<List<String>?> storedRecords() async {
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'cycle.dayRecords'},
    ),
  );
  return preferences.getStringList('cycle.dayRecords');
}

Future<List<String>?> storedLegacy() async {
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'cycle.periodStarts'},
    ),
  );
  return preferences.getStringList('cycle.periodStarts');
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('migrating Step 11 data', () {
    test('every recorded start survives as an explicit day 1', () async {
      await seedLegacy();

      final data = await SharedPreferencesCycleStore().read();

      expect(data.periodStarts, [dateA, dateB]);
      expect(data.isPeriodStart(dateA), isTrue);
      expect(data.isPeriodStart(dateB), isTrue);
    });

    test('each becomes exactly one day of recorded bleeding', () async {
      await seedLegacy();

      final data = await SharedPreferencesCycleStore().read();

      expect(data.records, hasLength(2));
      expect(data.levelOn(dateA), BleedingLevel.bleeding);
      expect(data.levelOn(dateB), BleedingLevel.bleeding);
    });

    test('and no following days are invented', () async {
      await seedLegacy();

      final data = await SharedPreferencesCycleStore().read();

      // The old data said one thing: the day a period began. Filling in
      // the next four days would put bleeding in somebody's history
      // that they never entered.
      for (var after = 1; after <= 5; after++) {
        expect(
          data.recordOn(dateA.addDays(after)),
          isNull,
          reason: '\$after day(s) after A',
        );
        expect(
          data.recordOn(dateB.addDays(after)),
          isNull,
          reason: '\$after day(s) after B',
        );
      }
    });

    test('the assumed length is preserved', () async {
      await seedLegacy(length: 28);
      expect(
        (await SharedPreferencesCycleStore().read()).assumedCycleLength,
        28,
      );

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      await seedLegacy(length: 33);
      expect(
        (await SharedPreferencesCycleStore().read()).assumedCycleLength,
        33,
      );
    });

    test('it is deterministic', () async {
      await seedLegacy();
      final first = await SharedPreferencesCycleStore().read();

      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      await seedLegacy();
      final second = await SharedPreferencesCycleStore().read();

      expect(first, second);
    });

    test('it happens once: the old key is gone afterwards', () async {
      await seedLegacy();
      expect(await storedLegacy(), isNotNull);

      await SharedPreferencesCycleStore().read();

      expect(await storedLegacy(), anyOf(isNull, isEmpty));
      expect(await storedRecords(), hasLength(2));
    });

    test('and re-reading does not duplicate anything', () async {
      await seedLegacy();

      final store = SharedPreferencesCycleStore();
      final first = await store.read();
      final second = await store.read();
      // A different store object too: what a restart is.
      final third = await SharedPreferencesCycleStore().read();

      expect(first.records, hasLength(2));
      expect(second.records, hasLength(2));
      expect(third.records, hasLength(2));
      expect(third, first);
      expect(await storedRecords(), hasLength(2));
    });

    test('an unreadable legacy date is dropped, not fatal', () async {
      final preferences = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: {'cycle.periodStarts'},
        ),
      );
      await preferences.setStringList('cycle.periodStarts', [
        dateA.iso,
        'not-a-date',
        dateB.iso,
      ]);

      final data = await SharedPreferencesCycleStore().read();

      expect(data.periodStarts, [dateA, dateB]);
    });

    test('legacy data plus new data merge without loss', () async {
      // An unlikely shape, and the honest thing is still not to lose
      // anything: a version that wrote both keys, or a partial
      // migration that was interrupted.
      await SharedPreferencesCycleStore().write(
        CycleData(
          records: [
            CycleDayRecord(
              date: CalendarDate(2026, 9, 1),
              level: BleedingLevel.heavy,
            ),
          ],
        ),
      );
      await seedLegacy();

      // A fresh store, because a real launch opens its cache after both
      // keys are already on disk.
      final data = await SharedPreferencesCycleStore().read();

      expect(data.records, hasLength(3));
      expect(data.levelOn(CalendarDate(2026, 9, 1)), BleedingLevel.heavy);
      expect(data.periodStarts, [dateA, dateB]);
    });

    test('nothing to migrate is the ordinary path', () async {
      final data = await SharedPreferencesCycleStore().read();

      expect(data.isEmpty, isTrue);
      expect(data.assumedCycleLength, kDefaultCycleLength);
      expect(await storedRecords(), isNull);
    });

    test(
      'deleting everything removes the old key as well as the new',
      () async {
        await seedLegacy();
        final store = SharedPreferencesCycleStore();

        await store.deleteAll();

        expect(await storedLegacy(), anyOf(isNull, isEmpty));
        expect(await storedRecords(), anyOf(isNull, isEmpty));
        // And no migration is waiting to bring the old data back.
        expect((await SharedPreferencesCycleStore().read()).isEmpty, isTrue);
      },
    );

    test('a store deletes only its own keys', () {
      for (final key in SharedPreferencesCycleStore.keys) {
        expect(key, startsWith('cycle.'));
      }
      // The legacy key is in the set precisely so it can be removed.
      expect(SharedPreferencesCycleStore.keys, contains('cycle.periodStarts'));
    });
  });

  group('the migration function on its own', () {
    test('turns each start into one bleeding day marked as day 1', () {
      final records = migrateLegacyStarts([dateA, dateB]);

      expect(records, hasLength(2));
      for (final record in records) {
        expect(record.level, BleedingLevel.bleeding);
        expect(record.isPeriodStart, isTrue);
      }
      expect(records.map((r) => r.date), [dateA, dateB]);
    });

    test('and nothing at all from nothing', () {
      expect(migrateLegacyStarts(const []), isEmpty);
    });

    test('it is a pure function: same input, same output', () {
      expect(migrateLegacyStarts([dateA]), migrateLegacyStarts([dateA]));
    });
  });

  group('what the old Cycle did still holds', () {
    test('the cycle counts from the latest migrated start', () async {
      await seedLegacy();
      final data = await SharedPreferencesCycleStore().read();

      final moment = cycleMomentAt(
        today: CalendarDate(2026, 8, 15),
        data: data,
      );

      expect(moment.recordedStart, dateB);
      expect(moment.currentDay, 15);
      expect(moment.recordedLengths, [29]);
    });

    test('and a chosen phase was never stored by Step 11', () async {
      await seedLegacy();

      final data = await SharedPreferencesCycleStore().read();

      expect(data.manualPhase, isNull);
      expect(CyclePhase.values, hasLength(4));
    });
  });
}
