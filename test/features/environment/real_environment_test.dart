import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/natural_environment.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 keeps the Override type out of its main export.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// End-to-end checks that the whole chain works on real data: a real
/// position, a real IANA zone, a real solar calculation, and the theme
/// engine from Step 2 following it.
void main() {
  setUpAll(useTimeZoneDatabase);

  /// The real solar service, not a fake — this is the point of these tests.
  List<Override> realEnvironment({
    required DateTime now,
    required LocalTimeZone zone,
    required GeoLocation? position,
    Hemisphere? chosen = Hemisphere.northern,
  }) => environmentOverrides(
    now: now,
    timeZone: zone,
    hemisphere: chosen,
    solarService: const AstronomicalSolarService(),
    locationState: position == null
        ? const LocationPermissionDenied()
        : LocationAvailable(position, obtainedAt: now),
  );

  Future<NaturalEnvironment> resolve(List<Override> overrides) async {
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container.read(naturalEnvironmentProvider.future);
  }

  group('Wellington with real location and real solar data', () {
    final zone = TestTimeZones.wellington;

    test('midday in July is winter, in daylight, from real sunrise', () async {
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 12),
          zone: zone,
          position: TestLocations.wellington,
          // Stored choice deliberately wrong, to prove location wins.
          chosen: Hemisphere.northern,
        ),
      );

      expect(environment.hemisphere, Hemisphere.southern);
      expect(
        environment.hemisphereSource,
        HemisphereSource.derivedFromLocation,
      );
      expect(environment.season.season, Season.winter);
      expect(environment.dayNight.phase, DayPhase.day);
      expect(
        environment.dayNight.accuracy,
        DayNightAccuracy.fromSolarEvents,
        reason: 'with a real position this must not be an estimate',
      );
      expect(environment.timeZone.id, 'Pacific/Auckland');
    });

    test('06:00 in July is before sunrise, so night', () async {
      // Wellington's July sunrise is about 07:47 local.
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 6),
          zone: zone,
          position: TestLocations.wellington,
        ),
      );

      expect(environment.dayNight.phase, DayPhase.night);
      expect(environment.dayNight.daylight, 0);
    });

    test('18:00 in July is after sunset, so night', () async {
      // Sunset is about 16:58 local, so 18:00 is well past dusk.
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 18),
          zone: zone,
          position: TestLocations.wellington,
        ),
      );

      expect(environment.dayNight.phase, DayPhase.night);
    });

    test('the same clock time in December is still daylight', () async {
      // 18:00 is night in July but broad daylight in December, when
      // sunset is about 20:53 — which a fixed clock rule could not know.
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 12, 15, 18),
          zone: zone,
          position: TestLocations.wellington,
        ),
      );

      expect(environment.dayNight.phase, DayPhase.day);
      expect(environment.season.season, Season.spring);
    });

    test('twilight gives a partial daylight value, not a switch', () async {
      // A few minutes after the July sunrise of about 07:47 local.
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 7, 50),
          zone: zone,
          position: TestLocations.wellington,
        ),
      );

      expect(environment.dayNight.isTransitioning, isTrue);
      expect(environment.dayNight.daylight, greaterThan(0));
      expect(environment.dayNight.daylight, lessThan(1));
    });
  });

  group('a northern location, same machinery', () {
    final zone = TestTimeZones.london;

    test('midday in July is summer, in daylight', () async {
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 12),
          zone: zone,
          position: TestLocations.london,
          chosen: Hemisphere.southern,
        ),
      );

      expect(environment.hemisphere, Hemisphere.northern);
      expect(environment.season.season, Season.summer);
      expect(environment.dayNight.phase, DayPhase.day);
    });

    test('22:00 in December is night, but in June it is barely dusk', () async {
      final december = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 12, 15, 22),
          zone: zone,
          position: TestLocations.london,
        ),
      );
      final june = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 6, 21, 21, 30),
          zone: zone,
          position: TestLocations.london,
        ),
      );

      expect(december.dayNight.phase, DayPhase.night);
      // London's June sunset is about 21:21, so 21:30 is mid-dusk.
      expect(june.dayNight.isTransitioning, isTrue);
    });
  });

  group('inside the Arctic circle', () {
    final zone = TestTimeZones.tromso;

    test('midnight sun keeps the day palette at midnight', () async {
      // Early July: comfortably inside Tromsø's midnight-sun period, and
      // clear of the solstice itself so the season is unambiguous.
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 1, 0, 30),
          zone: zone,
          position: TestLocations.tromso,
        ),
      );

      expect(environment.dayNight.phase, DayPhase.day);
      expect(environment.dayNight.daylight, 1);
      expect(environment.season.season, Season.summer);
    });

    test('polar night keeps the night palette at midday', () async {
      // Early January: inside the polar night, and past the December
      // solstice so the season has definitely turned.
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2026, 1, 5, 12),
          zone: zone,
          position: TestLocations.tromso,
        ),
      );

      expect(environment.dayNight.phase, DayPhase.night);
      expect(environment.dayNight.daylight, 0);
      expect(environment.season.season, Season.winter);
    });
  });

  group('with location declined', () {
    final zone = TestTimeZones.wellington;

    test('seasons still work from the chosen hemisphere', () async {
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 12),
          zone: zone,
          position: null,
          chosen: Hemisphere.southern,
        ),
      );

      expect(environment.hemisphere, Hemisphere.southern);
      expect(environment.hemisphereSource, HemisphereSource.userSelected);
      expect(environment.season.season, Season.winter);
      expect(environment.hasPreciseLocation, isFalse);
    });

    test('day and night are estimated, and say so', () async {
      final environment = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 12),
          zone: zone,
          position: null,
          chosen: Hemisphere.southern,
        ),
      );

      expect(environment.dayNight.isDaytime, isTrue);
      expect(
        environment.dayNight.accuracy,
        DayNightAccuracy.estimatedWithoutLocation,
        reason: 'without a position the app must not claim solar accuracy',
      );
    });

    test('and the estimate still follows the local clock', () async {
      final night = await resolve(
        realEnvironment(
          now: zone.instantAtLocal(2025, 7, 15, 2),
          zone: zone,
          position: null,
          chosen: Hemisphere.southern,
        ),
      );

      expect(night.dayNight.isDaytime, isFalse);
    });
  });

  group('the running app follows real solar events', () {
    testWidgets('daylight in Wellington gives the winter day palette', (
      tester,
    ) async {
      final zone = TestTimeZones.wellington;
      await tester.pumpWidget(
        ProviderScope(
          overrides: realEnvironment(
            now: zone.instantAtLocal(2025, 7, 15, 12),
            zone: zone,
            position: TestLocations.wellington,
          ),
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      final palette = tester.element(find.byType(NavigationBar)).palette;
      expect(palette.name, 'Winter Day');
    });

    testWidgets('after the real sunset it is the winter night palette', (
      tester,
    ) async {
      final zone = TestTimeZones.wellington;
      await tester.pumpWidget(
        ProviderScope(
          // 18:00 local, well after Wellington's ~16:58 July sunset.
          overrides: realEnvironment(
            now: zone.instantAtLocal(2025, 7, 15, 18),
            zone: zone,
            position: TestLocations.wellington,
          ),
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();

      final palette = tester.element(find.byType(NavigationBar)).palette;
      expect(palette.name, 'Winter Night');
    });
  });
}
