import 'dart:io';

import 'package:almanac/features/cookbook/domain/cycle_recipes.dart';
import 'package:almanac/features/cookbook/domain/recipe_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every word of a recipe, for checking what is actually in it.
String contentsOf(Recipe recipe) => [
  recipe.name,
  recipe.description,
  for (final ingredient in recipe.ingredients) ingredient.name,
].join(' ').toLowerCase();

void main() {
  group('the mapping belongs to the Cookbook', () {
    test('and Cycle names no recipe and no ingredient', () {
      // Cycle knows it would like recipes for a phase. Which recipes
      // those are is a question about recipes, and it is answered here.
      final cycleSources = Directory('lib/features/cycle')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      final ids = [for (final list in CycleRecipes.byPhase.values) ...list];

      for (final file in cycleSources) {
        final code = file.readAsStringSync();
        for (final id in ids) {
          expect(
            code.contains(id),
            isFalse,
            reason: '${file.path} names the recipe $id',
          );
        }
        expect(
          code.contains('RecipeCatalogue'),
          isFalse,
          reason: '${file.path} reaches into the Cookbook',
        );
      }
    });

    test('the Cookbook does not reach into Cycle either', () {
      final cookbookSources = Directory('lib/features/cookbook')
          .listSync(recursive: true)
          .whereType<File>()
          .expand((file) => file.readAsLinesSync())
          .where((line) => line.startsWith('import '));

      for (final line in cookbookSources) {
        expect(line.contains('features/cycle'), isFalse, reason: line);
      }
    });
  });

  group('the cycle collections', () {
    test('every phase has one, and it is useful', () {
      for (final phase in CyclePhase.values) {
        final recipes = CycleRecipes.forPhase(phase);
        expect(recipes.length, greaterThanOrEqualTo(4), reason: phase.name);
      }
    });

    test('every mapped id exists in the catalogue', () {
      for (final entry in CycleRecipes.byPhase.entries) {
        for (final id in entry.value) {
          expect(
            RecipeCatalogue.all.map((recipe) => recipe.id),
            contains(id),
            reason: '${entry.key.name}: $id',
          );
        }
      }
    });

    test('with no duplicates inside a phase', () {
      for (final entry in CycleRecipes.byPhase.entries) {
        expect(
          entry.value.toSet(),
          hasLength(entry.value.length),
          reason: entry.key.name,
        );
      }
    });

    test('and no phase is simply the whole cookbook', () {
      for (final phase in CyclePhase.values) {
        expect(
          CycleRecipes.forPhase(phase).length,
          lessThan(RecipeCatalogue.all.length),
          reason: phase.name,
        );
      }
    });

    test('they come back in catalogue order', () {
      for (final phase in CyclePhase.values) {
        final recipes = CycleRecipes.forPhase(phase);
        final positions = [
          for (final recipe in recipes) RecipeCatalogue.all.indexOf(recipe),
        ];
        expect(
          positions,
          orderedEquals([...positions]..sort()),
          reason: phase.name,
        );
      }
    });

    test('and every phase has a note about what the collection is', () {
      for (final phase in CyclePhase.values) {
        final note = CycleRecipes.collectionNote(phase);
        expect(note.trim(), isNotEmpty, reason: phase.name);
        expect(note, endsWith('.'), reason: phase.name);
      }
      expect({
        for (final phase in CyclePhase.values)
          CycleRecipes.collectionNote(phase),
      }, hasLength(4));
    });
  });

  group('the menstrual collection is chosen for what is in it', () {
    test('every recipe carries an iron-containing food', () {
      // Not arbitrary recipes: menstruation involves blood loss, so the
      // collection is the meals that genuinely contain lentils, beans,
      // chickpeas, leafy greens, eggs or meat.
      const ironFoods = [
        'lentil',
        'bean',
        'chickpea',
        'spinach',
        'silverbeet',
        'greens',
        'egg',
        'chicken',
        'beef',
        'lamb',
      ];

      final recipes = CycleRecipes.forPhase(CyclePhase.menstrual);
      for (final recipe in recipes) {
        final contents = contentsOf(recipe);
        expect(
          ironFoods.any(contents.contains),
          isTrue,
          reason: '${recipe.id} carries none of them',
        );
      }
    });

    test('and the note says which foods, without diagnosing anybody', () {
      final note = CycleRecipes.collectionNote(CyclePhase.menstrual)
          .toLowerCase();

      expect(note, contains('iron'));
      for (final claim in [
        'deficien',
        'you need',
        'restore',
        'replenish',
        'boost',
      ]) {
        expect(note, isNot(contains(claim)), reason: claim);
      }
    });

    test('no dessert is offered as an iron meal', () {
      // A pudding is a fine thing; it is not what this collection is
      // for, and putting one here to reach a count would be padding.
      final recipes = CycleRecipes.forPhase(CyclePhase.menstrual);
      for (final recipe in recipes) {
        for (final dessert in ['crumble', 'pudding', 'bake', 'stone fruit']) {
          expect(
            recipe.name.toLowerCase().contains(dessert),
            isFalse,
            reason: '${recipe.id} is a $dessert',
          );
        }
      }
    });
  });

  group('what the collections never claim', () {
    test('no recipe is said to treat anything', () {
      final said = [
        for (final phase in CyclePhase.values)
          CycleRecipes.collectionNote(phase),
      ];

      const forbidden = [
        'relieve',
        'reduce cramp',
        'ease cramp',
        'symptom',
        'treats ',
        'cure',
        'heal',
        'remedy',
        'balance your hormones',
        'detox',
      ];

      for (final note in said) {
        for (final claim in forbidden) {
          expect(
            note.toLowerCase().contains(claim),
            isFalse,
            reason: '"$note" contains "$claim"',
          );
        }
      }
    });
  });

  group('the seasonal cookbook is untouched', () {
    test('still sixteen recipes, four to a season', () {
      expect(RecipeCatalogue.all, hasLength(16));
      for (final season in Season.values) {
        expect(
          RecipeCatalogue.forSeason(season),
          hasLength(4),
          reason: season.name,
        );
      }
    });

    test('and every recipe is still reachable by season', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(
          RecipeCatalogue.forSeason(recipe.season),
          contains(recipe),
          reason: recipe.id,
        );
      }
    });
  });
}
