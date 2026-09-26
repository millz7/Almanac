import 'package:almanac/app/app.dart';
import 'package:almanac/app/context/festival_context.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/daypart.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/environment/time_zone_service.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/environment/presentation/weather_narrative.dart';
import 'package:almanac/features/wheel/application/wheel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A device time zone a test can change while the app is "away".
class _MovableTimeZoneService implements TimeZoneService {
  _MovableTimeZoneService(this.zone);

  LocalTimeZone zone;

  @override
  Future<LocalTimeZone> currentTimeZone() async => zone;
}

/// Walks the real Android lifecycle out to the background and back, with
/// [whileAway] happening in between — a phone in a pocket.
Future<void> backgroundAndResume(
  WidgetTester tester, {
  void Function()? whileAway,
}) async {
  for (final state in [
    AppLifecycleState.resumed,
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  whileAway?.call();
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(useTimeZoneDatabase);

  final london = TestTimeZones.london;

  Future<ProviderContainer> open(
    WidgetTester tester,
    List<Override> overrides, {
    bool disposeAtTearDown = true,
  }) async {
    tester.view.physicalSize = const Size(430, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: overrides);
    if (disposeAtTearDown) addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('midnight while the app stays open', () {
    testWidgets('the environment re-resolves on its own at local midnight: '
        'date, Cycle Home and the Wheel all move', (tester) async {
      var now = DateTime.utc(2026, 1, 31, 23, 50);
      final c = await open(
        tester,
        environmentOverrides(
          clock: () => now,
          refreshEnabled: true,
          features: {FeatureId.cycle, FeatureId.wheel},
        ),
        // Its refresh timer is real, so the container is closed inside
        // the test, where the timer can be seen to go with it.
        disposeAtTearDown: false,
      );
      expect(c.read(todayProvider), const CalendarDate(2026, 1, 31));
      expect(find.text('Saturday 31 January'), findsOneWidget);
      // Imbolc (1 February) is tomorrow.
      expect(c.read(almanacFestivalProvider(null))!.daysUntil, 1);

      c.read(routerProvider).go(FeatureRegistry.byId(FeatureId.cycle).route);
      await tester.pumpAndSettle();
      expect(find.textContaining('January'), findsWidgets);

      // The clock crosses midnight; nothing but the app's own scheduled
      // re-resolution happens — no resume, no tap, no polling.
      now = DateTime.utc(2026, 2, 1, 0, 5);
      await tester.pump(const Duration(minutes: 11));
      await tester.pumpAndSettle();

      expect(c.read(todayProvider), const CalendarDate(2026, 2, 1));
      expect(find.textContaining('February'), findsWidgets);
      expect(
        c.read(almanacFestivalProvider(null))!.state,
        FestivalTimingState.today,
      );
      c.read(routerProvider).go(kEnvironmentRoute);
      await tester.pumpAndSettle();
      expect(find.text('Sunday 1 February'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });

    testWidgets('or on resume, after a night in a pocket', (tester) async {
      var now = DateTime.utc(2026, 3, 10, 22);
      final c = await open(tester, environmentOverrides(clock: () => now));
      expect(c.read(todayProvider), const CalendarDate(2026, 3, 10));

      await backgroundAndResume(
        tester,
        whileAway: () => now = DateTime.utc(2026, 3, 11, 7),
      );
      expect(c.read(todayProvider), const CalendarDate(2026, 3, 11));
      expect(c.read(currentDaypartProvider), Daypart.morning);
    });

    testWidgets('month rollover: Cycle Home follows the month; a browsed '
        'Calendar month stays where the user left it', (tester) async {
      var now = DateTime.utc(2026, 2, 28, 23, 55);
      final c = await open(
        tester,
        environmentOverrides(clock: () => now, features: {FeatureId.cycle}),
      );
      c.read(routerProvider).go(FeatureRegistry.byId(FeatureId.cycle).route);
      await tester.pumpAndSettle();
      await tester.tap(find.text(CycleText.calendar));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(CycleText.previousMonth));
      await tester.pumpAndSettle();
      expect(find.text('January 2026'), findsWidgets);

      await backgroundAndResume(
        tester,
        whileAway: () => now = DateTime.utc(2026, 3, 1, 8),
      );
      // Still browsing January: the Calendar is not dragged along.
      expect(find.text('January 2026'), findsWidgets);

      await tester.tap(find.text(CycleText.back));
      await tester.pumpAndSettle();
      expect(c.read(todayProvider), const CalendarDate(2026, 3, 1));
      expect(find.textContaining('March'), findsWidgets);
    });

    testWidgets('year rollover: 31 December → 1 January, nothing stuck in '
        'the old year', (tester) async {
      var now = DateTime.utc(2026, 12, 31, 23, 50);
      final c = await open(
        tester,
        environmentOverrides(
          clock: () => now,
          features: {FeatureId.wheel, FeatureId.cycle},
        ),
      );
      final before = c.read(nextFestivalProvider);
      expect(before.date.year, 2027);

      await backgroundAndResume(
        tester,
        whileAway: () => now = DateTime.utc(2027, 1, 1, 9),
      );
      expect(c.read(todayProvider), const CalendarDate(2027, 1, 1));
      expect(find.text('Friday 1 January'), findsOneWidget);
      final environment = c.read(naturalEnvironmentProvider).value!;
      expect(environment.season.season, Season.winter);
      expect(environment.season.endsAt.year, 2027);
      final next = c.read(nextFestivalProvider);
      expect(next.id, before.id);
      expect(next.date, before.date);
      expect(c.read(currentMoonProvider), isNotNull);
    });
  });

  group('a new time zone, picked up on resume', () {
    testWidgets('London to Auckland while away: date, daypart, Wheel and '
        'Cycle follow; the chosen hemisphere does not', (tester) async {
      final zones = _MovableTimeZoneService(london);
      final now = DateTime.utc(2026, 4, 27, 13);
      final c = await open(
        tester,
        environmentOverrides(
          now: now,
          timeZoneService: zones,
          features: {FeatureId.wheel, FeatureId.cycle},
        ),
      );
      expect(c.read(todayProvider), const CalendarDate(2026, 4, 27));
      expect(c.read(currentDaypartProvider), Daypart.afternoon);
      expect(c.read(almanacFestivalProvider(null))!.daysUntil, 4);

      await backgroundAndResume(
        tester,
        whileAway: () => zones.zone = TestTimeZones.wellington,
      );

      expect(c.read(timeZoneProvider).id, 'Pacific/Auckland');
      // 01:00 on the 28th in New Zealand.
      expect(c.read(todayProvider), const CalendarDate(2026, 4, 28));
      expect(c.read(currentDaypartProvider), Daypart.night);
      expect(c.read(almanacFestivalProvider(null))!.daysUntil, 3);
      expect(c.read(userSettingsProvider).hemisphere, Hemisphere.northern);
      expect(find.text('Tuesday 28 April'), findsOneWidget);
    });
  });

  group('daylight saving', () {
    tz.TZDateTime at(DateTime utc) => london.wallTimeAt(utc);

    test('spring forward (London, 29 March 2026): no hour that does not '
        'exist, and the dayparts step correctly', () {
      expect(daypartAt(at(DateTime.utc(2026, 3, 29, 0, 59))), Daypart.night);
      // 01:00 UTC is 02:00 BST — the clock skipped an hour.
      expect(at(DateTime.utc(2026, 3, 29, 1)).hour, 2);
      expect(daypartAt(at(DateTime.utc(2026, 3, 29, 3, 59))), Daypart.night);
      expect(daypartAt(at(DateTime.utc(2026, 3, 29, 4))), Daypart.morning);
      // Asking for the missing local hour does not throw.
      expect(() => london.instantAtLocal(2026, 3, 29, 1, 30), returnsNormally);
      expect(
        london
            .midnightOf(DateTime.utc(2026, 3, 29, 12))
            .isAtSameMomentAs(DateTime.utc(2026, 3, 29)),
        isTrue,
      );
    });

    test('fall back (London, 25 October 2026): the repeated hour is night '
        'both times, and morning arrives once', () {
      expect(at(DateTime.utc(2026, 10, 25, 0, 30)).hour, 1);
      expect(at(DateTime.utc(2026, 10, 25, 1, 30)).hour, 1);
      expect(daypartAt(at(DateTime.utc(2026, 10, 25, 0, 30))), Daypart.night);
      expect(daypartAt(at(DateTime.utc(2026, 10, 25, 1, 30))), Daypart.night);
      expect(daypartAt(at(DateTime.utc(2026, 10, 25, 4, 59))), Daypart.night);
      expect(daypartAt(at(DateTime.utc(2026, 10, 25, 5))), Daypart.morning);
      // The day is 25 hours long, and still one date.
      final midnight = london.midnightOf(DateTime.utc(2026, 10, 25, 12));
      final next = london.midnightOf(DateTime.utc(2026, 10, 26, 12));
      expect(next.difference(midnight), const Duration(hours: 25));
    });

    test('weather across the repeated hour reads in order, and describes '
        'without error', () {
      final start = DateTime.utc(2026, 10, 24, 22);
      final snapshot = WeatherSnapshot(
        location: TestLocations.london,
        obtainedAt: start,
        current: const CurrentWeather(
          temperatureC: 11,
          apparentTemperatureC: 10,
          condition: WeatherCondition.cloudy,
          precipitationMm: 0,
          cloudCoverPercent: 80,
          windSpeedKmh: 10,
        ),
        today: const DailySummary(
          highC: 13,
          lowC: 8,
          precipitationProbabilityPercent: 20,
        ),
        hourly: [
          for (var i = 0; i < 12; i++)
            HourlyWeather(
              time: start.add(Duration(hours: i)),
              condition: i > 6
                  ? WeatherCondition.rain
                  : WeatherCondition.cloudy,
              temperatureC: 10,
              precipitationProbabilityPercent: i > 6 ? 80 : 10,
              windSpeedKmh: 10,
            ),
        ],
      );
      // The instants stay strictly ordered even though two of them read
      // 01:xx on the local clock.
      for (var i = 1; i < snapshot.hourly.length; i++) {
        expect(
          snapshot.hourly[i].time.isAfter(snapshot.hourly[i - 1].time),
          isTrue,
        );
      }
      final sentence = describeWeather(
        weather: snapshot,
        localNow: at(DateTime.utc(2026, 10, 25, 1, 15)),
      );
      expect(sentence, isNotEmpty);
    });

    test('a solstice lands on the local date, zone and daylight saving '
        'included', () {
      // The December solstice falls in the evening UTC: still the 21st
      // in London, already the 22nd in New Zealand's summer time.
      final north = FestivalCalendar.dateOf(
        FestivalId.yule,
        2026,
        Hemisphere.northern,
        london,
      );
      final south = FestivalCalendar.dateOf(
        FestivalId.litha,
        2026,
        Hemisphere.southern,
        TestTimeZones.wellington,
      );
      expect(north, const CalendarDate(2026, 12, 21));
      expect(south, const CalendarDate(2026, 12, 22));
    });
  });

  group('daypart boundaries', () {
    tz.TZDateTime clock(int hour, int minute) =>
        tz.TZDateTime(london.location, 2026, 6, 1, hour, minute);

    for (final (hour, minute, expected) in [
      (4, 59, Daypart.night),
      (5, 0, Daypart.morning),
      (11, 59, Daypart.morning),
      (12, 0, Daypart.afternoon),
      (16, 59, Daypart.afternoon),
      (17, 0, Daypart.evening),
      (20, 59, Daypart.evening),
      (21, 0, Daypart.night),
    ]) {
      final label =
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
      test('$label is ${expected.name}', () {
        expect(daypartAt(clock(hour, minute)), expected);
      });
    }

    test('read in the local zone, not UTC', () {
      // 04:30 UTC is 05:30 in London's summer: morning, not night.
      expect(
        daypartAt(london.wallTimeAt(DateTime.utc(2026, 6, 1, 4, 30))),
        Daypart.morning,
      );
      // And 16:30 in Auckland's winter, for the same instant.
      expect(
        daypartAt(
          TestTimeZones.wellington.wallTimeAt(DateTime.utc(2026, 6, 1, 4, 30)),
        ),
        Daypart.afternoon,
      );
    });
  });

  group('festival approaching boundaries', () {
    /// The festival state at noon local time, [daysBefore] days before
    /// [festival]'s date.
    ActiveFestival? stateAt({
      required FestivalId festival,
      required int year,
      required int daysBefore,
      Hemisphere hemisphere = Hemisphere.northern,
      LocalTimeZone? zone,
    }) {
      final z = zone ?? london;
      final date = FestivalCalendar.dateOf(festival, year, hemisphere, z);
      final day = date.addDays(-daysBefore);
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: z.instantAtLocal(day.year, day.month, day.day, 12),
          timeZone: z,
          hemisphere: hemisphere,
          features: {FeatureId.wheel},
        ),
      );
      addTearDown(container.dispose);
      return container.read(almanacFestivalProvider(null));
    }

    for (final (label, festival, hemisphere, zone) in [
      (
        'Beltane, a cross-quarter day, north',
        FestivalId.beltane,
        Hemisphere.northern,
        null,
      ),
      ('Litha, a solstice, north', FestivalId.litha, Hemisphere.northern, null),
      (
        'Beltane in the south',
        FestivalId.beltane,
        Hemisphere.southern,
        TestTimeZones.wellington,
      ),
    ]) {
      test(label, () {
        ActiveFestival? at(int daysBefore) => stateAt(
          festival: festival,
          year: 2026,
          daysBefore: daysBefore,
          hemisphere: hemisphere,
          zone: zone,
        );
        expect(at(8), isNull, reason: '8 days before');
        expect(at(7)!.state, FestivalTimingState.approaching);
        expect(at(7)!.daysUntil, 7);
        expect(at(7)!.id, festival);
        expect(at(1)!.state, FestivalTimingState.approaching);
        expect(at(1)!.daysUntil, 1);
        expect(at(0)!.state, FestivalTimingState.today);
        expect(at(-1), isNull, reason: 'the day after');
      });
    }

    test('across the new year: Imbolc approaches from the right year', () {
      // 31 December: Imbolc (1 February next year) is 32 days away.
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 12, 31, 12),
          features: {FeatureId.wheel},
        ),
      );
      addTearDown(container.dispose);
      expect(container.read(almanacFestivalProvider(null)), isNull);
      expect(container.read(nextFestivalProvider).id, FestivalId.imbolc);
      expect(
        container.read(nextFestivalProvider).date,
        const CalendarDate(2027, 2, 1),
      );

      final approaching = stateAt(
        festival: FestivalId.imbolc,
        year: 2027,
        daysBefore: 7,
      );
      expect(approaching!.state, FestivalTimingState.approaching);
    });
  });

  group('location permission changed outside the app', () {
    test('revoked in system settings, noticed on the very next resume '
        'even though the fix was fresh', () async {
      final service = FakeLocationService(
        checkResult: const LocationAvailable(TestLocations.london),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationService: service,
          locationState: LocationAvailable(
            TestLocations.london,
            obtainedAt: DateTime.utc(2025, 7, 15, 11, 55),
          ),
        ),
      );
      addTearDown(container.dispose);

      service.checkResult = const LocationPermissionDenied();
      await container.read(locationStateProvider.notifier).refresh();
      expect(
        container.read(locationStateProvider),
        isA<LocationPermissionDenied>(),
      );
      expect(service.requestCount, 0);
    });

    test('granted later in settings, picked up by the next refresh, with '
        'no prompt', () async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionDenied(),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(
          locationService: service,
          locationState: const LocationPermissionDenied(),
        ),
      );
      addTearDown(container.dispose);

      service.checkResult = const LocationAvailable(TestLocations.london);
      await container.read(locationStateProvider.notifier).refresh();
      expect(container.read(locationStateProvider).location, isNotNull);
      expect(service.requestCount, 0);
    });

    test('permanently denied stays so, and only the settings pathway is '
        'offered', () async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionPermanentlyDenied(),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(
          locationService: service,
          locationState: const LocationPermissionPermanentlyDenied(),
        ),
      );
      addTearDown(container.dispose);

      await container.read(locationStateProvider.notifier).refresh();
      expect(
        container.read(locationStateProvider),
        isA<LocationPermissionPermanentlyDenied>(),
      );
      expect(container.read(locationStateProvider).canRequest, isFalse);
      expect(
        await container
            .read(locationStateProvider.notifier)
            .openSystemSettings(),
        isTrue,
      );
      expect(service.requestCount, 0);
    });

    test('a still-fresh, still-permitted fix is not re-read', () async {
      final service = FakeLocationService(
        checkResult: const LocationAvailable(TestLocations.london),
      );
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationService: service,
          // Obtained five minutes ago: fresh.
          locationState: LocationAvailable(
            TestLocations.london,
            obtainedAt: DateTime.utc(2025, 7, 15, 11, 55),
          ),
        ),
      );
      addTearDown(container.dispose);

      await container.read(locationStateProvider.notifier).refresh();
      expect(service.permissionCheckCount, 1);
      expect(service.checkCount, 0);
    });
  });
}
