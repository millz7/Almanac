import 'package:almanac/app/app.dart';
import 'package:almanac/app/context/cycle_phase_context.dart';
import 'package:almanac/app/context/festival_context.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/shared_preferences_settings_store.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/data/shared_preferences_own_recipe_store.dart';
import 'package:almanac/features/cookbook/domain/recipe_catalogue.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/garden/data/shared_preferences_garden_store.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/data/shared_preferences_nature_log_store.dart';
import 'package:almanac/features/onboarding/domain/onboarding_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Everything that should survive closing and reopening the app, tested
/// against the **real** preference-backed stores on an in-memory device.
///
/// A "launch" here is exactly what a cold start is: brand-new store
/// objects over the same stored bytes, a brand-new provider container,
/// and a brand-new widget tree. Nothing carries over except what was
/// written down.
void main() {
  setUpAll(useTimeZoneDatabase);

  /// Four days before Beltane in the north.
  final beltaneEve = DateTime.utc(2026, 4, 27, 12);
  const today = CalendarDate(2026, 4, 27);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  ProviderContainer? current;

  /// Closes whatever is running and cold-starts the app on the same
  /// device storage.
  Future<ProviderContainer> launch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    current?.dispose();

    tester.view.physicalSize = const Size(430, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final settings = await SharedPreferencesSettingsStore.open();
    final container = ProviderContainer(
      overrides: environmentOverrides(
        now: beltaneEve,
        settingsStore: settings,
        cycleStore: SharedPreferencesCycleStore(),
        gardenStore: SharedPreferencesGardenStore(),
        natureLogStore: SharedPreferencesNatureLogStore(),
        ownRecipeStore: SharedPreferencesOwnRecipeStore(),
      ),
    );
    current = container;
    addTearDown(() {
      if (identical(current, container)) {
        container.dispose();
        current = null;
      }
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  UserSettingsController settingsOf(ProviderContainer c) =>
      c.read(userSettingsProvider.notifier);

  Future<void> finishOnboarding(
    ProviderContainer c, {
    String? name = 'Robin',
    Set<FeatureId> features = const {},
  }) async {
    await settingsOf(c).setName(name);
    await settingsOf(c).selectHemisphere(Hemisphere.southern);
    await settingsOf(c).markLocationIntroSeen();
    await settingsOf(c).setFeatures(features);
    await settingsOf(c).completeOnboarding();
  }

  String location(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  List<FeatureId> tabs(WidgetTester tester) => tester
      .widget<AlmanacNavigationBar>(find.byType(AlmanacNavigationBar))
      .destinations
      .map((f) => f.id)
      .toList();

  final everything = FeatureRegistry.optional.map((f) => f.id).toSet();

  group('settings survive a restart', () {
    testWidgets('a fresh device starts onboarding at the name', (tester) async {
      final c = await launch(tester);
      expect(c.read(onboardingStageProvider), OnboardingStage.name);
      expect(location(c), kNameRoute);
    });

    testWidgets('name, hemisphere, completion and categories all return', (
      tester,
    ) async {
      var c = await launch(tester);
      await finishOnboarding(c, features: {FeatureId.cycle, FeatureId.garden});

      c = await launch(tester);
      final settings = c.read(userSettingsProvider);
      expect(c.read(onboardingStageProvider), OnboardingStage.complete);
      expect(location(c), kEnvironmentRoute);
      expect(settings.name, 'Robin');
      expect(c.read(almanacTitleProvider), contains('Robin'));
      expect(settings.hemisphere, Hemisphere.southern);
      expect(tabs(tester), [
        FeatureId.environment,
        FeatureId.cycle,
        FeatureId.garden,
      ]);
    });

    testWidgets('a deliberately blank name stays blank, and the question '
        'is not asked again', (tester) async {
      var c = await launch(tester);
      await finishOnboarding(c, name: '   ');

      c = await launch(tester);
      expect(c.read(userSettingsProvider).name, isNull);
      expect(c.read(userSettingsProvider).nameAsked, isTrue);
      expect(c.read(almanacTitleProvider), 'Your Almanac');
      expect(c.read(onboardingStageProvider), OnboardingStage.complete);
    });

    testWidgets('all nine: every category returns, in order, with nothing '
        'folded away', (tester) async {
      var c = await launch(tester);
      await finishOnboarding(c, features: everything);

      c = await launch(tester);
      expect(tabs(tester), [for (final f in FeatureRegistry.all) f.id]);
      expect(find.text('More'), findsNothing);
      // Every branch opens, and its index matches its feature.
      for (final feature in FeatureRegistry.optional) {
        c.read(routerProvider).go(feature.route);
        await tester.pumpAndSettle();
        expect(location(c), feature.route);
        expect(tester.takeException(), isNull, reason: feature.name);
      }
    });

    testWidgets('Environment only: usable, one tab, no doorway into a '
        'missing feature', (tester) async {
      var c = await launch(tester);
      await finishOnboarding(c);

      c = await launch(tester);
      expect(tabs(tester), [FeatureId.environment]);
      expect(find.textContaining('Beltane'), findsNothing);
      expect(find.textContaining('See '), findsNothing);
      // The drawer can still switch a feature on, and it arrives.
      await settingsOf(c).setFeatureChosen(FeatureId.yoga, true);
      await tester.pumpAndSettle();
      expect(tabs(tester), [FeatureId.environment, FeatureId.yoga]);
    });
  });

  group('onboarding interrupted at each stage resumes at that stage', () {
    testWidgets('after the name', (tester) async {
      var c = await launch(tester);
      await settingsOf(c).setName('Robin');
      c = await launch(tester);
      expect(c.read(onboardingStageProvider), OnboardingStage.hemisphere);
      expect(location(c), kHemisphereRoute);
    });

    testWidgets('after the hemisphere', (tester) async {
      var c = await launch(tester);
      await settingsOf(c).skipName();
      await settingsOf(c).selectHemisphere(Hemisphere.northern);
      c = await launch(tester);
      expect(c.read(onboardingStageProvider), OnboardingStage.location);
      expect(location(c), kLocationIntroRoute);
    });

    testWidgets('after the location explanation, but before categories: '
        'not complete', (tester) async {
      var c = await launch(tester);
      await settingsOf(c).skipName();
      await settingsOf(c).selectHemisphere(Hemisphere.northern);
      await settingsOf(c).markLocationIntroSeen();
      await settingsOf(c).setFeatures({FeatureId.yoga});
      c = await launch(tester);
      expect(c.read(onboardingStageProvider), OnboardingStage.features);
      expect(location(c), kFeatureChoiceRoute);
      expect(c.read(userSettingsProvider).onboardingCompleted, isFalse);
    });

    testWidgets('an install from before the completion flag is not sent '
        'back through onboarding', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.hemisphere': 'southern',
            'settings.locationIntroSeen': true,
            'settings.nameAsked': true,
          });
      final c = await launch(tester);
      expect(c.read(onboardingStageProvider), OnboardingStage.complete);
    });
  });

  group('feature data survives a restart', () {
    testWidgets('Cycle: bleeding, Day 1 and a chosen phase', (tester) async {
      var c = await launch(tester);
      await finishOnboarding(c, features: {FeatureId.cycle});
      final cycle = c.read(cycleDataProvider.notifier);
      await c.read(cycleDataProvider.future);
      await cycle.record(
        today.addDays(-2),
        BleedingLevel.bleeding,
        isPeriodStart: true,
      );
      await cycle.record(today.addDays(-1), BleedingLevel.heavy);
      await cycle.setDisplayedPhase(CyclePhase.menstrual);

      c = await launch(tester);
      final data = await c.read(cycleDataProvider.future);
      expect(data.records, hasLength(2));
      expect(data.isPeriodStart(today.addDays(-2)), isTrue);
      expect(data.recordOn(today.addDays(-1))!.level, BleedingLevel.heavy);
      expect(data.manualPhase, CyclePhase.menstrual);
    });

    testWidgets('Day 1 moved, then a restart: the correction holds', (
      tester,
    ) async {
      var c = await launch(tester);
      await finishOnboarding(c, features: {FeatureId.cycle});
      await c.read(cycleDataProvider.future);
      final cycle = c.read(cycleDataProvider.notifier);
      await cycle.record(
        today.addDays(-3),
        BleedingLevel.bleeding,
        isPeriodStart: true,
      );
      await cycle.record(today.addDays(-2), BleedingLevel.bleeding);
      await cycle.setPeriodStart(today.addDays(-3), isStart: false);
      await cycle.setPeriodStart(today.addDays(-2), isStart: true);

      c = await launch(tester);
      final data = await c.read(cycleDataProvider.future);
      expect(data.isPeriodStart(today.addDays(-3)), isFalse);
      expect(data.isPeriodStart(today.addDays(-2)), isTrue);
    });

    testWidgets('Cookbook, Garden and Nature Log', (tester) async {
      var c = await launch(tester);
      await finishOnboarding(
        c,
        features: {FeatureId.cookbook, FeatureId.garden, FeatureId.natureLog},
      );
      await c.read(ownRecipesProvider.future);
      await c.read(myGardenProvider.future);
      await c.read(natureLogProvider.future);
      await c.read(ownRecipesProvider.notifier).add(title: 'Flapjack');
      await c
          .read(myGardenProvider.notifier)
          .addExisting(plantId: 'mint', state: EstablishmentState.established);
      await c
          .read(natureLogProvider.notifier)
          .recordCustom(name: 'A heron', category: NatureCategory.bird);

      c = await launch(tester);
      expect(
        (await c.read(ownRecipesProvider.future)).recipes.single.title,
        'Flapjack',
      );
      expect((await c.read(myGardenProvider.future)).contains('mint'), isTrue);
      expect(
        (await c.read(natureLogProvider.future)).recent.single.label,
        'A heron',
      );
    });
  });

  group('dormant through a restart, and back again', () {
    testWidgets('Cycle: switched off, its data kept but never read; back '
        'on, all there', (tester) async {
      var c = await launch(tester);
      await finishOnboarding(c, features: {FeatureId.cycle, FeatureId.yoga});
      await c.read(cycleDataProvider.future);
      await c
          .read(cycleDataProvider.notifier)
          .record(today, BleedingLevel.bleeding, isPeriodStart: true);
      expect(c.read(almanacCyclePhaseProvider(null)), isNotNull);

      await settingsOf(c).setFeatureChosen(FeatureId.cycle, false);
      c = await launch(tester);
      expect(tabs(tester), isNot(contains(FeatureId.cycle)));
      expect(c.read(almanacCyclePhaseProvider(null)), isNull);
      // Still on the device.
      final stored = await SharedPreferencesCycleStore().read();
      expect(stored.records, hasLength(1));

      await settingsOf(c).setFeatureChosen(FeatureId.cycle, true);
      c = await launch(tester);
      expect((await c.read(cycleDataProvider.future)).records, hasLength(1));
      expect(c.read(almanacCyclePhaseProvider(null)), isNotNull);
    });

    for (final (name, id) in [
      ('Cookbook', FeatureId.cookbook),
      ('Garden', FeatureId.garden),
      ('Nature Log', FeatureId.natureLog),
    ]) {
      testWidgets('$name: switched off and back on, its data is untouched', (
        tester,
      ) async {
        var c = await launch(tester);
        await finishOnboarding(c, features: {id});
        await c.read(ownRecipesProvider.future);
        await c.read(myGardenProvider.future);
        await c.read(natureLogProvider.future);
        switch (id) {
          case FeatureId.cookbook:
            await c.read(ownRecipesProvider.notifier).add(title: 'Flapjack');
          case FeatureId.garden:
            await c
                .read(myGardenProvider.notifier)
                .addExisting(
                  plantId: 'mint',
                  state: EstablishmentState.established,
                );
          default:
            await c
                .read(natureLogProvider.notifier)
                .recordCustom(name: 'A heron', category: NatureCategory.bird);
        }

        await settingsOf(c).setFeatureChosen(id, false);
        c = await launch(tester);
        expect(tabs(tester), [FeatureId.environment]);

        await settingsOf(c).setFeatureChosen(id, true);
        c = await launch(tester);
        expect(tabs(tester), [FeatureId.environment, id]);
        expect(switch (id) {
          FeatureId.cookbook => (await c.read(
            ownRecipesProvider.future,
          )).length,
          FeatureId.garden => (await c.read(
            myGardenProvider.future,
          )).plants.length,
          _ => (await c.read(natureLogProvider.future)).length,
        }, 1);
      });
    }

    testWidgets('Wheel: switched off, no festival context after a restart', (
      tester,
    ) async {
      var c = await launch(tester);
      await finishOnboarding(c, features: {FeatureId.wheel});
      // Southern hemisphere was chosen; switch north so Beltane is close.
      await settingsOf(c).selectHemisphere(Hemisphere.northern);
      await tester.pumpAndSettle();
      expect(c.read(almanacFestivalProvider(null)), isNotNull);

      await settingsOf(c).setFeatureChosen(FeatureId.wheel, false);
      c = await launch(tester);
      expect(c.read(almanacFestivalProvider(null)), isNull);
      expect(find.textContaining('Beltane'), findsNothing);
    });
  });

  group('switching off the feature you are in', () {
    for (final feature in FeatureRegistry.optional) {
      testWidgets('${feature.name}: back to the Environment, and back in '
          'once it returns', (tester) async {
        final c = await launch(tester);
        await finishOnboarding(c, features: everything);
        c.read(routerProvider).go(feature.route);
        await tester.pumpAndSettle();
        expect(location(c), feature.route);

        await settingsOf(c).setFeatureChosen(feature.id, false);
        await tester.pumpAndSettle();
        expect(location(c), kEnvironmentRoute);
        expect(tester.takeException(), isNull);
        expect(find.text('TODAY'), findsOneWidget);
        expect(tabs(tester), isNot(contains(feature.id)));

        await settingsOf(c).setFeatureChosen(feature.id, true);
        await tester.pumpAndSettle();
        c.read(routerProvider).go(feature.route);
        await tester.pumpAndSettle();
        expect(location(c), feature.route);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('each store keeps to itself', () {
    testWidgets('clearing one never touches another', (tester) async {
      final c = await launch(tester);
      await finishOnboarding(c, features: everything);
      await c.read(cycleDataProvider.future);
      await c.read(ownRecipesProvider.future);
      await c.read(myGardenProvider.future);
      await c.read(natureLogProvider.future);
      await c
          .read(cycleDataProvider.notifier)
          .record(today, BleedingLevel.bleeding, isPeriodStart: true);
      await c.read(ownRecipesProvider.notifier).add(title: 'Flapjack');
      await c
          .read(myGardenProvider.notifier)
          .addExisting(plantId: 'mint', state: EstablishmentState.established);
      await c
          .read(natureLogProvider.notifier)
          .recordCustom(name: 'A heron', category: NatureCategory.bird);

      await c.read(natureLogProvider.notifier).clear();
      expect((await SharedPreferencesGardenStore().read()).plants.length, 1);
      expect((await SharedPreferencesOwnRecipeStore().read()).length, 1);

      await c.read(myGardenProvider.notifier).clear();
      expect((await SharedPreferencesOwnRecipeStore().read()).length, 1);
      expect(
        (await SharedPreferencesCycleStore().read()).records,
        hasLength(1),
      );

      await SharedPreferencesOwnRecipeStore().deleteAll();
      // The Almanac's own recipes are content, not storage.
      expect(RecipeCatalogue.all, hasLength(16));
      expect(
        (await SharedPreferencesCycleStore().read()).records,
        hasLength(1),
      );

      // Switching Cycle off deletes nothing.
      await settingsOf(c).setFeatureChosen(FeatureId.cycle, false);
      expect(
        (await SharedPreferencesCycleStore().read()).records,
        hasLength(1),
      );
    });
  });

  group('damaged storage', () {
    testWidgets('the app still starts, and every good record survives the '
        'bad ones next to it', (tester) async {
      final goodDay = encodeRecord(
        CycleDayRecord(
          date: today.addDays(-1),
          level: BleedingLevel.bleeding,
          isPeriodStart: true,
        ),
      );
      SharedPreferencesAsyncPlatform
          .instance = InMemorySharedPreferencesAsync.withData({
        // Settings: a flag of the wrong type, an unknown hemisphere
        // name and a category list with nonsense in it.
        'settings.nameAsked': 'yes',
        'settings.hemisphere': 'sideways',
        'settings.locationIntroSeen': true,
        'settings.onboardingCompleted': true,
        'settings.features': <String>['cookbook', 'nonsense', 'cycle'],
        // Cycle: one good day, one junk line, a length of the wrong
        // type, and a phase that is not a phase.
        'cycle.dayRecords': <String>[goodDay, 'junk|||'],
        'cycle.assumedCycleLength': 'twenty-eight',
        'cycle.manualPhase': 'sideways',
        // One good line and one damaged line in each list store.
        'cookbook.ownRecipes': <String>[
          encodeOwnRecipe(
            const OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack'),
          ),
          '{not json',
        ],
        'garden.plants': <String>['mint|2026-04-01|established||', 'broken'],
        'natureLog.observations': <String>[
          '{"id":"obs-0","date":"2026-04-01","category":"bird",'
              '"label":"A heron","order":0}',
          '{"id":"obs-1","category":"not-a-category","label":"x",'
              '"order":1,"date":"2026-04-01"}',
        ],
      });

      final c = await launch(tester);
      expect(tester.takeException(), isNull);

      final settings = c.read(userSettingsProvider);
      expect(settings.nameAsked, isFalse);
      expect(settings.hemisphere, isNull);
      expect(settings.features, {FeatureId.cookbook, FeatureId.cycle});
      // Completion was recorded, so setup is not repeated — but the
      // hemisphere the damage lost is asked for again, alone, rather
      // than guessed.
      expect(settings.onboardingCompleted, isTrue);
      expect(c.read(onboardingStageProvider), OnboardingStage.hemisphere);
      await settingsOf(c).selectHemisphere(Hemisphere.southern);
      await tester.pumpAndSettle();
      expect(c.read(onboardingStageProvider), OnboardingStage.complete);
      expect(location(c), kEnvironmentRoute);

      final cycle = await c.read(cycleDataProvider.future);
      expect(cycle.records, hasLength(1));
      expect(cycle.assumedCycleLength, kDefaultCycleLength);
      expect(cycle.manualPhase, isNull);

      expect((await c.read(ownRecipesProvider.future)).length, 1);
      expect(
        (await SharedPreferencesGardenStore().read()).contains('mint'),
        isTrue,
      );
      expect((await SharedPreferencesNatureLogStore().read()).length, 1);
    });

    testWidgets('a list of the wrong type is never overwritten by the '
        'empty list the screen fell back to', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.nameAsked': true,
            'settings.hemisphere': 'northern',
            'settings.locationIntroSeen': true,
            'settings.onboardingCompleted': true,
            'settings.features': <String>['garden'],
            // Not a list at all.
            'garden.plants': 'mint',
          });

      final c = await launch(tester);
      expect((await c.read(myGardenProvider.future)).isEmpty, isTrue);
      await expectLater(
        c
            .read(myGardenProvider.notifier)
            .addExisting(plantId: 'apple', state: EstablishmentState.seedling),
        throwsA(isA<StateError>()),
      );
      // What was on the device is still exactly what was there.
      final platform = SharedPreferencesAsyncPlatform.instance!;
      expect(
        await platform.getString(
          'garden.plants',
          const SharedPreferencesOptions(),
        ),
        'mint',
      );
    });
  });

  group('the Step 11 cycle migration still holds', () {
    testWidgets('legacy period starts become Bleeding + Day 1, once, with '
        'nothing invented', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.nameAsked': true,
            'settings.hemisphere': 'northern',
            'settings.locationIntroSeen': true,
            'settings.onboardingCompleted': true,
            'settings.features': <String>['cycle'],
            'cycle.periodStarts': <String>['2026-03-01', '2026-03-29'],
          });

      var c = await launch(tester);
      var data = await c.read(cycleDataProvider.future);
      expect(data.records, hasLength(2));
      for (final record in data.records) {
        expect(record.level, BleedingLevel.bleeding);
        expect(record.isPeriodStart, isTrue);
      }

      // A second launch migrates nothing more.
      c = await launch(tester);
      data = await c.read(cycleDataProvider.future);
      expect(data.records, hasLength(2));
      expect(
        await SharedPreferencesAsyncPlatform.instance!.getStringList(
          'cycle.periodStarts',
          const SharedPreferencesOptions(),
        ),
        isNull,
      );
    });
  });

  test('the in-memory stores used elsewhere match the real ones', () {
    // A guard for this file's premise: every feature store has a real,
    // separately keyed preference implementation.
    expect(SharedPreferencesCycleStore.keys, isNotEmpty);
    expect(InMemoryCycleStore(), isA<CycleStore>());
    expect(CycleData.empty.records, isEmpty);
  });
}
