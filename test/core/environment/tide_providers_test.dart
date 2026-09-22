import 'dart:async';

import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/tide_providers.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  final start = DateTime.utc(2025, 7, 15, 12);

  ProviderContainer containerWith({
    LocationState? locationState,
    FakeTideService? tideService,
    DateTime Function()? clock,
    LocationService? locationService,
    Hemisphere? hemisphere = Hemisphere.northern,
  }) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: start,
        clock: clock,
        locationState: locationState,
        tideService: tideService,
        locationService: locationService,
        hemisphere: hemisphere,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  final london = testTideSnapshot(
    location: TestLocations.london,
    obtainedAt: start,
  );

  group('no location, no request', () {
    test('with location never requested, the state is locationRequired and unfetched', () async {
      final service = FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            TideFetchData(london),
      );
      final container = containerWith(
        locationState: const LocationPermissionNotRequested(),
        tideService: service,
      );

      final state = await container.read(tideControllerProvider.future);

      expect(state, isA<TideLocationRequired>());
      expect(service.fetchCount, 0);
    });

    test(
      'with location denied, the state is locationRequired and unfetched',
      () async {
        final service = FakeTideService(
          result: ({required location, required timeZone, required now}) =>
              TideFetchData(london),
        );
        final container = containerWith(
          locationState: const LocationPermissionDenied(),
          tideService: service,
        );

        final state = await container.read(tideControllerProvider.future);

        expect(state, isA<TideLocationRequired>());
        expect(service.fetchCount, 0);
      },
    );
  });

  group('a shared location, fetched once', () {
    test('a first read with location available fetches once', () async {
      final service = FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            TideFetchData(london),
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        tideService: service,
      );

      final state = await container.read(tideControllerProvider.future);

      expect(state, isA<TideAvailable>());
      expect((state as TideAvailable).snapshot, london);
      expect(service.fetchCount, 1);
    });

    test('several consumers reading the same tide cause one fetch', () async {
      final service = FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            TideFetchData(london),
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        tideService: service,
      );

      await container.read(tideControllerProvider.future);
      final first = container.read(currentTideProvider);
      final second = container.read(currentTideProvider);
      final third = container.read(tideControllerProvider).value;

      expect(first, isA<TideAvailable>());
      expect(second, isA<TideAvailable>());
      expect(third, isA<TideAvailable>());
      expect(service.fetchCount, 1);
    });

    test(
      'a location with no marine data resolves to unavailableForLocation',
      () async {
        final service = FakeTideService(
          result: ({required location, required timeZone, required now}) =>
              const TideFetchNoData(),
        );
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          tideService: service,
        );

        final state = await container.read(tideControllerProvider.future);

        expect(state, isA<TideUnavailableForLocation>());
      },
    );
  });

  group('caching', () {
    test('a fresh state is reused rather than fetched again', () async {
      var now = start;
      final service = FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            TideFetchData(london),
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        tideService: service,
        clock: () => now,
      );

      await container.read(tideControllerProvider.future);
      expect(service.fetchCount, 1);

      now = now.add(const Duration(minutes: 10));
      container.invalidate(tideControllerProvider);
      final state = await container.read(tideControllerProvider.future);

      expect(state, isA<TideAvailable>());
      expect(service.fetchCount, 1);
    });

    test('a stale state is fetched again', () async {
      var now = start;
      final service = FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            TideFetchData(london),
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        tideService: service,
        clock: () => now,
      );

      await container.read(tideControllerProvider.future);
      expect(service.fetchCount, 1);

      now = now.add(kTideCacheDuration + const Duration(minutes: 1));
      container.invalidate(tideControllerProvider);
      await container.read(tideControllerProvider.future);

      expect(service.fetchCount, 2);
    });

    test(
      'a known "no data here" answer is also cached, not retried in a loop',
      () async {
        var now = start;
        final service = FakeTideService(
          result: ({required location, required timeZone, required now}) =>
              const TideFetchNoData(),
        );
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          tideService: service,
          clock: () => now,
        );

        await container.read(tideControllerProvider.future);
        expect(service.fetchCount, 1);

        now = now.add(const Duration(minutes: 5));
        container.invalidate(tideControllerProvider);
        final state = await container.read(tideControllerProvider.future);

        expect(state, isA<TideUnavailableForLocation>());
        expect(service.fetchCount, 1);
      },
    );
  });

  group('failure and offline behaviour', () {
    test(
      'a timeout with no prior cache reads as providerUnavailable, not a crash',
      () async {
        final service = FakeTideService(
          failWith: TimeoutException('no response'),
        );
        final container = containerWith(
          locationState: const LocationAvailable(TestLocations.london),
          tideService: service,
        );

        final state = await container.read(tideControllerProvider.future);

        expect(state, isA<TideProviderUnavailable>());
      },
    );

    test('a later failure falls back to a still-usable cached tide', () async {
      var now = start;
      final service = FakeTideService(
        result: ({required location, required timeZone, required now}) =>
            TideFetchData(london),
      );
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        tideService: service,
        clock: () => now,
      );

      final first = await container.read(tideControllerProvider.future);
      expect(first, isA<TideAvailable>());

      now = now.add(kTideCacheDuration + const Duration(minutes: 1));
      service.result = null;
      service.failWith = TimeoutException('no response');
      container.invalidate(tideControllerProvider);
      final second = await container.read(tideControllerProvider.future);

      expect(second, isA<TideAvailable>());
      expect((second as TideAvailable).snapshot, london);
    });

    test('.future completes normally however the service failed', () async {
      final service = FakeTideService(failWith: StateError('boom'));
      final container = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        tideService: service,
      );

      await expectLater(
        container.read(tideControllerProvider.future),
        completion(isA<TideProviderUnavailable>()),
      );
    });
  });

  group('no GPS retrigger from tides', () {
    test(
      'resolving the tide never calls the location service directly',
      () async {
        final locationService = FakeLocationService(
          checkResult: const LocationAvailable(TestLocations.london),
        );
        final tideService = FakeTideService(
          result: ({required location, required timeZone, required now}) =>
              TideFetchData(london),
        );
        final container = containerWith(
          locationService: locationService,
          tideService: tideService,
        );

        await container.read(locationStateProvider.notifier).refresh();
        expect(locationService.checkCount, 1);

        await container.read(tideControllerProvider.future);
        container.invalidate(tideControllerProvider);
        await container.read(tideControllerProvider.future);

        expect(locationService.checkCount, 1);
      },
    );
  });

  group('hemisphere independence', () {
    test('changing hemisphere without changing location does not change the tide request', () async {
      GeoLocation? requestedNorth;
      GeoLocation? requestedSouth;

      final northContainer = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        hemisphere: Hemisphere.northern,
        tideService: FakeTideService(
          result: ({required location, required timeZone, required now}) {
            requestedNorth = location;
            return TideFetchData(london);
          },
        ),
      );
      final southContainer = containerWith(
        locationState: const LocationAvailable(TestLocations.london),
        hemisphere: Hemisphere.southern,
        tideService: FakeTideService(
          result: ({required location, required timeZone, required now}) {
            requestedSouth = location;
            return TideFetchData(london);
          },
        ),
      );

      await northContainer.read(tideControllerProvider.future);
      await southContainer.read(tideControllerProvider.future);

      // Location — not the chosen hemisphere — is the only thing a
      // tide request is ever built from.
      expect(requestedNorth, requestedSouth);
    });
  });
}
