import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/widgets/almanac_doorway.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/theme/app_theme.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/environment/domain/moon_reflection.dart';
import 'package:almanac/features/environment/presentation/moon_screen.dart';
import 'package:almanac/features/environment/presentation/moon_text.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:almanac/features/environment/presentation/widgets/sky_hero.dart';
import 'package:almanac/features/meditation/domain/moon_meditation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A moon pinned to one phase, so a test about the page is not also a
/// test of the date it happens to be.
class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.state);

  final MoonPhaseState state;

  @override
  MoonPhaseState phaseAt(DateTime instant) => state;
}

const _waxingCrescent = MoonPhaseState(
  phase: MoonPhase.waxingCrescent,
  elongationDegrees: 60,
  illuminatedFraction: 0.34,
);

const _fullMoon = MoonPhaseState(
  phase: MoonPhase.fullMoon,
  elongationDegrees: 180,
  illuminatedFraction: 1,
);

void main() {
  setUpAll(useTimeZoneDatabase);

  // Built on demand: `bySemanticsLabel` needs the binding, which is not
  // up yet while `main` is still declaring things.
  Finder moonCardFor(MoonPhaseState moon) =>
      find.bySemanticsLabel(MoonText.spokenFacts(moon));
  Finder moonCard() => moonCardFor(_waxingCrescent);
  Finder doorway() => find.bySemanticsLabel(MoonText.tryAMeditation);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Future<ProviderContainer> openEnvironment(
    WidgetTester tester, {
    MoonPhaseState moon = _waxingCrescent,
    Hemisphere hemisphere = Hemisphere.northern,
    Set<FeatureId> features = const {FeatureId.meditation},
    double textScale = 1,
    bool reducedMotion = false,
    DateTime? now,
    Size surface = const Size(420, 2200),
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

    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(
          now: now,
          hemisphere: hemisphere,
          features: features,
          timeZone: hemisphere == Hemisphere.southern
              ? TestTimeZones.wellington
              : TestTimeZones.london,
        ),
        moonServiceProvider.overrideWithValue(_FixedMoonService(moon)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openMoon(WidgetTester tester) async {
    await tester.ensureVisible(moonCard());
    await tester.pumpAndSettle();
    await tester.tap(moonCard());
    await tester.pumpAndSettle();
  }

  group('the way in', () {
    testWidgets('the moon on the Environment page can be opened', (
      tester,
    ) async {
      await openEnvironment(tester);

      expect(moonCard(), findsOneWidget);
      // Its own composition is unchanged: the same words in the same
      // section, now with a tap on them.
      expect(find.text('The moon'), findsOneWidget);
      expect(find.text('Waxing Crescent'), findsOneWidget);
      expect(find.text('34% lit'), findsOneWidget);
    });

    testWidgets('and tapping it opens the Moon page', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      expect(find.byType(MoonScreen), findsOneWidget);
      expect(find.text(MoonText.title), findsOneWidget);
    });

    testWidgets('the Environment page is otherwise untouched', (tester) async {
      await openEnvironment(tester);

      // The same page, in the same order, as before the moon became a
      // door: date, sky, sun, moon, tides.
      double topOf(Finder finder) => tester.getTopLeft(finder.first).dy;
      expect(
        topOf(find.byType(SkyHero)),
        lessThan(topOf(find.text('The sun today'))),
      );
      expect(
        topOf(find.text('The sun today')),
        lessThan(topOf(find.text('The moon'))),
      );
      expect(topOf(find.text('The moon')), lessThan(topOf(find.text('Tides'))));
      // No new section, and no feature-card grid.
      expect(find.text(MoonText.forThisMoon), findsNothing);
    });
  });

  group('the Moon is not a feature', () {
    test('it has no FeatureId and no registry entry', () {
      for (final id in FeatureId.values) {
        expect(id.name.toLowerCase(), isNot(contains('moon')));
      }
      for (final feature in FeatureRegistry.all) {
        expect(feature.name.toLowerCase(), isNot(contains('moon')));
        expect(feature.route, isNot(contains('moon')));
      }
    });

    testWidgets('and it is not a bottom-navigation destination', (
      tester,
    ) async {
      await openEnvironment(tester, features: FeatureId.values.toSet());
      await openMoon(tester);

      // Every tab the user chose is still there, and no ghost Moon tab
      // has appeared beside them.
      expect(navTab('Environment'), findsOneWidget);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
      expect(navTab(MoonText.title), findsNothing);

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations, hasLength(FeatureRegistry.all.length));
      for (final destination in bar.destinations) {
        expect(destination.name, isNot(MoonText.title));
      }
    });

    testWidgets('the navigation bar keeps the Environment selected', (
      tester,
    ) async {
      await openEnvironment(tester);
      await openMoon(tester);

      final bar = tester.widget<AlmanacNavigationBar>(
        find.byType(AlmanacNavigationBar),
      );
      expect(bar.destinations[bar.selectedIndex].id, FeatureId.environment);
    });
  });

  group('the factual layer', () {
    testWidgets('is the astronomy the app already calculated', (tester) async {
      final container = await openEnvironment(tester);
      await openMoon(tester);

      final moon = container.read(currentMoonProvider);
      expect(find.text(moon.phase.label), findsOneWidget);
      expect(
        find.text(MoonText.illumination(moon.illuminatedPercent)),
        findsOneWidget,
      );
      expect(find.text('34% illuminated'), findsOneWidget);
      expect(find.text(MoonText.direction(moon.phase)), findsOneWidget);
      expect(find.text('Waxing'), findsOneWidget);
    });

    testWidgets('and it is the same moon the Environment showed', (
      tester,
    ) async {
      final container = await openEnvironment(tester, moon: _fullMoon);

      expect(find.text('Full Moon'), findsWidgets);
      await tester.tap(moonCardFor(_fullMoon));
      await tester.pumpAndSettle();

      expect(find.text('100% illuminated'), findsOneWidget);
      expect(find.text('Waning'), findsOneWidget);
      expect(
        container.read(currentMoonProvider).phase,
        container.read(naturalEnvironmentProvider).value!.moon.phase,
      );
    });

    testWidgets('the lit side still turns over in the south', (tester) async {
      Future<bool> mirroredFor(Hemisphere hemisphere) async {
        await openEnvironment(tester, hemisphere: hemisphere);
        await openMoon(tester);
        // The large moon on the detail page, not the small one behind it.
        final discs = tester.widgetList<MoonDisc>(find.byType(MoonDisc));
        return discs.last.mirrored;
      }

      expect(await mirroredFor(Hemisphere.northern), isFalse);
      expect(await mirroredFor(Hemisphere.southern), isTrue);
    });

    testWidgets('and no timing is invented', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      // The existing astronomy resolves a phase at an instant; it does
      // not search for the instant a phase begins. Rather than guess,
      // the page says nothing.
      for (final invented in ['Next full moon', 'in 3 days', 'days until']) {
        expect(find.textContaining(invented), findsNothing, reason: invented);
      }
    });
  });

  group('the reflective layer', () {
    testWidgets('offers the theme, the words and the practices', (
      tester,
    ) async {
      await openEnvironment(tester);
      await openMoon(tester);

      final reflection = MoonReflections.forPhase(MoonPhase.waxingCrescent);
      expect(find.text(MoonText.forThisMoon), findsOneWidget);
      expect(find.text(reflection.theme), findsOneWidget);
      expect(find.text(reflection.wordLine), findsOneWidget);
      expect(find.text(reflection.explanation), findsOneWidget);
      expect(find.text(MoonText.practices), findsOneWidget);
      for (final practice in reflection.practices) {
        expect(
          find.text(practice.label),
          findsOneWidget,
          reason: practice.name,
        );
      }
    });

    testWidgets('and frames itself once, without disclaiming', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      // One line under the heading, naming the way of reading. Not a
      // sentence at the bottom explaining what the page is not.
      expect(find.text(MoonText.reflectiveFraming), findsOneWidget);
      expect(find.textContaining('not a physical effect'), findsNothing);
      expect(find.textContaining('spiritual traditions'), findsOneWidget);
    });

    testWidgets('and the factual half stays above the reflective one', (
      tester,
    ) async {
      await openEnvironment(tester);
      await openMoon(tester);

      double topOf(Finder finder) => tester.getTopLeft(finder.first).dy;

      // Told apart by tone and by order: what the moon is doing, a
      // rule, then what somebody might do with it.
      expect(
        topOf(find.text('34% illuminated')),
        lessThan(topOf(find.text(MoonText.forThisMoon))),
      );
      expect(
        topOf(find.text(MoonText.forThisMoon)),
        lessThan(topOf(find.text(MoonText.reflectiveFraming))),
      );
      expect(
        topOf(find.text(MoonText.reflectiveFraming)),
        lessThan(
          topOf(
            find.text(MoonReflections.forPhase(MoonPhase.waxingCrescent).theme),
          ),
        ),
      );
    });

    testWidgets('a different phase is a different page', (tester) async {
      await openEnvironment(tester, moon: _fullMoon);
      await tester.tap(moonCardFor(_fullMoon));
      await tester.pumpAndSettle();

      expect(
        find.text(MoonReflections.forPhase(MoonPhase.fullMoon).theme),
        findsOneWidget,
      );
      expect(
        find.text(MoonReflections.forPhase(MoonPhase.newMoon).theme),
        findsNothing,
      );
    });
  });

  group('the page is paper, not scenery', () {
    testWidgets('it is written on the paper ground', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      expect(find.byType(AlmanacPaperSurface), findsOneWidget);
      expect(find.byType(AlmanacSectionDivider), findsWidgets);
    });

    testWidgets('and it is the same paper after dark', (tester) async {
      Future<Color> groundAt(DateTime instant) async {
        await openEnvironment(tester, now: instant);
        await openMoon(tester);
        final surface = tester.widget<AlmanacPaperSurface>(
          find.byType(AlmanacPaperSurface),
        );
        expect(surface, isNotNull);
        return tester
            .widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byType(AlmanacPaperSurface),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            )
            .color;
      }

      // 02:00 in London in July is night; midday is not. The
      // Environment outside changes completely between them; the page
      // inside the Almanac does not.
      final night = await groundAt(DateTime.utc(2025, 7, 15, 1));
      final day = await groundAt(DateTime.utc(2025, 7, 15, 12));

      expect(night, AlmanacPaper.ground);
      expect(day, AlmanacPaper.ground);
      expect(night, day);
    });

    testWidgets('and the same paper in every season', (tester) async {
      // One sheet through the year: no seasonal page backgrounds.
      for (final instant in [
        DateTime.utc(2025, 1, 15, 12),
        DateTime.utc(2025, 4, 15, 12),
        DateTime.utc(2025, 7, 15, 12),
        DateTime.utc(2025, 10, 15, 12),
      ]) {
        await openEnvironment(tester, now: instant);
        await openMoon(tester);

        expect(
          tester
              .widget<ColoredBox>(
                find
                    .descendant(
                      of: find.byType(AlmanacPaperSurface),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color,
          AlmanacPaper.ground,
          reason: '$instant',
        );
      }
    });

    testWidgets('and its text is printed in paper ink, not palette ink', (
      tester,
    ) async {
      await openEnvironment(tester, now: DateTime.utc(2025, 7, 15, 1));
      await openMoon(tester);

      // The night palette's own text colour would be a light one, and
      // invisible here. Inside the paper surface the theme is
      // re-printed, so a page's widgets get paper ink without asking.
      final context = tester.element(find.text(MoonText.title));
      final palette = Theme.of(context).extension<SeasonalPalette>()!;
      expect(palette.background, AlmanacPaper.ground);
      expect(palette.textPrimary, AlmanacPaper.ink);
      expect(Theme.of(context).textTheme.bodyLarge?.color, AlmanacPaper.ink);
    });

    testWidgets('with no landscape, and no scene behind the moon', (
      tester,
    ) async {
      await openEnvironment(tester);
      await openMoon(tester);

      // Environment is the app's one living painting. This page does not
      // duplicate it — which is the rule that stops every future screen
      // needing four seasonal paintings and two day/night versions.
      expect(find.byType(SkyHero), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('and one illustration: no wreath, no flowers, no forest', (
      tester,
    ) async {
      await openEnvironment(tester);
      await openMoon(tester);

      // Exactly one drawing on the page, and it is the moon.
      expect(find.byType(MoonDisc), findsOneWidget);
      expect(find.byType(CustomPaint).evaluate(), isNotEmpty);
      // Nothing botanical has been drawn around it.
      expect(find.byType(SkyHero), findsNothing);
    });

    testWidgets('and the moon is the biggest thing on it', (tester) async {
      await openEnvironment(tester, surface: const Size(400, 1200));
      await openMoon(tester);

      final moonSize = tester.getSize(find.byType(MoonDisc));
      final titleSize = tester.getSize(find.text(MoonText.title));
      expect(moonSize.height, greaterThan(titleSize.height * 3));
    });
  });

  group('getting back', () {
    testWidgets('Back returns to the Environment', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      await tester.tap(find.byTooltip(MoonText.back));
      await tester.pumpAndSettle();

      expect(find.byType(MoonScreen), findsNothing);
      expect(find.text('The moon'), findsOneWidget);
      expect(moonCard(), findsOneWidget);
    });

    testWidgets('and so does the system back gesture', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(MoonScreen), findsNothing);
      expect(find.text('The moon'), findsOneWidget);
    });

    testWidgets('opening and leaving twice leaves no stack behind', (
      tester,
    ) async {
      await openEnvironment(tester);

      for (var i = 0; i < 3; i++) {
        await openMoon(tester);
        expect(find.byType(MoonScreen), findsOneWidget, reason: 'open $i');
        await tester.tap(find.byTooltip(MoonText.back));
        await tester.pumpAndSettle();
        expect(find.byType(MoonScreen), findsNothing, reason: 'closed $i');
      }
      // One Environment, not four stacked on each other.
      expect(find.text('The moon'), findsOneWidget);
    });

    testWidgets('the Almanac stays reachable from the Moon', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      expect(find.byType(AlmanacButton), findsOneWidget);
      await tester.tap(find.byType(AlmanacButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Almanac'), findsWidgets);
    });
  });

  group('the optional doorway', () {
    testWidgets('is there when Meditation is part of the Almanac', (
      tester,
    ) async {
      await openEnvironment(tester, features: {FeatureId.meditation});
      await openMoon(tester);

      expect(doorway(), findsOneWidget);
    });

    testWidgets('is absent when it is not — and the guidance stays', (
      tester,
    ) async {
      await openEnvironment(tester, features: {FeatureId.garden});
      await openMoon(tester);

      final reflection = MoonReflections.forPhase(MoonPhase.waxingCrescent);

      // Gone.
      expect(doorway(), findsNothing);
      // And every word of the guidance is still here. This is the
      // product rule: feature choices control the doorway, never the
      // guidance.
      expect(find.text(MoonText.forThisMoon), findsOneWidget);
      expect(find.text(MoonText.reflectiveFraming), findsOneWidget);
      expect(find.text(reflection.theme), findsOneWidget);
      expect(find.text(reflection.explanation), findsOneWidget);
      expect(find.text(MoonText.practices), findsOneWidget);
      for (final practice in reflection.practices) {
        expect(
          find.text(practice.label),
          findsOneWidget,
          reason: practice.name,
        );
      }
      // Including the words that name the feature they do not have.
      expect(find.text(MoonPractice.breathe.label), findsOneWidget);
      expect(find.text(MoonText.title), findsOneWidget);
    });

    testWidgets('no placeholder, no disabled button, nothing at all', (
      tester,
    ) async {
      await openEnvironment(tester, features: const {});
      await openMoon(tester);

      // Nothing is rendered: no label, no arrow, no space taken. The
      // widget is in the tree and draws nothing, which is what "absent"
      // has to mean for a doorway that must reappear on its own.
      expect(doorway(), findsNothing);
      expect(find.text(MoonText.tryAMeditation), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AlmanacDoorway),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byType(AlmanacDoorway)), Size.zero);
      // And no consolation prize in its place.
      expect(find.textContaining('Coming soon'), findsNothing);
      expect(find.textContaining('not available'), findsNothing);
      expect(find.textContaining('Enable'), findsNothing);
    });

    testWidgets('and it comes back when Meditation is re-enabled', (
      tester,
    ) async {
      final container = await openEnvironment(tester, features: const {});
      await openMoon(tester);
      expect(doorway(), findsNothing);

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.meditation, true);
      await tester.pumpAndSettle();

      // Still on the Moon, and the door has appeared.
      expect(find.byType(MoonScreen), findsOneWidget);
      expect(doorway(), findsOneWidget);

      await container
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(FeatureId.meditation, false);
      await tester.pumpAndSettle();

      expect(doorway(), findsNothing);
      expect(find.text(MoonText.forThisMoon), findsOneWidget);
    });

    testWidgets('it opens the real Meditation, carrying the moon', (
      tester,
    ) async {
      final container = await openEnvironment(tester);
      await openMoon(tester);

      await tester.tap(doorway());
      await tester.pumpAndSettle();

      // The normal Meditation feature, with the moon it arrived with.
      expect(find.text('Meditation'), findsWidgets);
      expect(
        find.text(const MoonMeditationIntent(MoonPhase.waxingCrescent).heading),
        findsOneWidget,
      );
      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );
      // Taken on arrival, so nothing is left waiting.
      expect(container.read(almanacIntentProvider), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the drawn moon says nothing', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      expect(
        find.descendant(
          of: find.byType(MoonDisc),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the facts are one spoken sentence', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      expect(
        find.bySemanticsLabel(
          'Waxing Crescent. 34 percent illuminated. Waxing.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the practices are real text, not icons', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      for (final practice in MoonReflections.forPhase(
        MoonPhase.waxingCrescent,
      ).practices) {
        expect(
          find.widgetWithText(Wrap, practice.label),
          findsOneWidget,
          reason: practice.name,
        );
      }
    });

    testWidgets('the doorway and the way back are comfortable targets', (
      tester,
    ) async {
      await openEnvironment(tester);
      await openMoon(tester);

      expect(tester.getSize(doorway()).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSize(find.byTooltip(MoonText.back)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('and the moon card on the Environment is one too', (
      tester,
    ) async {
      await openEnvironment(tester);

      expect(tester.getSize(moonCard()).height, greaterThanOrEqualTo(48));
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openEnvironment(
        tester,
        textScale: 2,
        surface: const Size(420, 4200),
      );
      await openMoon(tester);

      final reflection = MoonReflections.forPhase(MoonPhase.waxingCrescent);
      // Nothing essential is shortened or replaced by an ellipsis.
      expect(find.text(MoonText.title), findsOneWidget);
      expect(find.text('Waxing Crescent'), findsOneWidget);
      expect(find.text('34% illuminated'), findsOneWidget);
      expect(find.text(reflection.theme), findsOneWidget);
      expect(find.text(reflection.wordLine), findsOneWidget);
      expect(doorway(), findsOneWidget);
      expect(find.textContaining('…'), findsNothing);
    });
  });

  group('motion', () {
    testWidgets('nothing is ticking once the page has settled', (tester) async {
      await openEnvironment(tester);
      await openMoon(tester);

      // Nature moves; the interface stays still. The transition is a
      // one-shot, and the page introduces no ticker of its own.
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('and reduced motion arrives rather than travelling', (
      tester,
    ) async {
      await openEnvironment(tester, reducedMotion: true);
      await openMoon(tester);

      expect(find.byType(MoonScreen), findsOneWidget);
      expect(find.text(MoonText.title), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);

      // And everything still works.
      await tester.tap(find.byTooltip(MoonText.back));
      await tester.pumpAndSettle();
      expect(find.byType(MoonScreen), findsNothing);
    });
  });
}
