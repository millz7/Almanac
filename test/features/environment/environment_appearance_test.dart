import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:almanac/features/environment/presentation/widgets/environment_artwork_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/contrast.dart';
import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  const surface = Size(420, 1800);

  /// One date squarely inside each northern season. The southern
  /// hemisphere gets the opposite season from the same date, which is
  /// what the last group here checks.
  final seasonDates = <String, DateTime>{
    'Spring': DateTime.utc(2025, 5, 1),
    'Summer': DateTime.utc(2025, 7, 15),
    'Autumn': DateTime.utc(2025, 10, 15),
    'Winter': DateTime.utc(2025, 1, 15),
  };

  /// Local times that are unambiguously day and unambiguously night,
  /// given the 06:00–20:00 local sun the test overrides supply.
  const dayHour = 11;
  const nightHour = 0;

  Future<void> openToday(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const AlmanacApp()),
    );
    await tester.pumpAndSettle();
  }

  /// The palette the screen is actually wearing, read from a widget
  /// inside the page rather than from a provider, so this asserts what
  /// the user sees.
  SeasonalPalette paletteOf(WidgetTester tester) =>
      tester.element(find.byType(EnvironmentArtworkView)).palette;

  group('every season, day and night', () {
    seasonDates.forEach((season, date) {
      for (final (phase, hour) in [('Day', dayHour), ('Night', nightHour)]) {
        testWidgets('$season $phase renders and wears its own palette', (
          tester,
        ) async {
          await openToday(
            tester,
            overrides: environmentOverrides(
              now: DateTime.utc(date.year, date.month, date.day, hour),
              locationState: const LocationAvailable(TestLocations.london),
            ),
          );

          // No overflow, no assertion, no exception: pumping is the test.
          expect(tester.takeException(), isNull);
          expect(paletteOf(tester).name, '$season $phase');

          // The page is dressed by the season without any screen asking
          // which season it is, so every part of it must be present in
          // all eight.
          // Step 18 replaced the four stacked sections with the
          // reference's strip; what must be present in all eight states
          // is unchanged.
          expect(find.byType(EnvironmentArtworkView), findsOneWidget);
          expect(find.text('Sunrise'), findsOneWidget);
          expect(find.text('Sunset'), findsOneWidget);
          expect(find.text('Moon'), findsOneWidget);
          expect(find.text('Tides'), findsOneWidget);
        });

        testWidgets('$season $phase keeps its text readable', (tester) async {
          await openToday(
            tester,
            overrides: environmentOverrides(
              now: DateTime.utc(date.year, date.month, date.day, hour),
              locationState: const LocationAvailable(TestLocations.london),
            ),
          );

          final palette = paletteOf(tester);
          for (final (label, ground) in [
            ('background', palette.background),
            ('surface', palette.surface),
          ]) {
            final ratio = contrastRatio(palette.textPrimary, ground);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason:
                  '$season $phase: body text on $label is '
                  '${ratio.toStringAsFixed(2)}:1',
            );
          }
        });
      }
    });
  });

  group('nothing is hard-coded', () {
    testWidgets('the artwork changes when the season changes', (tester) async {
      String plateFor(WidgetTester tester) => tester
          .widget<EnvironmentArtworkView>(find.byType(EnvironmentArtworkView))
          .asset;

      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 15, 11)),
      );
      expect(plateFor(tester), contains('summer'));

      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 1, 15, 11)),
      );

      // The season is authoritative, and the painting follows it.
      expect(plateFor(tester), contains('winter'));
    });

    testWidgets('the same date is a different season south of the equator', (
      tester,
    ) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          // Wellington is UTC+12 in July, so this is late morning there
          // on the 15th — the same day as the northern case above.
          now: DateTime.utc(2025, 7, 14, 23),
          timeZone: TestTimeZones.wellington,
          hemisphere: Hemisphere.southern,
        ),
      );

      expect(paletteOf(tester).name, 'Winter Day');
    });
  });

  group('accessibility', () {
    testWidgets('the sky is decorative and says nothing', (tester) async {
      await openToday(tester, overrides: environmentOverrides());

      // The painting is decorative: everything it shows is written in
      // words on the page, so a screen reader loses nothing by skipping
      // it. Excluded at the view, and again on the image itself.
      expect(
        find.descendant(
          of: find.byType(EnvironmentArtworkView),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(
        tester
            .widget<Image>(
              find.descendant(
                of: find.byType(EnvironmentArtworkView),
                matching: find.byType(Image),
              ),
            )
            .excludeFromSemantics,
        isTrue,
      );
    });

    testWidgets('the drawn moon is decorative, and the words carry it', (
      tester,
    ) async {
      await openToday(tester, overrides: environmentOverrides());

      expect(
        find.descendant(
          of: find.byType(MoonDisc),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      // The phase is a real, readable string, not only a picture. Since
      // Step 18 it is worded the same way the Moon page words it.
      expect(find.textContaining('% illuminated'), findsOneWidget);
    });

    testWidgets('sunrise and sunset read as one label each', (tester) async {
      // Disposed inside the test body: the framework checks for leaked
      // semantics handles before tearDowns run.
      final handle = tester.ensureSemantics();

      await openToday(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2025, 7, 15, 12),
          sunrise: DateTime.utc(2025, 7, 15, 5, 12),
          sunset: DateTime.utc(2025, 7, 15, 20, 41),
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      expect(find.bySemanticsLabel('Sunrise 6:12 AM'), findsOneWidget);
      expect(find.bySemanticsLabel('Sunset 9:41 PM'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('doubling the text size does not break the page', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await openToday(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      // An overflow is reported as an exception during layout, so this
      // catches text running out of its card.
      expect(tester.takeException(), isNull);
      expect(find.text('Sunrise'), findsOneWidget);
    });
  });

  group('motion', () {
    testWidgets('settles, rather than animating forever', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      // pumpAndSettle in openToday has already returned, which means no
      // animation is still scheduling frames. Confirm there is no ticker
      // left holding the screen awake.
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('is switched off when the device asks for less of it', (
      tester,
    ) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await openToday(
        tester,
        overrides: environmentOverrides(
          locationState: const LocationAvailable(TestLocations.london),
        ),
      );

      // The artwork changes at once rather than fading, and nothing is
      // left ticking behind the page.
      expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero,
      );
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
