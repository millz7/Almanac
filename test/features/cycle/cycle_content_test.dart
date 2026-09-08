import 'dart:io';

import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/domain/cycle_syncing.dart';
import 'package:almanac/features/cycle/domain/moon_cycle_type.dart';
import 'package:almanac/features/cycle/presentation/cycle_text.dart';
import 'package:almanac/features/meditation/domain/cycle_meditation.dart';
import 'package:almanac/features/yoga/domain/cycle_yoga.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/culinary_words.dart';

/// Everything the Cycle feature and its three answers can say.
List<String> everythingSaid() => [
  ...CycleText.everythingSaid,
  for (final guide in PhaseGuides.all) ...[
    guide.focus,
    guide.about,
    ...guide.food,
    ...guide.movement,
    guide.reflection,
    guide.duration,
  ],
  for (final suggestion in CycleYoga.all) suggestion.invitation,
  for (final meditation in CycleMeditations.all) meditation.invitation,
];

void main() {
  group('the four phase guides', () {
    test('there is one for every phase, and only one', () {
      expect(PhaseGuides.all, hasLength(4));
      expect(PhaseGuides.all.map((g) => g.phase).toList(), CyclePhase.values);
      for (final phase in CyclePhase.values) {
        expect(PhaseGuides.forPhase(phase).phase, phase);
      }
    });

    test('every section of every one has real content', () {
      for (final guide in PhaseGuides.all) {
        final id = guide.phase.name;

        expect(guide.focus.trim(), isNotEmpty, reason: id);
        expect(guide.focus.length, lessThan(40), reason: id);

        expect(guide.about.trim(), isNotEmpty, reason: id);
        expect(guide.about.length, greaterThan(60), reason: id);

        expect(guide.food.length, greaterThanOrEqualTo(3), reason: id);
        expect(guide.movement.length, greaterThanOrEqualTo(3), reason: id);
        for (final line in [...guide.food, ...guide.movement]) {
          expect(line.trim(), isNotEmpty, reason: id);
          expect(line, endsWith('.'), reason: '$id: "$line"');
        }

        expect(guide.reflection.trim(), isNotEmpty, reason: id);
        expect(guide.duration.trim(), isNotEmpty, reason: id);
      }
    });

    test('the four are actually different from each other', () {
      expect(PhaseGuides.all.map((g) => g.focus).toSet(), hasLength(4));
      expect(PhaseGuides.all.map((g) => g.about).toSet(), hasLength(4));
      expect(PhaseGuides.all.map((g) => g.duration).toSet(), hasLength(4));
    });

    test('menstruation offers iron-containing foods, by name', () {
      final food = PhaseGuides.forPhase(CyclePhase.menstrual).food
          .join(' ')
          .toLowerCase();

      // Because menstruation involves blood loss and that is worth
      // knowing — not because anybody is told they are short of iron.
      expect(food, contains('iron'));
      for (final example in ['spinach', 'lentils', 'beans', 'eggs']) {
        expect(food, contains(example), reason: example);
      }
      // And the pairing that actually helps absorption.
      expect(food, contains('vitamin-c'));
    });

    test('and never says the user is deficient or needs a supplement', () {
      const forbidden = [
        'deficien',
        'supplement',
        'you need iron',
        'low in iron',
        'top up your',
        'replenish your',
        'restore your',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('movement is offered, never forbidden and never required', () {
      for (final guide in PhaseGuides.all) {
        final movement = guide.movement.join(' ').toLowerCase();
        expect(
          movement.contains('if') ||
              movement.contains('may') ||
              movement.contains('whatever'),
          isTrue,
          reason: guide.phase.name,
        );
      }

      const forbidden = [
        'do not exercise',
        'avoid exercise',
        'no exercise',
        'must rest',
        'should rest',
        'must not',
        'you have to',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });
  });

  group('what Cycle Syncing never claims', () {
    test('no detox, no seed cycling, no hormone-balancing foods', () {
      const forbidden = [
        'detox',
        'seed cycling',
        'seed-cycling',
        'hormone balancing',
        'hormone-balancing',
        'balance your hormones',
        'clean eating',
        'superfood',
        'anti-inflammatory diet',
        'elimination diet',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('no guaranteed energy, mood or capability', () {
      const forbidden = [
        'you will feel',
        'you will have',
        'you will be',
        'your energy will',
        'energy is highest',
        'energy is lowest',
        'you will want',
        'makes you feel',
        'you should feel',
        'expect to feel',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('no fertility, conception or pregnancy anywhere', () {
      const forbidden = [
        'fertile',
        'fertility',
        'infertil',
        'conceive',
        'conception',
        'pregnan',
        'safe day',
        'trying for',
        'basal temperature',
        'ovulation test',
        'cervical',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('and the domain contains no fertility arithmetic', () {
      final sources = Directory('lib/features/cycle/domain')
          .listSync()
          .whereType<File>()
          .expand((file) => file.readAsLinesSync())
          .where((line) => !line.trimLeft().startsWith('///'))
          .join('\n')
          .toLowerCase();

      for (final forbidden in ['fertile', 'conception', 'pregnan']) {
        expect(sources, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('no medical diagnosis or symptom interpretation', () {
      const forbidden = [
        'diagnos',
        'symptom',
        'disorder',
        'pcos',
        'endometriosis',
        'see a doctor',
        'consult a',
        'medical advice',
        'treats ',
        'cures',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('and it does not plaster the screen with disclaimers either', () {
      // The claims are kept out of the content rather than apologised
      // for. One honest line about experience differing is enough.
      const disclaimers = [
        'not medical advice',
        'informational purposes',
        'consult your doctor',
        'we are not doctors',
        'this is not a substitute',
      ];

      for (final said in everythingSaid()) {
        for (final claim in disclaimers) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
      expect(
        everythingSaid().where((said) => said == kExperienceMayDiffer),
        hasLength(1),
      );
    });
  });

  group('the moon and the cycle stay separate', () {
    test('nothing says the moon moves a period', () {
      const forbidden = [
        'the moon causes',
        'moon controls',
        'caused by the moon',
        'because of the moon',
        'the moon makes',
        'moon affects your',
        'lunar biology',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('and nothing suggests a period should match the moon', () {
      const forbidden = [
        'should align',
        'in sync with the moon',
        'back in sync',
        'realign your',
        'correct your cycle',
        'better alignment',
        'ideal alignment',
        'out of sync',
        'natural rhythm restored',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('the four moon cycle types are not ranked', () {
      const forbidden = [
        'healthier',
        'more natural',
        'more feminine',
        'more spiritual',
        'more fertile',
        'the best',
        'better than',
        'most desirable',
        'ideal',
        'rare and special',
      ];

      for (final type in MoonCycleType.values) {
        for (final said in [
          type.label,
          CycleText.moonCycleLine(type),
          CycleText.moonCycleAbout(type),
          ...CycleText.moonCycleThemes(type),
        ]) {
          for (final claim in forbidden) {
            expect(
              said.toLowerCase().contains(claim),
              isFalse,
              reason: '"$said" contains "$claim"',
            );
          }
        }
      }
      // And the app says out loud that none is better.
      expect(CycleText.moonCycleChanges, contains('None of the four'));
    });

    test('each type is framed as a tradition, not as biology', () {
      for (final type in MoonCycleType.values) {
        expect(
          CycleText.moonCycleAbout(type),
          startsWith('In some modern spiritual traditions'),
          reason: type.name,
        );
        expect(
          CycleText.moonCycleThemes(type),
          hasLength(4),
          reason: type.name,
        );
      }
      expect(
        CycleText.moonCycleFraming,
        startsWith('In some modern spiritual traditions'),
      );
    });

    test('and it says the type can change', () {
      expect(CycleText.moonCycleChanges, contains('different'));
      expect(CycleText.moonCycleChanges, contains('next month'));
    });

    test('no type is described as a kind of person', () {
      const forbidden = [
        // Narrowed from a bare 'you are a', which matched "whatever you
        // are already making" — a sentence about pumpkin seeds. The harm
        // is naming a type as somebody's identity, so the phrases name
        // the types. Same class of false positive as the Cookbook's red
        // wine vinegar.
        'you are a white',
        'you are a red',
        'you are a pink',
        'you are a purple',
        'moon woman',
        'moon women',
        'your type is',
        'personality',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });
  });

  group('the wording elsewhere', () {
    test('says "estimated" where a value is estimated', () {
      expect(CycleText.dayLineEstimated(12), contains('estimated'));
      expect(
        CycleText.nextPeriodAround(const CalendarDate(2026, 9, 24)),
        contains('estimated'),
      );
      expect(
        CycleText.nextPeriodAround(const CalendarDate(2026, 9, 24)),
        contains('around'),
      );
      for (final phase in CyclePhase.values) {
        expect(phase.heading, contains('Approximate'));
      }
    });

    test('and never presents an estimate as a fact', () {
      const forbidden = [
        'your period will begin',
        'your next period is',
        'you will bleed',
        'definitely',
        'guaranteed',
        // Narrowed from a bare 'exactly'. "Your recorded dates stay
        // exactly as you entered them" is a promise about data, and the
        // right one to make; the harm is claiming a duration nobody has.
        'exactly 5',
        'exactly five',
        'exactly 14',
        'exactly fourteen',
        'lasts exactly',
      ];

      for (final said in everythingSaid()) {
        for (final claim in forbidden) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('it keeps no score', () {
      const gamified = [
        'streak',
        'badge',
        'points',
        'xp',
        'achievement',
        'reward',
        'challenge',
        'goal',
        'rank',
      ];

      for (final said in everythingSaid()) {
        expect(
          phrasesIn(said, gamified),
          isEmpty,
          reason: '"$said" reads like a game',
        );
      }
    });

    test('and says where the data lives', () {
      expect(CycleText.privacyNote, contains('this device'));
      expect(CycleText.privacyNote, contains('delete'));
    });

    test('a phase override is described as the user\'s, not a correction', () {
      expect(CycleText.phaseIsYours, contains('you chose'));
      expect(CycleText.phaseIsYours, contains('unchanged'));
    });
  });
}
