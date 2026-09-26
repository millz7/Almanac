import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:almanac/core/environment/weather_condition.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cookbook/presentation/widgets/recipe_card.dart';
import 'package:almanac/features/cycle/application/cycle_providers.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/environment/presentation/moon_screen.dart';
import 'package:almanac/features/environment/presentation/tide_screen.dart';
import 'package:almanac/features/environment/presentation/tide_text.dart';
import 'package:almanac/features/environment/presentation/widgets/environment_artwork_view.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/meditation/presentation/meditation_screen.dart';
import 'package:almanac/features/meditation/presentation/widgets/moon_context_card.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:almanac/features/wheel/presentation/festival_detail_page.dart';
import 'package:almanac/features/yoga/presentation/widgets/cycle_context_card.dart';
import 'package:almanac/features/yoga/presentation/yoga_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// The last app-level look before the app goes on a real phone: every
/// destination and a representative inner page of each, the Environment
/// in every state it can be in, every shared context at once, features
/// switched on and off in quick succession, and a cold start with parts
/// of the world missing.
void main() {
  setUpAll(useTimeZoneDatabase);

  /// Four days before Beltane in the north, 13:00 in London.
  final beltaneEve = DateTime.utc(2026, 4, 27, 12);
  final everything = FeatureRegistry.optional.map((f) => f.id).toSet();
  const located = LocationAvailable(TestLocations.london);

  FakeWeatherService weather({
    WeatherCondition condition = WeatherCondition.clear,
  }) => FakeWeatherService(
    result: ({required location, required timeZone, required now}) =>
        testWeatherSnapshot(
          location: location,
          obtainedAt: now,
          condition: condition,
        ),
  );

  FakeTideService tides() => FakeTideService(
    result: ({required location, required timeZone, required now}) =>
        TideFetchData(testTideSnapshot(location: location, obtainedAt: now)),
  );

  FakeWeatherService offlineWeather() =>
      FakeWeatherService(failWith: const SocketException('offline'));
  FakeTideService offlineTides() =>
      FakeTideService(failWith: const SocketException('offline'));

  late ProviderContainer container;

  Future<void> open(
    WidgetTester tester,
    List<Override> overrides, {
    Size surface = const Size(834, 2400),
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  List<FeatureId> tabs(WidgetTester tester) => tester
      .widget<AlmanacNavigationBar>(find.byType(AlmanacNavigationBar))
      .destinations
      .map((f) => f.id)
      .toList();

  Finder navItem(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Future<void> press(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  Future<bool> back(WidgetTester tester) async {
    final kept = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    return kept;
  }

  group('full route smoke test', () {
    testWidgets('every destination, a representative inner page of each, '
        'and Back out of every one', (tester) async {
      final recipes = InMemoryOwnRecipeStore(
        const OwnRecipes([OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack')]),
      );
      final garden = InMemoryGardenStore(
        MyGarden([
          GardenPlant(
            instanceId: 'mint',
            plantId: 'mint',
            addedOn: const CalendarDate(2026, 3, 1),
            state: EstablishmentState.established,
          ),
        ]),
      );
      final nature = InMemoryNatureLogStore(
        NatureLog([
          NatureObservation(
            instanceId: 'obs-0-2026-04-20',
            date: const CalendarDate(2026, 4, 20),
            category: NatureCategory.bird,
            label: 'A heron',
            order: 0,
          ),
        ]),
      );
      final handle = tester.ensureSemantics();
      await open(
        tester,
        environmentOverrides(
          now: beltaneEve,
          features: everything,
          locationState: located,
          weatherService: weather(),
          tideService: tides(),
          ownRecipeStore: recipes,
          gardenStore: garden,
          natureLogStore: nature,
        ),
      );

      Future<void> via(FeatureDefinition feature) async {
        await press(tester, navItem(feature.name));
        expect(location(), feature.route, reason: feature.name);
        expect(tester.takeException(), isNull, reason: feature.name);
        expect(tabs(tester), hasLength(9), reason: feature.name);
      }

      Future<void> backTo(String route, String what) async {
        expect(await back(tester), isTrue, reason: what);
        expect(location(), route, reason: what);
        expect(tester.takeException(), isNull, reason: what);
      }

      // Environment → Moon and Tides detail.
      // Both are pushed over the Environment, as the fact strip does.
      await press(tester, find.text('Moon'));
      expect(find.byType(MoonScreen), findsOneWidget);
      await backTo(kEnvironmentRoute, 'Moon');
      expect(find.byType(MoonScreen), findsNothing);
      await press(tester, find.text(TideText.title));
      expect(find.byType(TideScreen), findsOneWidget);
      await backTo(kEnvironmentRoute, 'Tides');
      expect(find.byType(TideScreen), findsNothing);

      String route(FeatureId id) => FeatureRegistry.byId(id).route;

      await via(FeatureRegistry.byId(FeatureId.meditation));
      await press(tester, find.widgetWithText(ChoiceCard, 'Sleep'));
      expect(find.bySemanticsLabel('Begin'), findsOneWidget);
      await backTo(route(FeatureId.meditation), 'a meditation practice');
      expect(find.widgetWithText(ChoiceCard, 'Sleep'), findsOneWidget);

      await via(FeatureRegistry.byId(FeatureId.yoga));
      await press(tester, find.widgetWithText(ChoiceCard, 'Morning'));
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
      await backTo(route(FeatureId.yoga), 'a yoga practice');

      await via(FeatureRegistry.byId(FeatureId.chakras));
      await press(tester, find.bySemanticsLabel(RegExp(r'^Root chakra\.')));
      expect(find.text('Back to the seven'), findsOneWidget);
      await backTo(route(FeatureId.chakras), 'a chakra');

      await via(FeatureRegistry.byId(FeatureId.cycle));
      for (final page in [CycleText.calendar, CycleText.syncing]) {
        await press(tester, find.text(page));
        expect(find.text(CycleText.back), findsOneWidget, reason: page);
        await backTo(route(FeatureId.cycle), page);
      }

      await via(FeatureRegistry.byId(FeatureId.cookbook));
      await press(tester, find.byType(RecipeCard));
      expect(find.text(CookbookText.back), findsOneWidget);
      await backTo(route(FeatureId.cookbook), 'a catalogue recipe');
      await press(tester, find.text('Flapjack'));
      expect(find.text(CookbookText.editRecipe), findsOneWidget);
      await backTo(route(FeatureId.cookbook), 'an own recipe');

      await via(FeatureRegistry.byId(FeatureId.garden));
      await press(tester, find.bySemanticsLabel(RegExp(r'^My Garden\.')));
      await press(tester, find.bySemanticsLabel(RegExp(r'^Mint\.')));
      expect(find.text('What to know'), findsWidgets);
      await backTo(route(FeatureId.garden), 'a garden plant');
      await backTo(route(FeatureId.garden), 'My Garden');

      await via(FeatureRegistry.byId(FeatureId.natureLog));
      await press(
        tester,
        find.bySemanticsLabel(RegExp('^${NatureLogText.myObservations}\\.')),
      );
      await press(tester, find.bySemanticsLabel(RegExp(r'^A heron[.,]')));
      expect(
        find.widgetWithText(ElevatedButton, NatureLogText.saveChanges),
        findsOneWidget,
      );
      // Untouched, so Back asks nothing.
      await backTo(route(FeatureId.natureLog), 'an observation');
      expect(find.text(UnsavedChanges.title), findsNothing);

      await via(FeatureRegistry.byId(FeatureId.wheel));
      await press(tester, find.text('Yule'));
      expect(find.byType(FestivalDetailPage), findsOneWidget);
      await backTo(route(FeatureId.wheel), 'a festival');

      // And home again, from the bar.
      await via(FeatureRegistry.environment);
      expect(find.text('TODAY'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Environment readiness matrix', () {
    Future<void> openEnvironment(
      WidgetTester tester, {
      LocationState? locationState = located,
      FakeWeatherService? weatherService,
      FakeTideService? tideService,
      Set<FeatureId> features = const {FeatureId.wheel},
      SolarDayKind? polar,
      DateTime? now,
    }) async {
      final polarNow = now ?? beltaneEve;
      await open(
        tester,
        environmentOverrides(
          now: polarNow,
          timeZone: polar == null ? null : TestTimeZones.tromso,
          locationState: polar == null
              ? locationState
              : const LocationAvailable(TestLocations.tromso),
          solarService: polar != null
              ? FakeSolarService(kind: polar)
              : locationState == null
              ? FakeSolarService()
              : null,
          weatherService: weatherService ?? weather(),
          tideService: tideService ?? tides(),
          features: features,
        ),
      );
    }

    void artworkResolves(WidgetTester tester) {
      final art = tester.widget<EnvironmentArtworkView>(
        find.byType(EnvironmentArtworkView),
      );
      expect(art.asset, isNotEmpty);
    }

    const invitation =
        'Connect location to see sunrise, sunset, weather and tides where '
        'you are.';

    testWidgets('A: location and network', (tester) async {
      await openEnvironment(tester);
      artworkResolves(tester);
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('Moon'), findsOneWidget);
      expect(find.text(TideText.title), findsOneWidget);
      expect(find.text(TideText.locationNeeded), findsNothing);
      expect(find.text(TideText.notAvailableNow), findsNothing);
      expect(find.textContaining('afternoon'), findsOneWidget);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.text(invitation), findsNothing);
    });

    testWidgets('B: weather fails — TODAY still reads', (tester) async {
      await openEnvironment(tester, weatherService: offlineWeather());
      artworkResolves(tester);
      expect(find.textContaining('afternoon'), findsNothing);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.text(TideText.title), findsOneWidget);
      expect(find.text(invitation), findsNothing);
    });

    testWidgets('C: tides fail — said quietly, nothing else lost', (
      tester,
    ) async {
      await openEnvironment(tester, tideService: offlineTides());
      expect(find.text(TideText.notAvailableNow), findsOneWidget);
      expect(find.textContaining('afternoon'), findsOneWidget);
      expect(find.text('Sunrise'), findsOneWidget);
    });

    testWidgets('D: no location — one invitation, no made-up times', (
      tester,
    ) async {
      await openEnvironment(tester, locationState: null);
      artworkResolves(tester);
      expect(find.text('Sunrise'), findsNothing);
      expect(find.text(TideText.locationNeeded), findsOneWidget);
      expect(find.text(invitation), findsOneWidget);
      expect(find.textContaining('arrives'), findsOneWidget);
      expect(find.text('Moon'), findsOneWidget);
    });

    testWidgets('E: Wheel on, festival approaching', (tester) async {
      await openEnvironment(tester);
      expect(find.text('Beltane is approaching · 4 days'), findsOneWidget);
      expect(find.text('See Beltane'), findsOneWidget);
    });

    testWidgets('F: Wheel off — no festival anywhere', (tester) async {
      await openEnvironment(tester, features: const {});
      expect(find.textContaining('Beltane'), findsNothing);
    });

    testWidgets('G: polar day', (tester) async {
      await openEnvironment(
        tester,
        polar: SolarDayKind.sunNeverSets,
        now: DateTime.utc(2026, 6, 25, 12),
      );
      artworkResolves(tester);
      expect(
        find.text('The sun stays above the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('Sunrise'), findsNothing);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text(invitation), findsNothing);
    });

    testWidgets('H: polar night', (tester) async {
      await openEnvironment(
        tester,
        polar: SolarDayKind.sunNeverRises,
        now: DateTime.utc(2026, 1, 5, 12),
      );
      artworkResolves(tester);
      expect(
        find.text('The sun stays below the horizon all day where you are.'),
        findsOneWidget,
      );
      expect(find.text('Sunset'), findsNothing);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text(invitation), findsNothing);
    });
  });

  group('every shared context at once', () {
    testWidgets('weather, tides, moon, cycle, festival and garden together: '
        'nothing throws, and the density limits hold', (tester) async {
      final cycle = InMemoryCycleStore(
        CycleData(
          records: [
            CycleDayRecord(
              date: const CalendarDate(2026, 4, 20),
              level: BleedingLevel.bleeding,
              isPeriodStart: true,
            ),
          ],
        ),
      );
      final garden = InMemoryGardenStore(
        MyGarden([
          GardenPlant(
            instanceId: 'rhubarb',
            plantId: 'rhubarb',
            addedOn: const CalendarDate(2025, 3, 1),
            state: EstablishmentState.established,
          ),
        ]),
      );
      await open(
        tester,
        environmentOverrides(
          now: beltaneEve,
          features: everything,
          locationState: located,
          weatherService: weather(condition: WeatherCondition.rain),
          tideService: tides(),
          cycleStore: cycle,
          gardenStore: garden,
        ),
      );

      for (final id in [
        FeatureId.environment,
        FeatureId.meditation,
        FeatureId.yoga,
        FeatureId.cookbook,
        FeatureId.garden,
        FeatureId.natureLog,
      ]) {
        container.read(routerProvider).go(FeatureRegistry.byId(id).route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: id.name);
        if (id == FeatureId.meditation) {
          final cards = tester
              .widgetList<MoonContextCard>(find.byType(MoonContextCard))
              .toList();
          expect(cards.length, lessThanOrEqualTo(kMaxMeditationContexts));
          expect(cards, isNotEmpty);
        }
        if (id == FeatureId.yoga) {
          final cards = tester
              .widgetList<CycleContextCard>(find.byType(CycleContextCard))
              .toList();
          expect(cards.length, lessThanOrEqualTo(kMaxYogaContexts));
          // The weather yields rather than repeat a practice already
          // suggested (cycle and festival may agree with each other —
          // two separate contexts, by design).
          final weatherCard = cards.where((c) => c.heading == 'Weather today');
          final others = [
            for (final c in cards)
              if (c.heading != 'Weather today') c.practice.id,
          ];
          for (final c in weatherCard) {
            expect(others, isNot(contains(c.practice.id)));
          }
        }
      }
    });
  });

  group('switching features on and off in quick succession', () {
    testWidgets('including the open tab and the Wheel: Environment stays, '
        'no duplicates, and the bar follows the stored choice', (tester) async {
      final recipes = InMemoryOwnRecipeStore(
        const OwnRecipes([OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack')]),
      );
      await open(
        tester,
        environmentOverrides(features: everything, ownRecipeStore: recipes),
      );
      final settings = container.read(userSettingsProvider.notifier);

      container
          .read(routerProvider)
          .go(FeatureRegistry.byId(FeatureId.wheel).route);
      await tester.pumpAndSettle();

      for (final (id, on) in [
        (FeatureId.wheel, false),
        (FeatureId.cookbook, false),
        (FeatureId.yoga, false),
        (FeatureId.wheel, true),
        (FeatureId.cookbook, true),
        (FeatureId.garden, false),
        (FeatureId.garden, true),
        (FeatureId.yoga, true),
        (FeatureId.cycle, false),
      ]) {
        await settings.setFeatureChosen(id, on);
        await tester.pumpAndSettle();
        final bar = tabs(tester);
        expect(bar.first, FeatureId.environment);
        expect(bar.toSet().length, bar.length, reason: 'duplicate tab');
        expect(bar.toSet(), {
          FeatureId.environment,
          ...container.read(userSettingsProvider).features,
        });
        expect(tester.takeException(), isNull);
      }
      // The Wheel was open when it was switched off: back to the
      // Environment, and it stays a valid place to be.
      expect(location(), kEnvironmentRoute);
      // Holidays is back, and opens.
      await press(tester, navItem('Wheel of the Year'));
      expect(location(), FeatureRegistry.byId(FeatureId.wheel).route);
      // The Cookbook's data survived its time away.
      expect((await recipes.read()).length, 1);
    });
  });

  group('bottom navigation, to a screen reader', () {
    testWidgets('full names, whatever the short label, and the open tab is '
        'announced as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await open(
        tester,
        environmentOverrides(features: everything),
        // Wide enough for the short labels, as on a large phone held
        // sideways or a tablet.
        surface: const Size(760, 900),
      );
      final strip = find.descendant(
        of: find.byType(AlmanacNavigationBar),
        matching: find.byType(Scrollable),
      );

      for (final feature in FeatureRegistry.all) {
        if (strip.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            navItem(feature.name),
            80,
            scrollable: strip,
          );
        }
        expect(navItem(feature.name), findsOneWidget, reason: feature.name);
      }
      // Short on screen, full to a screen reader.
      for (final short in ['Env', 'Med', 'Chak', 'Cook', 'Hols']) {
        expect(find.text(short), findsWidgets, reason: short);
      }

      await press(tester, navItem('Wheel of the Year'));
      expect(
        tester.getSemantics(navItem('Wheel of the Year')),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(navItem('Environment')),
        isSemantics(isSelected: false),
      );
      handle.dispose();
    });
  });

  group('a cold start with parts of the world missing', () {
    for (final (name, overrides) in [
      (
        'weather unavailable',
        () => environmentOverrides(
          features: everything,
          locationState: located,
          weatherService: offlineWeather(),
          tideService: tides(),
        ),
      ),
      (
        'tides unavailable',
        () => environmentOverrides(
          features: everything,
          locationState: located,
          weatherService: weather(),
          tideService: offlineTides(),
        ),
      ),
      (
        'no network at all',
        () => environmentOverrides(
          features: everything,
          locationState: located,
          weatherService: offlineWeather(),
          tideService: offlineTides(),
        ),
      ),
      (
        'location denied',
        () => environmentOverrides(
          features: everything,
          locationState: const LocationPermissionDenied(),
          weatherService: weather(),
          tideService: tides(),
        ),
      ),
      (
        'a feature store that throws on every call',
        () => environmentOverrides(
          features: everything,
          gardenStore: _BrokenGardenStore(),
        ),
      ),
    ]) {
      testWidgets('$name: the Environment is still usable', (tester) async {
        await open(tester, overrides());
        expect(tester.takeException(), isNull);
        expect(location(), kEnvironmentRoute);
        expect(find.text('TODAY'), findsOneWidget);
        expect(tabs(tester), hasLength(9));
        // And every feature still opens.
        for (final feature in FeatureRegistry.optional) {
          container.read(routerProvider).go(feature.route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: feature.name);
        }
      });
    }
  });

  group('nothing to say, anywhere', () {
    testWidgets('no location, weather, tides, Wheel or Cycle, and empty '
        'Garden and Nature Log: everything still works', (tester) async {
      final remaining = {...everything}
        ..remove(FeatureId.wheel)
        ..remove(FeatureId.cycle);
      final w = offlineWeather();
      final t = offlineTides();
      await open(
        tester,
        environmentOverrides(
          features: remaining,
          solarService: FakeSolarService(),
          weatherService: w,
          tideService: t,
        ),
      );
      for (final feature in [
        FeatureRegistry.environment,
        for (final id in remaining) FeatureRegistry.byId(id),
      ]) {
        container.read(routerProvider).go(feature.route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: feature.name);
        expect(location(), feature.route, reason: feature.name);
      }
      expect(w.fetchCount, 0);
      expect(t.fetchCount, 0);
    });
  });
}

class _BrokenGardenStore implements GardenStore {
  @override
  Future<MyGarden> read() async => throw StateError('broken');
  @override
  Future<void> write(MyGarden garden) async => throw StateError('broken');
  @override
  Future<void> deleteAll() async => throw StateError('broken');
}
