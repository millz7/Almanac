import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/garden/presentation/garden_text.dart';
import 'package:almanac/features/garden/presentation/widgets/plant_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Mid-February: the middle of the tomato harvest in temperate NZ.
final february = DateTime.utc(2026, 2, 15, 12);

/// Mid-July: nothing to harvest, and the month apples are pruned.
final july = DateTime.utc(2026, 7, 15, 12);

const wellington = GeoLocation(latitude: -41.29, longitude: 174.78);

void main() {
  setUpAll(useTimeZoneDatabase);

  final back = find.widgetWithText(TextButton, GardenText.back);
  final addToMyGarden = find.widgetWithText(
    ElevatedButton,
    GardenText.addToMyGarden,
  );
  final addExisting = find.widgetWithText(
    ElevatedButton,
    GardenText.addExisting,
  );

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Finder chapter(String title) => find.bySemanticsLabel(RegExp('^$title\\.'));

  Future<ProviderContainer> openGarden(
    WidgetTester tester, {
    DateTime? now,
    GardenStore? store,
    LocationState? locationState = const LocationAvailable(wellington),
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 2600),
    Set<FeatureId> features = const {FeatureId.garden},
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
      overrides: environmentOverrides(
        now: now ?? february,
        hemisphere: Hemisphere.southern,
        locationState: locationState,
        features: features,
        gardenStore: store ?? InMemoryGardenStore(),
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlmanacApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(navTab('Garden'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// Back to the six chapters, however deep in the Garden we are. The
  /// precision note is only on the landing page, so it is how the test
  /// knows it has arrived.
  Future<void> toLanding(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      if (find.text(GardenText.precisionNote).evaluate().isNotEmpty) return;
      await press(tester, back);
    }
    expect(find.text(GardenText.precisionNote), findsOneWidget);
  }

  /// Adds a plant through the real screens, the way somebody with an
  /// established garden would.
  Future<void> addExistingPlant(
    WidgetTester tester,
    String name, {
    EstablishmentState state = EstablishmentState.established,
  }) async {
    await press(tester, chapter(GardenText.myGarden));
    await press(tester, addExisting);
    await press(tester, find.bySemanticsLabel(RegExp('^$name\\.')));
    await press(tester, addToMyGarden);
    await press(tester, find.text(state.question));
  }

  group('the landing page', () {
    testWidgets('is six calm chapters and nothing else', (tester) async {
      await openGarden(tester);

      for (final title in [
        'Sow',
        'Plant',
        'Tend',
        'Harvest',
        'Prune',
        GardenText.myGarden,
      ]) {
        expect(chapter(title), findsOneWidget, reason: title);
      }
      // No plant lists on the first page.
      expect(find.byType(PlantMark), findsNothing);
    });

    testWidgets('says where and when it is talking about', (tester) async {
      await openGarden(tester);

      expect(find.text('February · Temperate New Zealand'), findsOneWidget);
      expect(find.text(GardenText.precisionNote), findsOneWidget);
      expect(find.text(GardenText.noLocationNote), findsNothing);
    });

    testWidgets('and says when it is working without a location', (
      tester,
    ) async {
      await openGarden(tester, locationState: const LocationPermissionDenied());

      expect(
        find.text('February · General Southern Hemisphere guide'),
        findsOneWidget,
      );
      expect(find.text(GardenText.noLocationNote), findsOneWidget);
    });

    testWidgets('each chapter opens its own page', (tester) async {
      await openGarden(tester);

      for (final action in GardenAction.values) {
        await press(tester, chapter(action.label));
        expect(
          find.textContaining(GardenText.intro(action)),
          findsOneWidget,
          reason: action.label,
        );
        await press(tester, back);
      }

      await press(tester, chapter(GardenText.myGarden));
      expect(find.text(GardenText.gardenEmpty), findsOneWidget);
    });
  });

  group('Sow is discovery', () {
    testWidgets('it groups the book by category', (tester) async {
      await openGarden(tester, now: DateTime.utc(2026, 10, 15, 12));
      await press(tester, chapter('Sow'));

      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Flowers'), findsOneWidget);
      // Lettuce is sown in October; broad beans are not.
      expect(find.bySemanticsLabel(RegExp('^Lettuce\\.')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Broad bean\\.')), findsNothing);
    });

    testWidgets('it says where the seed goes', (tester) async {
      await openGarden(tester, now: DateTime.utc(2026, 9, 15, 12));
      await press(tester, chapter('Sow'));

      expect(find.text('Sow under cover'), findsWidgets);
      expect(find.text('Sow outdoors'), findsWidgets);
      expect(
        find.bySemanticsLabel('Tomato. Vegetable. Sow under cover'),
        findsOneWidget,
      );
    });

    testWidgets('it does not need My Garden to have anything in it', (
      tester,
    ) async {
      await openGarden(tester, now: DateTime.utc(2026, 10, 15, 12));
      await press(tester, chapter('Sow'));

      expect(find.byType(PlantMark), findsWidgets);
    });
  });

  group('adding a plant', () {
    testWidgets('from Sow records it as sown today', (tester) async {
      final container = await openGarden(
        tester,
        now: DateTime.utc(2026, 10, 15, 12),
      );
      await press(tester, chapter('Sow'));
      await press(tester, find.bySemanticsLabel(RegExp('^Lettuce\\.')));
      await press(tester, addToMyGarden);

      // Quietly acknowledged, and no celebration.
      expect(find.text(GardenText.added), findsOneWidget);

      final entry = container.read(myGardenProvider).value!.find('lettuce')!;
      expect(entry.state, EstablishmentState.sown);
      expect(entry.sownOn, container.read(todayProvider));
    });

    testWidgets('and My Garden shows it straight away', (tester) async {
      await openGarden(tester, now: DateTime.utc(2026, 10, 15, 12));
      await press(tester, chapter('Sow'));
      await press(tester, find.bySemanticsLabel(RegExp('^Lettuce\\.')));
      await press(tester, addToMyGarden);
      await toLanding(tester);
      await press(tester, chapter(GardenText.myGarden));

      expect(find.text('Lettuce'), findsOneWidget);
      expect(find.bySemanticsLabel('Lettuce. Sown.'), findsOneWidget);
    });

    testWidgets('something already growing is asked one question', (
      tester,
    ) async {
      final container = await openGarden(tester);
      await press(tester, chapter(GardenText.myGarden));
      await press(tester, addExisting);
      await press(tester, find.bySemanticsLabel(RegExp('^Apple\\.')));
      await press(tester, addToMyGarden);

      expect(find.text(GardenText.howIsItGrowing), findsOneWidget);
      for (final state in EstablishmentState.values) {
        expect(find.text(state.question), findsOneWidget);
      }

      await press(tester, find.text(EstablishmentState.established.question));

      final entry = container.read(myGardenProvider).value!.find('apple')!;
      expect(entry.state, EstablishmentState.established);
      // And no date was invented for it.
      expect(entry.sownOn, isNull);
      expect(entry.plantedOn, isNull);
    });
  });

  group('Harvest is personal', () {
    testWidgets('an empty garden says so, and offers no substitute', (
      tester,
    ) async {
      await openGarden(tester);
      await press(tester, chapter('Harvest'));

      expect(find.text(GardenText.nothingToHarvest), findsOneWidget);
      expect(find.byType(PlantMark), findsNothing);
      // February is the middle of the tomato harvest generally — and
      // tomatoes are still not offered, because nobody grows any.
      expect(find.text('Tomato'), findsNothing);
    });

    testWidgets('adding tomatoes is what makes tomatoes appear', (
      tester,
    ) async {
      await openGarden(tester);

      await press(tester, chapter('Harvest'));
      expect(find.text('Tomato'), findsNothing);
      await toLanding(tester);

      await addExistingPlant(tester, 'Tomato');
      await toLanding(tester);
      await press(tester, chapter('Harvest'));

      expect(find.text('Tomato'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Tomato. Vegetable. May be ready to harvest.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('${GardenText.relevantBecause}: February'),
        findsOneWidget,
      );
    });

    testWidgets('and the month is what makes them go away again', (
      tester,
    ) async {
      final store = InMemoryGardenStore();
      await openGarden(tester, store: store);
      await addExistingPlant(tester, 'Tomato');

      // The same garden, five months later.
      await openGarden(tester, store: store, now: july);
      await press(tester, chapter('Harvest'));

      expect(find.text(GardenText.nothingToHarvest), findsOneWidget);

      // Out of the recommendation, still in the garden.
      await press(tester, back);
      await press(tester, chapter(GardenText.myGarden));
      expect(find.text('Tomato'), findsOneWidget);
    });
  });

  group('Tend and Prune are personal too', () {
    testWidgets('Tend explains why each job is showing', (tester) async {
      await openGarden(tester, now: DateTime.utc(2026, 12, 15, 12));
      await addExistingPlant(
        tester,
        'Tomato',
        state: EstablishmentState.seedling,
      );
      await toLanding(tester);
      await press(tester, chapter('Tend'));

      // In December a tomato wants two things — staking and feeding —
      // and each is its own line rather than a vague "tend your
      // tomatoes".
      expect(find.text('Tomato'), findsNWidgets(2));
      expect(find.text('Support.'), findsOneWidget);
      expect(find.text('Feed.'), findsOneWidget);
      expect(
        find.textContaining('${GardenText.relevantBecause}: December'),
        findsNWidgets(2),
      );
    });

    testWidgets('Prune shows an apple in winter and nothing in summer', (
      tester,
    ) async {
      final store = InMemoryGardenStore();
      await openGarden(tester, store: store, now: july);
      await addExistingPlant(tester, 'Apple');
      await toLanding(tester);
      await press(tester, chapter('Prune'));

      expect(find.text('Apple'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Apple. Fruit. Typically pruned around this time.',
        ),
        findsOneWidget,
      );

      await openGarden(tester, store: store, now: february);
      await press(tester, chapter('Prune'));
      expect(find.text(GardenText.nothingToPrune), findsOneWidget);
    });
  });

  group('a plant page', () {
    testWidgets('leads with what to know and the section you came for', (
      tester,
    ) async {
      await openGarden(tester, now: DateTime.utc(2026, 9, 15, 12));
      await press(tester, chapter('Sow'));
      await press(tester, find.bySemanticsLabel(RegExp('^Tomato\\.')));

      expect(find.text('Tomato'), findsWidgets);
      expect(find.text(GardenText.whatToKnow), findsOneWidget);
      // Sow first, because that is the chapter it was opened from.
      expect(
        tester.getTopLeft(find.text('Sow')).dy,
        lessThan(tester.getTopLeft(find.text('Harvest')).dy),
      );
      expect(find.text('August to October'), findsOneWidget);
    });

    testWidgets('a pruning section always carries its caution', (tester) async {
      await openGarden(tester, now: july);
      await press(tester, chapter(GardenText.myGarden));
      await press(tester, addExisting);
      await press(tester, find.bySemanticsLabel(RegExp('^Peach\\.')));

      expect(find.textContaining('silver leaf'), findsOneWidget);
    });

    testWidgets('an entry can be edited and removed', (tester) async {
      final container = await openGarden(tester);
      await addExistingPlant(tester, 'Mint');

      // Change how far along it is.
      await press(
        tester,
        find.bySemanticsLabel(EstablishmentState.seedling.label),
      );
      expect(
        container.read(myGardenProvider).value!.find('mint')!.state,
        EstablishmentState.seedling,
      );

      // Removing asks first, and says what it does and does not do.
      await press(tester, find.widgetWithText(TextButton, GardenText.remove));
      expect(find.text('Remove mint from My Garden?'), findsOneWidget);
      expect(find.text(GardenText.removeBody), findsOneWidget);

      await press(tester, find.widgetWithText(TextButton, GardenText.keep));
      expect(container.read(myGardenProvider).value!.contains('mint'), isTrue);

      await press(tester, find.widgetWithText(TextButton, GardenText.remove));
      await press(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, GardenText.remove),
        ),
      );
      expect(container.read(myGardenProvider).value!.contains('mint'), isFalse);
    });
  });

  group('My Garden', () {
    testWidgets('empty, it asks to be told what is growing', (tester) async {
      await openGarden(tester);
      await press(tester, chapter(GardenText.myGarden));

      expect(find.text(GardenText.gardenEmpty), findsOneWidget);
      expect(addExisting, findsOneWidget);
      expect(find.text(GardenText.privacyNote), findsNothing);
    });

    testWidgets('it groups what you have by category', (tester) async {
      await openGarden(tester);
      await addExistingPlant(tester, 'Apple');
      await toLanding(tester);
      await addExistingPlant(tester, 'Mint');
      await toLanding(tester);
      await press(tester, chapter(GardenText.myGarden));

      expect(find.text('Fruit'), findsOneWidget);
      expect(find.text('Herbs'), findsOneWidget);
      expect(find.text(GardenText.privacyNote), findsOneWidget);
    });

    testWidgets('it can all be cleared, after being asked', (tester) async {
      final store = InMemoryGardenStore();
      final container = await openGarden(tester, store: store);
      await addExistingPlant(tester, 'Apple');
      await toLanding(tester);
      await press(tester, chapter(GardenText.myGarden));

      await press(tester, find.widgetWithText(TextButton, GardenText.clearAll));
      expect(find.text(GardenText.clearTitle), findsOneWidget);
      expect(find.text(GardenText.clearBody), findsOneWidget);

      await press(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, GardenText.remove),
        ),
      );

      expect(container.read(myGardenProvider).value!.isEmpty, isTrue);
      expect((await store.read()).isEmpty, isTrue);
      expect(find.text(GardenText.gardenEmpty), findsOneWidget);
    });

    testWidgets('it survives a restart', (tester) async {
      final store = InMemoryGardenStore();
      await openGarden(tester, store: store);
      await addExistingPlant(tester, 'Apple');

      // A second launch over the same store.
      await openGarden(tester, store: store);
      await press(tester, chapter(GardenText.myGarden));

      expect(find.bySemanticsLabel('Apple. Established.'), findsOneWidget);
    });
  });

  group('living in the Almanac', () {
    testWidgets('the Almanac is reachable from every page', (tester) async {
      await openGarden(tester);
      expect(find.byType(AlmanacButton), findsOneWidget);

      await press(tester, chapter('Sow'));
      expect(find.byType(AlmanacButton), findsOneWidget);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('nothing is left running when you leave', (tester) async {
      await openGarden(
        tester,
        features: {FeatureId.garden, FeatureId.natureLog},
      );
      await press(tester, chapter('Sow'));

      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(navTab('Nature Log'));
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byType(PlantMark), findsNothing);
    });
  });

  group('reduced motion', () {
    testWidgets('the marks are simply already drawn', (tester) async {
      await openGarden(
        tester,
        now: DateTime.utc(2026, 10, 15, 12),
        reducedMotion: true,
      );
      await press(tester, chapter('Sow'));

      for (final mark in tester.widgetList<PlantMark>(find.byType(PlantMark))) {
        expect(mark.growth, 1);
      }
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('and everything still works', (tester) async {
      final container = await openGarden(tester, reducedMotion: true);
      await addExistingPlant(tester, 'Apple');

      expect(container.read(myGardenProvider).value!.contains('apple'), isTrue);
    });
  });

  group('accessibility', () {
    testWidgets('a chapter says what it is for', (tester) async {
      await openGarden(tester);

      expect(
        find.bySemanticsLabel('Harvest. What in your garden may be ready.'),
        findsOneWidget,
      );
    });

    testWidgets('a plant says its name, its category and what is relevant', (
      tester,
    ) async {
      await openGarden(tester, now: DateTime.utc(2026, 10, 15, 12));
      await press(tester, chapter('Sow'));

      expect(
        find.bySemanticsLabel('Pea. Vegetable. Sow outdoors'),
        findsOneWidget,
      );
    });

    testWidgets('the drawn marks say nothing', (tester) async {
      await openGarden(tester, now: DateTime.utc(2026, 10, 15, 12));
      await press(tester, chapter('Sow'));

      expect(
        find.descendant(
          of: find.byType(PlantMark),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openGarden(tester);

      for (final action in GardenAction.values) {
        expect(
          tester.getSize(chapter(action.label)).height,
          greaterThanOrEqualTo(48),
          reason: action.label,
        );
      }

      await press(tester, chapter(GardenText.myGarden));
      expect(tester.getSize(addExisting).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openGarden(
        tester,
        now: DateTime.utc(2026, 10, 15, 12),
        textScale: 2,
      );

      // Chapter names are not shortened.
      for (final action in GardenAction.values) {
        expect(find.text(action.label), findsWidgets, reason: action.label);
      }

      await press(tester, chapter('Sow'));
      expect(find.text('Vegetables'), findsOneWidget);
      // And a long plant name wraps rather than truncating.
      expect(find.bySemanticsLabel(RegExp('^Broad bean\\.')), findsNothing);
      expect(find.text('Lettuce'), findsOneWidget);
    });
  });
}
