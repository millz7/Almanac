import 'dart:async';

import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/core/environment/weather_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final start = DateTime.utc(2025, 7, 15, 12);

  ProviderContainer containerWith({
    LocationState? locationState,
    FakeWeatherService? weatherService,
    DateTime Function()? clock,
    LocationService? locationService,
  }) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: start,
        clock: clock,
        locationState: locationState,
        weatherService: weatherService,
        locationService: locationService,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  final london = testWeatherSnapshot(
    location: TestLocations.london,
    obtainedAt: start,
  );

  group('no location, no request', () {
    test(
      'with location never requested, weather is null and unfetched',
      () async {
        final service = FakeWeatherService(
          result: ({required location, required timeZone, required now}) =>
              london,
        );
        final container = containerWith(
          locationState: const LocationPermissionNotRequested(),
          weatherService: service,
        );

        final value = await container.read(weatherControllerProvider.future);

        expect(value, isNull);
        expect(service.fetchCount, 0);
      },
    );

    test('with location denied, weather is null and unfetched', () async {
      final service = FakeWeatherService(
        result: ({required location, required timeZone, required now}) =>
            london,
      );
      final container = containerWith(
        locationState: const LocationPermissionDenied(),
        weatherService: service,
      );

      final value = await container.read(weatherControllerProvider.future);

      expect(value, isNull);
      expect(service.fetchCount, 0);
    });
  });

  group('a shared location, fetched once', () {
    test('a first read with location available fetches once', () async {
      final service = FakeWeatherService(
        result: ({required location, required timeZone, required now}) =>
            london,
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        weatherService: service,
      );

      final value = await container.read(weatherControllerProvider.future);

      expect(value, london);
      expect(service.fetchCount, 1);
    });

    test(
      'several consumers reading the same forecast cause one fetch',
      () async {
        final service = FakeWeatherService(
          result: ({required location, required timeZone, required now}) =>
              london,
        );
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          weatherService: service,
        );

        // Environment, and every feature's own suggestion widget, all read
        // through the same selector — "one forecast, many interpretations".
        await container.read(weatherControllerProvider.future);
        final first = container.read(currentWeatherProvider);
        final second = container.read(currentWeatherProvider);
        final third = container.read(weatherControllerProvider).value;

        expect(first, london);
        expect(second, london);
        expect(third, london);
        expect(service.fetchCount, 1);
      },
    );
  });

  group('caching', () {
    test('a fresh cache is reused rather than fetched again', () async {
      var now = start;
      final service = FakeWeatherService(
        result: ({required location, required timeZone, required now}) =>
            london,
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        weatherService: service,
        clock: () => now,
      );

      await container.read(weatherControllerProvider.future);
      expect(service.fetchCount, 1);

      // Nothing about the location or the clock has changed enough to
      // matter — well inside kWeatherCacheDuration — so a rebuild (the
      // same thing an app resume or an unrelated provider change would
      // trigger) must not fetch again.
      now = now.add(const Duration(minutes: 10));
      container.invalidate(weatherControllerProvider);
      final value = await container.read(weatherControllerProvider.future);

      expect(value, london);
      expect(service.fetchCount, 1);
    });

    test('a stale cache is fetched again', () async {
      var now = start;
      final service = FakeWeatherService(
        result: ({required location, required timeZone, required now}) =>
            london,
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        weatherService: service,
        clock: () => now,
      );

      await container.read(weatherControllerProvider.future);
      expect(service.fetchCount, 1);

      now = now.add(kWeatherCacheDuration + const Duration(minutes: 1));
      container.invalidate(weatherControllerProvider);
      await container.read(weatherControllerProvider.future);

      expect(service.fetchCount, 2);
    });
  });

  group('failure and offline behaviour', () {
    test('a timeout leaves the app with no weather, not a crash', () async {
      final service = FakeWeatherService(
        failWith: TimeoutException('no response'),
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        weatherService: service,
      );

      final value = await container.read(weatherControllerProvider.future);

      expect(value, isNull);
      expect(service.fetchCount, 1);
    });

    test(
      'an unparseable response leaves the app with no weather, not a crash',
      () async {
        final service = FakeWeatherService(
          failWith: const WeatherServiceFailure('unexpected response shape'),
        );
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          weatherService: service,
        );

        final value = await container.read(weatherControllerProvider.future);

        expect(value, isNull);
      },
    );

    test(
      'a later failure falls back to a still-usable cached forecast',
      () async {
        var now = start;
        final service = FakeWeatherService(
          result: ({required location, required timeZone, required now}) =>
              london,
        );
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          weatherService: service,
          clock: () => now,
        );

        final first = await container.read(weatherControllerProvider.future);
        expect(first, london);

        // The forecast is now stale enough to be worth asking again, and
        // this time the network attempt fails outright.
        now = now.add(kWeatherCacheDuration + const Duration(minutes: 1));
        service.result = null;
        service.failWith = TimeoutException('no response');
        container.invalidate(weatherControllerProvider);
        final second = await container.read(weatherControllerProvider.future);

        expect(second, london, reason: 'the stale-but-usable cache stands in');
      },
    );

    test(
      'a failure with no prior cache leaves weather absent, not an error',
      () async {
        final service = FakeWeatherService(failWith: StateError('boom'));
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          weatherService: service,
        );

        // `.future` must complete normally — never throw — however the
        // underlying service failed.
        await expectLater(
          container.read(weatherControllerProvider.future),
          completion(isNull),
        );
      },
    );
  });

  group('no GPS retrigger from weather', () {
    test(
      'resolving weather never calls the location service directly',
      () async {
        final locationService = FakeLocationService(
          checkResult: const LocationAvailable(TestLocations.london),
        );
        final weatherService = FakeWeatherService(
          result: ({required location, required timeZone, required now}) =>
              london,
        );
        final container = containerWith(
          locationService: locationService,
          weatherService: weatherService,
        );

        // Populate a real, non-fixed location the way the app does.
        await container.read(locationStateProvider.notifier).refresh();
        expect(locationService.checkCount, 1);

        await container.read(weatherControllerProvider.future);
        container.invalidate(weatherControllerProvider);
        await container.read(weatherControllerProvider.future);

        // Weather resolved twice; the location service was asked no more
        // than the one explicit refresh above.
        expect(locationService.checkCount, 1);
      },
    );
  });
}
