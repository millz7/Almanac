import 'dart:io';

import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A moon pinned to one phase, so a test about the classification is not
/// also a test of the date it happens to be.
class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.phase);

  final MoonPhase phase;

  @override
  MoonPhaseState phaseAt(DateTime instant) => MoonPhaseState(
    phase: phase,
    elongationDegrees: phase.isWaxing ? 60 : 240,
    illuminatedFraction: 0.5,
  );
}

/// Records which instants it was asked about, so a test can prove the
/// wheel and the cycle type ask the one service.
class _RecordingMoonService implements MoonService {
  final asked = <DateTime>[];

  @override
  MoonPhaseState phaseAt(DateTime instant) {
    asked.add(instant);
    return const MoonPhaseState(
      phase: MoonPhase.waxingCrescent,
      elongationDegrees: 60,
      illuminatedFraction: 0.34,
    );
  }
}

final testNow = DateTime.utc(2026, 9, 20, 12);
const day1 = CalendarDate(2026, 9, 4);

void main() {
  setUpAll(useTimeZoneDatabase);

  ProviderContainer containerWith({
    MoonService? moonService,
    CycleData? data,
    DateTime? now,
    LocalTimeZone? timeZone,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(
          now: now ?? testNow,
          timeZone: timeZone,
          cycleStore: InMemoryCycleStore(data ?? CycleData.empty),
        ),
        if (moonService != null)
          moonServiceProvider.overrideWithValue(moonService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  CycleData withDay1(CalendarDate date) => CycleData(
    records: [
      CycleDayRecord(
        date: date,
        level: BleedingLevel.bleeding,
        isPeriodStart: true,
      ),
    ],
  );

  group('the moon cycle type is derived from the day-1 moon', () {
    test('a new moon is a White Moon cycle', () async {
      final container = containerWith(
        moonService: const _FixedMoonService(MoonPhase.newMoon),
        data: withDay1(day1),
      );
      await container.read(cycleDataProvider.future);

      expect(container.read(moonCycleTypeProvider), MoonCycleType.white);
    });

    test('a full moon is a Red Moon cycle', () async {
      final container = containerWith(
        moonService: const _FixedMoonService(MoonPhase.fullMoon),
        data: withDay1(day1),
      );
      await container.read(cycleDataProvider.future);

      expect(container.read(moonCycleTypeProvider), MoonCycleType.red);
    });

    test('the waxing phases are a Pink Moon cycle', () async {
      for (final phase in [
        MoonPhase.waxingCrescent,
        MoonPhase.firstQuarter,
        MoonPhase.waxingGibbous,
      ]) {
        final container = containerWith(
          moonService: _FixedMoonService(phase),
          data: withDay1(day1),
        );
        await container.read(cycleDataProvider.future);

        expect(
          container.read(moonCycleTypeProvider),
          MoonCycleType.pink,
          reason: phase.name,
        );
      }
    });

    test('the waning phases are a Purple Moon cycle', () async {
      for (final phase in [
        MoonPhase.waningGibbous,
        MoonPhase.lastQuarter,
        MoonPhase.waningCrescent,
      ]) {
        final container = containerWith(
          moonService: _FixedMoonService(phase),
          data: withDay1(day1),
        );
        await container.read(cycleDataProvider.future);

        expect(
          container.read(moonCycleTypeProvider),
          MoonCycleType.purple,
          reason: phase.name,
        );
      }
    });

    test('every phase classifies, and only into the four', () {
      for (final phase in MoonPhase.values) {
        expect(MoonCycleType.values, contains(MoonCycleType.forPhase(phase)));
      }
      // Both directions: each type names exactly the phases that
      // produce it.
      expect(MoonCycleType.white.phases, [MoonPhase.newMoon]);
      expect(MoonCycleType.red.phases, [MoonPhase.fullMoon]);
      expect(MoonCycleType.pink.phases, [
        MoonPhase.waxingCrescent,
        MoonPhase.firstQuarter,
        MoonPhase.waxingGibbous,
      ]);
      expect(MoonCycleType.purple.phases, [
        MoonPhase.waningGibbous,
        MoonPhase.lastQuarter,
        MoonPhase.waningCrescent,
      ]);
      // Eight phases, all accounted for, none twice.
      expect([
        for (final type in MoonCycleType.values) ...type.phases,
      ], hasLength(MoonPhase.values.length));
    });

    test('there is no type without a recorded day 1', () async {
      final container = containerWith(
        moonService: const _FixedMoonService(MoonPhase.newMoon),
      );
      await container.read(cycleDataProvider.future);

      expect(container.read(moonCycleTypeProvider), isNull);
    });

    test('and none from spotting alone', () async {
      final container = containerWith(
        moonService: const _FixedMoonService(MoonPhase.newMoon),
        data: CycleData(
          records: [CycleDayRecord(date: day1, level: BleedingLevel.spotting)],
        ),
      );
      await container.read(cycleDataProvider.future);

      expect(container.read(moonCycleTypeProvider), isNull);
    });

    test('it changes when a later cycle begins under another moon', () async {
      // The same install, two cycles, two moons. Nothing is persisted
      // about the type — it is derived each time — so the second period
      // simply reads differently.
      final byDate = <CalendarDate, MoonPhase>{
        const CalendarDate(2026, 8, 3): MoonPhase.newMoon,
        const CalendarDate(2026, 9, 4): MoonPhase.fullMoon,
      };

      for (final entry in byDate.entries) {
        final container = containerWith(
          moonService: _FixedMoonService(entry.value),
          data: withDay1(entry.key),
          now: DateTime.utc(2026, 9, 20, 12),
        );
        await container.read(cycleDataProvider.future);

        expect(
          container.read(moonCycleTypeProvider),
          MoonCycleType.forPhase(entry.value),
          reason: entry.key.iso,
        );
      }
    });

    test('nothing about the type is persisted', () async {
      final container = containerWith(
        moonService: const _FixedMoonService(MoonPhase.newMoon),
        data: withDay1(day1),
      );
      await container.read(cycleDataProvider.future);
      expect(container.read(moonCycleTypeProvider), MoonCycleType.white);

      final stored = encodeRecords(container.read(cycleDataProvider).value!);
      for (final line in stored) {
        expect(line.toLowerCase(), isNot(contains('white')));
        expect(line.toLowerCase(), isNot(contains('moon')));
      }
    });
  });

  group('one lunar calculation, shared', () {
    test('the wheel asks the app\'s own moon service, once per day', () {
      final service = _RecordingMoonService();
      final container = containerWith(moonService: service);

      final moons = container.read(
        monthMoonsProvider(const CalendarDate(2026, 9, 15)),
      );

      expect(moons, hasLength(30));
      expect(service.asked, hasLength(30));
    });

    test('and February gets 28 or 29 asks, not 30', () {
      for (final (year, days) in [(2026, 28), (2024, 29)]) {
        final service = _RecordingMoonService();
        final container = containerWith(moonService: service);

        expect(
          container.read(monthMoonsProvider(CalendarDate(year, 2, 10))),
          hasLength(days),
          reason: '$year',
        );
      }
    });

    test('every date is asked at local midday', () {
      final service = _RecordingMoonService();
      final container = containerWith(
        moonService: service,
        timeZone: TestTimeZones.wellington,
      );

      container.read(monthMoonsProvider(const CalendarDate(2026, 9, 15)));

      final zone = container.read(timeZoneProvider);
      for (final (index, instant) in service.asked.indexed) {
        final local = zone.wallTimeAt(instant);
        expect(local.hour, 12, reason: 'day ${index + 1}');
        expect(local.day, index + 1, reason: 'day ${index + 1}');
        expect(local.month, 9);
      }
    });

    test('and the cycle type reads the same instant the wheel does', () async {
      final service = _RecordingMoonService();
      final container = containerWith(
        moonService: service,
        data: withDay1(day1),
        timeZone: TestTimeZones.wellington,
      );

      await container.read(cycleDataProvider.future);
      service.asked.clear();
      container.read(moonCycleTypeProvider);
      final forType = service.asked.single;

      service.asked.clear();
      container.read(monthMoonsProvider(day1));
      final forWheel = service.asked[day1.day - 1];

      // The two can never disagree about what a date's moon was.
      expect(forType, forWheel);
    });

    test('a southern time zone is not shifted to the previous day', () async {
      final service = _RecordingMoonService();
      final container = containerWith(
        moonService: service,
        data: withDay1(day1),
        timeZone: TestTimeZones.wellington,
      );

      await container.read(cycleDataProvider.future);
      service.asked.clear();
      container.read(moonCycleTypeProvider);

      // Midnight UTC on the 4th is the afternoon of the 4th in
      // Wellington, but local midnight is the 3rd in UTC — which is
      // exactly the trap this seam avoids.
      final local = container
          .read(timeZoneProvider)
          .wallTimeAt(service.asked.single);
      expect(local.day, 4);
      expect(local.hour, 12);
    });

    test('Cycle contains no lunar arithmetic of its own', () {
      final sources = Directory('lib/features/cycle')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      expect(sources, isNotEmpty);
      for (final file in sources) {
        // Comments are prose about the design; the check is about the
        // code.
        final code = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        for (final forbidden in [
          'MoonCalculator',
          'synodic',
          'elongationDegrees =',
          'DateTime.now',
          'seasonAt(',
        ]) {
          expect(
            code.contains(forbidden),
            isFalse,
            reason: '${file.path} contains $forbidden',
          );
        }
      }
    });
  });
}
