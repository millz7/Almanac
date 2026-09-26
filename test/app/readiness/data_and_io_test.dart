import 'dart:async';
import 'dart:convert';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/open_meteo_marine_tide_service.dart';
import 'package:almanac/core/environment/open_meteo_weather_service.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/core/environment/tide_providers.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/core/environment/weather_providers.dart';
import 'package:almanac/core/environment/weather_service.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/settings/shared_preferences_settings_store.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/data/shared_preferences_own_recipe_store.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/garden/data/shared_preferences_garden_store.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/data/shared_preferences_nature_log_store.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// A location service whose platform calls wait until the test lets
/// them finish — so a second tap can arrive while the first is still
/// out, as it does on a real phone.
class _SlowLocationService extends FakeLocationService {
  _SlowLocationService() : super(checkResult: const LocationPermissionDenied());

  final gate = Completer<void>();

  @override
  Future<LocationState> requestAccess() async {
    requestCount++;
    await gate.future;
    return const LocationAvailable(TestLocations.london);
  }

  @override
  Future<LocationState> currentState() async {
    checkCount++;
    await gate.future;
    return const LocationAvailable(TestLocations.london);
  }

  @override
  Future<bool> openSystemSettings() async {
    openSettingsCount++;
    await gate.future;
    return true;
  }
}

class _SlowWeather implements WeatherService {
  final gate = Completer<void>();
  int fetchCount = 0;

  @override
  Future<WeatherSnapshot> fetch({
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime now,
  }) async {
    fetchCount++;
    await gate.future;
    return testWeatherSnapshot(location: location, obtainedAt: now);
  }
}

class _SlowTides implements TideService {
  final gate = Completer<void>();
  int fetchCount = 0;

  @override
  Future<TideFetchResult> fetch({
    required GeoLocation location,
    required LocalTimeZone timeZone,
    required DateTime now,
  }) async {
    fetchCount++;
    await gate.future;
    return TideFetchData(testTideSnapshot(location: location, obtainedAt: now));
  }
}

/// A solar service that counts how often the environment resolves.
class _CountingSolar extends FakeSolarService {
  int calls = 0;

  @override
  Future<SolarEvents> eventsFor({
    required DateTime instant,
    required LocalTimeZone timeZone,
    GeoLocation? location,
  }) {
    calls++;
    return super.eventsFor(
      instant: instant,
      timeZone: timeZone,
      location: location,
    );
  }
}

void main() {
  setUpAll(useTimeZoneDatabase);

  ProviderContainer containerWith({
    OwnRecipeStore? recipes,
    NatureLogStore? nature,
    GardenStore? garden,
    CycleStore? cycle,
  }) {
    final c = ProviderContainer(
      overrides: environmentOverrides(
        now: DateTime.utc(2026, 9, 10, 12),
        ownRecipeStore: recipes,
        natureLogStore: nature,
        gardenStore: garden,
        cycleStore: cycle,
      ),
    );
    addTearDown(c.dispose);
    return c;
  }

  group('what people type is kept as they meant it', () {
    test('a name loses only its outer spaces', () async {
      final c = ProviderContainer(overrides: environmentOverrides());
      addTearDown(c.dispose);
      await c.read(userSettingsProvider.notifier).setName('  Mary  Ann  ');
      expect(c.read(userSettingsProvider).name, 'Mary  Ann');
      await c.read(userSettingsProvider.notifier).setName('   ');
      expect(c.read(userSettingsProvider).name, isNull);
      expect(c.read(userSettingsProvider).nameAsked, isTrue);
    });

    test('a recipe needs a real name; blank lines are not ingredients; '
        'notes keep their own line breaks', () async {
      final store = InMemoryOwnRecipeStore();
      final c = containerWith(recipes: store);
      await c.read(ownRecipesProvider.future);
      final recipes = c.read(ownRecipesProvider.notifier);

      await expectLater(recipes.add(title: ''), throwsArgumentError);
      await expectLater(recipes.add(title: '   \n '), throwsArgumentError);
      expect((await store.read()).isEmpty, isTrue);

      final id = await recipes.add(
        title: '  Leek   soup ',
        ingredients: linesOf('2 leeks\n\n   \n3  potatoes'),
        method: linesOf('Soften.\n\nSimmer.'),
        note: '  Better the next day.\n\nFreezes well.  ',
      );
      final saved = (await store.read()).find(id)!;
      expect(saved.title, 'Leek   soup');
      expect(saved.ingredients, ['2 leeks', '3  potatoes']);
      expect(saved.method, ['Soften.', 'Simmer.']);
      expect(saved.note, 'Better the next day.\n\nFreezes well.');

      await expectLater(
        recipes.edit(id, title: '  ', ingredients: [], method: []),
        throwsArgumentError,
      );
      expect((await store.read()).find(id)!.title, 'Leek   soup');
    });

    test('an observation needs a real name; a blank note or place is '
        'simply absent', () async {
      final store = InMemoryNatureLogStore();
      final c = containerWith(nature: store);
      await c.read(natureLogProvider.future);
      final log = c.read(natureLogProvider.notifier);

      await expectLater(
        log.recordCustom(name: '  ', category: NatureCategory.bird),
        throwsArgumentError,
      );
      await log.recordCustom(
        name: ' A heron ',
        category: NatureCategory.bird,
        note: '   ',
        placeLabel: '',
      );
      final saved = (await store.read()).recent.single;
      expect(saved.label, 'A heron');
      expect(saved.note, isNull);
      expect(saved.placeLabel, isNull);
    });
  });

  group('forms and the keyboard', () {
    Future<ProviderContainer> openAt(
      WidgetTester tester,
      FeatureId feature, {
      OwnRecipeStore? recipes,
      NatureLogStore? nature,
    }) async {
      tester.view.physicalSize = const Size(430, 2400) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = ProviderContainer(
        overrides: environmentOverrides(
          features: {feature},
          ownRecipeStore: recipes,
          natureLogStore: nature,
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AlmanacApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go(FeatureRegistry.byId(feature).route);
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> press(WidgetTester tester, Finder target) async {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
      await tester.tap(target.first);
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextField, label);

    testWidgets('recipe: Done on the name does not save; the long fields '
        'are multiline; focus walks the fields in order', (tester) async {
      final store = InMemoryOwnRecipeStore();
      await openAt(tester, FeatureId.cookbook, recipes: store);
      await press(tester, find.text(CookbookText.addRecipe));

      await tester.tap(field(CookbookText.titleLabel));
      await tester.enterText(field(CookbookText.titleLabel), 'Flapjack');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect((await store.read()).isEmpty, isTrue);
      expect(field(CookbookText.titleLabel), findsOneWidget);

      for (final label in [
        CookbookText.ingredientsLabel,
        CookbookText.methodLabel,
        CookbookText.noteLabel,
      ]) {
        final text = tester.widget<TextField>(field(label));
        expect(text.keyboardType, TextInputType.multiline, reason: label);
        expect(text.maxLines, greaterThan(1), reason: label);
      }

      // Focus order follows the page: name, then ingredients.
      await tester.tap(field(CookbookText.titleLabel));
      await tester.pump();
      FocusManager.instance.primaryFocus!.nextFocus();
      await tester.pump();
      final ingredients = tester.widget<TextField>(
        field(CookbookText.ingredientsLabel),
      );
      expect(
        ingredients.focusNode?.hasFocus ??
            _hasFocus(tester, field(CookbookText.ingredientsLabel)),
        isTrue,
      );
    });

    testWidgets('observation: Done on the name does not save, and a blank '
        'name keeps Save unavailable', (tester) async {
      final store = InMemoryNatureLogStore();
      await openAt(tester, FeatureId.natureLog, nature: store);
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );
      await tester.tap(field(NatureLogText.nameLabel));
      await tester.enterText(field(NatureLogText.nameLabel), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, NatureLogText.saveObservation),
      );
      expect(save.onPressed, isNull);
      expect((await store.read()).isEmpty, isTrue);
    });
  });

  group('a good deal of data', () {
    test('50 recipes: every id distinct, and edit and delete reach only '
        'their own recipe', () async {
      final store = InMemoryOwnRecipeStore();
      final c = containerWith(recipes: store);
      await c.read(ownRecipesProvider.future);
      final recipes = c.read(ownRecipesProvider.notifier);
      final ids = [
        for (var i = 0; i < 50; i++) await recipes.add(title: 'Recipe $i'),
      ];
      expect(ids.toSet(), hasLength(50));

      await recipes.edit(
        ids[20],
        title: 'Changed',
        ingredients: const ['x'],
        method: const [],
      );
      await recipes.remove(ids[30]);
      final stored = await store.read();
      expect(stored.length, 49);
      expect(stored.find(ids[20])!.title, 'Changed');
      expect(stored.find(ids[21])!.title, 'Recipe 21');
      expect(stored.find(ids[30]), isNull);
      expect(stored.find(ids[31])!.title, 'Recipe 31');
    });

    test('100 observations, a full garden and a year of cycle days all '
        'round-trip through the real stores', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      final log = NatureLog([
        for (var i = 0; i < 100; i++)
          NatureObservation(
            instanceId: 'obs-$i-2026-01-01',
            date: const CalendarDate(2026, 1, 1).addDays(i),
            category: NatureCategory.values[i % NatureCategory.values.length],
            label: 'Sighting $i',
            order: i,
            note: i.isEven ? 'Note $i' : null,
          ),
      ]);
      await SharedPreferencesNatureLogStore().write(log);
      final readLog = await SharedPreferencesNatureLogStore().read();
      expect(readLog.length, 100);
      expect(readLog.find('obs-57-2026-01-01')!.label, 'Sighting 57');

      final plants = PlantBook.all.take(30).toList();
      await SharedPreferencesGardenStore().write(
        MyGarden([
          for (final plant in plants)
            GardenPlant(
              instanceId: plant.id,
              plantId: plant.id,
              addedOn: const CalendarDate(2026, 3, 1),
              state: EstablishmentState.established,
            ),
        ]),
      );
      final garden = await SharedPreferencesGardenStore().read();
      expect(garden.plants, hasLength(plants.length));

      final days = [
        for (var month = 0; month < 12; month++)
          for (var d = 0; d < 5; d++)
            CycleDayRecord(
              date: const CalendarDate(2025, 9, 1).addDays(month * 28 + d),
              level: d == 0 ? BleedingLevel.bleeding : BleedingLevel.heavy,
              isPeriodStart: d == 0,
            ),
      ];
      await SharedPreferencesCycleStore().write(CycleData(records: days));
      final cycle = await SharedPreferencesCycleStore().read();
      expect(cycle.records, hasLength(60));
      expect(cycle.records.where((r) => r.isPeriodStart), hasLength(12));
    });

    testWidgets('and every screen builds with it', (tester) async {
      tester.view.physicalSize = const Size(430, 2400) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 10, 12),
          features: FeatureRegistry.optional.map((f) => f.id).toSet(),
          ownRecipeStore: InMemoryOwnRecipeStore(
            OwnRecipes([
              for (var i = 0; i < 50; i++)
                OwnRecipe(id: 'own-$i', order: i, title: 'Recipe $i'),
            ]),
          ),
          natureLogStore: InMemoryNatureLogStore(
            NatureLog([
              for (var i = 0; i < 100; i++)
                NatureObservation(
                  instanceId: 'obs-$i',
                  date: const CalendarDate(2026, 6, 1).addDays(i % 90),
                  category: NatureCategory.bird,
                  label: 'Sighting $i',
                  order: i,
                ),
            ]),
          ),
          cycleStore: InMemoryCycleStore(
            CycleData(
              records: [
                for (var month = 0; month < 12; month++)
                  CycleDayRecord(
                    date: const CalendarDate(2025, 9, 1).addDays(month * 28),
                    level: BleedingLevel.bleeding,
                    isPeriodStart: true,
                  ),
              ],
            ),
          ),
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AlmanacApp()),
      );
      await tester.pumpAndSettle();
      for (final feature in FeatureRegistry.optional) {
        c.read(routerProvider).go(feature.route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: feature.name);
      }
      c
          .read(routerProvider)
          .go(FeatureRegistry.byId(FeatureId.natureLog).route);
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(RegExp('^${NatureLogText.myObservations}\\.')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('identifiers', () {
    test(
      'delete an older recipe, restart, add another: no id reused',
      () async {
        final store = InMemoryOwnRecipeStore();
        var c = containerWith(recipes: store);
        await c.read(ownRecipesProvider.future);
        final first = await c.read(ownRecipesProvider.notifier).add(title: 'A');
        final second = await c
            .read(ownRecipesProvider.notifier)
            .add(title: 'B');
        final third = await c.read(ownRecipesProvider.notifier).add(title: 'C');
        await c.read(ownRecipesProvider.notifier).remove(first);

        c = containerWith(recipes: store); // a restart over the same store
        await c.read(ownRecipesProvider.future);
        final fourth = await c
            .read(ownRecipesProvider.notifier)
            .add(title: 'D');
        expect([second, third], isNot(contains(fourth)));
        final stored = await store.read();
        expect(stored.recipes.map((r) => r.id).toSet(), hasLength(3));
        expect(stored.find(second)!.title, 'B');
        expect(stored.find(third)!.title, 'C');
      },
    );

    test('a damaged file whose ids and order disagree cannot make a new '
        'recipe overwrite an old one', () async {
      final store = InMemoryOwnRecipeStore(
        const OwnRecipes([
          OwnRecipe(id: 'own-3', order: 1, title: 'Keep me'),
          OwnRecipe(id: 'own-2', order: 2, title: 'And me'),
        ]),
      );
      final c = containerWith(recipes: store);
      await c.read(ownRecipesProvider.future);
      final added = await c.read(ownRecipesProvider.notifier).add(title: 'New');
      expect(added, isNot(anyOf('own-3', 'own-2')));
      final stored = await store.read();
      expect(stored.find('own-3')!.title, 'Keep me');
      expect(stored.find('own-2')!.title, 'And me');
      expect(stored.length, 3);
    });

    test('two stored lines claiming one id: only one is read, so a delete '
        'can never take two', () {
      final line = encodeOwnRecipe(
        const OwnRecipe(id: 'own-0', order: 0, title: 'Original'),
      );
      final twin = encodeOwnRecipe(
        const OwnRecipe(id: 'own-0', order: 5, title: 'Twin'),
      );
      final recipes = decodeOwnRecipes([line, twin]);
      expect(recipes.length, 1);
      expect(recipes.recipes.single.title, 'Original');

      final obs = encodeObservation(
        NatureObservation(
          instanceId: 'obs-0',
          date: const CalendarDate(2026, 1, 1),
          category: NatureCategory.bird,
          label: 'One',
          order: 0,
        ),
      );
      expect(decodeLog([obs, obs]).length, 1);
    });

    test('Nature ids stay unique too, even over a damaged file', () async {
      final store = InMemoryNatureLogStore(
        NatureLog([
          NatureObservation(
            // An id the next observation would otherwise be given.
            instanceId: 'obs-1-2026-09-10',
            date: const CalendarDate(2026, 9, 10),
            category: NatureCategory.bird,
            label: 'Already here',
            order: 0,
          ),
        ]),
      );
      final c = containerWith(nature: store);
      await c.read(natureLogProvider.future);
      await c
          .read(natureLogProvider.notifier)
          .recordCustom(name: 'New', category: NatureCategory.plant);
      final stored = await store.read();
      expect(stored.length, 2);
      expect(stored.find('obs-1-2026-09-10')!.label, 'Already here');
    });
  });

  group('older and newer stored data', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<List<String>?> raw(String key) => SharedPreferencesAsyncPlatform
        .instance!
        .getStringList(key, const SharedPreferencesOptions());

    test('a Nature category from a newer version is kept, untouched, '
        'through a save', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'natureLog.observations': <String>[
              jsonEncode({
                'id': 'obs-0',
                'date': '2026-01-01',
                'category': 'mammal',
                'label': 'A hedgehog',
                'order': 0,
              }),
            ],
          });
      final store = SharedPreferencesNatureLogStore();
      final log = await store.read();
      expect(log.isEmpty, isTrue);

      await store.write(
        log.adding(
          NatureObservation(
            instanceId: 'obs-1',
            date: const CalendarDate(2026, 1, 2),
            category: NatureCategory.animal,
            label: 'A deer',
            order: 1,
          ),
        ),
      );
      final lines = await raw('natureLog.observations');
      expect(lines, hasLength(2));
      expect(lines!.any((l) => l.contains('hedgehog')), isTrue);
      // And the Animal category written by this version reads back.
      expect(
        (await SharedPreferencesNatureLogStore().read()).recent.single.category,
        NatureCategory.animal,
      );
    });

    test(
      'a Cycle level from a newer version survives recording a day',
      () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              'cycle.dayRecords': <String>['2026-01-01|brandNewLevel|start'],
            });
        final store = SharedPreferencesCycleStore();
        final data = await store.read();
        expect(data.records, isEmpty);
        await store.write(
          data.recording(
            const CalendarDate(2026, 1, 5),
            BleedingLevel.bleeding,
          ),
        );
        final lines = await raw('cycle.dayRecords');
        expect(lines, contains('2026-01-01|brandNewLevel|start'));
        expect(lines, hasLength(2));
      },
    );

    test('an own recipe from before notes existed still reads; a field '
        'from the future is ignored, not fatal', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'cookbook.ownRecipes': <String>[
              jsonEncode({'id': 'own-0', 'order': 0, 'title': 'Old'}),
              jsonEncode({
                'id': 'own-1',
                'order': 1,
                'title': 'New',
                'photo': 'somewhere.jpg',
              }),
            ],
          });
      final recipes = await SharedPreferencesOwnRecipeStore().read();
      expect(recipes.length, 2);
      expect(recipes.find('own-0')!.ingredients, isEmpty);
      expect(recipes.find('own-0')!.note, isNull);
    });

    test('a category chosen in a newer version is not lost by a save '
        'in this one; Holidays is read by its stored name', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.features': <String>['wheel', 'starGazing'],
            'settings.hemisphere': 'northern',
            'settings.nameAsked': true,
            'settings.locationIntroSeen': true,
            'settings.onboardingCompleted': true,
          });
      final store = await SharedPreferencesSettingsStore.open();
      final settings = store.read();
      expect(settings.features, {FeatureId.wheel});

      await store.write(settings.copyWith(name: 'Robin'));
      expect(await raw('settings.features'), ['wheel', 'starGazing']);
    });

    test('an unknown plant stays in My Garden storage', () async {
      SharedPreferencesAsyncPlatform
          .instance = InMemorySharedPreferencesAsync.withData({
        'garden.plants': <String>['moonflower-2030|2026-01-01|established||'],
      });
      final store = SharedPreferencesGardenStore();
      final garden = await store.read();
      await store.write(
        garden.adding(
          GardenPlant(
            instanceId: 'mint',
            plantId: 'mint',
            addedOn: const CalendarDate(2026, 2, 1),
            state: EstablishmentState.seedling,
          ),
        ),
      );
      final lines = await raw('garden.plants');
      expect(lines!.any((l) => l.startsWith('moonflower-2030|')), isTrue);
      expect(lines.any((l) => l.startsWith('mint|')), isTrue);
    });
  });

  group('one request at a time', () {
    test('location: three quick taps, one permission prompt', () async {
      final service = _SlowLocationService();
      final c = ProviderContainer(
        overrides: environmentOverrides(locationService: service),
      );
      addTearDown(c.dispose);
      final location = c.read(locationStateProvider.notifier);
      final taps = [
        location.requestAccess(),
        location.requestAccess(),
        location.requestAccess(),
      ];
      final checks = [location.refresh(force: true), location.refresh()];
      final settings = [
        location.openSystemSettings(),
        location.openSystemSettings(),
      ];
      service.gate.complete();
      await Future.wait([...taps, ...checks, ...settings]);

      expect(service.requestCount, 1);
      expect(service.checkCount, 1);
      expect(service.openSettingsCount, 1);
      expect(c.read(locationStateProvider).location, isNotNull);

      // Finished: the next deliberate tap is heard.
      await location.requestAccess();
      expect(service.requestCount, 2);
    });

    test('weather: rebuilds while a request is out share it', () async {
      final service = _SlowWeather();
      final c = ProviderContainer(
        overrides: environmentOverrides(
          locationState: const LocationAvailable(TestLocations.london),
          locationService: FakeLocationService(
            checkResult: const LocationAvailable(TestLocations.london),
          ),
          weatherService: service,
        ),
      );
      addTearDown(c.dispose);
      final first = c.read(weatherControllerProvider.future);
      // A resume and a fresh position for the same place, both while the
      // first request is still out.
      c.invalidate(weatherControllerProvider);
      final second = c.read(weatherControllerProvider.future);
      await c.read(locationStateProvider.notifier).refresh(force: true);
      final third = c.read(weatherControllerProvider.future);
      service.gate.complete();
      await Future.wait([first, second, third]);
      expect(service.fetchCount, 1);
      expect(c.read(weatherControllerProvider).value, isNotNull);
    });

    test('tides: the same', () async {
      final service = _SlowTides();
      final c = ProviderContainer(
        overrides: environmentOverrides(
          locationState: const LocationAvailable(TestLocations.london),
          locationService: FakeLocationService(
            checkResult: const LocationAvailable(TestLocations.london),
          ),
          tideService: service,
        ),
      );
      addTearDown(c.dispose);
      final first = c.read(tideControllerProvider.future);
      c.invalidate(tideControllerProvider);
      final second = c.read(tideControllerProvider.future);
      await c.read(locationStateProvider.notifier).refresh(force: true);
      final third = c.read(tideControllerProvider.future);
      service.gate.complete();
      await Future.wait([first, second, third]);
      expect(service.fetchCount, 1);
      expect(c.read(tideControllerProvider).value, isA<TideAvailable>());
    });
  });

  group('responses that make no sense are refused quietly', () {
    Map<String, Object?> weatherBody({
      num temperature = 12,
      List<int>? times,
      List<num>? temps,
    }) => {
      'current': {
        'temperature_2m': temperature,
        'apparent_temperature': 11,
        'weather_code': 3,
        'precipitation': 0,
        'cloud_cover': 80,
        'wind_speed_10m': 10,
      },
      'hourly': {
        'time': times ?? <int>[],
        'temperature_2m': temps ?? <num>[],
        'weather_code': [for (final _ in times ?? const []) 3],
        'precipitation_probability': [for (final _ in times ?? const []) 10],
        'wind_speed_10m': [for (final _ in times ?? const []) 10],
      },
      'daily': {
        'time': [1790000000],
        'temperature_2m_max': [14],
        'temperature_2m_min': [8],
        'precipitation_probability_max': [20],
      },
    };

    Future<WeatherSnapshot> fetchWeather(Map<String, Object?> body) =>
        OpenMeteoWeatherService(
          client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
        ).fetch(
          location: TestLocations.london,
          timeZone: TestTimeZones.london,
          now: DateTime.utc(2026, 9, 10, 12),
        );

    test('an impossible temperature is a failure, not a forecast', () async {
      await expectLater(
        fetchWeather(weatherBody(temperature: 9999)),
        throwsA(isA<WeatherServiceFailure>()),
      );
      await expectLater(
        fetchWeather(weatherBody(temperature: 1e308 * 10)),
        throwsA(anything),
      );
    });

    test('no hours at all is still a usable current reading', () async {
      final snapshot = await fetchWeather(weatherBody());
      expect(snapshot.hourly, isEmpty);
      expect(snapshot.current.temperatureC, 12);
    });

    test('hours out of order or repeated are read once, in order', () async {
      final base = DateTime.utc(2026, 9, 10, 12).millisecondsSinceEpoch ~/ 1000;
      final snapshot = await fetchWeather(
        weatherBody(
          times: [base + 7200, base, base + 3600, base + 3600],
          temps: [13, 11, 12, 12],
        ),
      );
      final times = [for (final h in snapshot.hourly) h.time];
      expect(times, hasLength(3));
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue);
      }
      expect(snapshot.hourly.first.temperatureC, 11);
    });

    Future<TideFetchResult> fetchTides(List<Object> times, List<num?> h) =>
        OpenMeteoMarineTideService(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'hourly': {'time': times, 'sea_level_height_msl': h},
              }),
              200,
            ),
          ),
        ).fetch(
          location: TestLocations.london,
          timeZone: TestTimeZones.london,
          now: DateTime.utc(2026, 9, 10, 12),
        );

    test('a sea level of kilometres is a failure', () async {
      await expectLater(
        fetchTides([1790000000, 1790003600], [1.0, 5000]),
        throwsA(isA<TideServiceFailure>()),
      );
    });

    test(
      'empty tide lists are a failure; out-of-order times are ordered',
      () async {
        await expectLater(
          fetchTides(const [], const []),
          throwsA(isA<TideServiceFailure>()),
        );
        final result = await fetchTides(
          [1790007200, 1790000000, 1790003600],
          [1.2, 1.0, 1.1],
        );
        final samples = (result as TideFetchData).snapshot.samples;
        for (var i = 1; i < samples.length; i++) {
          expect(samples[i].time.isAfter(samples[i - 1].time), isTrue);
        }
      },
    );
  });

  group('time-driven providers', () {
    testWidgets('repeated resumes leave one refresh timer, and nothing '
        'survives disposal', (tester) async {
      tester.view.physicalSize = const Size(430, 1600) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final solar = _CountingSolar();
      final c = ProviderContainer(
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 10, 12),
          solarService: solar,
          refreshEnabled: true,
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AlmanacApp()),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }
      final afterResumes = solar.calls;

      // Six hours of an open app: one timer's worth of refreshes, not
      // five stacked ones.
      await tester.pump(const Duration(hours: 6, minutes: 1));
      await tester.pumpAndSettle();
      expect(solar.calls - afterResumes, lessThanOrEqualTo(2));

      // Closing everything cancels the timer: the test binding would
      // fail this test if one were still pending.
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await tester.pump(const Duration(hours: 7));
      expect(tester.takeException(), isNull);
    });
  });
}

bool _hasFocus(WidgetTester tester, Finder field) {
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).focusNode.hasFocus;
}
