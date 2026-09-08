import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

final testNow = DateTime.utc(2026, 9, 20, 12);
const testToday = CalendarDate(2026, 9, 20);

/// 2 Sep to 6 Sep, the example the product rules use: two days of
/// spotting, then bleeding, heavy, bleeding — with 4 Sep as the day the
/// period actually began.
const sep2 = CalendarDate(2026, 9, 2);
const sep3 = CalendarDate(2026, 9, 3);
const sep4 = CalendarDate(2026, 9, 4);
const sep5 = CalendarDate(2026, 9, 5);
const sep6 = CalendarDate(2026, 9, 6);

void main() {
  setUpAll(useTimeZoneDatabase);

  ProviderContainer containerWith({CycleStore? store, DateTime? now}) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now ?? testNow,
        cycleStore: store ?? InMemoryCycleStore(),
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  group('recording a day', () {
    test('spotting, bleeding and heavy are each their own record', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);

      await cycle.record(sep2, BleedingLevel.spotting);
      await cycle.record(sep4, BleedingLevel.bleeding);
      await cycle.record(sep5, BleedingLevel.heavy);

      final data = container.read(cycleDataProvider).value!;
      expect(data.levelOn(sep2), BleedingLevel.spotting);
      expect(data.levelOn(sep4), BleedingLevel.bleeding);
      expect(data.levelOn(sep5), BleedingLevel.heavy);
      expect(data.records, hasLength(3));
    });

    test('nothing recorded is the absence of a record, not a level', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding);

      await cycle.clearDay(sep4);

      final data = container.read(cycleDataProvider).value!;
      expect(data.recordOn(sep4), isNull);
      expect(data.levelOn(sep4), isNull);
      expect(data.isEmpty, isTrue);
    });

    test('a level can be changed either way', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);

      await cycle.record(sep4, BleedingLevel.spotting);
      await cycle.record(sep4, BleedingLevel.bleeding);
      expect(
        container.read(cycleDataProvider).value!.levelOn(sep4),
        BleedingLevel.bleeding,
      );

      await cycle.record(sep4, BleedingLevel.heavy);
      await cycle.record(sep4, BleedingLevel.spotting);
      final data = container.read(cycleDataProvider).value!;
      expect(data.levelOn(sep4), BleedingLevel.spotting);
      // One record for the day, not four.
      expect(data.records, hasLength(1));
    });

    test('a day that has not happened cannot be recorded', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);

      await container
          .read(cycleDataProvider.notifier)
          .record(testToday.addDays(1), BleedingLevel.bleeding);

      expect(container.read(cycleDataProvider).value!.isEmpty, isTrue);
    });
  });

  group('spotting never starts a period', () {
    test('however it is recorded', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);

      // Asked for explicitly, which the editor never does — the model
      // refuses it anyway.
      await container
          .read(cycleDataProvider.notifier)
          .record(sep2, BleedingLevel.spotting, isPeriodStart: true);

      final data = container.read(cycleDataProvider).value!;
      expect(data.isPeriodStart(sep2), isFalse);
      expect(data.periodStarts, isEmpty);
      expect(data.levelOn(sep2), BleedingLevel.spotting);
    });

    test('and it does not reset a cycle that is already running', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);

      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      final before = container.read(cycleMomentProvider).currentDay;

      // Two weeks later, some spotting.
      await cycle.record(sep4.addDays(14), BleedingLevel.spotting);

      expect(container.read(cycleMomentProvider).currentDay, before);
      expect(container.read(cycleMomentProvider).recordedStart, sep4);
    });

    test('the whole example: day 1 is 4 September, not 2 September', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);

      await cycle.record(sep2, BleedingLevel.spotting);
      await cycle.record(sep3, BleedingLevel.spotting);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.record(sep5, BleedingLevel.heavy);
      await cycle.record(sep6, BleedingLevel.bleeding);

      final moment = container.read(cycleMomentProvider);
      expect(moment.recordedStart, sep4);
      // 20 September is cycle day 17 counting from the 4th.
      expect(moment.currentDay, 17);

      // And every record survives exactly as entered.
      final data = container.read(cycleDataProvider).value!;
      expect(data.levelOn(sep2), BleedingLevel.spotting);
      expect(data.levelOn(sep3), BleedingLevel.spotting);
      expect(data.levelOn(sep5), BleedingLevel.heavy);
      expect(data.periodStarts, [sep4]);
    });

    test('a month of spotting leaves the cycle where it was', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);

      for (var day = 8; day <= 18; day += 2) {
        await cycle.record(CalendarDate(2026, 9, day), BleedingLevel.spotting);
      }

      final data = container.read(cycleDataProvider).value!;
      expect(data.periodStarts, [sep4]);
      expect(container.read(cycleMomentProvider).currentDay, 17);
      // All of them still spotting, none promoted.
      for (var day = 8; day <= 18; day += 2) {
        expect(
          data.levelOn(CalendarDate(2026, 9, day)),
          BleedingLevel.spotting,
          reason: '$day September',
        );
      }
    });

    test(
      'and turning spotting into bleeding does not smuggle one in',
      () async {
        final container = containerWith();
        await container.read(cycleDataProvider.future);
        final cycle = container.read(cycleDataProvider.notifier);
        await cycle.record(sep2, BleedingLevel.spotting);

        // The editor would ask; this is the answer being "no".
        await cycle.record(sep2, BleedingLevel.bleeding);

        expect(
          container.read(cycleDataProvider).value!.isPeriodStart(sep2),
          isFalse,
        );
        expect(container.read(cycleMomentProvider).currentDay, isNull);
      },
    );
  });

  group('the day 1 the user chose', () {
    test('can be corrected, and the cycle day follows', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.record(sep5, BleedingLevel.heavy);
      expect(container.read(cycleMomentProvider).currentDay, 17);

      // "Actually it began on the 5th."
      await cycle.setPeriodStart(sep4, isStart: false);
      await cycle.setPeriodStart(sep5, isStart: true);

      final moment = container.read(cycleMomentProvider);
      expect(moment.recordedStart, sep5);
      expect(moment.currentDay, 16);
    });

    test('and correcting it never erases a bleeding record', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.record(sep5, BleedingLevel.heavy);

      await cycle.setPeriodStart(sep4, isStart: false);

      final data = container.read(cycleDataProvider).value!;
      expect(data.levelOn(sep4), BleedingLevel.bleeding);
      expect(data.levelOn(sep5), BleedingLevel.heavy);
      expect(data.records, hasLength(2));
      // No day 1 left, so no cycle to count — and no data lost.
      expect(container.read(cycleMomentProvider).currentDay, isNull);
      expect(container.read(cycleMomentProvider).hasRecords, isTrue);
    });

    test('it cannot be set on a day with no record', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);

      await container
          .read(cycleDataProvider.notifier)
          .setPeriodStart(sep4, isStart: true);

      expect(container.read(cycleDataProvider).value!.isEmpty, isTrue);
    });

    test('or on a spotting day', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep2, BleedingLevel.spotting);

      await cycle.setPeriodStart(sep2, isStart: true);

      expect(container.read(cycleDataProvider).value!.periodStarts, isEmpty);
    });

    test('the latest one is the one counted from', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);

      await cycle.record(
        CalendarDate(2026, 8, 5),
        BleedingLevel.bleeding,
        isPeriodStart: true,
      );
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);

      expect(container.read(cycleMomentProvider).recordedStart, sep4);
      expect(container.read(cycleDataProvider).value!.recordedLengths, [30]);
    });

    test('the default offered is a suggestion, not a rule', () {
      final data = CycleData(
        records: [
          CycleDayRecord(
            date: sep4,
            level: BleedingLevel.bleeding,
            isPeriodStart: true,
          ),
        ],
      );

      // The day after a recorded day reads as a continuation.
      expect(data.looksLikeNewEpisode(sep5), isFalse);
      // A day well clear of everything reads as a beginning.
      expect(data.looksLikeNewEpisode(CalendarDate(2026, 9, 20)), isTrue);
      // And the day itself, on an empty log, does too.
      expect(CycleData().looksLikeNewEpisode(sep4), isTrue);
    });
  });

  group('the phase override', () {
    test('changes what is displayed and nothing factual', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      final estimated = container.read(cycleMomentProvider).phase;

      await cycle.setDisplayedPhase(CyclePhase.menstrual);

      final moment = container.read(cycleMomentProvider);
      expect(moment.displayedPhase, CyclePhase.menstrual);
      expect(moment.phaseIsManual, isTrue);
      // The estimate is untouched, and so is everything recorded.
      expect(moment.phase, estimated);
      expect(moment.recordedStart, sep4);
      expect(moment.currentDay, 17);
      expect(
        container.read(cycleDataProvider).value!.levelOn(sep4),
        BleedingLevel.bleeding,
      );
    });

    test('and can be handed back to the estimate', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.setDisplayedPhase(CyclePhase.menstrual);

      await cycle.setDisplayedPhase(null);

      final moment = container.read(cycleMomentProvider);
      expect(moment.phaseIsManual, isFalse);
      expect(moment.displayedPhase, moment.phase);
    });

    test('a new period start clears a stale one', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.setDisplayedPhase(CyclePhase.luteal);
      expect(container.read(cycleMomentProvider).phaseIsManual, isTrue);

      // A new cycle has begun, so an answer about the last one is let go.
      await cycle.record(
        CalendarDate(2026, 9, 18),
        BleedingLevel.bleeding,
        isPeriodStart: true,
      );

      final moment = container.read(cycleMomentProvider);
      expect(moment.phaseIsManual, isFalse);
      expect(moment.recordedStart, CalendarDate(2026, 9, 18));
    });

    test('but ordinary bleeding does not', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.setDisplayedPhase(CyclePhase.luteal);

      await cycle.record(sep5, BleedingLevel.heavy);
      await cycle.record(sep6, BleedingLevel.spotting);

      expect(container.read(cycleMomentProvider).phaseIsManual, isTrue);
    });

    test('and marking a new day 1 by correction clears it too', () async {
      final container = containerWith();
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.record(sep5, BleedingLevel.heavy);
      await cycle.setDisplayedPhase(CyclePhase.ovulatory);

      await cycle.setPeriodStart(sep5, isStart: true);

      expect(container.read(cycleMomentProvider).phaseIsManual, isFalse);
    });
  });

  group('what is recorded and what is estimated', () {
    test('an estimated menstrual day is not a bleeding record', () async {
      final container = containerWith(now: DateTime.utc(2026, 9, 6, 12));
      await container.read(cycleDataProvider.future);

      // Day 1 recorded, and nothing else. Today is cycle day 3, inside
      // the estimated menstrual span.
      await container
          .read(cycleDataProvider.notifier)
          .record(sep4, BleedingLevel.bleeding, isPeriodStart: true);

      final moment = container.read(cycleMomentProvider);
      expect(moment.currentDay, 3);
      expect(moment.phase, CyclePhase.menstrual);
      // Estimated, and therefore not claimed as recorded.
      expect(moment.recordedToday, isNull);
      expect(moment.bleedingToday, isFalse);
      expect(
        container
            .read(cycleDataProvider)
            .value!
            .recordOn(CalendarDate(2026, 9, 6)),
        isNull,
      );
    });

    test('and a recorded day is stated as a fact', () async {
      final container = containerWith(now: DateTime.utc(2026, 9, 6, 12));
      await container.read(cycleDataProvider.future);
      final cycle = container.read(cycleDataProvider.notifier);
      await cycle.record(sep4, BleedingLevel.bleeding, isPeriodStart: true);
      await cycle.record(CalendarDate(2026, 9, 6), BleedingLevel.heavy);

      final moment = container.read(cycleMomentProvider);
      expect(moment.recordedToday?.level, BleedingLevel.heavy);
      expect(moment.bleedingToday, isTrue);
    });

    test('spotting today is recorded but is not bleeding', () async {
      final container = containerWith(now: DateTime.utc(2026, 9, 6, 12));
      await container.read(cycleDataProvider.future);
      await container
          .read(cycleDataProvider.notifier)
          .record(CalendarDate(2026, 9, 6), BleedingLevel.spotting);

      final moment = container.read(cycleMomentProvider);
      expect(moment.recordedToday?.level, BleedingLevel.spotting);
      expect(moment.bleedingToday, isFalse);
    });
  });

  group('across a restart', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('every record, its level and its day 1 survive', () async {
      await SharedPreferencesCycleStore().write(
        CycleData(
          records: [
            CycleDayRecord(date: sep2, level: BleedingLevel.spotting),
            CycleDayRecord(
              date: sep4,
              level: BleedingLevel.bleeding,
              isPeriodStart: true,
            ),
            CycleDayRecord(date: sep5, level: BleedingLevel.heavy),
          ],
          assumedCycleLength: 31,
        ),
      );

      // A new store object on the same device: what a restart is.
      final reopened = await SharedPreferencesCycleStore().read();

      expect(reopened.records, hasLength(3));
      expect(reopened.levelOn(sep2), BleedingLevel.spotting);
      expect(reopened.levelOn(sep4), BleedingLevel.bleeding);
      expect(reopened.levelOn(sep5), BleedingLevel.heavy);
      expect(reopened.periodStarts, [sep4]);
      expect(reopened.assumedCycleLength, 31);
    });

    test('and a chosen phase survives, or its absence does', () async {
      await SharedPreferencesCycleStore().write(
        CycleData(manualPhase: CyclePhase.luteal),
      );
      expect(
        (await SharedPreferencesCycleStore().read()).manualPhase,
        CyclePhase.luteal,
      );

      await SharedPreferencesCycleStore().write(CycleData());
      expect((await SharedPreferencesCycleStore().read()).manualPhase, isNull);
    });

    test('a malformed line costs its own day and nothing else', () {
      final records = decodeRecords([
        '2026-09-04|bleeding|1',
        '',
        'not a record',
        '2026-09-05|bleeding',
        'not-a-date|bleeding|0',
        '2026-09-06|torrential|0',
        '2026-09-07|heavy|0',
      ]);

      expect(records.map((r) => r.date.day), [4, 7]);
    });

    test('a round trip through storage changes nothing', () {
      final data = CycleData(
        records: [
          CycleDayRecord(date: sep2, level: BleedingLevel.spotting),
          CycleDayRecord(
            date: sep4,
            level: BleedingLevel.bleeding,
            isPeriodStart: true,
          ),
          CycleDayRecord(date: sep5, level: BleedingLevel.heavy),
        ],
        assumedCycleLength: 26,
      );

      expect(
        CycleData(
          records: decodeRecords(encodeRecords(data)),
          assumedCycleLength: data.assumedCycleLength,
        ),
        data,
      );
    });

    test('a spotting day stored as a day 1 is not trusted', () {
      // However the line got there — an older version, a hand edit — the
      // rule is enforced on the way in.
      final data = CycleData(records: decodeRecords(['2026-09-02|spotting|1']));

      expect(data.periodStarts, isEmpty);
      expect(data.levelOn(sep2), BleedingLevel.spotting);
    });

    test('deleting everything really removes it', () async {
      final store = SharedPreferencesCycleStore();
      await store.write(
        CycleData(
          records: [
            CycleDayRecord(
              date: sep4,
              level: BleedingLevel.bleeding,
              isPeriodStart: true,
            ),
          ],
          assumedCycleLength: 33,
          manualPhase: CyclePhase.luteal,
        ),
      );

      await store.deleteAll();

      final reopened = await SharedPreferencesCycleStore().read();
      expect(reopened.isEmpty, isTrue);
      expect(reopened.manualPhase, isNull);
      expect(reopened.assumedCycleLength, kDefaultCycleLength);
    });
  });
}
