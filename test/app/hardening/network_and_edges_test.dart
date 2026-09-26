import 'dart:convert';
import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/open_meteo_marine_tide_service.dart';
import 'package:almanac/core/environment/open_meteo_weather_service.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/core/environment/tide_providers.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:almanac/core/environment/weather_providers.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/garden/presentation/garden_text.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Where the app meets the world: weather and tide caches across moves
/// and outages, the edges of the map (polar days, no location), and the
/// promise that only two approved requests ever leave the device.
void main() {
  setUpAll(useTimeZoneDatabase);

  const a = TestLocations.london;
  // Well over the ~1 km rounding tolerance away.
  const b = GeoLocation(latitude: 51.60, longitude: -0.30);
  // Well within it.
  const aNearby = GeoLocation(latitude: 51.5079, longitude: -0.1275);

  final t0 = DateTime.utc(2026, 5, 10, 12);

  FakeTideService tides({TideFetchResult Function(GeoLocation)? answer}) =>
      FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            answer?.call(location) ??
            TideFetchData(
              testTideSnapshot(location: location, obtainedAt: now),
            ),
      );

  FakeWeatherService weather() => FakeWeatherService(
    result: ({required location, required timeZone, required now}) =>
        testWeatherSnapshot(location: location, obtainedAt: now),
  );

  /// A container whose shared location can be moved, and whose clock can
  /// be walked forward.
  (ProviderContainer, FakeLocationService, void Function(DateTime)) setUpAt(
    GeoLocation start, {
    FakeWeatherService? weatherService,
    FakeTideService? tideService,
  }) {
    var now = t0;
    final location = FakeLocationService(
      checkResult: LocationAvailable(start, obtainedAt: t0),
    );
    final container = ProviderContainer(
      overrides: environmentOverrides(
        clock: () => now,
        locationService: location,
        locationState: LocationAvailable(start, obtainedAt: t0),
        weatherService: weatherService,
        tideService: tideService,
      ),
    );
    addTearDown(container.dispose);
    return (container, location, (next) => now = next);
  }

  Future<void> moveTo(
    ProviderContainer c,
    FakeLocationService service,
    GeoLocation to,
  ) async {
    service.checkResult = LocationAvailable(to, obtainedAt: t0);
    await c.read(locationStateProvider.notifier).refresh(force: true);
  }

  group('weather never describes another place', () {
    test('a fresh forecast for A is not used for B', () async {
      final service = weather();
      final (c, loc, _) = setUpAt(a, weatherService: service);
      expect((await c.read(weatherControllerProvider.future))!.location, a);

      await moveTo(c, loc, b);
      final atB = await c.read(weatherControllerProvider.future);
      expect(atB!.location, b);
      expect(service.fetchCount, 2);
    });

    test('a few metres of drift reuses the fresh forecast', () async {
      final service = weather();
      final (c, loc, _) = setUpAt(a, weatherService: service);
      await c.read(weatherControllerProvider.future);

      await moveTo(c, loc, aNearby);
      await c.read(weatherControllerProvider.future);
      expect(service.fetchCount, 1);
    });

    test('offline at B, with only A cached: no weather, not A\'s', () async {
      final service = weather();
      final (c, loc, _) = setUpAt(a, weatherService: service);
      await c.read(weatherControllerProvider.future);

      service.failWith = const SocketException('offline');
      await moveTo(c, loc, b);
      expect(await c.read(weatherControllerProvider.future), isNull);
    });
  });

  group('tides never describe another shore', () {
    test('a curve for A is not shown for B', () async {
      final service = tides();
      final (c, loc, _) = setUpAt(a, tideService: service);
      final atA = await c.read(tideControllerProvider.future);
      expect((atA as TideAvailable).snapshot.location, a);

      await moveTo(c, loc, b);
      final atB = await c.read(tideControllerProvider.future);
      expect((atB as TideAvailable).snapshot.location, b);
      expect(service.fetchCount, 2);
    });

    test(
      '"nothing here" at an inland A does not poison the coast at B',
      () async {
        final service = tides(
          answer: (location) => location == a
              ? const TideFetchNoData()
              : TideFetchData(
                  testTideSnapshot(location: location, obtainedAt: t0),
                ),
        );
        final (c, loc, _) = setUpAt(a, tideService: service);
        expect(
          await c.read(tideControllerProvider.future),
          isA<TideUnavailableForLocation>(),
        );

        await moveTo(c, loc, b);
        expect(
          await c.read(tideControllerProvider.future),
          isA<TideAvailable>(),
        );
      },
    );

    test(
      'offline at B, with only A cached: unavailable, not A\'s curve',
      () async {
        final service = tides();
        final (c, loc, _) = setUpAt(a, tideService: service);
        await c.read(tideControllerProvider.future);

        service.failWith = const SocketException('offline');
        await moveTo(c, loc, b);
        expect(
          await c.read(tideControllerProvider.future),
          isA<TideProviderUnavailable>(),
        );
      },
    );
  });

  group('network loss and recovery', () {
    test(
      'offline with a recent forecast: the forecast stands; hours later '
      'it is let go; back online it recovers, one request per trigger',
      () async {
        final service = weather();
        final (c, _, setNow) = setUpAt(a, weatherService: service);
        await c.read(weatherControllerProvider.future);
        expect(service.fetchCount, 1);

        // Fifty minutes on, past the cache window, and offline.
        service.failWith = const SocketException('offline');
        setNow(t0.add(const Duration(minutes: 50)));
        c.invalidate(weatherControllerProvider);
        expect(await c.read(weatherControllerProvider.future), isNotNull);
        expect(service.fetchCount, 2);

        // Four hours on, still offline: too old to be "now".
        setNow(t0.add(const Duration(hours: 4)));
        c.invalidate(weatherControllerProvider);
        expect(await c.read(weatherControllerProvider.future), isNull);
        expect(service.fetchCount, 3);

        // Signal returns; the next trigger recovers.
        service.failWith = null;
        c.invalidate(weatherControllerProvider);
        final recovered = await c.read(weatherControllerProvider.future);
        expect(recovered!.obtainedAt, t0.add(const Duration(hours: 4)));
        expect(service.fetchCount, 4);
      },
    );

    test(
      'offline with nothing cached: no weather, and a quiet tide state',
      () async {
        final w = weather()..failWith = const SocketException('offline');
        final t = tides()..failWith = const SocketException('offline');
        final (c, _, _) = setUpAt(a, weatherService: w, tideService: t);
        expect(await c.read(weatherControllerProvider.future), isNull);
        expect(
          await c.read(tideControllerProvider.future),
          isA<TideProviderUnavailable>(),
        );
        // One attempt each, not a retry loop.
        expect(w.fetchCount, 1);
        expect(t.fetchCount, 1);
      },
    );

    test(
      'an offline tide curve is kept only while it still covers now',
      () async {
        final service = tides();
        final (c, _, setNow) = setUpAt(a, tideService: service);
        await c.read(tideControllerProvider.future);
        service.failWith = const SocketException('offline');

        setNow(t0.add(const Duration(hours: 2)));
        c.invalidate(tideControllerProvider);
        expect(
          await c.read(tideControllerProvider.future),
          isA<TideAvailable>(),
        );

        // The test curve runs 48 hours past its fetch.
        setNow(t0.add(const Duration(hours: 60)));
        c.invalidate(tideControllerProvider);
        expect(
          await c.read(tideControllerProvider.future),
          isA<TideProviderUnavailable>(),
        );
      },
    );

    testWidgets('in the app: a failed fetch recovers on the next resume, '
        'with no restart', (tester) async {
      tester.view.physicalSize = const Size(430, 2400) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final service = weather()..failWith = const SocketException('offline');
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: t0,
          locationState: LocationAvailable(a, obtainedAt: t0),
          locationService: FakeLocationService(
            checkResult: LocationAvailable(a, obtainedAt: t0),
          ),
          weatherService: service,
          tideService: tides(),
        ),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(weatherControllerProvider).value, isNull);

      service.failWith = null;
      for (final state in [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(container.read(weatherControllerProvider).value, isNotNull);
      expect(find.textContaining('afternoon'), findsOneWidget);
    });
  });

  group('the requests themselves', () {
    test('weather: coordinates, fields and time settings only — and '
        'instants that survive a clock change', () async {
      Uri? asked;
      // 01:00 BST and then 01:00 GMT on 25 October 2026: the same local
      // hour twice, told apart only as instants.
      final firstOne = DateTime.utc(2026, 10, 25, 0).millisecondsSinceEpoch;
      final secondOne = DateTime.utc(2026, 10, 25, 1).millisecondsSinceEpoch;
      final service = OpenMeteoWeatherService(
        client: MockClient((request) async {
          asked = request.url;
          return http.Response(
            jsonEncode({
              'current': {
                'temperature_2m': 11,
                'apparent_temperature': 10,
                'weather_code': 3,
                'precipitation': 0,
                'cloud_cover': 90,
                'wind_speed_10m': 9,
              },
              'hourly': {
                'time': [firstOne ~/ 1000, secondOne ~/ 1000],
                'temperature_2m': [11, 10],
                'weather_code': [3, 61],
                'precipitation_probability': [10, 70],
                'wind_speed_10m': [9, 10],
              },
              'daily': {
                'time': [
                  DateTime.utc(2026, 10, 25).millisecondsSinceEpoch ~/ 1000,
                ],
                'temperature_2m_max': [13],
                'temperature_2m_min': [8],
                'precipitation_probability_max': [70],
              },
            }),
            200,
          );
        }),
      );

      final snapshot = await service.fetch(
        location: a,
        timeZone: TestTimeZones.london,
        now: DateTime.utc(2026, 10, 25, 0, 30),
      );

      expect(asked!.host, 'api.open-meteo.com');
      expect(asked!.queryParameters.keys.toSet(), {
        'timeformat',
        'latitude',
        'longitude',
        'current',
        'hourly',
        'daily',
        'timezone',
        'forecast_days',
      });
      expect(asked!.queryParameters['latitude'], '51.51');
      expect(asked!.queryParameters['timeformat'], 'unixtime');
      expect(snapshot.hourly, hasLength(2));
      expect(
        snapshot.hourly.last.time.isAfter(snapshot.hourly.first.time),
        isTrue,
      );
    });

    test('tides: the repeated hour, read the old way, never yields two '
        'samples at one instant', () async {
      final service = OpenMeteoMarineTideService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'hourly': {
                'time': [
                  '2026-10-25T00:00',
                  '2026-10-25T01:00',
                  '2026-10-25T01:00',
                  '2026-10-25T02:00',
                ],
                'sea_level_height_msl': [1.0, 1.2, 1.3, 1.1],
              },
            }),
            200,
          ),
        ),
      );
      final result = await service.fetch(
        location: a,
        timeZone: TestTimeZones.london,
        now: DateTime.utc(2026, 10, 25, 1),
      );
      final samples = (result as TideFetchData).snapshot.samples;
      for (var i = 1; i < samples.length; i++) {
        expect(samples[i].time.isAfter(samples[i - 1].time), isTrue);
      }
    });

    test('only the two approved services open a network connection', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final code = file.readAsStringSync();
        final networked =
            code.contains('package:http/') ||
            code.contains('HttpClient') ||
            code.contains('WebSocket') ||
            code.contains('Socket.connect');
        if (networked) offenders.add(file.path.replaceAll('\\', '/'));
      }
      expect(offenders..sort(), [
        'lib/core/environment/open_meteo_marine_tide_service.dart',
        'lib/core/environment/open_meteo_weather_service.dart',
      ]);
    });

    test('and those two know nothing about the person using the app', () {
      for (final path in [
        'lib/core/environment/open_meteo_weather_service.dart',
        'lib/core/environment/open_meteo_marine_tide_service.dart',
      ]) {
        final code = File(path).readAsStringSync();
        for (final private in [
          'settings',
          'UserSettings',
          'cycle',
          'Cycle',
          'recipe',
          'Recipe',
          'observation',
          'Observation',
          'garden',
          'Garden',
          'FeatureId',
          'name:',
        ]) {
          expect(code, isNot(contains(private)), reason: '$path: $private');
        }
      }
    });
  });

  group('the edges of the map', () {
    Future<ProviderContainer> openPolar(
      WidgetTester tester, {
      required DateTime now,
      required SolarDayKind kind,
      FakeWeatherService? weatherService,
      FakeTideService? tideService,
    }) async {
      tester.view.physicalSize = const Size(430, 2400) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: now,
          timeZone: TestTimeZones.tromso,
          solarService: FakeSolarService(kind: kind),
          locationState: const LocationAvailable(TestLocations.tromso),
          features: {FeatureId.wheel},
          weatherService: weatherService,
          tideService: tideService,
        ),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('polar night, no weather, tides and the Wheel present', (
      tester,
    ) async {
      await openPolar(
        tester,
        // Four days before Imbolc.
        now: DateTime.utc(2026, 1, 28, 11),
        kind: SolarDayKind.sunNeverRises,
        weatherService: weather()..failWith = const SocketException('offline'),
        tideService: tides(),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('The sun stays below the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('Sunrise'), findsNothing);
      expect(find.text('Sunset'), findsNothing);
      expect(find.text('Tides'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.textContaining('Imbolc'), findsWidgets);
    });

    testWidgets('midnight sun, weather present, tides unavailable', (
      tester,
    ) async {
      await openPolar(
        tester,
        now: DateTime.utc(2026, 6, 25, 22),
        kind: SolarDayKind.sunNeverSets,
        weatherService: weather(),
        tideService: tides(answer: (_) => const TideFetchNoData()),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('The sun stays above the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Tides'), findsOneWidget);
    });

    testWidgets('no location: nothing requested, nothing prompted, nothing '
        'invented — and every feature still opens', (tester) async {
      tester.view.physicalSize = const Size(430, 2400) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final location = FakeLocationService(
        checkResult: const LocationPermissionDenied(),
      );
      final w = weather();
      final t = tides();
      final container = ProviderContainer(
        overrides: environmentOverrides(
          // The day before Beltane in the south (a fixed 1 November).
          now: DateTime.utc(2026, 10, 31, 0),
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
          locationService: location,
          locationState: const LocationPermissionDenied(),
          weatherService: w,
          tideService: t,
          features: FeatureRegistry.optional.map((f) => f.id).toSet(),
        ),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      for (final feature in FeatureRegistry.all) {
        container.read(routerProvider).go(feature.route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: feature.name);
      }
      container.read(routerProvider).go(kEnvironmentRoute);
      await tester.pumpAndSettle();
      expect(find.text('Beltane is approaching · 1 day'), findsOneWidget);

      container
          .read(routerProvider)
          .go(FeatureRegistry.byId(FeatureId.natureLog).route);
      await tester.pumpAndSettle();
      expect(find.text(NatureLogText.noLocationNote), findsOneWidget);

      container
          .read(routerProvider)
          .go(FeatureRegistry.byId(FeatureId.garden).route);
      await tester.pumpAndSettle();
      expect(find.text(GardenText.noLocationNote), findsOneWidget);

      expect(w.fetchCount, 0);
      expect(t.fetchCount, 0);
      expect(location.requestCount, 0);
    });
  });
}
