import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/natural_environment.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  ProviderContainer containerAt({
    required DateTime now,
    LocalTimeZone? timeZone,
    Hemisphere? hemisphere = Hemisphere.northern,
    LocationState? locationState,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: now,
        timeZone: timeZone,
        hemisphere: hemisphere,
        locationState: locationState,
        sunrise: sunrise,
        sunset: sunset,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<NaturalEnvironment> resolve(ProviderContainer container) =>
      container.read(naturalEnvironmentProvider.future);

  group('resolution', () {
    test('resolves season and day/night from the injected services', () async {
      final environment = await resolve(
        containerAt(
          now: DateTime.utc(2025, 7, 15, 12),
          sunrise: DateTime.utc(2025, 7, 15, 5),
          sunset: DateTime.utc(2025, 7, 15, 21),
        ),
      );

      expect(environment.season.season, Season.summer);
      expect(environment.dayNight.phase, DayPhase.day);
      expect(environment.dayNight.daylight, 1);
    });

    test('night is reported when the instant falls outside the sun', () async {
      final environment = await resolve(
        containerAt(
          now: DateTime.utc(2025, 1, 20, 2),
          sunrise: DateTime.utc(2025, 1, 20, 8),
          sunset: DateTime.utc(2025, 1, 20, 16),
        ),
      );

      expect(environment.season.season, Season.winter);
      expect(environment.dayNight.phase, DayPhase.night);
      expect(environment.dayNight.daylight, 0);
    });

    test('mid-dusk reports a partial daylight value', () async {
      final sunset = DateTime.utc(2025, 4, 20, 19);
      final environment = await resolve(
        containerAt(
          now: sunset,
          sunrise: DateTime.utc(2025, 4, 20, 6),
          sunset: sunset,
        ),
      );

      expect(environment.dayNight.phase, DayPhase.dusk);
      expect(environment.dayNight.daylight, closeTo(0.5, 0.01));
      expect(environment.dayNight.isTransitioning, isTrue);
    });
  });

  group('hemisphere resolution', () {
    test(
      'uses the hemisphere the user chose when there is no location',
      () async {
        final environment = await resolve(
          containerAt(
            now: DateTime.utc(2025, 7, 15, 12),
            hemisphere: Hemisphere.southern,
          ),
        );

        expect(environment.hemisphere, Hemisphere.southern);
        expect(environment.hemisphereSource, HemisphereSource.userSelected);
        expect(environment.season.season, Season.winter);
        expect(environment.hasPreciseLocation, isFalse);
        expect(environment.location, isNull);
      },
    );

    test(
      'the same instant gives opposite seasons in each hemisphere',
      () async {
        final now = DateTime.utc(2025, 7, 15, 12);

        final northern = await resolve(
          containerAt(now: now, hemisphere: Hemisphere.northern),
        );
        final southern = await resolve(
          containerAt(now: now, hemisphere: Hemisphere.southern),
        );

        expect(northern.season.season, Season.summer);
        expect(southern.season.season, Season.winter);
      },
    );

    test(
      'a real latitude takes precedence over the chosen hemisphere',
      () async {
        // The user said northern; their phone says they are in Wellington.
        final environment = await resolve(
          containerAt(
            now: DateTime.utc(2025, 7, 15, 12),
            hemisphere: Hemisphere.northern,
            locationState: const LocationAvailable(TestLocations.wellington),
          ),
        );

        expect(environment.hemisphere, Hemisphere.southern);
        expect(
          environment.hemisphereSource,
          HemisphereSource.derivedFromLocation,
        );
        expect(environment.season.season, Season.winter);
        expect(environment.location, TestLocations.wellington);
      },
    );

    test('a technical fallback is used only when nothing is known', () async {
      final environment = await resolve(
        containerAt(now: DateTime.utc(2025, 7, 15, 12), hemisphere: null),
      );

      expect(environment.hemisphereSource, HemisphereSource.technicalFallback);
      expect(environment.hemisphere, kTechnicalFallbackHemisphere);
    });
  });

  group('precise location is passed on only when it exists', () {
    test('forwarded to the solar service when available', () async {
      final container = containerAt(
        now: DateTime.utc(2025, 7, 15, 12),
        locationState: const LocationAvailable(TestLocations.wellington),
      );
      await resolve(container);

      final solar = container.read(solarServiceProvider) as FakeSolarService;
      expect(solar.lastLocation, TestLocations.wellington);
    });

    test('omitted when the user has not shared it', () async {
      final container = containerAt(now: DateTime.utc(2025, 7, 15, 12));
      await resolve(container);

      final solar = container.read(solarServiceProvider) as FakeSolarService;
      expect(solar.lastLocation, isNull);
    });
  });

  group('time zone is independent of location', () {
    test('the local day comes from the time zone, not a position', () async {
      final environment = await resolve(
        containerAt(
          now: DateTime.utc(2025, 7, 15, 12),
          timeZone: TestTimeZones.wellington,
        ),
      );

      expect(environment.timeZone, TestTimeZones.wellington);
      expect(environment.location, isNull);
    });
  });
}
