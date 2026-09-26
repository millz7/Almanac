import 'dart:io';

import 'package:almanac/app/app.dart';
import 'package:almanac/app/navigation/almanac_navigation_bar.dart';
import 'package:almanac/core/features/feature_registry.dart';
import 'package:almanac/features/cookbook/application/own_recipes_providers.dart';
import 'package:almanac/features/cookbook/data/shared_preferences_own_recipe_store.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:almanac/features/cycle/data/shared_preferences_cycle_store.dart';
import 'package:almanac/features/garden/data/shared_preferences_garden_store.dart';
import 'package:almanac/features/nature_log/data/shared_preferences_nature_log_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fake_environment_services.dart';
import '../../support/test_overrides.dart';

const _soup = OwnRecipe(
  id: 'own-0',
  order: 0,
  title: 'Leek and potato soup',
  ingredients: ['2 leeks', '3 potatoes', '1 litre stock'],
  method: ['Soften the leeks.', 'Add the potatoes and stock.', 'Simmer.'],
  note: 'Better the next day.',
);

void main() {
  setUpAll(useTimeZoneDatabase);

  group('the recipe itself', () {
    test('a line per item, blank lines dropped, each trimmed', () {
      expect(linesOf('  2 leeks \n\n3 potatoes\n   \n'), [
        '2 leeks',
        '3 potatoes',
      ]);
    });

    test('newest first, and a new one never takes an old one\'s place', () {
      final book = const OwnRecipes([_soup])
          .adding(const OwnRecipe(id: 'own-1', order: 1, title: 'Flapjack'));
      expect(book.newestFirst.map((r) => r.title), [
        'Flapjack',
        'Leek and potato soup',
      ]);
      expect(book.nextOrder, 2);
      expect(book.removing('own-1').nextOrder, 1);
    });

    test('a stored line round-trips, free text and all', () {
      const tricky = OwnRecipe(
        id: 'own-3',
        order: 3,
        title: 'Soup | "the good one"',
        ingredients: ['a, b | c'],
        method: ['Stir {gently}'],
      );
      final back = decodeOwnRecipes(
        encodeOwnRecipes(const OwnRecipes([tricky])),
      );
      expect(back.recipes.single, tricky);
    });

    test('a damaged line costs that recipe and nothing more', () {
      final lines = [
        ...encodeOwnRecipes(const OwnRecipes([_soup])),
        '{oops',
      ];
      expect(decodeOwnRecipes(lines).recipes, [_soup]);
    });
  });

  group('the dedicated store', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('starts empty', () async {
      expect((await SharedPreferencesOwnRecipeStore().read()).isEmpty, isTrue);
    });

    test('keeps recipes across a restart', () async {
      await SharedPreferencesOwnRecipeStore().write(const OwnRecipes([_soup]));
      // A new store object on the same device: what a restart is.
      final reopened = await SharedPreferencesOwnRecipeStore().read();
      expect(reopened.recipes, [_soup]);
    });

    test('deleting really removes them', () async {
      final store = SharedPreferencesOwnRecipeStore();
      await store.write(const OwnRecipes([_soup]));
      await store.deleteAll();
      expect((await SharedPreferencesOwnRecipeStore().read()).isEmpty, isTrue);
    });

    test('its key is its own', () {
      for (final key in SharedPreferencesOwnRecipeStore.keys) {
        expect(key, startsWith('cookbook.'));
      }
      for (final other in [
        SharedPreferencesCycleStore.keys,
        SharedPreferencesGardenStore.keys,
        SharedPreferencesNatureLogStore.keys,
      ]) {
        expect(
          SharedPreferencesOwnRecipeStore.keys.intersection(other),
          isEmpty,
        );
      }
    });

    test('and it is local: nothing in the Cookbook reaches the network', () {
      for (final file in Directory(
        'lib/features/cookbook',
      ).listSync(recursive: true).whereType<File>()) {
        final code = file.readAsStringSync();
        expect(code, isNot(contains('package:http')), reason: file.path);
        expect(code, isNot(contains('HttpClient')), reason: file.path);
      }
    });
  });

  group('in the Cookbook', () {
    Finder navTab(String name) => find.descendant(
      of: find.byType(AlmanacNavigationBar),
      matching: find.bySemanticsLabel(name),
    );

    final page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;

    /// Opens the Cookbook on [store]. Pumping a second time on the same
    /// store, with a fresh container, is an app restart.
    Future<void> open(
      WidgetTester tester,
      OwnRecipeStore store, {
      Size surface = const Size(420, 2400),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = surface * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = ProviderContainer(
        overrides: environmentOverrides(
          features: {FeatureId.cookbook},
          ownRecipeStore: store,
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
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      final target = find.text(text);
      await tester.scrollUntilVisible(target, 300, scrollable: page);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> restart(WidgetTester tester, OwnRecipeStore store) async {
      await tester.pumpWidget(const SizedBox());
      await open(tester, store);
    }

    Future<void> scrollTo(WidgetTester tester, Finder target) =>
        tester.scrollUntilVisible(target, 300, scrollable: page);

    Finder field(String label) => find.widgetWithText(TextField, label);

    testWidgets('empty, it says so and offers the one thing to do', (
      tester,
    ) async {
      await open(tester, InMemoryOwnRecipeStore());

      await scrollTo(tester, find.text(CookbookText.noOwnRecipes));
      expect(find.text(CookbookText.yourRecipes), findsOneWidget);
      expect(find.text(CookbookText.noOwnRecipes), findsOneWidget);
      expect(find.text(CookbookText.noOwnRecipesNote), findsOneWidget);
      expect(find.text(CookbookText.addRecipe), findsOneWidget);
      expect(find.text('No data'), findsNothing);
    });

    testWidgets('create, then restart: it is still there', (tester) async {
      final store = InMemoryOwnRecipeStore();
      await open(tester, store);

      await tapText(tester, CookbookText.addRecipe);
      await tester.enterText(field(CookbookText.titleLabel), 'Flapjack');
      await tester.enterText(
        field(CookbookText.ingredientsLabel),
        'Oats\n\nButter\nGolden syrup',
      );
      await tester.enterText(
        field(CookbookText.methodLabel),
        'Melt.\nStir in the oats.\nBake.',
      );
      await tester.enterText(field(CookbookText.noteLabel), 'Cut while warm.');
      await tapText(tester, CookbookText.saveRecipe);

      // Straight to the recipe, which says it was kept.
      expect(find.text(CookbookText.saved), findsOneWidget);
      expect(find.text('Golden syrup'), findsOneWidget);
      expect(find.text('Stir in the oats.'), findsOneWidget);

      final stored = (await store.read()).recipes.single;
      expect(stored.title, 'Flapjack');
      expect(stored.ingredients, ['Oats', 'Butter', 'Golden syrup']);
      expect(stored.note, 'Cut while warm.');

      await restart(tester, store);
      await scrollTo(tester, find.text('Flapjack'));
      expect(find.text('Flapjack'), findsOneWidget);
      expect(find.text('3 ingredients · 3 steps'), findsOneWidget);
      expect(find.text(CookbookText.noOwnRecipes), findsNothing);
    });

    testWidgets('a nameless recipe cannot be saved, and says why', (
      tester,
    ) async {
      final store = InMemoryOwnRecipeStore();
      await open(tester, store);
      await tapText(tester, CookbookText.addRecipe);

      expect(find.text(CookbookText.nameNeeded), findsOneWidget);
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, CookbookText.saveRecipe),
      );
      expect(save.onPressed, isNull);

      await tester.enterText(field(CookbookText.titleLabel), '   ');
      await tester.pumpAndSettle();
      expect(find.text(CookbookText.nameNeeded), findsOneWidget);
      expect((await store.read()).isEmpty, isTrue);
    });

    testWidgets('edit, then restart: the change is kept', (tester) async {
      final store = InMemoryOwnRecipeStore(const OwnRecipes([_soup]));
      await open(tester, store);

      await tapText(tester, _soup.title);
      await tapText(tester, CookbookText.editRecipe);
      // The form opens holding what was there.
      expect(find.text('2 leeks\n3 potatoes\n1 litre stock'), findsOneWidget);
      await tester.enterText(field(CookbookText.titleLabel), 'Leek soup');
      await tester.enterText(field(CookbookText.noteLabel), '');
      await tapText(tester, CookbookText.saveChanges);

      expect(find.text(CookbookText.saved), findsOneWidget);
      final stored = (await store.read()).recipes.single;
      expect(stored.title, 'Leek soup');
      expect(stored.id, _soup.id);
      expect(stored.note, isNull);
      expect(stored.method, _soup.method);

      await restart(tester, store);
      await scrollTo(tester, find.text('Leek soup'));
      expect(find.text('Leek soup'), findsOneWidget);
      expect(find.text(_soup.title), findsNothing);
    });

    testWidgets('delete asks first, and keeping it keeps it', (tester) async {
      final store = InMemoryOwnRecipeStore(const OwnRecipes([_soup]));
      await open(tester, store);

      await tapText(tester, _soup.title);
      await tapText(tester, CookbookText.deleteRecipe);
      expect(find.text(CookbookText.deleteTitle), findsOneWidget);
      await tester.tap(find.text(CookbookText.keep));
      await tester.pumpAndSettle();

      expect((await store.read()).recipes, [_soup]);
      expect(find.text(CookbookText.editRecipe), findsOneWidget);
    });

    testWidgets('delete, confirm, restart: it is gone', (tester) async {
      final store = InMemoryOwnRecipeStore(const OwnRecipes([_soup]));
      await open(tester, store);

      await tapText(tester, _soup.title);
      await tapText(tester, CookbookText.deleteRecipe);
      await tester.tap(find.text(CookbookText.delete));
      await tester.pumpAndSettle();

      expect((await store.read()).isEmpty, isTrue);
      // Back on the collection, which is empty again.
      await scrollTo(tester, find.text(CookbookText.noOwnRecipes));
      expect(find.text(CookbookText.noOwnRecipes), findsOneWidget);

      await restart(tester, store);
      await scrollTo(tester, find.text(CookbookText.noOwnRecipes));
      expect(find.text(_soup.title), findsNothing);
    });

    testWidgets('leaving a changed form asks, and "keep editing" keeps '
        'the words', (tester) async {
      final store = InMemoryOwnRecipeStore();
      await open(tester, store);
      await tapText(tester, CookbookText.addRecipe);
      await tester.enterText(field(CookbookText.titleLabel), 'Half written');

      await tapText(tester, CookbookText.cancel);
      expect(find.text(CookbookText.leaveTitle), findsOneWidget);
      await tester.tap(find.text(CookbookText.keepEditing));
      await tester.pumpAndSettle();
      expect(find.text('Half written'), findsOneWidget);

      await tapText(tester, CookbookText.cancel);
      await tester.tap(find.text(CookbookText.leave));
      await tester.pumpAndSettle();
      expect(find.text('Half written'), findsNothing);
      expect((await store.read()).isEmpty, isTrue);
    });

    testWidgets('an untouched form leaves without asking', (tester) async {
      await open(tester, InMemoryOwnRecipeStore());
      await tapText(tester, CookbookText.addRecipe);
      await tapText(tester, CookbookText.cancel);

      expect(find.text(CookbookText.leaveTitle), findsNothing);
      await scrollTo(tester, find.text(CookbookText.yourRecipes));
      expect(find.text(CookbookText.yourRecipes), findsOneWidget);
    });

    testWidgets('every control is named and a comfortable target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, InMemoryOwnRecipeStore(const OwnRecipes([_soup])));

      final row = find.bySemanticsLabel(CookbookText.ownRecipeLabel(_soup));
      await scrollTo(tester, row);
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));

      await tapText(tester, _soup.title);
      for (final label in [
        CookbookText.editRecipe,
        CookbookText.deleteRecipe,
        CookbookText.back,
      ]) {
        final control = find.text(label);
        await scrollTo(tester, control);
        final size = tester.getSize(
          find
              .ancestor(
                of: control,
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              )
              .first,
        );
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }

      await tapText(tester, CookbookText.editRecipe);
      for (final label in [
        CookbookText.titleLabel,
        CookbookText.ingredientsLabel,
        CookbookText.methodLabel,
        CookbookText.noteLabel,
      ]) {
        expect(field(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });

    for (final size in [const Size(390, 844), const Size(834, 1194)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${size.width.toInt()}×${size.height.toInt()} at '
            '${scale}x: list, recipe and form all fit', (tester) async {
          await open(
            tester,
            InMemoryOwnRecipeStore(const OwnRecipes([_soup])),
            surface: size,
            textScale: scale,
          );
          Future<void> readToTheEnd(String where) async {
            for (var i = 0; i < 14; i++) {
              await tester.drag(page, const Offset(0, -500));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: where);
            }
          }

          await readToTheEnd('collection');
          await tapText(tester, _soup.title);
          expect(tester.takeException(), isNull);
          await readToTheEnd('recipe');
          await tapText(tester, CookbookText.editRecipe);
          expect(tester.takeException(), isNull);
          await readToTheEnd('form');
          expect(find.textContaining('…'), findsNothing);
        });
      }
    }
  });
}
