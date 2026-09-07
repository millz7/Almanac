import 'package:almanac/features/garden/domain/garden_guide.dart';
import 'package:almanac/features/garden/presentation/garden_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/culinary_words.dart';

void main() {
  group('the plant book', () {
    test('is large enough for each shelf to feel real', () {
      expect(PlantBook.all.length, greaterThanOrEqualTo(40));
      expect(PlantBook.all.length, lessThanOrEqualTo(70));

      for (final category in PlantCategory.values) {
        expect(
          PlantBook.ofCategory(category).length,
          greaterThanOrEqualTo(10),
          reason: category.plural,
        );
      }
    });

    test('has every category represented, in book order', () {
      expect(
        PlantBook.all.map((p) => p.category).toSet(),
        PlantCategory.values.toSet(),
      );
      // Vegetables, then herbs, then fruit, then flowers.
      final categories = PlantBook.all.map((p) => p.category).toList();
      expect(categories.first, PlantCategory.vegetable);
      expect(categories.last, PlantCategory.flower);
    });

    test('has unique ids and unique names', () {
      final ids = PlantBook.all.map((p) => p.id).toSet();
      final names = PlantBook.all.map((p) => p.name).toSet();

      expect(ids, hasLength(PlantBook.all.length));
      expect(names, hasLength(PlantBook.all.length));
    });

    test('ids are stable, readable and lower case', () {
      for (final plant in PlantBook.all) {
        expect(
          plant.id,
          matches(RegExp(r'^[a-z]+(-[a-z]+)*$')),
          reason: plant.id,
        );
        expect(PlantBook.byId(plant.id), same(plant));
        expect(PlantBook.contains(plant.id), isTrue);
      }
    });

    test('an unknown id is a null, not a crash', () {
      expect(PlantBook.tryFind('triffid'), isNull);
      expect(PlantBook.contains('triffid'), isFalse);
    });

    test('is ordered alphabetically within each shelf, every time', () {
      for (final category in PlantCategory.values) {
        final names = PlantBook.ofCategory(category).map((p) => p.name);
        expect(
          names,
          orderedEquals([...names]..sort()),
          reason: category.plural,
        );
        // And the same order on a second read.
        expect(
          PlantBook.ofCategory(category).map((p) => p.id),
          PlantBook.ofCategory(category).map((p) => p.id),
        );
      }
    });
  });

  group('every plant', () {
    test('has a name, a description and a lifecycle', () {
      for (final plant in PlantBook.all) {
        expect(plant.name.trim(), isNotEmpty, reason: plant.id);
        expect(plant.name, plant.name.trim());
        expect(plant.description.trim(), isNotEmpty, reason: plant.id);
        expect(plant.description, endsWith('.'), reason: plant.id);
        expect(plant.description.length, lessThan(140), reason: plant.id);
      }
    });

    test('has at least one rule, and every rule is usable', () {
      for (final plant in PlantBook.all) {
        expect(plant.rules, isNotEmpty, reason: plant.id);

        for (final rule in plant.rules) {
          expect(rule.guidance.trim(), isNotEmpty, reason: plant.id);
          expect(rule.guidance, endsWith('.'), reason: plant.id);
          expect(rule.regions, isNotEmpty, reason: plant.id);
          // Only real regions, and no window outside the calendar.
          for (final region in rule.regions) {
            expect(GardeningRegion.values, contains(region));
          }
          expect(rule.window.from, inInclusiveRange(1, 12), reason: plant.id);
          expect(rule.window.to, inInclusiveRange(1, 12), reason: plant.id);
          expect(rule.window.length, inInclusiveRange(1, 12), reason: plant.id);
        }
      }
    });

    test('says where a seed goes whenever it says to sow one', () {
      for (final plant in PlantBook.all) {
        for (final rule in plant.rulesFor(GardenAction.sow)) {
          expect(rule.method, isNotNull, reason: plant.id);
        }
      }
    });

    test('names the attention it wants, and the state it must be in', () {
      for (final plant in PlantBook.all) {
        for (final rule in plant.rulesFor(GardenAction.tend)) {
          expect(rule.tend, isNotNull, reason: plant.id);
          expect(rule.requires, isNotNull, reason: plant.id);
        }
      }
    });

    test('qualifies every pruning rule', () {
      // The one place bad timing does lasting damage, so a pruning rule
      // without a caution is a defect.
      for (final plant in PlantBook.all) {
        for (final rule in plant.rulesFor(GardenAction.prune)) {
          expect(rule.caution, isNotNull, reason: plant.id);
          expect(rule.caution, isNotEmpty, reason: plant.id);
          expect(
            rule.requires,
            EstablishmentState.established,
            reason: plant.id,
          );
        }
      }
    });

    test('keeps ages broad, and only where they mean something', () {
      for (final plant in PlantBook.all) {
        for (final rule in plant.rules) {
          if (rule.minWeeksFromSowing case final weeks?) {
            expect(rule.action, GardenAction.harvest, reason: plant.id);
            expect(weeks, inInclusiveRange(4, 40), reason: plant.id);
          }
        }
      }
    });

    test('is drawn from the small vocabulary of forms', () {
      final formsUsed = PlantBook.all.map((p) => p.form).toSet();
      // Every form in use is a real one, and most of them are used.
      expect(formsUsed.length, greaterThanOrEqualTo(6));
      for (final form in formsUsed) {
        expect(PlantForm.values, contains(form));
      }
    });
  });

  group('the rules a gardener would check', () {
    PlantDefinition plant(String id) => PlantBook.byId(id);

    GardeningRule ruleFor(String id, GardenAction action) =>
        plant(id).rulesFor(action).first;

    test('garlic goes in near the shortest day and comes out near the '
        'longest', () {
      final planting = ruleFor('garlic', GardenAction.plant);
      final harvest = ruleFor('garlic', GardenAction.harvest);

      expect(planting.window.contains(6), isTrue);
      expect(harvest.window.contains(12), isTrue);
      // And it does not shift with the band: the old rule is a calendar
      // one, not a seasonal one.
      expect(planting.shiftsWithRegion, isFalse);
      expect(planting.windowIn(GardeningRegion.nzSouthern), planting.window);
    });

    test('tomatoes are started under cover before they are planted out', () {
      final sowing = ruleFor('tomato', GardenAction.sow);
      final planting = ruleFor('tomato', GardenAction.plant);

      expect(sowing.method, SowingMethod.underCover);
      expect(sowing.window.from, lessThan(planting.window.from));
      expect(planting.caution, contains('Frost'));
    });

    test('stone fruit are pruned in the warm months, not in winter', () {
      for (final id in ['peach', 'plum']) {
        final prune = ruleFor(id, GardenAction.prune);

        // November to February, not June to August: a winter cut in wet
        // weather is how silver leaf gets in, and the caution says so.
        expect(prune.window.contains(12), isTrue, reason: id);
        expect(prune.window.contains(7), isFalse, reason: id);
        expect(prune.caution, contains('silver leaf'), reason: id);
      }
    });

    test('pip fruit are pruned in winter', () {
      for (final id in ['apple', 'pear']) {
        final prune = ruleFor(id, GardenAction.prune);
        expect(prune.window.contains(7), isTrue, reason: id);
      }
    });

    test('lavender is never cut into old wood', () {
      expect(
        ruleFor('lavender', GardenAction.prune).caution,
        contains('old wood'),
      );
    });

    test('kumara and sweetcorn are not offered to the cool south', () {
      for (final id in ['kumara', 'sweetcorn']) {
        for (final rule in plant(id).rules) {
          expect(
            rule.appliesIn(GardeningRegion.nzSouthern),
            isFalse,
            reason: '$id ${rule.action.name}',
          );
          expect(rule.appliesIn(GardeningRegion.nzNorthern), isTrue);
        }
      }
    });

    test('broad beans are an autumn sowing', () {
      final sowing = ruleFor('broad-bean', GardenAction.sow);
      expect(sowing.window.contains(5), isTrue);
      expect(sowing.window.contains(11), isFalse);
    });
  });

  group('the wording', () {
    /// Every sentence the feature can show.
    List<String> everythingSaid() => [
      ...GardenText.everythingSaid,
      for (final plant in PlantBook.all) ...[
        plant.name,
        plant.description,
        for (final rule in plant.rules) ...[rule.guidance, ?rule.caution],
      ],
    ];

    test('promises nothing', () {
      const overclaims = [
        'guaranteed',
        'guarantee',
        'will grow',
        'perfect conditions',
        'must',
        'always works',
        'certain',
        'ready today',
        'harvest today',
      ];

      for (final said in everythingSaid()) {
        for (final claim in overclaims) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('is a recommendation, not a scoreboard', () {
      const gamified = [
        'score',
        'streak',
        'badge',
        'achievement',
        'reward',
        'points',
        'xp',
        'challenge',
        'progress',
      ];

      for (final said in everythingSaid()) {
        expect(
          phrasesIn(said, gamified),
          isEmpty,
          reason: '"$said" reads like a game',
        );
      }

      // "Level" is gardening English — a crown planted level with the
      // soil — so it is the game sense that is banned, not the word.
      for (final said in everythingSaid()) {
        for (final phrase in ['level up', 'next level', 'unlock']) {
          expect(
            said.toLowerCase().contains(phrase),
            isFalse,
            reason: '"$said" contains "$phrase"',
          );
        }
      }
    });

    test('never claims to have seen the plant', () {
      for (final said in everythingSaid()) {
        final lower = said.toLowerCase();
        for (final claim in [
          'your plant is ready',
          'is ready',
          'your tomatoes are ready',
        ]) {
          expect(lower.contains(claim), isFalse, reason: '"$said"');
        }
      }
      // The words it uses instead.
      expect(
        GardenText.actionPhrase(
          GardenSuggestion(
            plant: PlantBook.byId('tomato'),
            rule: PlantBook.byId('tomato').rulesFor(GardenAction.harvest).first,
          ),
        ),
        'May be ready to harvest.',
      );
    });
  });
}
