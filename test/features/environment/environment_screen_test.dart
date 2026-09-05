import 'package:almanac/app/app.dart';
import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/features/environment/presentation/widgets/explore_links.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:almanac/features/environment/presentation/widgets/sky_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A moon service pinned to one phase, so a test about what the screen
/// says is not also a test of the date it happens to be.
class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.state);

  final MoonPhaseState state;

  @override
  MoonPhaseState phaseAt(DateTime instant) => state;
}

void main() {
  setUpAll(useTimeZoneDatabase);

  /// A tall test surface, so the whole page is laid out at once and a
  /// `find` does not miss a section that is merely below the fold.
  const tallSurface = Size(420, 1800);

  /// A realistic phone, for the tests that are about proportion.
  const phoneSurface = Size(400, 860);

  Future<void> openToday(
    WidgetTester tester, {
    required List<Override> overrides,
    Size surface = tallSurface,
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const AlmanacApp()),
    );
    await tester.pumpAndSettle();
  }

  group('the date and the season', () {
    testWidgets('shows today\'s real local date', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 15, 12)),
      );

      expect(find.text('Tuesday 15 July'), findsOneWidget);
    });

    testWidgets('uses the local day, not the UTC one', (tester) async {
      // 20:00 UTC on 14 July is already midday on the 15th in Wellington.
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 14, 20),
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
        ),
      );

      expect(find.text('Tuesday 15 July'), findsOneWidget);
    });

    testWidgets('names the season and where in it we are', (tester) async {
      // A fortnight after the June solstice: early summer in the north.
      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 5, 12)),
      );

      expect(find.text('Early summer'), findsOneWidget);
      expect(find.textContaining('Autumn arrives in'), findsOneWidget);
    });

    testWidgets('the same date is the opposite season in the south', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 5, 12),
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
        ),
      );

      expect(find.text('Early winter'), findsOneWidget);
      expect(find.textContaining('Spring arrives in'), findsOneWidget);
    });
  });

  group('sunrise and sunset', () {
    testWidgets('shows real local times, not UTC', (tester) async {
      // 05:12 and 20:41 UTC are 06:12 and 21:41 in London in July.
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          sunrise: DateTime.utc(2025, 7, 15, 5, 12),
          sunset: DateTime.utc(2025, 7, 15, 20, 41),
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('6:12 AM'), findsOneWidget);
      expect(find.text('9:41 PM'), findsOneWidget);
    });

    testWidgets('says how long the light lasts', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          sunrise: DateTime.utc(2025, 7, 15, 5),
          sunset: DateTime.utc(2025, 7, 15, 20, 30),
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      expect(find.text('15 hours 30 minutes of light'), findsOneWidget);
    });

    testWidgets('a Wellington evening reads in Wellington time', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 12, 21, 0),
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
          // Wellington is UTC+13 in December, so 16:48 UTC on the 20th
          // is 05:48 local on the 21st — the previous UTC day carries
          // this local morning's sunrise.
          sunrise: DateTime.utc(2025, 12, 20, 16, 48),
          sunset: DateTime.utc(2025, 12, 21, 7, 53),
          locationState: const LocationAvailable(TestLocations.wellington),
        ),
      );

      expect(find.text('5:48 AM'), findsOneWidget);
      expect(find.text('8:53 PM'), findsOneWidget);
    });
  });

  group('without location', () {
    testWidgets('invites location instead of showing a made-up time', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(solarService: FakeSolarService()),
      );

      expect(
        find.text('Connect location to see sunrise and sunset where you are.'),
        findsOneWidget,
      );
      expect(find.text('Enable location'), findsOneWidget);
      // Nothing that looks like a sunrise time is shown.
      expect(find.text('Sunrise'), findsNothing);
      expect(find.text('Sunset'), findsNothing);
    });

    testWidgets('the invitation is not an error', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(solarService: FakeSolarService()),
      );

      // A quiet text action, not a warning or a filled call to action.
      expect(
        find.widgetWithText(TextButton, 'Enable location'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
    });

    testWidgets('tapping it asks once, and only from the tap', (tester) async {
      final service = FakeLocationService();

      await openToday(
        tester,
        overrides: environmentOverrides(
          solarService: FakeSolarService(),
          locationService: service,
        ),
      );

      // Merely opening the screen must never prompt.
      expect(service.requestCount, 0);

      await tester.tap(find.text('Enable location'));
      await tester.pumpAndSettle();

      expect(service.requestCount, 1);
    });

    testWidgets('a permanent denial offers settings, not another prompt', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          solarService: FakeSolarService(),
          locationState: const LocationPermissionPermanentlyDenied(),
        ),
      );

      expect(find.text('Open device settings'), findsOneWidget);
      expect(find.text('Enable location'), findsNothing);
    });

    testWidgets('the rest of the day is still there', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(solarService: FakeSolarService()),
      );

      // Season and moon need no coordinates, so they must not disappear
      // along with the sun times.
      expect(find.text('The moon'), findsOneWidget);
      expect(find.textContaining('summer'), findsOneWidget);
    });
  });

  group('polar days', () {
    testWidgets('midnight sun is said, not fabricated', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 1, 12),
          timeZone: TestTimeZones.tromso,
          solarService: FakeSolarService(kind: SolarDayKind.sunNeverSets),
          locationState: const LocationAvailable(TestLocations.tromso),
        ),
      );

      expect(
        find.text('The sun stays above the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('Sunrise'), findsNothing);
    });

    testWidgets('polar night is said, not fabricated', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 1, 5, 12),
          timeZone: TestTimeZones.tromso,
          solarService: FakeSolarService(kind: SolarDayKind.sunNeverRises),
          locationState: const LocationAvailable(TestLocations.tromso),
        ),
      );

      expect(
        find.text('The sun stays below the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('Sunset'), findsNothing);
    });
  });

  group('the moon', () {
    testWidgets('names the phase and how much is lit', (tester) async {
      await openToday(
        tester,
        overrides: [
          ...environmentOverrides(),
          moonServiceProvider.overrideWithValue(
            const _FixedMoonService(
              MoonPhaseState(
                phase: MoonPhase.waxingCrescent,
                elongationDegrees: 45,
                illuminatedFraction: 0.146,
              ),
            ),
          ),
        ],
      );

      expect(find.text('Waxing Crescent'), findsOneWidget);
      expect(find.text('15% lit'), findsOneWidget);
    });

    testWidgets('is drawn, not fetched as a picture', (tester) async {
      await openToday(tester, overrides: environmentOverrides());

      expect(find.byType(MoonDisc), findsOneWidget);
      // No network image and no bundled artwork.
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('the lit side turns over in the southern hemisphere', (
      tester,
    ) async {
      Future<bool> mirroredFor(Hemisphere hemisphere) async {
        await openToday(
          tester,
          overrides: environmentOverrides(
            hemisphere: hemisphere,
            timeZone: hemisphere == Hemisphere.southern
                ? TestTimeZones.wellington
                : TestTimeZones.london,
          ),
        );
        return tester.widget<MoonDisc>(find.byType(MoonDisc)).mirrored;
      }

      expect(await mirroredFor(Hemisphere.northern), isFalse);
      expect(await mirroredFor(Hemisphere.southern), isTrue);
    });
  });

  group('tides', () {
    testWidgets('are held open with no data at all', (tester) async {
      await openToday(tester, overrides: environmentOverrides());

      expect(find.text('Tides'), findsOneWidget);
      expect(find.text('Not here yet'), findsOneWidget);
      // Nothing that could be mistaken for a tide time.
      expect(find.textContaining('High water at'), findsNothing);
      expect(find.textContaining('m'), findsWidgets); // 'moon', not metres
    });
  });

  group('the shape of the page', () {
    testWidgets('leads with the day, then the sky, then the details', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      double topOf(Finder finder) => tester.getTopLeft(finder.first).dy;

      final date = topOf(find.text('Tuesday 15 July'));
      final hero = topOf(find.byType(SkyHero));
      final sun = topOf(find.text('The sun today'));
      final moon = topOf(find.text('The moon'));
      final tides = topOf(find.text('Tides'));

      expect(date, lessThan(hero));
      expect(hero, lessThan(sun));
      expect(sun, lessThan(moon));
      expect(moon, lessThan(tides));
    });

    testWidgets('the hero is the biggest thing on the page', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(),
        surface: phoneSurface,
      );

      final hero = tester.getSize(find.byType(SkyHero));
      final screen = tester.getSize(find.byType(MaterialApp));

      // Dominant, but not the whole screen — the day still reads as a
      // page rather than a wallpaper.
      expect(hero.height, greaterThan(screen.height * 0.2));
      expect(hero.height, lessThan(screen.height * 0.5));
    });

    testWidgets('links onward to the parts of the Almanac they chose', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          features: const {FeatureId.yoga, FeatureId.garden},
        ),
      );

      expect(find.text('Elsewhere in your Almanac'), findsOneWidget);
      // Once as a link here, once in the navigation bar.
      expect(find.text('Yoga'), findsNWidgets(2));
      expect(find.text('Garden'), findsNWidgets(2));
      // Nothing they did not choose.
      expect(find.text('Cookbook'), findsNothing);
      expect(find.text('Meditation'), findsNothing);
    });

    testWidgets('the links are absent entirely when nothing was chosen', (
      tester,
    ) async {
      await openToday(tester, overrides: environmentOverrides());

      expect(find.byType(ExploreLinks), findsOneWidget);
      expect(find.text('Elsewhere in your Almanac'), findsNothing);
    });

    testWidgets('a link goes to that feature', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(features: const {FeatureId.garden}),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(ExploreLinks),
          matching: find.text('Garden'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('the Almanac is one tap away from the top right', (
      tester,
    ) async {
      await openToday(tester, overrides: environmentOverrides());

      await tester.tap(find.byType(AlmanacButton));
      await tester.pumpAndSettle();

      expect(find.text('Location & Region'), findsOneWidget);
    });
  });

  group('what the light is doing', () {
    testWidgets('daytime says the sun is up', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      expect(find.text('The sun is up'), findsOneWidget);
    });

    testWidgets('after dark says so', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 23, 30),
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      expect(find.text('Dark, and the world is resting'), findsOneWidget);
    });

    testWidgets('an estimate is described as an estimate', (tester) async {
      // No coordinates, so day/night came from the clock. The wording
      // must not imply the app knows where the sun is.
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          solarService: FakeSolarService(),
        ),
      );

      expect(find.text('Daylight, by the clock'), findsOneWidget);
      expect(find.text('The sun is up'), findsNothing);
    });

    testWidgets('midnight sun is described as itself', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 1, 12),
          timeZone: TestTimeZones.tromso,
          solarService: FakeSolarService(kind: SolarDayKind.sunNeverSets),
          locationState: const LocationAvailable(TestLocations.tromso),
        ),
      );

      expect(find.text('The sun does not set here today'), findsOneWidget);
    });
  });
}
