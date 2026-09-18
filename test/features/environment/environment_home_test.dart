import 'package:almanac/app/app.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/moon_phase.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/environment/domain/landscape_appearance.dart';
import 'package:almanac/features/environment/presentation/environment_text.dart';
import 'package:almanac/features/environment/presentation/widgets/almanac_landscape_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// The Home composition, from the approved reference.
void main() {
  setUpAll(useTimeZoneDatabase);

  Future<void> openHome(
    WidgetTester tester, {
    DateTime? now,
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(390, 900),
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    if (reducedMotion) {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: environmentOverrides(
          now: now ?? DateTime.utc(2025, 7, 15, 12),
          locationState: const LocationAvailable(TestLocations.london),
        ),
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the masthead and the standing line', () {
    testWidgets('the book names itself', (tester) async {
      await openHome(tester);

      expect(find.text(EnvironmentText.masthead), findsOneWidget);
      expect(find.text(EnvironmentText.mastheadRule), findsOneWidget);
    });

    testWidgets('and the approved tagline is used exactly', (tester) async {
      await openHome(tester);

      // Locked copy. Not paraphrased, not replaced with generic wellness
      // wording, and asserted character for character.
      expect(
        EnvironmentText.tagline,
        'In tune with the natural world and yourself',
      );
      expect(find.text(EnvironmentText.tagline), findsOneWidget);
    });

    testWidgets('the date leads, with the season under it', (tester) async {
      await openHome(tester);

      double topOf(Finder finder) => tester.getTopLeft(finder.first).dy;

      expect(find.text('Tuesday 15 July'), findsOneWidget);
      expect(
        topOf(find.text(EnvironmentText.masthead)),
        lessThan(topOf(find.text('Tuesday 15 July'))),
      );
      expect(
        topOf(find.text('Tuesday 15 July')),
        lessThan(topOf(find.byType(AlmanacLandscapeView))),
      );
    });
  });

  group('ENVIRONMENT IS OUTSIDE', () {
    testWidgets('the landscape is there, and it is decorative', (tester) async {
      await openHome(tester);

      expect(find.byType(AlmanacLandscapeView), findsOneWidget);
      // Everything it hints at is written in words underneath it, so it
      // says nothing to a screen reader.
      expect(
        find.descendant(
          of: find.byType(AlmanacLandscapeView),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNothing,
      );
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(AlmanacLandscapeView),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, isNull);
    });

    testWidgets('and the page is not on the book\'s paper', (tester) async {
      await openHome(tester);

      // The one screen that is allowed to follow the sky. Every other
      // feature is wrapped in the paper surface; this one must not be.
      expect(find.byType(AlmanacPaperSurface), findsNothing);
    });

    testWidgets('the painting is dominant but not the whole page', (
      tester,
    ) async {
      await openHome(tester);

      final painting = tester.getSize(find.byType(AlmanacLandscapeView));
      final screen = tester.getSize(find.byType(MaterialApp));

      expect(painting.height, greaterThan(screen.height * 0.2));
      expect(painting.height, lessThan(screen.height * 0.5));
      // Edge to edge, as in the reference, while the words keep margins.
      expect(painting.width, screen.width);
    });
  });

  group('NATURE MOVES. INTERFACE STAYS STILL.', () {
    testWidgets('nothing is ticking once the page has settled', (tester) async {
      await openHome(tester);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('and reduced motion changes nothing about that', (
      tester,
    ) async {
      await openHome(tester, reducedMotion: true);

      expect(find.byType(AlmanacLandscapeView), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    });

    test('the painter does no work when nothing has changed', () {
      // A static scene should cost nothing to keep on screen.
      LandscapePainter painterFor(DayPhase phase) => LandscapePainter(
        appearance: LandscapeAppearance.resolve(
          season: Season.summer,
          dayNight: DayNightState(phase: phase, daylight: 1),
          palette: SeasonalPalettes.resolve(season: Season.summer, daylight: 1),
        ),
        dayProgress: 0.5,
        moon: const MoonPhaseState(
          phase: MoonPhase.waxingCrescent,
          elongationDegrees: 60,
          illuminatedFraction: 0.34,
        ),
        southern: false,
      );

      expect(
        painterFor(DayPhase.day).shouldRepaint(painterFor(DayPhase.day)),
        isFalse,
      );
      expect(
        painterFor(DayPhase.day).shouldRepaint(painterFor(DayPhase.night)),
        isTrue,
      );
    });
  });

  group('accessibility', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('the page survives text at ${scale}x', (tester) async {
        await openHome(tester, textScale: scale);

        // The page grows and scrolls rather than compressing the words
        // into the painting.
        expect(tester.takeException(), isNull);
        expect(find.text(EnvironmentText.masthead), findsOneWidget);

        // At 2x the header alone is taller than the viewport, so the
        // painting and the facts are below the fold — which is the point:
        // the page grows and scrolls rather than squeezing the words into
        // the picture. Everything is still there to reach.
        await tester.scrollUntilVisible(
          find.text(EnvironmentText.today),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(EnvironmentText.today), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the facts are readable as words, not only as pictures', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openHome(tester);

      // The sun's position in the painting is not the only way to know
      // where the light is, and the moon's shape is not the only way to
      // know its phase.
      expect(find.text(EnvironmentText.sunriseLabel), findsOneWidget);
      expect(find.text(EnvironmentText.moonLabel), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(EnvironmentText.today),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(EnvironmentText.today), findsOneWidget);

      handle.dispose();
    });

    testWidgets('and the Almanac control stays a comfortable target', (
      tester,
    ) async {
      await openHome(tester);

      final control = find.byTooltip('Your Almanac');
      expect(control, findsOneWidget);
      expect(
        tester.getSize(control).height,
        greaterThanOrEqualTo(AppDimens.minTouchTarget),
      );
    });
  });
}
