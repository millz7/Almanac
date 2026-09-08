import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/moon_service.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cookbook/domain/cycle_recipes.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/meditation/domain/cycle_meditation.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/meditation/domain/moon_meditation.dart';
import 'package:almanac/features/meditation/presentation/meditation_text.dart';
import 'package:almanac/features/yoga/domain/cycle_yoga.dart';
import 'package:almanac/features/yoga/domain/yoga_practices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

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

final testNow = DateTime.utc(2026, 9, 20, 12);
const sep4 = CalendarDate(2026, 9, 4);

/// Day 1 on 4 September, so 20 September is cycle day 17 — luteal on a
/// 28-day estimate.
CycleData withDay1({CyclePhase? manualPhase}) => CycleData(
  records: [
    CycleDayRecord(
      date: sep4,
      level: BleedingLevel.bleeding,
      isPeriodStart: true,
    ),
  ],
  manualPhase: manualPhase,
);

const everything = {
  FeatureId.cycle,
  FeatureId.cookbook,
  FeatureId.yoga,
  FeatureId.meditation,
};

void main() {
  setUpAll(useTimeZoneDatabase);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );
  Finder route(String title) => find.bySemanticsLabel(RegExp('^$title\\.'));

  Future<ProviderContainer> openCycle(
    WidgetTester tester, {
    CycleData? data,
    Set<FeatureId> features = everything,
    Size surface = const Size(430, 4000),
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...environmentOverrides(
          now: testNow,
          features: features,
          cycleStore: InMemoryCycleStore(data ?? withDay1()),
        ),
        moonServiceProvider.overrideWithValue(
          const _FixedMoonService(_waxingCrescent),
        ),
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
    await tester.tap(navTab(CycleText.title));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Cycle → Cycle Syncing → one of its doorways.
  Future<void> walkThrough(WidgetTester tester, String doorway) async {
    await press(tester, route(CycleText.syncing));
    await press(tester, find.bySemanticsLabel(doorway));
  }

  group('Cycle Syncing to the Cookbook', () {
    testWidgets('the phase arrives, and the collection is for it', (
      tester,
    ) async {
      final container = await openCycle(tester);

      await walkThrough(tester, CycleText.seeRecipes);

      expect(find.text(CookbookText.title), findsWidgets);
      expect(
        find.text(CookbookText.forYourPhase(CyclePhase.luteal)),
        findsOneWidget,
      );
      expect(
        find.text(CycleRecipes.collectionNote(CyclePhase.luteal)),
        findsOneWidget,
      );
      // And the intent was taken on arrival.
      expect(container.read(almanacIntentProvider), isNull);
    });

    testWidgets('the recipes shown are the ones mapped to that phase', (
      tester,
    ) async {
      await openCycle(tester);
      await walkThrough(tester, CycleText.seeRecipes);

      for (final recipe in CycleRecipes.forPhase(CyclePhase.luteal)) {
        expect(find.text(recipe.name), findsWidgets, reason: recipe.id);
      }
    });

    testWidgets('and the seasonal collection is still the page', (
      tester,
    ) async {
      await openCycle(tester);
      await walkThrough(tester, CycleText.seeRecipes);

      double topOf(Finder finder) => tester.getTopLeft(finder.first).dy;

      // Seasonal first, cycle underneath: not a replacement.
      expect(find.text(CookbookText.introduction), findsOneWidget);
      expect(
        topOf(find.text(CookbookText.introduction)),
        lessThan(
          topOf(find.text(CookbookText.forYourPhase(CyclePhase.luteal))),
        ),
      );
    });

    testWidgets('a later direct entry has current context, not a stale one', (
      tester,
    ) async {
      final container = await openCycle(tester);
      await walkThrough(tester, CycleText.seeRecipes);
      expect(
        find.text(CookbookText.forYourPhase(CyclePhase.luteal)),
        findsOneWidget,
      );

      await press(tester, navTab('Environment'));
      await press(tester, navTab('Cookbook'));

      // The context is still true, so it is still offered — under the
      // quieter heading, because they did not arrive through the door.
      expect(find.text(CookbookText.forYourCycle), findsOneWidget);
      expect(
        find.text(CookbookText.forYourPhase(CyclePhase.luteal)),
        findsNothing,
      );
      expect(container.read(almanacIntentProvider), isNull);
    });

    testWidgets('and no cycle collection at all without Cycle', (tester) async {
      final container = ProviderContainer(
        overrides: environmentOverrides(
          now: testNow,
          features: const {FeatureId.cookbook},
        ),
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(430, 3000) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();
      await press(tester, navTab('Cookbook'));

      expect(find.text(CookbookText.forYourCycle), findsNothing);
      // The seasonal cookbook is untouched.
      expect(find.text(CookbookText.introduction), findsOneWidget);
    });

    testWidgets('and none with Cycle on but nothing recorded', (tester) async {
      await openCycle(tester, data: CycleData.empty);
      await press(tester, navTab('Cookbook'));

      expect(find.text(CookbookText.forYourCycle), findsNothing);
    });

    testWidgets('unless the user chose a phase in Cycle Syncing', (
      tester,
    ) async {
      await openCycle(
        tester,
        data: CycleData(manualPhase: CyclePhase.menstrual),
      );
      await press(tester, navTab('Cookbook'));

      expect(find.text(CookbookText.forYourCycle), findsOneWidget);
      expect(
        find.text(CycleRecipes.collectionNote(CyclePhase.menstrual)),
        findsOneWidget,
      );
    });
  });

  group('Cycle Syncing to Yoga', () {
    testWidgets('the phase arrives, and a fitting practice is offered', (
      tester,
    ) async {
      final container = await openCycle(tester);

      await walkThrough(tester, CycleText.tryYoga);

      final suggestion = CycleYoga.forPhase(CyclePhase.luteal);
      expect(
        find.text(CycleYogaIntent(CyclePhase.luteal).heading),
        findsOneWidget,
      );
      expect(find.text(suggestion.invitation), findsOneWidget);
      expect(
        find.text(YogaPractices.byId(suggestion.practice).name),
        findsWidgets,
      );
      expect(container.read(almanacIntentProvider), isNull);
    });

    testWidgets('all three practices are still offered', (tester) async {
      await openCycle(tester);
      await walkThrough(tester, CycleText.tryYoga);

      expect(YogaPractices.all, hasLength(3));
      for (final practice in YogaPractices.all) {
        // The chooser appends the practice's length to its line, so the
        // description is contained rather than equal.
        expect(
          find.textContaining(practice.description),
          findsOneWidget,
          reason: practice.name,
        );
      }
    });

    testWidgets('and no stale intent survives leaving', (tester) async {
      final container = await openCycle(tester);
      await walkThrough(tester, CycleText.tryYoga);

      await press(tester, navTab('Environment'));
      await press(tester, navTab('Yoga'));

      expect(container.read(almanacIntentProvider), isNull);
      expect(
        find.text(CycleYogaIntent(CyclePhase.luteal).heading),
        findsNothing,
      );
      // The context is still true, under the quieter heading.
      expect(find.text('For today'), findsOneWidget);
    });
  });

  group('Cycle Syncing to Meditation', () {
    testWidgets('the phase arrives, and a fitting practice is offered', (
      tester,
    ) async {
      final container = await openCycle(tester);

      await walkThrough(tester, CycleText.tryMeditation);

      final suggestion = CycleMeditations.forPhase(CyclePhase.luteal);
      expect(
        find.text(CycleMeditationIntent(CyclePhase.luteal).heading),
        findsOneWidget,
      );
      expect(find.text(suggestion.invitation), findsOneWidget);
      expect(container.read(almanacIntentProvider), isNull);
    });

    testWidgets('all four breathing practices are still offered', (
      tester,
    ) async {
      await openCycle(tester);
      await walkThrough(tester, CycleText.tryMeditation);

      expect(MeditationTechniques.all, hasLength(4));
      for (final technique in MeditationTechniques.all) {
        expect(
          find.text(technique.description),
          findsOneWidget,
          reason: technique.name,
        );
      }
    });

    testWidgets('and the moon suggestion remains independent', (tester) async {
      await openCycle(tester);
      await walkThrough(tester, CycleText.tryMeditation);

      // Two observations about the same day, shown as two suggestions.
      expect(
        find.text(CycleMeditations.forPhase(CyclePhase.luteal).invitation),
        findsOneWidget,
      );
      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );
      // And never combined into one claim.
      expect(find.textContaining('menstrual new moon'), findsNothing);
      expect(find.textContaining('Luteal Waxing'), findsNothing);
    });

    testWidgets('a direct entry shows both under one quiet heading', (
      tester,
    ) async {
      await openCycle(tester);
      await press(tester, navTab('Meditation'));

      // Said once, not twice.
      expect(find.text(MeditationText.forToday), findsOneWidget);
      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );
      expect(
        find.text(CycleMeditations.forPhase(CyclePhase.luteal).invitation),
        findsOneWidget,
      );
      // And the four practices are not pushed off the page.
      for (final technique in MeditationTechniques.all) {
        expect(find.text(technique.description), findsOneWidget);
      }
    });

    testWidgets('with Cycle off, only the moon suggestion appears', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          ...environmentOverrides(
            now: testNow,
            features: const {FeatureId.meditation},
          ),
          moonServiceProvider.overrideWithValue(
            const _FixedMoonService(_waxingCrescent),
          ),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(430, 3000) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AlmanacApp(),
        ),
      );
      await tester.pumpAndSettle();
      await press(tester, navTab('Meditation'));

      expect(
        find.text(
          MoonMeditations.forPhase(MoonPhase.waxingCrescent).invitation,
        ),
        findsOneWidget,
      );
      for (final phase in CyclePhase.values) {
        expect(
          find.text(CycleMeditations.forPhase(phase).invitation),
          findsNothing,
          reason: phase.name,
        );
      }
    });

    testWidgets('and no stale intent survives leaving', (tester) async {
      final container = await openCycle(tester);
      await walkThrough(tester, CycleText.tryMeditation);

      await press(tester, navTab('Environment'));
      await press(tester, navTab('Meditation'));

      expect(container.read(almanacIntentProvider), isNull);
      expect(
        find.text(CycleMeditationIntent(CyclePhase.luteal).heading),
        findsNothing,
      );
      expect(find.text(MeditationText.forToday), findsOneWidget);
    });
  });

  group('the intents themselves', () {
    test('are typed values, and carry no strings', () {
      for (final phase in CyclePhase.values) {
        expect(CycleCookbookIntent(phase).destination, FeatureId.cookbook);
        expect(CycleYogaIntent(phase).destination, FeatureId.yoga);
        expect(CycleMeditationIntent(phase).destination, FeatureId.meditation);

        expect(CycleCookbookIntent(phase).heading, 'For your ${phase.phrase}');
        expect(CycleCookbookIntent(phase), CycleCookbookIntent(phase));
      }
    });

    test('and three destinations for one phase are three intents', () {
      const phase = CyclePhase.luteal;
      // Same payload, different journeys — so one cannot be taken by
      // the wrong destination.
      expect(
        CycleCookbookIntent(phase),
        isNot(CycleYogaIntent(phase) as Object),
      );
      expect(
        CycleYogaIntent(phase),
        isNot(CycleMeditationIntent(phase) as Object),
      );
    });

    test('a moon intent and a cycle intent are never equal', () {
      expect(
        const CycleMeditationIntent(CyclePhase.menstrual),
        isNot(const MoonMeditationIntent(MoonPhase.newMoon) as Object),
      );
    });
  });
}
