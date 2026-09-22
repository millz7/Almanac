import 'package:almanac/app/app.dart';
import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/core/environment/tide_extrema.dart';
import 'package:almanac/core/environment/tide_providers.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:almanac/features/environment/presentation/tide_screen.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:almanac/features/environment/presentation/widgets/environment_artwork_view.dart';
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
        find.text(
          'Connect location to see sunrise, sunset and today\'s weather '
          'where you are.',
        ),
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
      expect(find.text('Moon'), findsOneWidget);
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
      expect(find.text('15% illuminated'), findsOneWidget);
    });

    testWidgets('is drawn, not fetched as a picture', (tester) async {
      await openToday(tester, overrides: environmentOverrides());

      expect(find.byType(MoonDisc), findsOneWidget);
      // The moon fact is drawn from the real phase, not cropped out of
      // the painting: no image inside it, and no network image anywhere.
      // (The landscape itself *is* a bundled plate — that is the
      // artwork — but it is not where the facts come from.)
      expect(
        find.descendant(
          of: find.byType(MoonDisc),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
      expect(find.byType(NetworkImage), findsNothing);
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
    testWidgets('with no location shared, the fact says so plainly', (
      tester,
    ) async {
      await openToday(tester, overrides: environmentOverrides());

      expect(find.text('Tides'), findsOneWidget);
      expect(find.text('Location needed'), findsOneWidget);
      // Nothing that could be mistaken for a tide time or a fabricated
      // reading.
      expect(find.textContaining('High water at'), findsNothing);
      expect(find.text('0:00'), findsNothing);
    });

    testWidgets('with a curve available, the fact shows the direction', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
          tideService: FakeTideService(
            result: ({required location, required timeZone, required now}) =>
                TideFetchData(
                  testTideSnapshot(location: location, obtainedAt: now),
                ),
          ),
        ),
      );

      expect(find.text('Tides'), findsOneWidget);
      expect(
        find.textContaining(RegExp('Rising|Falling|Near high|Near low')),
        findsOneWidget,
      );
    });

    testWidgets('tapping the fact opens the tide detail page', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
          tideService: FakeTideService(
            result: ({required location, required timeZone, required now}) =>
                TideFetchData(
                  testTideSnapshot(location: location, obtainedAt: now),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Tides'));
      await tester.pumpAndSettle();

      expect(find.text('Current'), findsOneWidget);
      expect(find.textContaining('Not for navigation'), findsOneWidget);
    });

    testWidgets('a near-high reading reads as "Near high", not a number', (
      tester,
    ) async {
      final now = DateTime.utc(2025, 7, 15, 12);
      // A curve whose one turning point sits exactly at "now".
      final samples = [
        TideSample(
          time: now.subtract(const Duration(hours: 2)),
          heightMetres: 1.0,
        ),
        TideSample(
          time: now.subtract(const Duration(hours: 1)),
          heightMetres: 1.6,
        ),
        TideSample(time: now, heightMetres: 1.9),
        TideSample(time: now.add(const Duration(hours: 1)), heightMetres: 1.6),
        TideSample(time: now.add(const Duration(hours: 2)), heightMetres: 1.0),
      ];
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: now,
          locationState: const LocationAvailable(TestLocations.london),
          tideService: FakeTideService(
            result: ({required location, required timeZone, required now}) =>
                TideFetchData(
                  TideSnapshot(
                    location: location,
                    obtainedAt: now,
                    samples: samples,
                    extrema: extractTideExtrema(
                      samples,
                      minSeparation: Duration.zero,
                    ),
                  ),
                ),
          ),
        ),
      );

      expect(find.text('Near high'), findsOneWidget);
    });

    testWidgets(
      'a location the marine model has nothing for reads as unavailable',
      (tester) async {
        await openToday(
          tester,
          overrides: environmentOverrides(
            now: DateTime.utc(2025, 7, 15, 12),
            locationState: const LocationAvailable(TestLocations.london),
            tideService: FakeTideService(
              result: ({required location, required timeZone, required now}) =>
                  const TideFetchNoData(),
            ),
          ),
        );

        expect(find.text('Unavailable here'), findsOneWidget);

        await tester.tap(find.text('Tides'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining("isn't available for this location"),
          findsOneWidget,
        );
      },
    );

    testWidgets('a provider failure reads as not available now, quietly', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
          tideService: FakeTideService(failWith: Exception('no connectivity')),
        ),
      );

      expect(find.text('Not available now'), findsOneWidget);
      // Never a raw error on the primary Almanac page.
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('HTTP'), findsNothing);
    });

    testWidgets(
      'the detail page survives double text size with nothing clipped',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1400) * 2;
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final now = DateTime.utc(2025, 7, 15, 12);
        final container = ProviderContainer(
          overrides: environmentOverrides(
            now: now,
            locationState: const LocationAvailable(TestLocations.london),
            tideService: FakeTideService(
              result: ({required location, required timeZone, required now}) =>
                  TideFetchData(
                    testTideSnapshot(location: location, obtainedAt: now),
                  ),
            ),
          ),
        );
        addTearDown(container.dispose);
        // Resolve the tide once before pumping the detail page directly,
        // so the page's very first frame already has a real reading —
        // this test is about the page's own layout at 2x text, not about
        // waiting out its async loading state.
        await container.read(tideControllerProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.fromPalette(SeasonalPalettes.fallback),
              home: const TideScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Current'), findsOneWidget);
        expect(find.textContaining('Not for navigation'), findsOneWidget);
      },
    );
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
      double leftOf(Finder finder) => tester.getTopLeft(finder.first).dx;

      // The day first, then the painting, then the facts, then today.
      final date = topOf(find.text('Tuesday 15 July'));
      final artwork = topOf(find.byType(EnvironmentArtworkView));
      final sunrise = topOf(find.text('Sunrise'));

      expect(date, lessThan(artwork));
      expect(artwork, lessThan(sunrise));
      expect(sunrise, lessThan(topOf(find.text('TODAY'))));

      // Sunrise reads before sunset, and the moon before the tides —
      // whether the strip is one row or, on a narrow phone, two.
      expect(
        leftOf(find.text('Sunrise')),
        lessThan(leftOf(find.text('Sunset'))),
      );
      expect(leftOf(find.text('Moon')), lessThan(leftOf(find.text('Tides'))));
      expect(
        topOf(find.text('Sunrise')),
        lessThanOrEqualTo(topOf(find.text('Moon'))),
      );
    });

    testWidgets('the hero is the biggest thing on the page', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(),
        surface: phoneSurface,
      );

      final hero = tester.getSize(find.byType(EnvironmentArtworkView));
      final screen = tester.getSize(find.byType(MaterialApp));

      // Dominant, but not the whole screen — the day still reads as a
      // page rather than a wallpaper.
      expect(hero.height, greaterThan(screen.height * 0.2));
      expect(hero.height, lessThan(screen.height * 0.5));
    });

    testWidgets(
      'there is no "Elsewhere in your Almanac" section, whatever is chosen',
      (tester) async {
        // Enough destinations that the bar would have had to scroll —
        // exactly the case the old footnote used to appear for.
        await openToday(
          tester,
          overrides: environmentOverrides(
            features: const {
              FeatureId.meditation,
              FeatureId.yoga,
              FeatureId.chakras,
              FeatureId.cycle,
              FeatureId.cookbook,
              FeatureId.garden,
              FeatureId.natureLog,
            },
          ),
        );

        expect(find.text('Elsewhere in your Almanac'), findsNothing);
      },
    );

    testWidgets('removing the section leaves the bottom navigation untouched', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          features: const {FeatureId.yoga, FeatureId.garden},
        ),
      );

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations.map((feature) => feature.name), [
        'Environment',
        'Yoga',
        'Garden',
      ]);

      await tester.tap(find.bySemanticsLabel('Yoga'));
      await tester.pumpAndSettle();
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
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

  group('the weather sentence on TODAY', () {
    testWidgets('with a forecast available, the weather sentence shows', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
          weatherService: FakeWeatherService(
            result: ({required location, required timeZone, required now}) =>
                testWeatherSnapshot(location: location, obtainedAt: now),
          ),
        ),
      );

      // The exact wording is `weather_narrative_test.dart`'s job; this
      // only proves the sentence reaches the screen and that none of the
      // eight retired fixed light descriptions ever does. Noon UTC is
      // 1pm in London during British Summer Time — the afternoon.
      expect(find.textContaining('afternoon'), findsOneWidget);
      for (final retired in [
        'The sun does not set here today',
        'The sun stays below the horizon today',
        'The light is coming back',
        'Daylight, by the clock',
        'The sun is up',
        'The light is going',
        'Night, by the clock',
        'Dark, and the world is resting',
      ]) {
        expect(find.text(retired), findsNothing);
      }
    });

    testWidgets('with no location shared, there is no weather sentence', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 15, 12)),
      );

      // No location was shared, so no weather request was ever made and
      // nothing weather-shaped appears — the astronomical countdown
      // below it is unaffected either way, see the season group above.
      expect(find.textContaining('morning'), findsNothing);
      expect(find.textContaining('afternoon'), findsNothing);
      expect(find.textContaining('evening'), findsNothing);
      expect(find.textContaining('tonight'), findsNothing);
    });

    testWidgets('the season countdown still shows with no weather available', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 15, 12)),
      );

      expect(find.textContaining('arrives'), findsOneWidget);
    });
  });
}
