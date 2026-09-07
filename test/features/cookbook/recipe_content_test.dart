import 'package:almanac/features/cookbook/domain/recipe_catalogue.dart';
import 'package:almanac/features/cookbook/presentation/cookbook_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/culinary_words.dart';

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
      for (final recipe in RecipeCatalogue.all) {
        final list = recipe.ingredients.map((i) => i.name).join(', ');

        if (recipe.tags.contains(DietaryTag.vegan)) {
          expect(
            animalProductsIn(list),
            isEmpty,
            reason: '${recipe.id} is tagged vegan',
          );
        }
        if (recipe.tags.contains(DietaryTag.vegetarian)) {
          expect(
            meatOrFishIn(list),
            isEmpty,
            reason: '${recipe.id} is tagged vegetarian',
          );
        }
      }
    });

    test('a recipe with animal products is not tagged vegan', () {
      // The other direction: the tags have to be complete as well as
      // true. Anything with no animal product in it and no tag would be
      // a missed vegan.
      for (final recipe in RecipeCatalogue.all) {
        final list = recipe.ingredients.map((i) => i.name).join(', ');
        final animal = animalProductsIn(list);

        expect(
          recipe.tags.contains(DietaryTag.vegan),
          animal.isEmpty,
          reason: animal.isEmpty
              ? '${recipe.id} has no animal products but is not tagged vegan'
              : '${recipe.id} is tagged vegan but lists ${animal.join(', ')}',
        );
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
      for (final line in everyLine()) {
        expect(alcoholIn(line), isEmpty, reason: '"$line" names a drink');
      }
    });

    test('no peanuts', () {
      for (final line in everyLine()) {
        expect(
          phrasesIn(line, ['peanut', 'peanuts', 'groundnut', 'groundnuts']),
          isEmpty,
          reason: line,
        );
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
        'hormones',
        'healing',
        'heals',
        'immunity',
        'immune',
        'boost',
        'boosts',
        'boosting',
        'superfoods',
        'nutrient-dense',
        // Whole words, so a future recipe may still describe a cured
        // ham or a manicured herb garden.
        'cure',
        'cures',
        'treatment',
        'disease',
        'prevention',
        'superfood',
        'metabolism',
        'gut health',
      ];

      for (final said in CookbookText.everythingSaid) {
        expect(
          phrasesIn(said, claims),
          isEmpty,
          reason: '"$said" makes a health claim',
        );
      }
    });

    test('counts nothing', () {
      const counting = [
        'calorie',
        'calories',
        'kcal',
        'kilojoule',
        'kilojoules',
        'macro',
        'macros',
        // Whole words, so carbonara is safe and a carb count is not.
        'carb',
        'carbs',
        'low-fat',
        'fat-free',
        'sugar-free',
      ];

      for (final said in CookbookText.everythingSaid) {
        expect(
          phrasesIn(said, counting),
          isEmpty,
          reason: '"$said" counts something',
        );
      }
      // The multi-word ones, which a word list cannot hold.
      for (final said in CookbookText.everythingSaid) {
        for (final phrase in [
          'low fat',
          'fat free',
          'sugar free',
          'protein per',
          'portion control',
        ]) {
          expect(
            said.toLowerCase().contains(phrase),
            isFalse,
            reason: '"$said" contains "$phrase"',
          );
        }
      }
    });

    test('moralises about nothing', () {
      const moralising = [
        'guilt',
        'guilt-free',
        'cheat',
        'cheating',
        'naughty',
        'sinful',
        'indulgent',
        'healthy',
        'unhealthy',
        'skinny',
        'slimming',
        // Whole word, so "dietary" is not caught by "diet".
        'diet',
      ];

      for (final said in CookbookText.everythingSaid) {
        expect(
          phrasesIn(said, moralising),
          isEmpty,
          reason: '"$said" moralises',
        );
      }
      for (final said in CookbookText.everythingSaid) {
        for (final phrase in [
          'clean eating',
          'good for you',
          'bad for you',
          'wellness benefit',
        ]) {
          expect(
            said.toLowerCase().contains(phrase),
            isFalse,
            reason: '"$said" contains "$phrase"',
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

  group('the content checks themselves', () {
    // These checks exist to keep genuinely unsuitable things out of the
    // recipes. A word list alone cannot do that: it rejects real
    // ingredients whose names merely contain an awkward word, and the
    // rejections look authoritative. Both directions are pinned here.

    group('a vinegar is not a drink', () {
      test('wine vinegars pass', () {
        for (final ingredient in [
          '1 tbsp red wine vinegar',
          '2 tsp white wine vinegar',
          '1 tbsp rice wine vinegar',
          '1 tbsp wine vinegar',
          '1 tbsp cider vinegar',
          '1 tbsp sherry vinegar',
          '1 tsp malt vinegar',
          '1 tbsp balsamic vinegar',
        ]) {
          expect(alcoholIn(ingredient), isEmpty, reason: ingredient);
        }
      });

      test('and the vinegar in the book is the one that was meant', () {
        final vegetables = RecipeCatalogue.byId(
          'summer-grilled-summer-vegetables',
        );
        expect(
          vegetables.ingredients.map((i) => i.line),
          contains('1 tbsp red wine vinegar'),
        );
      });

      test('but a real drink is still caught', () {
        expect(alcoholIn('150 ml white wine'), contains('wine'));
        expect(alcoholIn('a splash of red wine'), contains('wine'));
        expect(alcoholIn('50 ml brandy'), contains('brandy'));
        expect(alcoholIn('2 tbsp dark rum'), contains('rum'));
        expect(alcoholIn('330 ml beer'), contains('beer'));
        expect(alcoholIn('100 ml dry sherry'), contains('sherry'));
        expect(alcoholIn('1 tbsp orange liqueur'), contains('liqueur'));
        expect(alcoholIn('Deglaze the pan with white wine.'), isNotEmpty);
        expect(alcoholIn('50 ml vodka'), contains('vodka'));
        expect(alcoholIn('2 tbsp whisky'), contains('whisky'));
      });
    });

    group('a butter bean is a bean', () {
      test('butter beans are vegan', () {
        for (final ingredient in [
          '800 g tins cannellini or butter beans, drained',
          '400 g butter beans',
          '1 tin butter bean',
        ]) {
          expect(animalProductsIn(ingredient), isEmpty, reason: ingredient);
        }
      });

      test('and the stew lists them again', () {
        final stew = RecipeCatalogue.byId('winter-vegetable-and-bean-stew');
        expect(
          stew.ingredients.map((i) => i.line),
          contains('800 g tins cannellini or butter beans, drained'),
        );
        expect(stew.tags, contains(DietaryTag.vegan));
      });

      test('other plant foods named after animal ones are fine too', () {
        for (final ingredient in [
          '400 ml tin coconut milk',
          '200 ml coconut cream',
          '250 ml oat milk',
          '2 tbsp almond butter',
          '1 eggplant, sliced into rounds',
          '1 tsp cream of tartar',
          '1 butternut squash',
        ]) {
          expect(animalProductsIn(ingredient), isEmpty, reason: ingredient);
        }
      });

      test('but real dairy, eggs and meat are still caught', () {
        expect(animalProductsIn('100 g butter, softened'), contains('butter'));
        expect(animalProductsIn('100 ml milk'), contains('milk'));
        expect(animalProductsIn('200 ml cream'), contains('cream'));
        expect(animalProductsIn('250 ml buttermilk'), contains('buttermilk'));
        expect(animalProductsIn('80 g feta, crumbled'), contains('feta'));
        expect(animalProductsIn('8 eggs'), contains('eggs'));
        expect(animalProductsIn('2 tbsp honey'), contains('honey'));
        expect(animalProductsIn('1.5 kg whole chicken'), contains('chicken'));
        expect(meatOrFishIn('4 fillets salmon'), contains('salmon'));
        expect(meatOrFishIn('200 g bacon'), contains('bacon'));
        // Vegetarian is about meat and fish, not about dairy.
        expect(meatOrFishIn('100 g butter, softened'), isEmpty);
      });
    });

    group('whole words, not spellings', () {
      test('a coincidence of letters is not an ingredient', () {
        expect(alcoholIn('80 g feta, crumbled'), isEmpty);
        expect(alcoholIn('1 tsp ground cumin'), isEmpty);
        expect(animalProductsIn('1 eggplant'), isEmpty);
        expect(animalProductsIn('2 courgettes'), isEmpty);
        expect(phrasesIn('Cook the carbonara.', ['carb']), isEmpty);
        expect(phrasesIn('Serve with cured ham.', ['cure']), isEmpty);
        expect(phrasesIn('Dietary notes.', ['diet']), isEmpty);
      });

      test('and the word itself still is', () {
        expect(phrasesIn('30 g carbs', ['carbs']), contains('carbs'));
        expect(
          phrasesIn('It will cure what ails you.', ['cure']),
          contains('cure'),
        );
        expect(
          phrasesIn('A diet you can stick to.', ['diet']),
          contains('diet'),
        );
      });
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
