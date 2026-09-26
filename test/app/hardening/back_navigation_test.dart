import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/immersion.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/chakras/domain/chakras.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cookbook/presentation/widgets/recipe_card.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/garden/domain/gardening_rule.dart';
import 'package:almanac/features/garden/presentation/garden_text.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/nature_log/application/nature_log_providers.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:almanac/features/wheel/presentation/festival_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Android's system Back, across every detail flow in the app.
///
/// The rule: Back moves up one logical level. It never closes the app
/// from an inner page, never throws typed words away without asking,
/// never deletes anything, and a dialog on top is closed first.
///
/// `handlePopRoute` is exactly what the engine calls when the Back key
/// is pressed. It returns false only when nothing in the app wanted the
/// Back — which on a phone means the app goes to the background.
void main() {
  setUpAll(useTimeZoneDatabase);

  final everything = FeatureRegistry.optional.map((f) => f.id).toSet();

  late ProviderContainer container;

  Future<void> open(
    WidgetTester tester, {
    OwnRecipeStore? recipes,
    NatureLogStore? nature,
  }) async {
    tester.view.physicalSize = const Size(430, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
      overrides: environmentOverrides(
        features: everything,
        ownRecipeStore: recipes,
        natureLogStore: nature,
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
  }

  Future<void> go(WidgetTester tester, String route) async {
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  String routeOf(FeatureId id) => FeatureRegistry.byId(id).route;

  /// Presses system Back. Returns whether the app kept it.
  Future<bool> back(WidgetTester tester) async {
    final kept = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    return kept;
  }

  String location() => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  Future<void> press(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  group('routes', () {
    testWidgets('Moon detail: Back returns to the Environment, once', (
      tester,
    ) async {
      await open(tester);
      await go(tester, kMoonRoute);
      expect(location(), kMoonRoute);

      expect(await back(tester), isTrue);
      expect(location(), kEnvironmentRoute);
      // Nothing duplicated underneath: the next Back leaves the app.
      expect(await back(tester), isFalse);
    });

    testWidgets('Tides detail: Back returns to the Environment', (
      tester,
    ) async {
      await open(tester);
      await go(tester, kTidesRoute);

      expect(await back(tester), isTrue);
      expect(location(), kEnvironmentRoute);
    });
  });

  group('inner pages never close the app', () {
    testWidgets('Cookbook: a catalogue recipe goes back to the collection', (
      tester,
    ) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.cookbook));
      await press(tester, find.byType(RecipeCard));
      expect(find.text(CookbookText.back), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.text(CookbookText.back), findsNothing);
      expect(find.byType(RecipeCard), findsWidgets);
      expect(location(), routeOf(FeatureId.cookbook));
    });

    testWidgets('Cookbook: one of your recipes goes back to the collection', (
      tester,
    ) async {
      final store = InMemoryOwnRecipeStore(
        const OwnRecipes([OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack')]),
      );
      await open(tester, recipes: store);
      await go(tester, routeOf(FeatureId.cookbook));
      await press(tester, find.text('Flapjack'));
      expect(find.text(CookbookText.editRecipe), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.text(CookbookText.editRecipe), findsNothing);
      expect((await store.read()).length, 1);
    });

    testWidgets('Chakras: reflection → chakra → the seven', (tester) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.chakras));
      await press(
        tester,
        find.bySemanticsLabel(ChakraCatalogue.heart.semanticLabel),
      );
      await press(tester, find.text('Reflect'));
      expect(find.text('Not now'), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.text('Back to the seven'), findsOneWidget);
      expect(await back(tester), isTrue);
      expect(find.text('Back to the seven'), findsNothing);
      expect(
        find.bySemanticsLabel(ChakraCatalogue.heart.semanticLabel),
        findsOneWidget,
      );
      expect(await back(tester), isFalse);
    });

    testWidgets('Wheel: a festival goes back to the wheel', (tester) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.wheel));
      await press(tester, find.text('Yule'));
      expect(find.byType(FestivalDetailPage), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.byType(FestivalDetailPage), findsNothing);
      expect(location(), routeOf(FeatureId.wheel));
    });

    testWidgets('Cycle: Calendar and Cycle Syncing go back to Cycle Home', (
      tester,
    ) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.cycle));
      for (final page in [CycleText.calendar, CycleText.syncing]) {
        await press(tester, find.text(page));
        expect(find.text(CycleText.back), findsOneWidget, reason: page);
        expect(await back(tester), isTrue, reason: page);
        expect(find.text(CycleText.back), findsNothing, reason: page);
      }
      expect(await back(tester), isFalse);
    });

    testWidgets('Garden: a chapter goes back to the landing page', (
      tester,
    ) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.garden));
      await press(tester, find.bySemanticsLabel(RegExp('^My Garden\\.')));
      expect(find.text(GardenText.back), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.text(GardenText.back), findsNothing);
    });

    testWidgets('Nature Log: My observations goes back to the landing page', (
      tester,
    ) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.natureLog));
      await press(
        tester,
        find.bySemanticsLabel(RegExp('^${NatureLogText.myObservations}\\.')),
      );
      expect(find.text(NatureLogText.logEmpty), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.text(NatureLogText.logEmpty), findsNothing);
      expect(await back(tester), isFalse);
    });
  });

  group('unsaved words are asked about, never silently lost', () {
    Finder field(String label) => find.widgetWithText(TextField, label);

    testWidgets('Cookbook form: Back on an untouched form just leaves', (
      tester,
    ) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.cookbook));
      await press(tester, find.text(CookbookText.addRecipe));

      expect(await back(tester), isTrue);
      expect(find.text(UnsavedChanges.title), findsNothing);
      expect(field(CookbookText.titleLabel), findsNothing);
    });

    testWidgets('Cookbook form: Back on a changed form asks; Keep editing '
        'keeps every word', (tester) async {
      final store = InMemoryOwnRecipeStore();
      await open(tester, recipes: store);
      await go(tester, routeOf(FeatureId.cookbook));
      await press(tester, find.text(CookbookText.addRecipe));
      await tester.enterText(field(CookbookText.titleLabel), 'Half a soup');
      await tester.pumpAndSettle();

      expect(await back(tester), isTrue);
      expect(find.text(UnsavedChanges.title), findsOneWidget);
      await press(tester, find.text(UnsavedChanges.keepEditing));
      expect(find.text('Half a soup'), findsOneWidget);
      expect(location(), routeOf(FeatureId.cookbook));

      // Back again, and this time leave: nothing was ever saved.
      expect(await back(tester), isTrue);
      await press(tester, find.text(UnsavedChanges.leave));
      expect(field(CookbookText.titleLabel), findsNothing);
      expect((await store.read()).isEmpty, isTrue);
    });

    testWidgets('Cookbook form: Back while the question is showing closes '
        'the question, and keeps the words', (tester) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.cookbook));
      await press(tester, find.text(CookbookText.addRecipe));
      await tester.enterText(field(CookbookText.titleLabel), 'Half a soup');
      await tester.pumpAndSettle();

      await back(tester);
      expect(find.text(UnsavedChanges.title), findsOneWidget);
      expect(await back(tester), isTrue);
      expect(find.text(UnsavedChanges.title), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Half a soup'), findsOneWidget);
    });

    testWidgets('Cookbook form: editing a saved recipe and leaving never '
        'touches the saved one', (tester) async {
      const saved = OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack');
      final store = InMemoryOwnRecipeStore(const OwnRecipes([saved]));
      await open(tester, recipes: store);
      await go(tester, routeOf(FeatureId.cookbook));
      await press(tester, find.text('Flapjack'));
      await press(tester, find.text(CookbookText.editRecipe));
      await tester.enterText(field(CookbookText.titleLabel), 'Not flapjack');
      await tester.pumpAndSettle();

      await back(tester);
      await press(tester, find.text(UnsavedChanges.leave));
      // Up one level: the saved recipe, unchanged.
      expect(find.text(CookbookText.editRecipe), findsOneWidget);
      expect((await store.read()).recipes.single, saved);
    });

    testWidgets('Nature Log form: app Back and system Back ask the same '
        'question', (tester) async {
      final store = InMemoryNatureLogStore();
      await open(tester, nature: store);
      await go(tester, routeOf(FeatureId.natureLog));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );
      await tester.enterText(field(NatureLogText.nameLabel), 'A heron');
      await tester.pumpAndSettle();

      // The page's own Back.
      await press(tester, find.widgetWithText(TextButton, NatureLogText.back));
      expect(find.text(UnsavedChanges.title), findsOneWidget);
      await press(tester, find.text(UnsavedChanges.keepEditing));
      expect(find.text('A heron'), findsOneWidget);

      // System Back.
      expect(await back(tester), isTrue);
      expect(find.text(UnsavedChanges.title), findsOneWidget);
      await press(tester, find.text(UnsavedChanges.leave));
      expect(field(NatureLogText.nameLabel), findsNothing);
      expect((await store.read()).isEmpty, isTrue);
    });

    testWidgets('Nature Log form: untouched, Back leaves without asking', (
      tester,
    ) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.natureLog));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );

      expect(await back(tester), isTrue);
      expect(find.text(UnsavedChanges.title), findsNothing);
      expect(field(NatureLogText.nameLabel), findsNothing);
    });
  });

  group('a dialog on top is closed first', () {
    testWidgets('Garden removal: Back dismisses the question and keeps the '
        'plant', (tester) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.garden));
      await press(tester, find.bySemanticsLabel(RegExp('^My Garden\\.')));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, GardenText.addExisting),
      );
      await press(tester, find.bySemanticsLabel(RegExp('^Mint\\.')));
      await press(
        tester,
        find.widgetWithText(ElevatedButton, GardenText.addToMyGarden),
      );
      await press(tester, find.text(EstablishmentState.established.question));
      await press(tester, find.widgetWithText(TextButton, GardenText.remove));
      expect(find.byType(AlertDialog), findsOneWidget);

      expect(await back(tester), isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      // Still on the plant's page, and the plant is still in the garden.
      expect(
        find.widgetWithText(TextButton, GardenText.remove),
        findsOneWidget,
      );
    });
  });

  group('sessions', () {
    testWidgets('Meditation: Back ends a running session, then returns to '
        'the four practices', (tester) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.meditation));
      await press(tester, find.widgetWithText(ChoiceCard, 'Focus'));
      await tester.tap(find.bySemanticsLabel('Begin'));
      await tester.pump();
      await tester.pump(kSettlingPause + const Duration(seconds: 3));
      expect(container.read(immersiveModeProvider), isTrue);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(container.read(immersiveModeProvider), isFalse);
      // Back at the setup, not running, and nothing left ticking.
      expect(find.bySemanticsLabel('Begin'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);

      expect(await back(tester), isTrue);
      expect(find.widgetWithText(ChoiceCard, 'Focus'), findsOneWidget);
      expect(find.bySemanticsLabel('Begin'), findsNothing);
      expect(await back(tester), isFalse);
    });

    testWidgets('Yoga: Back ends a running practice, then returns to the '
        'three practices', (tester) async {
      await open(tester);
      await go(tester, routeOf(FeatureId.yoga));
      await press(tester, find.widgetWithText(ChoiceCard, 'Ground'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(container.read(immersiveModeProvider), isTrue);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(container.read(immersiveModeProvider), isFalse);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);

      expect(await back(tester), isTrue);
      expect(find.widgetWithText(ChoiceCard, 'Ground'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start'), findsNothing);
    });
  });
}
