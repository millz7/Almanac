import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/router.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/location_state.dart';
import 'package:almanac/core/environment/tide_service.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/widgets/widgets.dart';
import 'package:almanac/features/chakras/presentation/widgets/chakra_symbol.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cookbook/presentation/widgets/season_sprig.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/environment/presentation/moon_screen.dart';
import 'package:almanac/features/environment/presentation/tide_screen.dart';
import 'package:almanac/features/environment/presentation/tide_text.dart';
import 'package:almanac/features/environment/presentation/widgets/environment_artwork_view.dart';
import 'package:almanac/features/environment/presentation/widgets/moon_disc.dart';
import 'package:almanac/features/garden/application/garden_providers.dart';
import 'package:almanac/features/garden/presentation/garden_text.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:almanac/features/wheel/presentation/festival_detail_page.dart';
import 'package:almanac/features/wheel/presentation/widgets/wheel_diagram.dart';
import 'package:almanac/features/yoga/presentation/widgets/pose_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Functional accessibility only: what a screen reader is told, whether
/// decoration stays out of its way, and whether every action is still
/// reachable at double text size. No visual judgement is made here.
void main() {
  setUpAll(useTimeZoneDatabase);

  final everything = FeatureRegistry.optional.map((f) => f.id).toSet();
  late ProviderContainer container;

  Future<void> open(
    WidgetTester tester, {
    List<Override>? overrides,
    Size surface = const Size(430, 2400),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    container = ProviderContainer(
      overrides:
          overrides ??
          environmentOverrides(
            now: DateTime.utc(2026, 4, 27, 12),
            features: everything,
            locationState: const LocationAvailable(TestLocations.london),
            weatherService: FakeWeatherService(
              result: ({required location, required timeZone, required now}) =>
                  testWeatherSnapshot(location: location, obtainedAt: now),
            ),
            tideService: FakeTideService(
              result: ({required location, required timeZone, required now}) =>
                  TideFetchData(
                    testTideSnapshot(location: location, obtainedAt: now),
                  ),
            ),
            ownRecipeStore: InMemoryOwnRecipeStore(
              const OwnRecipes([
                OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack'),
              ]),
            ),
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

  Future<void> go(WidgetTester tester, FeatureId id) async {
    container.read(routerProvider).go(FeatureRegistry.byId(id).route);
    await tester.pumpAndSettle();
  }

  /// Scrolls [target] into view if it is further down a page, then taps.
  Future<void> press(WidgetTester tester, Finder target) async {
    final page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        // The topmost page's column: a drawer or sheet is built after the
        // page beneath it.
        .last;
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 300, scrollable: page);
    }
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  /// Reachable: on screen after scrolling, and actually hit by a tap.
  Future<void> reachable(
    WidgetTester tester,
    Finder target,
    String what,
  ) async {
    final page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        // The topmost page's column: a drawer or sheet is built after the
        // page beneath it.
        .last;
    if (target.evaluate().isEmpty && page.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(target, 300, scrollable: page);
    }
    await tester.ensureVisible(target.first);
    await tester.pumpAndSettle();
    // "Visible" to a scroll view can still be under the navigation bar,
    // which floats over the page; a person scrolls a little further, and
    // so does this.
    for (var i = 0; i < 4 && target.hitTestable().evaluate().isEmpty; i++) {
      if (page.evaluate().isEmpty) break;
      await tester.drag(page, const Offset(0, -150));
      await tester.pumpAndSettle();
    }
    expect(target.hitTestable(), findsWidgets, reason: what);
  }

  group('details and forms say what they are', () {
    testWidgets('Moon and Tides detail: a named way back, and the facts '
        'read as words', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await tester.tap(find.text('Moon'));
      await tester.pumpAndSettle();
      expect(find.byType(MoonScreen), findsOneWidget);
      expect(
        tester.getSemantics(find.byIcon(Icons.chevron_left).first),
        isSemantics(isButton: true),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text(TideText.title));
      await tester.pumpAndSettle();
      expect(find.byType(TideScreen), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(TideText.back)), findsOneWidget);
      expect(find.text(TideText.nonNavigationNote), findsOneWidget);
      handle.dispose();
    });

    testWidgets('festival detail: a named way back, and its doorways are '
        'buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await go(tester, FeatureId.wheel);
      await press(tester, find.text('Beltane'));
      expect(find.byType(FestivalDetailPage), findsOneWidget);
      expect(
        tester.getSemantics(find.byIcon(Icons.chevron_left).first),
        isSemantics(isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Try a yoga practice')),
        isSemantics(isButton: true),
      );
      handle.dispose();
    });

    testWidgets('recipe form: every field has its label; save, cancel and '
        'delete are named buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await go(tester, FeatureId.cookbook);
      await press(tester, find.text('Flapjack'));
      for (final label in [
        CookbookText.editRecipe,
        CookbookText.deleteRecipe,
      ]) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(isButton: true),
          reason: label,
        );
      }
      await press(tester, find.text(CookbookText.editRecipe));
      for (final label in [
        CookbookText.titleLabel,
        CookbookText.ingredientsLabel,
        CookbookText.methodLabel,
        CookbookText.noteLabel,
      ]) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(RegExp('^$label'))),
          isSemantics(isTextField: true),
          reason: label,
        );
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel(CookbookText.saveChanges)),
        isSemantics(isButton: true),
      );
      handle.dispose();
    });

    testWidgets('observation form: categories are buttons that say which is '
        'chosen', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await go(tester, FeatureId.natureLog);
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('^${NatureLogText.nameLabel}')),
        ),
        isSemantics(isTextField: true),
      );
      await press(tester, find.bySemanticsLabel('Animal'));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Animal')),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bird')),
        isSemantics(isButton: true, isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('Garden: how far along a plant is reads as a selected '
        'choice', (tester) async {
      final handle = tester.ensureSemantics();
      await open(
        tester,
        overrides: environmentOverrides(
          features: {FeatureId.garden},
          gardenStore: InMemoryGardenStore(
            MyGarden([
              GardenPlant(
                instanceId: 'mint',
                plantId: 'mint',
                addedOn: const CalendarDate(2025, 3, 1),
                state: EstablishmentState.established,
              ),
            ]),
          ),
        ),
      );
      await go(tester, FeatureId.garden);
      await press(tester, find.bySemanticsLabel(RegExp(r'^My Garden\.')));
      await press(tester, find.bySemanticsLabel(RegExp(r'^Mint\.')));
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(EstablishmentState.established.label),
        ),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.widgetWithText(TextButton, GardenText.remove)),
        isSemantics(isButton: true),
      );
      handle.dispose();
    });

    testWidgets('Cycle: bleeding levels are buttons that say which is '
        'chosen', (tester) async {
      final handle = tester.ensureSemantics();
      await open(
        tester,
        overrides: environmentOverrides(
          now: DateTime.utc(2026, 9, 10, 12),
          features: {FeatureId.cycle},
        ),
      );
      await go(tester, FeatureId.cycle);
      await press(tester, find.text(CycleText.calendar));
      await press(tester, find.bySemanticsLabel(RegExp('^9 September')));
      await press(tester, find.byKey(const ValueKey('level-heavy')));
      expect(
        tester.getSemantics(find.byKey(const ValueKey('level-heavy'))),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('level-spotting'))),
        isSemantics(isButton: true, isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('Meditation and Yoga sessions: the one control is named', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await go(tester, FeatureId.meditation);
      await press(tester, find.widgetWithText(ChoiceCard, 'Focus'));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Begin')),
        isSemantics(isButton: true),
      );
      await tester.tap(find.bySemanticsLabel('Begin'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.bySemanticsLabel('End the session'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await go(tester, FeatureId.yoga);
      await press(tester, find.widgetWithText(ChoiceCard, 'Ground'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.getSemantics(find.widgetWithText(TextButton, 'End practice')),
        isSemantics(isButton: true),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('decoration stays out of a screen reader\'s way', () {
    Finder excluded(Type type) => find.descendant(
      of: find.byType(type),
      matching: find.byWidgetPredicate(
        (w) => w is ExcludeSemantics && w.excluding,
      ),
    );

    testWidgets('artwork, moon disc, wheel diagram, pose figure, chakra and '
        'season marks are all excluded, and no file name is ever read', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      expect(excluded(EnvironmentArtworkView), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp(r'\.(png|jpe?g|webp)')),
        findsNothing,
      );

      await tester.tap(find.text('Moon'));
      await tester.pumpAndSettle();
      expect(excluded(MoonDisc), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await go(tester, FeatureId.wheel);
      expect(excluded(WheelDiagram), findsWidgets);
      // The wheel is still described in words.
      expect(find.bySemanticsLabel(RegExp('Beltane')), findsWidgets);

      await go(tester, FeatureId.chakras);
      await press(tester, find.bySemanticsLabel(RegExp(r'^Heart chakra\.')));
      expect(excluded(ChakraSymbol), findsWidgets);

      await go(tester, FeatureId.cookbook);
      expect(excluded(SeasonSprig), findsWidgets);

      await go(tester, FeatureId.yoga);
      await press(tester, find.widgetWithText(ChoiceCard, 'Ground'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(excluded(PoseFigure), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('at 2x text, every action can still be reached', () {
    const phone = Size(390, 844);

    for (final (stage, nameAsked, hemisphere, intro, action) in [
      ('name', false, false, false, 'Continue'),
      ('hemisphere', true, false, false, 'Southern Hemisphere'),
      ('location', true, true, false, 'Not Now'),
      ('categories', true, true, true, 'Just the Environment'),
    ]) {
      testWidgets('onboarding: $stage', (tester) async {
        await open(
          tester,
          surface: phone,
          textScale: 2,
          overrides: environmentOverrides(
            onboardingCompleted: false,
            nameAsked: nameAsked,
            hemisphere: hemisphere ? Hemisphere.northern : null,
            locationIntroSeen: intro,
          ),
        );
        await reachable(tester, find.textContaining(action), stage);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the drawer, the Environment, a festival, the recipe form, '
        'the observation form and the Cycle day editor', (tester) async {
      await open(tester, surface: phone, textScale: 2);

      await reachable(tester, find.text('See Beltane'), 'Environment doorway');
      // Back up to the masthead, where the Almanac opens.
      for (
        var i = 0;
        i < 12 && find.byType(AlmanacButton).hitTestable().evaluate().isEmpty;
        i++
      ) {
        await tester.drag(
          find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .last,
          const Offset(0, 300),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(AlmanacButton).hitTestable().first);
      await tester.pumpAndSettle();
      await reachable(tester, find.text('Save name'), 'drawer');
      // Closed the way a phone does it.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save name'), findsNothing);

      await go(tester, FeatureId.wheel);
      await press(tester, find.text('Beltane'));
      await reachable(tester, find.text('Try a yoga practice'), 'festival');

      await go(tester, FeatureId.cookbook);
      await press(tester, find.text(CookbookText.addRecipe));
      await reachable(
        tester,
        find.text(CookbookText.saveRecipe),
        'recipe form',
      );
      await reachable(tester, find.text(CookbookText.cancel), 'recipe form');
      await press(tester, find.text(CookbookText.cancel));

      await go(tester, FeatureId.natureLog);
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.recordSomething),
      );
      await press(
        tester,
        find.widgetWithText(ElevatedButton, NatureLogText.writeYourOwn),
      );
      await reachable(tester, find.text(NatureLogText.changeDate), 'nature');
      await reachable(
        tester,
        find.text(NatureLogText.saveObservation),
        'nature form',
      );

      container
          .read(routerProvider)
          .go(FeatureRegistry.byId(FeatureId.cycle).route);
      await tester.pumpAndSettle();
      await press(tester, find.text(CycleText.calendar));
      await press(tester, find.bySemanticsLabel(RegExp('^20 April')));
      await reachable(
        tester,
        find.widgetWithText(ElevatedButton, CycleText.save),
        'cycle day editor',
      );
      await reachable(tester, find.text(CycleText.cancel), 'cycle editor');
      expect(tester.takeException(), isNull);
    });
  });

  group('the shared question', () {
    testWidgets('its title and both answers are read; Back and a tap outside '
        'both answer "no"', (tester) async {
      final handle = tester.ensureSemantics();
      final store = InMemoryOwnRecipeStore(
        const OwnRecipes([OwnRecipe(id: 'own-0', order: 0, title: 'Flapjack')]),
      );
      await open(
        tester,
        overrides: environmentOverrides(
          features: {FeatureId.cookbook},
          ownRecipeStore: store,
        ),
      );
      await go(tester, FeatureId.cookbook);
      await press(tester, find.text('Flapjack'));

      for (final dismiss in ['back', 'outside']) {
        await press(tester, find.text(CookbookText.deleteRecipe));
        expect(find.bySemanticsLabel(CookbookText.deleteTitle), findsOneWidget);
        expect(find.bySemanticsLabel(CookbookText.deleteBody), findsOneWidget);
        for (final answer in [CookbookText.delete, CookbookText.keep]) {
          expect(
            tester.getSemantics(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.widgetWithText(TextButton, answer),
              ),
            ),
            isSemantics(isButton: true),
            reason: answer,
          );
        }
        if (dismiss == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tapAt(const Offset(4, 4));
        }
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing, reason: dismiss);
        expect((await store.read()).length, 1, reason: dismiss);
        // The recipe it was asked about is still on screen, ready.
        expect(find.text(CookbookText.editRecipe), findsOneWidget);
      }
      handle.dispose();
    });
  });
}
