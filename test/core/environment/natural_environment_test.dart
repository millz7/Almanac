import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/natural_environment.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/environment/solar_service.dart';
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

  group('what the screens need is on the state, not recalculated', () {
    test('carries the instant everything was resolved for', () async {
      final now = DateTime.utc(2025, 7, 15, 12, 34);
      final environment = await resolve(containerAt(now: now));

      // A screen must be able to say "today" without reading the clock
      // again — and in a test, without escaping the injected one.
      expect(environment.resolvedAt, now);
    });

    test('carries today\'s sunrise and sunset, as instants', () async {
      final environment = await resolve(
        containerAt(
          now: DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
          sunrise: DateTime.utc(2025, 7, 15, 5, 12),
          sunset: DateTime.utc(2025, 7, 15, 20, 41),
        ),
      );

      expect(environment.solarEvents.hasTimes, isTrue);
      expect(environment.solarEvents.sunrise, DateTime.utc(2025, 7, 15, 5, 12));
      expect(environment.solarEvents.sunset, DateTime.utc(2025, 7, 15, 20, 41));
      expect(environment.solarEvents.sunrise!.isUtc, isTrue);
      expect(
        environment.solarEvents.dayLength,
        const Duration(hours: 15, minutes: 29),
      );
    });

    test('reports no times when there is no position', () async {
      // The real solar service answers `locationRequired` without
      // coordinates, because sunrise genuinely cannot be calculated
      // without them.
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          solarService: FakeSolarService(),
        ),
      );
      addTearDown(container.dispose);

      final environment = await resolve(container);

      expect(environment.hasPreciseLocation, isFalse);
      expect(environment.solarEvents.hasTimes, isFalse);
      expect(environment.solarEvents.dayLength, isNull);
      expect(environment.dayProgress, isNull);
      expect(
        environment.dayNight.accuracy,
        DayNightAccuracy.estimatedWithoutLocation,
      );
    });

    test('carries the moon phase, which needs no position', () async {
      // A known full moon. The phase is a property of the moment, so it
      // is there whether or not location was ever shared.
      final environment = await resolve(
        containerAt(now: DateTime.utc(2025, 7, 10, 20, 37)),
      );

      expect(environment.moon.phase.name, 'fullMoon');
      expect(environment.moon.illuminatedPercent, 100);
    });

    test('day progress moves through the day and stops at the ends', () async {
      Future<double?> progressAt(int hour) async {
        final environment = await resolve(
          containerAt(
            now: DateTime.utc(2025, 7, 15, hour),
            locationState: const LocationAvailable(TestLocations.london),
            sunrise: DateTime.utc(2025, 7, 15, 5),
            sunset: DateTime.utc(2025, 7, 15, 20),
          ),
        );
        return environment.dayProgress;
      }

      expect(await progressAt(4), isNull);
      expect(await progressAt(5), 0);
      expect((await progressAt(12))!, closeTo(7 / 15, 1e-9));
      expect(await progressAt(20), 1);
      expect(await progressAt(22), isNull);
    });

    test('a polar day has no progress rather than a made-up one', () async {
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 1, 12),
          timeZone: TestTimeZones.tromso,
          locationState: const LocationAvailable(TestLocations.tromso),
          solarService: FakeSolarService(kind: SolarDayKind.sunNeverSets),
        ),
      );
      addTearDown(container.dispose);

      final environment = await resolve(container);

      expect(environment.solarEvents.kind, SolarDayKind.sunNeverSets);
      expect(environment.dayProgress, isNull);
      expect(environment.dayNight.daylight, 1);
    });
  });
}
