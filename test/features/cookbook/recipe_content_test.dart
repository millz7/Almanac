import 'package:almanac/features/cookbook/domain/recipe_catalogue.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whole words only. "eggplant" is not an egg and "crumbled" is not rum:
/// a plain substring search finds both, and would quietly make these
/// checks lie.
bool mentions(String text, String word) =>
    RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false).hasMatch(text);

void main() {
  group('the collection', () {
    test('is sixteen recipes', () {
      expect(RecipeCatalogue.all, hasLength(16));
    });

    test('is four to a season', () {
      for (final season in Season.values) {
        expect(
          RecipeCatalogue.forSeason(season),
          hasLength(4),
          reason: season.label,
        );
      }
    });

    test('is in a stable order, spring to winter', () {
      expect(RecipeCatalogue.all.map((r) => r.season), [
        ...List.filled(4, Season.spring),
        ...List.filled(4, Season.summer),
        ...List.filled(4, Season.autumn),
        ...List.filled(4, Season.winter),
      ]);
      // And reading it twice gives the same answer in the same order.
      expect(
        RecipeCatalogue.forSeason(Season.autumn).map((r) => r.id),
        RecipeCatalogue.forSeason(Season.autumn).map((r) => r.id),
      );
    });

    test('has no duplicate ids, and every one is findable', () {
      final ids = RecipeCatalogue.all.map((r) => r.id).toSet();
      expect(ids, hasLength(16));

      for (final recipe in RecipeCatalogue.all) {
        expect(RecipeCatalogue.byId(recipe.id), same(recipe));
        // Stable and readable, not generated.
        expect(recipe.id, matches(RegExp(r'^[a-z]+(-[a-z0-9]+)+$')));
        expect(recipe.id, startsWith(recipe.season.name));
      }
    });

    test('has no duplicate names', () {
      final names = RecipeCatalogue.all.map((r) => r.name).toSet();
      expect(names, hasLength(16));
    });
  });

  group('every recipe', () {
    test('has a name and a description worth reading', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(recipe.name.trim(), isNotEmpty, reason: recipe.id);
        expect(recipe.name, recipe.name.trim());
        expect(recipe.description.trim(), isNotEmpty, reason: recipe.id);
        // Short enough for a card, and a whole sentence.
        expect(recipe.description.length, lessThan(70), reason: recipe.id);
        expect(recipe.description, endsWith('.'), reason: recipe.id);
      }
    });

    test('belongs to exactly one season', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(Season.values, contains(recipe.season));
        expect(
          RecipeCatalogue.forSeason(recipe.season),
          contains(recipe),
          reason: recipe.id,
        );
      }
    });

    test('takes a plausible amount of time', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(recipe.prepTime, greaterThan(Duration.zero), reason: recipe.id);
        expect(recipe.cookTime, greaterThan(Duration.zero), reason: recipe.id);
        expect(
          recipe.prepTime.inMinutes,
          lessThanOrEqualTo(30),
          reason: recipe.id,
        );
        expect(
          recipe.cookTime.inMinutes,
          lessThanOrEqualTo(120),
          reason: recipe.id,
        );
        expect(recipe.totalTime, recipe.prepTime + recipe.cookTime);
      }
    });

    test('serves somebody', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(recipe.servings, greaterThan(0), reason: recipe.id);
        expect(recipe.servings, lessThanOrEqualTo(8), reason: recipe.id);
      }
    });

    test('has ingredients, each with an amount and a name', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
        expect(
          recipe.ingredients.length,
          greaterThanOrEqualTo(4),
          reason: recipe.id,
        );

        for (final ingredient in recipe.ingredients) {
          expect(ingredient.name.trim(), isNotEmpty, reason: recipe.id);
          // Either it says how much, or it says the cook decides. Never
          // an amount nobody can act on.
          expect(
            ingredient.toTaste || ingredient.quantity != null,
            isTrue,
            reason: '${recipe.id}: ${ingredient.name}',
          );
          if (ingredient.quantity case final quantity?) {
            expect(quantity, greaterThan(0), reason: recipe.id);
            expect(quantity, lessThanOrEqualTo(2000), reason: recipe.id);
          }
          // A measured ingredient has a unit; a counted one spells the
          // counting word into its name.
          if (ingredient.unit == null && !ingredient.toTaste) {
            expect(
              ingredient.line,
              matches(RegExp(r'^[\d/ ]+\S')),
              reason: '${recipe.id}: ${ingredient.line}',
            );
          }
          expect(ingredient.line.trim(), ingredient.line);
        }
      }
    });

    test('has a method, numbered from one, in order', () {
      for (final recipe in RecipeCatalogue.all) {
        expect(recipe.method, isNotEmpty, reason: recipe.id);
        expect(
          recipe.method.length,
          greaterThanOrEqualTo(3),
          reason: recipe.id,
        );

        for (final instruction in recipe.method) {
          expect(instruction.trim(), isNotEmpty, reason: recipe.id);
          expect(instruction, endsWith('.'), reason: recipe.id);
          // An instruction, not an essay.
          expect(instruction.length, lessThan(200), reason: recipe.id);
        }

        expect(
          recipe.steps.map((s) => s.number),
          List.generate(recipe.method.length, (i) => i + 1),
          reason: recipe.id,
        );
        expect(
          recipe.steps.map((s) => s.instruction),
          recipe.method,
          reason: recipe.id,
        );
        expect(recipe.steps.first.spoken, startsWith('Step 1. '));
      }
    });

    test('says what it happens to be, and nothing about anybody\'s diet', () {
      for (final recipe in RecipeCatalogue.all) {
        // Vegan implies vegetarian, and the label says only vegan.
        if (recipe.tags.contains(DietaryTag.vegan)) {
          expect(
            recipe.tags,
            contains(DietaryTag.vegetarian),
            reason: recipe.id,
          );
          expect(CookbookText.tagLine(recipe), 'Vegan');
        }
      }

      // No free-from claims anywhere in the vocabulary: a listed
      // ingredient cannot promise anything about an allergy.
      for (final tag in DietaryTag.values) {
        for (final claim in ['free', 'safe', 'allergy', 'allergen']) {
          expect(tag.label.toLowerCase(), isNot(contains(claim)));
        }
      }
    });

    test('the tags match what is actually in it', () {
      const animal = [
        'chicken',
        'beef',
        'lamb',
        'pork',
        'bacon',
        'fish',
        'anchovy',
        'butter',
        'milk',
        'cream',
        'yoghurt',
        'cheese',
        'feta',
        'parmesan',
        'egg',
        'honey',
      ];
      const notVegetarian = [
        'chicken',
        'beef',
        'lamb',
        'pork',
        'bacon',
        'fish',
      ];

      for (final recipe in RecipeCatalogue.all) {
        final list = recipe.ingredients
            .map((i) => i.name.toLowerCase())
            .join(' ')
            // Coconut milk is not dairy, and this is a check about what
            // is in a dish rather than about which words appear in it.
            .replaceAll('coconut milk', 'coconut')
            .replaceAll('coconut cream', 'coconut');

        if (recipe.tags.contains(DietaryTag.vegan)) {
          for (final word in animal) {
            expect(
              mentions(list, word),
              isFalse,
              reason: '${recipe.id} is tagged vegan but lists $word',
            );
          }
        }
        if (recipe.tags.contains(DietaryTag.vegetarian)) {
          for (final word in notVegetarian) {
            expect(
              mentions(list, word),
              isFalse,
              reason: '${recipe.id} is tagged vegetarian but lists $word',
            );
          }
        }
      }
    });
  });

  group('what is not in the ingredients', () {
    /// Every word of every recipe, ingredients and method alike.
    List<String> everyLine() => [
      for (final recipe in RecipeCatalogue.all) ...[
        recipe.name,
        recipe.description,
        ?recipe.note,
        for (final ingredient in recipe.ingredients) ingredient.line,
        ...recipe.method,
      ],
    ];

    test('no alcohol', () {
      const alcohol = [
        'wine',
        'beer',
        'cider',
        'brandy',
        'rum',
        'vodka',
        'whisky',
        'whiskey',
        'sherry',
        'vermouth',
        'liqueur',
        'sake',
        'stout',
        'lager',
      ];

      for (final line in everyLine()) {
        for (final word in alcohol) {
          expect(
            mentions(line, word),
            isFalse,
            reason: '"$line" contains "$word"',
          );
        }
      }
    });

    test('no peanuts', () {
      for (final line in everyLine()) {
        expect(mentions(line, 'peanut'), isFalse, reason: line);
        expect(mentions(line, 'peanuts'), isFalse, reason: line);
        expect(mentions(line, 'groundnut'), isFalse, reason: line);
      }
    });

    test('nothing that needs a machine most kitchens do not have', () {
      const specialised = [
        'sous vide',
        'thermomix',
        'pressure cooker',
        'air fryer',
        'dehydrator',
        'mandoline',
        'stand mixer',
        'blowtorch',
        'pasta machine',
      ];

      for (final line in everyLine()) {
        for (final tool in specialised) {
          expect(
            line.toLowerCase().contains(tool),
            isFalse,
            reason: '"$line" needs a $tool',
          );
        }
      }
    });
  });

  group('the wording', () {
    test('makes no health claim', () {
      const claims = [
        'detox',
        'cleanse',
        'anti-inflammatory',
        'inflammation',
        'hormone',
        'healing',
        'heals',
        'immunity',
        'immune',
        'boost',
        'cure',
        'treatment',
        'disease',
        'prevention',
        'superfood',
        'nutrient-dense',
        'metabolism',
        'gut health',
        'wellness benefit',
      ];

      for (final said in CookbookText.everythingSaid) {
        for (final claim in claims) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('counts nothing', () {
      const counting = [
        'calorie',
        'kcal',
        'macro',
        'protein per',
        'carb',
        'low fat',
        'low-fat',
        'fat free',
        'sugar free',
        'kilojoule',
        'portion control',
      ];

      for (final said in CookbookText.everythingSaid) {
        for (final word in counting) {
          expect(
            said.toLowerCase().contains(word),
            isFalse,
            reason: '"$said" contains "$word"',
          );
        }
      }
    });

    test('moralises about nothing', () {
      const moralising = [
        'guilt',
        'guilt-free',
        'cheat',
        'clean eating',
        'naughty',
        'sinful',
        'indulgent',
        'bad for you',
        'good for you',
        'healthy',
        'unhealthy',
        'skinny',
        'slimming',
        'diet ',
      ];

      for (final said in CookbookText.everythingSaid) {
        for (final word in moralising) {
          expect(
            said.toLowerCase().contains(word),
            isFalse,
            reason: '"$said" contains "$word"',
          );
        }
      }
    });

    test('never claims to know what is growing near anybody', () {
      for (final season in Season.values) {
        final note = RecipeCatalogue.collectionNote(season);

        expect(note, contains('A seasonal collection for'));
        expect(note, contains('inspired by'));
        expect(note, contains('wherever you are'));
      }

      for (final said in CookbookText.everythingSaid) {
        final lower = said.toLowerCase();
        for (final claim in [
          'locally in season',
          'in season near you',
          'local produce',
          'grown near',
          'at your farmers',
          'in your region',
        ]) {
          expect(lower.contains(claim), isFalse, reason: '"$said"');
        }
      }
    });
  });

  group('how a quantity is written', () {
    test('whole numbers stay whole, and halves are halves', () {
      expect(formatQuantity(2), '2');
      expect(formatQuantity(1.5), '1 1/2');
      expect(formatQuantity(0.5), '1/2');
      expect(formatQuantity(0.25), '1/4');
      expect(formatQuantity(0.75), '3/4');
      expect(formatQuantity(1.2), '1.2');
    });

    test('an ingredient reads the way a cook would write it', () {
      expect(const Ingredient(1, 'tbsp', 'olive oil').line, '1 tbsp olive oil');
      expect(const Ingredient(500, 'g', 'pumpkin').line, '500 g pumpkin');
      expect(const Ingredient.count(2, 'eggs').line, '2 eggs');
      expect(
        const Ingredient.toTaste('Salt and pepper').line,
        'Salt and pepper, to taste',
      );
      expect(
        const Ingredient(0.5, 'tsp', 'ground ginger').line,
        '1/2 tsp ground ginger',
      );
    });
  });

  group('how a time is written', () {
    test('says minutes and hours in words', () {
      expect(CookbookText.duration(const Duration(minutes: 20)), '20 minutes');
      expect(CookbookText.duration(const Duration(minutes: 1)), '1 minute');
      expect(CookbookText.duration(const Duration(hours: 1)), '1 hour');
      expect(
        CookbookText.duration(const Duration(hours: 1, minutes: 15)),
        '1 hour 15 minutes',
      );
      expect(
        CookbookText.duration(const Duration(minutes: 75)),
        '1 hour 15 minutes',
      );
    });

    test('a card says roughly how long the whole thing takes', () {
      final soup = RecipeCatalogue.byId('autumn-pumpkin-soup');
      expect(CookbookText.totalTime(soup), 'About 45 minutes');
    });
  });
}
