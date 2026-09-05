import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/environment/presentation/widgets/explore_links.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:almanac/features/environment/presentation/widgets/sky_hero.dart';
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
      tester.element(find.byType(SkyHero)).palette;

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
          expect(find.byType(SkyHero), findsOneWidget);
          expect(find.text('The sun today'), findsOneWidget);
          expect(find.text('The moon'), findsOneWidget);
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
    testWidgets('the hero repaints when the season changes', (tester) async {
      SkyHero heroFor(WidgetTester tester) =>
          tester.widget<SkyHero>(find.byType(SkyHero));

      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 7, 15, 11)),
      );
      final summer = paletteOf(tester).background;
      expect(heroFor(tester).environment.season.season.label, 'Summer');

      await openToday(
        tester,
        overrides: environmentOverrides(now: DateTime.utc(2025, 1, 15, 11)),
      );
      final winter = paletteOf(tester).background;

      expect(winter, isNot(summer));
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

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(SkyHero),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(semantics.excludeSemantics, isTrue);
      expect(semantics.properties.label, isNull);
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
      // The phase is a real, readable string, not only a picture.
      expect(find.textContaining('% lit'), findsOneWidget);
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

    testWidgets('every link is a comfortable tap target', (tester) async {
      await openToday(
        tester,
        overrides: environmentOverrides(
          features: const {
            FeatureId.meditation,
            FeatureId.yoga,
            FeatureId.garden,
            FeatureId.natureLog,
          },
        ),
      );

      for (final section in ['Meditation', 'Yoga', 'Garden', 'Nature Log']) {
        final pill = find.ancestor(
          of: find.descendant(
            of: find.byType(ExploreLinks),
            matching: find.text(section),
          ),
          matching: find.byType(InkWell),
        );
        expect(
          tester.getSize(pill.first).height,
          greaterThanOrEqualTo(48),
          reason: '$section link is too short to tap comfortably',
        );
      }
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

      final animations = tester
          .widgetList<TweenAnimationBuilder<double>>(
            find.byType(TweenAnimationBuilder<double>),
          )
          .toList();

      expect(animations, isNotEmpty);
      for (final animation in animations) {
        expect(animation.duration, Duration.zero);
      }
    });
  });
}
