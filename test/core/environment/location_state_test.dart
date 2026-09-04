import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_service.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/natural_environment.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  group('GeoLocation', () {
    test('derives the hemisphere from the sign of the latitude', () {
      expect(TestLocations.london.hemisphere, Hemisphere.northern);
      expect(TestLocations.wellington.hemisphere, Hemisphere.southern);
      expect(TestLocations.sydney.hemisphere, Hemisphere.southern);
    });

    test('the equator is northern, by documented decision', () {
      // The rule is arbitrary but it must be total: no third state, no
      // crash, no silent null. Someone on the equator can still override
      // it with the manual choice.
      expect(TestLocations.equator.hemisphere, Hemisphere.northern);
      expect(Hemisphere.ofLatitude(0), Hemisphere.northern);
      expect(Hemisphere.ofLatitude(-0.0001), Hemisphere.southern);
      expect(Hemisphere.ofLatitude(0.0001), Hemisphere.northern);
    });

    test('rejects coordinates the platform should never produce', () {
      expect(GeoLocation.tryCreate(latitude: double.nan, longitude: 0), isNull);
      expect(GeoLocation.tryCreate(latitude: 0, longitude: double.nan), isNull);
      expect(GeoLocation.tryCreate(latitude: 91, longitude: 0), isNull);
      expect(GeoLocation.tryCreate(latitude: -91, longitude: 0), isNull);
      expect(GeoLocation.tryCreate(latitude: 0, longitude: 181), isNull);
    });

    test('accepts the extremes of the valid range', () {
      expect(GeoLocation.tryCreate(latitude: -90, longitude: -180), isNotNull);
      expect(GeoLocation.tryCreate(latitude: 90, longitude: 180), isNotNull);
    });
  });

  group('LocationState', () {
    test('only the available state carries a position', () {
      expect(const LocationPermissionNotRequested().location, isNull);
      expect(const LocationPermissionDenied().location, isNull);
      expect(const LocationPermissionPermanentlyDenied().location, isNull);
      expect(const LocationUnavailable().location, isNull);
      expect(
        const LocationAvailable(TestLocations.wellington).location,
        TestLocations.wellington,
      );
    });

    test('a permanent denial is the one state that must not be re-asked', () {
      expect(const LocationPermissionNotRequested().canRequest, isTrue);
      expect(const LocationPermissionDenied().canRequest, isTrue);
      expect(const LocationUnavailable().canRequest, isTrue);
      expect(const LocationPermissionPermanentlyDenied().canRequest, isFalse);
    });
  });

  group('LocationController', () {
    ProviderContainer containerWith(LocationService service) {
      final container = ProviderContainer(
        overrides: environmentOverrides(locationService: service),
      );
      addTearDown(container.dispose);
      return container;
    }

    test('starts out having never asked', () {
      final container = containerWith(FakeLocationService());

      expect(
        container.read(locationStateProvider),
        isA<LocationPermissionNotRequested>(),
      );
    });

    test('refresh checks without ever prompting', () async {
      final service = FakeLocationService(
        checkResult: const LocationAvailable(TestLocations.wellington),
      );
      final container = containerWith(service);

      await container.read(locationStateProvider.notifier).refresh();

      expect(service.checkCount, 1);
      expect(service.requestCount, 0, reason: 'refresh must not prompt');
      expect(container.read(locationStateProvider), isA<LocationAvailable>());
    });

    test('requestAccess prompts and records the answer', () async {
      final service = FakeLocationService(
        checkResult: const LocationPermissionNotRequested(),
        requestResult: const LocationPermissionDenied(),
      );
      final container = containerWith(service);

      await container.read(locationStateProvider.notifier).requestAccess();

      expect(service.requestCount, 1);
      expect(
        container.read(locationStateProvider),
        isA<LocationPermissionDenied>(),
      );
    });

    test('a permanent denial is reported without crashing', () async {
      final container = containerWith(
        FakeLocationService(
          requestResult: const LocationPermissionPermanentlyDenied(),
        ),
      );

      await container.read(locationStateProvider.notifier).requestAccess();

      final state = container.read(locationStateProvider);
      expect(state, isA<LocationPermissionPermanentlyDenied>());
      expect(state.canRequest, isFalse);
    });

    test('a thrown platform error degrades to unavailable', () async {
      final container = containerWith(const ThrowingLocationService());

      await container.read(locationStateProvider.notifier).refresh();
      await container.read(locationStateProvider.notifier).requestAccess();

      expect(container.read(locationStateProvider), isA<LocationUnavailable>());
    });

    test(
      'the fallback service reports unavailable rather than lying',
      () async {
        const service = UnavailableLocationService();

        expect(await service.currentState(), isA<LocationUnavailable>());
        expect(await service.requestAccess(), isA<LocationUnavailable>());
      },
    );
  });

  group('hemisphere priority', () {
    ResolvedHemisphere resolveWith({
      Hemisphere? chosen,
      LocationState? locationState,
    }) {
      final container = ProviderContainer(
        overrides: environmentOverrides(
          hemisphere: chosen,
          locationState: locationState,
        ),
      );
      addTearDown(container.dispose);
      return container.read(resolvedHemisphereProvider);
    }

    test('a positive latitude derives the northern hemisphere', () {
      final resolved = resolveWith(
        chosen: Hemisphere.southern,
        locationState: const LocationAvailable(TestLocations.london),
      );

      expect(resolved.hemisphere, Hemisphere.northern);
      expect(resolved.source, HemisphereSource.derivedFromLocation);
    });

    test('a negative latitude derives the southern hemisphere', () {
      final resolved = resolveWith(
        chosen: Hemisphere.northern,
        locationState: const LocationAvailable(TestLocations.wellington),
      );

      expect(resolved.hemisphere, Hemisphere.southern);
      expect(resolved.source, HemisphereSource.derivedFromLocation);
    });

    test('the chosen hemisphere is used whenever there is no position', () {
      for (final state in const <LocationState>[
        LocationPermissionNotRequested(),
        LocationPermissionDenied(),
        LocationPermissionPermanentlyDenied(),
        LocationUnavailable(),
      ]) {
        final resolved = resolveWith(
          chosen: Hemisphere.southern,
          locationState: state,
        );

        expect(
          resolved.hemisphere,
          Hemisphere.southern,
          reason: 'the user\'s choice must survive $state',
        );
        expect(resolved.source, HemisphereSource.userSelected);
      }
    });

    test('the technical fallback applies only before anything is known', () {
      final resolved = resolveWith();

      expect(resolved.source, HemisphereSource.technicalFallback);
      expect(resolved.hemisphere, kTechnicalFallbackHemisphere);
    });
  });

  group('the stored preference is never overwritten by location', () {
    test(
      'a southern user whose phone reports the north keeps their choice',
      () async {
        final container = ProviderContainer(
          overrides: environmentOverrides(
            hemisphere: Hemisphere.southern,
            locationState: const LocationAvailable(TestLocations.london),
          ),
        );
        addTearDown(container.dispose);

        // Calculations follow the real latitude...
        expect(
          container.read(resolvedHemisphereProvider).hemisphere,
          Hemisphere.northern,
        );
        // ...but what the user told us is left exactly as they set it, so
        // revoking location returns them to their own preference.
        expect(
          container.read(userSettingsProvider).hemisphere,
          Hemisphere.southern,
        );
      },
    );
  });
}
