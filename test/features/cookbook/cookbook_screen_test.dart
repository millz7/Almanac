import 'package:almanac/app/almanac_button.dart';
import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/environment/environment_providers.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/core/settings/settings_providers.dart';
import 'package:almanac/features/cookbook/domain/recipe_catalogue.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cookbook/presentation/widgets/recipe_card.dart';
import 'package:almanac/features/cookbook/presentation/widgets/season_sprig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

/// Mid-January: high summer in the south, deep winter in the north. The
/// same instant gives two different seasons, which is exactly what the
/// Cookbook has to get right.
final januaryNoon = DateTime.utc(2026, 1, 15, 12);

/// Mid-July, the suite's usual date.
final julyNoon = DateTime.utc(2026, 7, 15, 12);

void main() {
  setUpAll(useTimeZoneDatabase);

  final back = find.widgetWithText(TextButton, CookbookText.back);

  Finder navTab(String name) => find.descendant(
    of: find.byType(AlmanacNavigationBar),
    matching: find.bySemanticsLabel(name),
  );

  Finder seasonChip(Season season, {bool current = false}) => find
      .bySemanticsLabel(CookbookText.seasonLabel(season, isCurrent: current));

  Future<ProviderContainer> openCookbook(
    WidgetTester tester, {
    DateTime? now,
    Hemisphere hemisphere = Hemisphere.northern,
    double textScale = 1,
    bool reducedMotion = false,
    Size surface = const Size(420, 2400),
    Set<FeatureId> features = const {FeatureId.cookbook},
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
        now: now ?? julyNoon,
        hemisphere: hemisphere,
        features: features,
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

    await tester.tap(navTab('Cookbook'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> press(WidgetTester tester, Finder control) async {
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  group('the collection', () {
    testWidgets('opens quietly, with its four seasons', (tester) async {
      await openCookbook(tester);

      // The heading, and the navigation label beside it.
      expect(find.text(CookbookText.title), findsNWidgets(2));
      expect(find.text(CookbookText.introduction), findsOneWidget);
      for (final season in Season.values) {
        expect(find.text(season.label), findsWidgets, reason: season.label);
      }
    });

    testWidgets('marks the season the user is actually in', (tester) async {
      // July in the north is summer.
      await openCookbook(tester, now: julyNoon);

      expect(find.text(CookbookText.yourSeason), findsOneWidget);
      expect(seasonChip(Season.summer, current: true), findsOneWidget);
      expect(seasonChip(Season.winter), findsOneWidget);
    });

    testWidgets('the marker follows the hemisphere, not the month', (
      tester,
    ) async {
      // The same instant, on the other side of the world.
      await openCookbook(
        tester,
        now: januaryNoon,
        hemisphere: Hemisphere.southern,
      );
      expect(seasonChip(Season.summer, current: true), findsOneWidget);

      await openCookbook(
        tester,
        now: januaryNoon,
        hemisphere: Hemisphere.northern,
      );
      expect(seasonChip(Season.winter, current: true), findsOneWidget);
    });

    testWidgets('opens on the season the user is in', (tester) async {
      await openCookbook(tester, now: julyNoon);

      for (final recipe in RecipeCatalogue.forSeason(Season.summer)) {
        expect(find.text(recipe.name), findsOneWidget, reason: recipe.id);
      }
      expect(find.byType(RecipeCard), findsNWidgets(4));
    });

    testWidgets('says what a seasonal collection is, and is not', (
      tester,
    ) async {
      await openCookbook(tester, now: julyNoon);

      expect(
        find.text(RecipeCatalogue.collectionNote(Season.summer)),
        findsOneWidget,
      );
      expect(find.textContaining('wherever you are'), findsOneWidget);
      expect(find.textContaining('near you'), findsNothing);
    });

    testWidgets('every season has its four, and only its four', (tester) async {
      await openCookbook(tester);

      for (final season in Season.values) {
        await press(
          tester,
          seasonChip(season, current: season == Season.summer),
        );

        expect(find.byType(RecipeCard), findsNWidgets(4), reason: season.label);
        for (final recipe in RecipeCatalogue.all) {
          expect(
            find.text(recipe.name),
            recipe.season == season ? findsOneWidget : findsNothing,
            reason: '${recipe.id} while browsing ${season.label}',
          );
        }
      }
    });

    testWidgets('browsing another season changes nothing but the list', (
      tester,
    ) async {
      final container = await openCookbook(tester, now: julyNoon);
      await press(tester, seasonChip(Season.winter));

      // The marker has not moved: the user is still in summer, they are
      // only looking at winter.
      expect(seasonChip(Season.summer, current: true), findsOneWidget);
      expect(find.text(CookbookText.yourSeason), findsOneWidget);
      expect(
        find.text(RecipeCatalogue.collectionNote(Season.winter)),
        findsOneWidget,
      );
      // And the Environment is untouched.
      expect(container.read(currentSeasonProvider), Season.summer);
      expect(
        container.read(userSettingsProvider).hemisphere,
        Hemisphere.northern,
      );
    });
  });

  group('a recipe', () {
    testWidgets('each card opens its own page', (tester) async {
      await openCookbook(tester);

      for (final season in Season.values) {
        await press(
          tester,
          seasonChip(season, current: season == Season.summer),
        );

        for (final recipe in RecipeCatalogue.forSeason(season)) {
          await press(tester, find.bySemanticsLabel(recipe.cardLabel));

          expect(find.text(recipe.name), findsOneWidget, reason: recipe.id);
          expect(find.text('${season.label} recipe'), findsOneWidget);
          expect(find.text(recipe.description), findsOneWidget);
          expect(find.byType(RecipeCard), findsNothing);

          await press(tester, back);
        }
      }
    });

    testWidgets('the ingredients are all there, in order', (tester) async {
      await openCookbook(tester);
      await press(tester, seasonChip(Season.autumn));
      final soup = RecipeCatalogue.byId('autumn-pumpkin-soup');
      await press(tester, find.bySemanticsLabel(soup.cardLabel));

      expect(find.text(CookbookText.ingredients), findsOneWidget);
      final tops = [
        for (final ingredient in soup.ingredients)
          tester.getTopLeft(find.text(ingredient.line)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(
        find.text('1 kg pumpkin, peeled and cut into chunks'),
        findsOneWidget,
      );
      expect(find.text('Salt and pepper, to taste'), findsOneWidget);
    });

    testWidgets('the method is numbered, in order', (tester) async {
      await openCookbook(tester);
      await press(tester, seasonChip(Season.autumn));
      final soup = RecipeCatalogue.byId('autumn-pumpkin-soup');
      await press(tester, find.bySemanticsLabel(soup.cardLabel));

      expect(find.text(CookbookText.method), findsOneWidget);
      final tops = [
        for (final step in soup.steps)
          tester.getTopLeft(find.text(step.instruction)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));

      for (final step in soup.steps) {
        expect(find.text('${step.number}'), findsWidgets);
        // Each step reads as one thought to a screen reader.
        expect(find.bySemanticsLabel(step.spoken), findsOneWidget);
      }
    });

    testWidgets('the times and the servings are said plainly', (tester) async {
      await openCookbook(tester);
      await press(tester, seasonChip(Season.autumn));
      final soup = RecipeCatalogue.byId('autumn-pumpkin-soup');
      await press(tester, find.bySemanticsLabel(soup.cardLabel));

      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
      expect(find.bySemanticsLabel('Preparation 15 minutes'), findsOneWidget);
      expect(find.bySemanticsLabel('Cooking 30 minutes'), findsOneWidget);
      expect(find.bySemanticsLabel('Serves 4'), findsOneWidget);
    });

    testWidgets('the illustration is small, and above the cooking', (
      tester,
    ) async {
      await openCookbook(tester);
      final recipe = RecipeCatalogue.forSeason(Season.summer).first;
      await press(tester, find.bySemanticsLabel(recipe.cardLabel));

      final sprig = tester.getSize(find.byType(SeasonSprig));
      expect(sprig.height, lessThanOrEqualTo(kLargeSprigSize));
      // Nothing to scroll past: the ingredients are on the first screen.
      expect(
        tester.getTopLeft(find.text(CookbookText.ingredients)).dy,
        lessThan(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
    });

    testWidgets('going back returns to the collection it came from', (
      tester,
    ) async {
      await openCookbook(tester);
      await press(tester, seasonChip(Season.winter));
      final stew = RecipeCatalogue.byId('winter-vegetable-and-bean-stew');

      await press(tester, find.bySemanticsLabel(stew.cardLabel));
      await press(tester, back);

      expect(find.byType(RecipeCard), findsNWidgets(4));
      expect(
        find.text(RecipeCatalogue.collectionNote(Season.winter)),
        findsOneWidget,
      );
    });
  });

  group('living in the Almanac', () {
    testWidgets('the Almanac is reachable from both pages', (tester) async {
      await openCookbook(tester);
      expect(find.byType(AlmanacButton), findsOneWidget);

      final recipe = RecipeCatalogue.forSeason(Season.summer).first;
      await press(tester, find.bySemanticsLabel(recipe.cardLabel));
      expect(find.byType(AlmanacButton), findsOneWidget);
      expect(find.byType(AlmanacNavigationBar), findsOneWidget);
    });

    testWidgets('nothing is left running when you leave', (tester) async {
      await openCookbook(
        tester,
        features: {FeatureId.cookbook, FeatureId.garden},
      );

      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(navTab('Garden'));
      await tester.pumpAndSettle();

      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byType(RecipeCard), findsNothing);
    });
  });

  group('reduced motion', () {
    testWidgets('the sprigs are simply already drawn', (tester) async {
      await openCookbook(tester, reducedMotion: true);

      for (final sprig in tester.widgetList<SeasonSprig>(
        find.byType(SeasonSprig),
      )) {
        expect(sprig.growth, 1);
      }
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('and everything still works', (tester) async {
      await openCookbook(tester, reducedMotion: true);
      await press(tester, seasonChip(Season.spring));

      expect(find.byType(RecipeCard), findsNWidgets(4));
      expect(tester.binding.transientCallbackCount, 0);

      final recipe = RecipeCatalogue.forSeason(Season.spring).first;
      await press(tester, find.bySemanticsLabel(recipe.cardLabel));
      expect(find.text(recipe.name), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('a card is one button that says what it is', (tester) async {
      await openCookbook(tester);

      for (final recipe in RecipeCatalogue.forSeason(Season.summer)) {
        expect(
          find.bySemanticsLabel(recipe.cardLabel),
          findsOneWidget,
          reason: recipe.id,
        );
      }
      expect(
        find.bySemanticsLabel(
          'Pumpkin soup. Autumn recipe. A simple warming soup, smooth and '
          'golden.',
        ),
        findsNothing,
      );

      await press(tester, seasonChip(Season.autumn));
      expect(
        find.bySemanticsLabel(
          'Pumpkin soup. Autumn recipe. A simple warming soup, smooth and '
          'golden.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the season selector says which one is chosen', (tester) async {
      await openCookbook(tester, now: julyNoon);

      final chips = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where(
            (s) => s.properties.selected != null && s.properties.label != null,
          )
          .where(
            (s) => Season.values.any(
              (season) => s.properties.label!.startsWith(season.label),
            ),
          );

      expect(chips.where((s) => s.properties.selected!), hasLength(1));
      expect(chips, hasLength(4));
    });

    testWidgets('the drawn sprigs say nothing', (tester) async {
      await openCookbook(tester);

      expect(
        find.descendant(
          of: find.byType(SeasonSprig),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('every control is a comfortable target', (tester) async {
      await openCookbook(tester);

      for (final season in Season.values) {
        expect(
          tester
              .getSize(seasonChip(season, current: season == Season.summer))
              .height,
          greaterThanOrEqualTo(48),
          reason: season.label,
        );
      }
      for (final recipe in RecipeCatalogue.forSeason(Season.summer)) {
        expect(
          tester.getSize(find.bySemanticsLabel(recipe.cardLabel)).height,
          greaterThanOrEqualTo(48),
        );
      }

      final recipe = RecipeCatalogue.forSeason(Season.summer).first;
      await press(tester, find.bySemanticsLabel(recipe.cardLabel));
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    });

    testWidgets('doubling the text size breaks nothing', (tester) async {
      await openCookbook(tester, textScale: 2);

      // Names grow rather than being cut short.
      for (final recipe in RecipeCatalogue.forSeason(Season.summer)) {
        expect(find.text(recipe.name), findsOneWidget, reason: recipe.id);
      }
      for (final season in Season.values) {
        expect(find.text(season.label), findsWidgets);
      }

      await press(
        tester,
        find.bySemanticsLabel(
          RecipeCatalogue.forSeason(Season.summer).first.cardLabel,
        ),
      );
      expect(find.text(CookbookText.ingredients), findsOneWidget);
      expect(find.text(CookbookText.method), findsOneWidget);
    });
  });
}
