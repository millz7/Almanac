import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/features/environment/presentation/moon_text.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/meditation/domain/moon_meditation.dart';
import 'package:almanac/features/meditation/presentation/meditation_text.dart';
import 'package:almanac/features/meditation/presentation/widgets/glowing_orb.dart';
import 'package:almanac/features/meditation/presentation/widgets/moon_context_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A moon pinned to one phase, so a test about Meditation's response is
/// not also a test of the date it happens to be.
class _FixedMoonService implements MoonService {
  const _FixedMoonService(this.state);

  final MoonPhaseState state;

  @override
  MoonPhaseState phaseAt(DateTime instant) => state;
}

const _newMoon = MoonPhaseState(
  phase: MoonPhase.newMoon,
  elongationDegrees: 3,
  illuminatedFraction: 0.002,
);

const _fullMoon = MoonPhaseState(
  phase: MoonPhase.fullMoon,
  elongationDegrees: 180,
  illuminatedFraction: 1,
);

void main() {
  setUpAll(useTimeZoneDatabase);

  Finder moonCardFor(MoonPhaseState moon) =>
      find.bySemanticsLabel(MoonText.spokenFacts(moon));
  Finder doorway() => find.bySemanticsLabel(MoonText.tryAMeditation);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Future<ProviderContainer> openApp(
    WidgetTester tester, {
    MoonPhaseState moon = _newMoon,
    Set<FeatureId> features = const {FeatureId.meditation},
    Size surface = const Size(420, 2400),
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(features: features),
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

  /// Environment → Moon → the doorway → Meditation.
  Future<void> walkFromMoon(
    WidgetTester tester, {
    MoonPhaseState moon = _newMoon,
  }) async {
    await tester.ensureVisible(moonCardFor(moon));
    await tester.pumpAndSettle();
    await tester.tap(moonCardFor(moon));
    await tester.pumpAndSettle();
    await tester.tap(doorway());
    await tester.pumpAndSettle();
  }

  Future<void> openMeditationDirectly(WidgetTester tester) async {
    await tester.tap(navTab('Meditation'));
    await tester.pumpAndSettle();
  }

  group('arriving from the Moon', () {
    testWidgets('Meditation says which moon it is answering', (tester) async {
      await openApp(tester);
      await walkFromMoon(tester);

      expect(
        find.text(const MoonMeditationIntent(MoonPhase.newMoon).heading),
        findsOneWidget,
      );
      expect(find.text("For today's New Moon"), findsOneWidget);
      // Not the quieter direct-entry heading.
      expect(find.text(MeditationText.forToday), findsNothing);
    });

    testWidgets('and offers a practice that suits it', (tester) async {
      await openApp(tester);
      await walkFromMoon(tester);

      final suggestion = MoonMeditations.forPhase(MoonPhase.newMoon);
      final technique = MoonMeditations.techniqueFor(MoonPhase.newMoon);
      expect(find.text(suggestion.invitation), findsOneWidget);
      expect(find.text('Begin ${technique.name}'), findsWidgets);
    });

    testWidgets('a full moon gets its own answer', (tester) async {
      await openApp(tester, moon: _fullMoon);
      await walkFromMoon(tester, moon: _fullMoon);

      expect(find.text("For today's Full Moon"), findsOneWidget);
      expect(
        find.text(MoonMeditations.forPhase(MoonPhase.fullMoon).invitation),
        findsOneWidget,
      );
      expect(
        find.text(MoonMeditations.forPhase(MoonPhase.newMoon).invitation),
        findsNothing,
      );
    });

    testWidgets('it is the normal Meditation, with all four practices', (
      tester,
    ) async {
      await openApp(tester);
      await walkFromMoon(tester);

      // No duplicate screen, and nothing removed to make room.
      expect(find.text('Choose a practice'), findsOneWidget);
      for (final technique in MeditationTechniques.all) {
        expect(
          find.text(technique.description),
          findsOneWidget,
          reason: technique.name,
        );
      }
    });

    testWidgets('the suggested practice can be begun from the card', (
      tester,
    ) async {
      await openApp(tester);
      await walkFromMoon(tester);

      final technique = MoonMeditations.techniqueFor(MoonPhase.newMoon);
      await tester.tap(find.bySemanticsLabel('Begin ${technique.name}'));
      await tester.pumpAndSettle();

      // Exactly where choosing it from the list below would have landed:
      // the practice's own setup, orb and all.
      expect(find.text('Tap to begin'), findsOneWidget);
      expect(find.byType(GlowingOrb), findsOneWidget);
      expect(find.text(technique.name), findsWidgets);
    });

    testWidgets('and the existing practices still work as they did', (
      tester,
    ) async {
      await openApp(tester);
      await walkFromMoon(tester);

      await tester.tap(find.text(MeditationTechniques.sleep.description));
      await tester.pumpAndSettle();

      expect(find.text('Tap to begin'), findsOneWidget);
      expect(find.byType(GlowingOrb), findsOneWidget);
    });

    testWidgets('and the context steps aside once a practice is chosen', (
      tester,
    ) async {
      await openApp(tester);
      await walkFromMoon(tester);

      await tester.tap(find.text(MeditationTechniques.focus.description));
      await tester.pumpAndSettle();

      // The suggestion belongs to the choosing, not to the practice.
      // From here on the page is the orb and nothing else, exactly as
      // it was before the Moon had a doorway.
      expect(find.byType(MoonContextCard), findsNothing);
      expect(find.text("For today's New Moon"), findsNothing);
      expect(find.byType(GlowingOrb), findsOneWidget);
    });
  });

  group('the intent does not linger', () {
    testWidgets('it is taken on arrival and nothing is left waiting', (
      tester,
    ) async {
      final container = await openApp(tester);
      await walkFromMoon(tester);

      expect(container.read(almanacIntentProvider), isNull);
    });

    testWidgets('leaving and coming back does not bring the moon along', (
      tester,
    ) async {
      final container = await openApp(tester);
      await walkFromMoon(tester);
      expect(find.text("For today's New Moon"), findsOneWidget);

      await tester.tap(navTab('Environment'));
      await tester.pumpAndSettle();
      await openMeditationDirectly(tester);

      // Same screen, and it has forgotten how the user got here first
      // time. The context is still true, so it is still offered — under
      // the quieter heading.
      expect(find.text("For today's New Moon"), findsNothing);
      expect(find.text(MeditationText.forToday), findsOneWidget);
      expect(container.read(almanacIntentProvider), isNull);
    });

    testWidgets('a direct entry never sees a stale intent', (tester) async {
      final container = await openApp(tester);
      await openMeditationDirectly(tester);

      expect(container.read(almanacIntentProvider), isNull);
      expect(find.textContaining("For today's"), findsNothing);
    });

    testWidgets('and an intent meant for elsewhere is left alone', (
      tester,
    ) async {
      final container = await openApp(
        tester,
        features: {FeatureId.meditation, FeatureId.cookbook},
      );

      // Nothing in the app sets a Cookbook intent yet, so this stands in
      // for one: opening Meditation must not consume it.
      container
          .read(almanacIntentProvider.notifier)
          .open(const MoonMeditationIntent(MoonPhase.fullMoon));
      await openMeditationDirectly(tester);

      // Meditation's own intent, so Meditation does take this one.
      expect(container.read(almanacIntentProvider), isNull);
      expect(find.text("For today's Full Moon"), findsOneWidget);
    });
  });

  group('opening Meditation normally', () {
    testWidgets('mentions today rather than announcing it', (tester) async {
      await openApp(tester);
      await openMeditationDirectly(tester);

      expect(find.text(MeditationText.forToday), findsOneWidget);
      expect(
        find.text(MoonMeditations.forPhase(MoonPhase.newMoon).invitation),
        findsOneWidget,
      );
    });

    testWidgets('and the practices are still the page', (tester) async {
      await openApp(tester);
      await openMeditationDirectly(tester);

      double topOf(Finder finder) => tester.getTopLeft(finder.first).dy;

      // The context is a quiet block above the choices, not instead of
      // them.
      expect(
        topOf(find.text(MeditationText.forToday)),
        lessThan(topOf(find.text('Choose a practice'))),
      );
      expect(find.byType(MoonContextCard), findsOneWidget);
      for (final technique in MeditationTechniques.all) {
        expect(
          find.text(technique.description),
          findsOneWidget,
          reason: technique.name,
        );
      }
    });

    testWidgets('it reads the same moon the Environment does', (tester) async {
      final container = await openApp(tester, moon: _fullMoon);
      await openMeditationDirectly(tester);

      expect(
        find.text(
          MoonMeditations.forPhase(container.read(currentMoonProvider).phase)
              .invitation,
        ),
        findsOneWidget,
      );
      expect(
        find.text(MoonMeditations.forPhase(MoonPhase.fullMoon).invitation),
        findsOneWidget,
      );
    });
  });

  group('accessibility', () {
    testWidgets('the suggestion is real text and a real button', (
      tester,
    ) async {
      await openApp(tester);
      await walkFromMoon(tester);

      final technique = MoonMeditations.techniqueFor(MoonPhase.newMoon);
      expect(find.bySemanticsLabel('Begin ${technique.name}'), findsOneWidget);
      expect(
        tester.getSize(find.bySemanticsLabel('Begin ${technique.name}')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('and nothing is ticking on the way in', (tester) async {
      await openApp(tester);
      await walkFromMoon(tester);

      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
