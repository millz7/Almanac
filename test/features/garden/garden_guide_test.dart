import 'dart:io';

import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/garden/domain/garden_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// The temperate middle, which is the baseline the book is written for.
const temperate = GardeningGuide(
  region: GardeningRegion.nzCentral,
  source: GuideSource.location,
);

CalendarDate on(int month, [int day = 15]) => CalendarDate(2026, month, day);

GardenPlant entry(
  String plantId, {
  EstablishmentState state = EstablishmentState.established,
  CalendarDate? sownOn,
}) => GardenPlant(
  instanceId: plantId,
  plantId: plantId,
  addedOn: sownOn ?? on(1),
  state: state,
  sownOn: sownOn,
);

PersonalGuide personal(
  int month, {
  List<GardenPlant> plants = const [],
  GardeningGuide guide = temperate,
}) =>
    personalGuideFor(guide: guide, today: on(month), garden: MyGarden(plants));

GeneralGuide general(int month, {GardeningGuide guide = temperate}) =>
    generalGuideFor(guide: guide, today: on(month));

Iterable<String> namesIn(List<GardenSuggestion> suggestions) =>
    suggestions.map((s) => s.plant.id);

void main() {
  group('the general guide is discovery', () {
    test('it offers the whole book, whatever the user grows', () {
      // Nobody has told the app anything, and Sow still has plenty in
      // it: sowing is browsing, not personalisation.
      final october = general(10);

      expect(october.sow, isNotEmpty);
      expect(namesIn(october.sow), contains('lettuce'));
      expect(namesIn(october.plant), contains('potato'));
    });

    test('it changes with the month', () {
      // Broad beans are an autumn sowing and tomatoes a late-winter one.
      expect(namesIn(general(5).sow), contains('broad-bean'));
      expect(namesIn(general(5).sow), isNot(contains('tomato')));

      expect(namesIn(general(9).sow), contains('tomato'));
      expect(namesIn(general(9).sow), isNot(contains('broad-bean')));
    });

    test('it changes with the band', () {
      // Tomatoes are sown under cover from August in the temperate
      // middle, a month earlier in the warm north, and a month later in
      // the south.
      const north = GardeningGuide(
        region: GardeningRegion.nzNorthern,
        source: GuideSource.location,
      );
      const south = GardeningGuide(
        region: GardeningRegion.nzSouthern,
        source: GuideSource.location,
      );

      expect(namesIn(general(7, guide: north).sow), contains('tomato'));
      expect(namesIn(general(7).sow), isNot(contains('tomato')));
      expect(namesIn(general(11, guide: south).sow), contains('tomato'));
    });

    test('the northern hemisphere guide is half a year across', () {
      const northern = GardeningGuide(
        region: GardeningRegion.genericNorthern,
        source: GuideSource.hemisphere,
      );

      // A southern October sowing is a northern April one.
      expect(namesIn(general(10).sow), contains('cosmos'));
      expect(namesIn(general(4, guide: northern).sow), contains('cosmos'));
      expect(
        namesIn(general(10, guide: northern).sow),
        isNot(contains('cosmos')),
      );
    });

    test('a band a plant is not offered in never shows it', () {
      const south = GardeningGuide(
        region: GardeningRegion.nzSouthern,
        source: GuideSource.location,
      );

      for (var month = 1; month <= 12; month++) {
        expect(
          namesIn(general(month, guide: south).plant),
          isNot(contains('kumara')),
          reason: 'month $month',
        );
      }
    });
  });

  group('harvest is personal', () {
    test('a plant nobody grows is never suggested', () {
      // February is the middle of the tomato harvest, and the general
      // guide would happily talk about tomatoes...
      expect(
        namesIn(personal(2, plants: [entry('pumpkin')]).harvest),
        isNot(contains('tomato')),
      );
      // ...but an empty garden has nothing to harvest at all.
      expect(personal(2).harvest, isEmpty);
    });

    test('adding the plant is what makes it appear', () {
      final before = personal(2);
      final after = personal(2, plants: [entry('tomato')]);

      expect(namesIn(before.harvest), isNot(contains('tomato')));
      expect(namesIn(after.harvest), contains('tomato'));
    });

    test('and leaving the window is what makes it go away again', () {
      final plants = [entry('tomato')];

      // January to April is the window; July is not.
      expect(namesIn(personal(2, plants: plants).harvest), contains('tomato'));
      expect(
        namesIn(personal(7, plants: plants).harvest),
        isNot(contains('tomato')),
      );
    });

    test('a recorded sowing date holds a harvest back, and then lets it '
        'through', () {
      // Sown in December, harvestable from January — but tomatoes carry
      // a broad sixteen-week minimum, so January is too early for this
      // particular plant and April is not.
      final sown = [entry('tomato', sownOn: on(12, 1))];

      expect(
        namesIn(
          personalGuideFor(
            guide: temperate,
            today: const CalendarDate(2027, 1, 15),
            garden: MyGarden(sown),
          ).harvest,
        ),
        isNot(contains('tomato')),
      );
      expect(
        namesIn(
          personalGuideFor(
            guide: temperate,
            today: const CalendarDate(2027, 4, 1),
            garden: MyGarden(sown),
          ).harvest,
        ),
        contains('tomato'),
      );
    });

    test('an unknown sowing date is not treated as zero weeks', () {
      // With no date recorded the app cannot apply an age, so the
      // calendar window carries the recommendation on its own. Guessing
      // "sown today" would silently hide everything the user added.
      final unknown = [entry('tomato', sownOn: null)];

      expect(namesIn(personal(2, plants: unknown).harvest), contains('tomato'));
    });

    test('it says why it is there, in plain words', () {
      final withDate = personal(
        2,
        // The previous October, so it is genuinely 19 weeks old by
        // February.
        plants: [entry('tomato', sownOn: const CalendarDate(2025, 10, 1))],
      ).harvest.single;
      final withoutDate = personal(2, plants: [entry('tomato')]).harvest.single;

      expect(withDate.reason, 'February · sown 19 weeks ago');
      expect(withoutDate.reason, 'February · established in your garden');
      // And no implementation jargon anywhere in it.
      for (final reason in [withDate.reason!, withoutDate.reason!]) {
        for (final jargon in ['rule', 'window', 'region', 'null', 'true']) {
          expect(reason.toLowerCase(), isNot(contains(jargon)));
        }
      }
    });

    test('the plant stays in My Garden when the window closes', () {
      final garden = MyGarden([entry('tomato')]);

      final winter = personalGuideFor(
        guide: temperate,
        today: on(7),
        garden: garden,
      );

      expect(winter.harvest, isEmpty);
      // Out of the recommendation, still in the garden.
      expect(garden.contains('tomato'), isTrue);
    });
  });

  group('tend is personal', () {
    test('only for plants in the garden, and only when they are ready', () {
      // Tomatoes want staking from November, but only once they are at
      // least a seedling: a seed in the ground does not.
      final sown = [entry('tomato', state: EstablishmentState.sown)];
      final seedling = [entry('tomato', state: EstablishmentState.seedling)];

      expect(personal(12).tend, isEmpty);
      expect(
        namesIn(personal(12, plants: sown).tend),
        isNot(contains('tomato')),
      );
      expect(namesIn(personal(12, plants: seedling).tend), contains('tomato'));
    });

    test('dividing is only for an established clump', () {
      final young = [entry('mint', state: EstablishmentState.seedling)];
      final old = [entry('mint', state: EstablishmentState.established)];

      expect(namesIn(personal(8, plants: young).tend), isNot(contains('mint')));
      expect(namesIn(personal(8, plants: old).tend), contains('mint'));
    });

    test('and it names the kind of attention', () {
      final suggestion = personal(
        12,
        plants: [entry('tomato', state: EstablishmentState.seedling)],
      ).tend.firstWhere((s) => s.rule.tend == TendAction.support);

      expect(suggestion.rule.tend, TendAction.support);
      expect(suggestion.rule.guidance, contains('stake'));
    });

    test('frost protection only appears where frost is expected', () {
      const north = GardeningGuide(
        region: GardeningRegion.nzNorthern,
        source: GuideSource.location,
      );
      final lemon = [entry('lemon', state: EstablishmentState.seedling)];

      final inTheSouth = personal(6, plants: lemon).tend;
      final inTheNorth = personal(6, plants: lemon, guide: north).tend;

      expect(
        inTheSouth.any((s) => s.rule.tend == TendAction.frostProtect),
        isTrue,
      );
      expect(
        inTheNorth.any((s) => s.rule.tend == TendAction.frostProtect),
        isFalse,
      );
    });
  });

  group('prune is personal', () {
    test('nothing is suggested for a garden with nothing in it', () {
      for (var month = 1; month <= 12; month++) {
        expect(personal(month).prune, isEmpty, reason: 'month $month');
      }
    });

    test('an apple in the garden is pruned in winter and not in summer', () {
      final apple = [entry('apple')];

      expect(namesIn(personal(7, plants: apple).prune), contains('apple'));
      expect(
        namesIn(personal(1, plants: apple).prune),
        isNot(contains('apple')),
      );
    });

    test('a young plant is not pruned at all', () {
      final young = [entry('apple', state: EstablishmentState.seedling)];

      expect(personal(7, plants: young).prune, isEmpty);
    });

    test('and the caution travels with it', () {
      final suggestion = personal(1, plants: [entry('peach')]).prune.single;

      expect(suggestion.rule.caution, contains('silver leaf'));
    });
  });

  group('the engine itself', () {
    test('is deterministic', () {
      final plants = [entry('tomato'), entry('apple'), entry('lettuce')];

      final first = personal(2, plants: plants);
      final second = personal(2, plants: plants);

      expect(namesIn(first.harvest), namesIn(second.harvest));
      expect(namesIn(first.tend), namesIn(second.tend));
      expect(namesIn(first.prune), namesIn(second.prune));
    });

    test('is in a stable, alphabetical order', () {
      final plants = [entry('tomato'), entry('courgette'), entry('cucumber')];
      final harvest = personal(2, plants: plants).harvest;

      expect(
        harvest.map((s) => s.plant.name),
        orderedEquals([...harvest.map((s) => s.plant.name)]..sort()),
      );
    });

    test('ignores a plant it has never heard of', () {
      // A garden written by a later version of the app must not crash
      // this one.
      final garden = MyGarden([entry('triffid'), entry('tomato')]);

      final guide = personalGuideFor(
        guide: temperate,
        today: on(2),
        garden: garden,
      );

      expect(namesIn(guide.harvest), ['tomato']);
      expect(garden.plants, hasLength(2));
      expect(garden.known, hasLength(1));
    });

    test('never reads a clock, and computes no probability', () {
      final source = File('lib/features/garden/domain/garden_guide.dart')
          .readAsStringSync();

      expect(source, isNot(contains('DateTime.now')));
      expect(source, isNot(contains('Random')));
      expect(source, isNot(contains('clockProvider')));
    });

    test('every month of the year is safe on an empty garden', () {
      for (final region in GardeningRegion.values) {
        for (var month = 1; month <= 12; month++) {
          final guide = GardeningGuide(
            region: region,
            source: GuideSource.hemisphere,
          );
          expect(
            personalGuideFor(
              guide: guide,
              today: on(month),
              garden: MyGarden.empty,
            ).harvest,
            isEmpty,
          );
          // And the general guide never throws, whatever the month.
          expect(
            generalGuideFor(guide: guide, today: on(month)).sow,
            isA<List<GardenSuggestion>>(),
          );
        }
      }
    });
  });
}
