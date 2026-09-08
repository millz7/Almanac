import 'package:almanac/core/context/almanac_context.dart';
import 'package:almanac/features/environment/domain/moon_reflection.dart';
import 'package:almanac/features/environment/presentation/moon_text.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/meditation/domain/moon_meditation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/culinary_words.dart';

void main() {
  group('the lunar reflections', () {
    test('cover all eight phases, once each, in cycle order', () {
      expect(MoonReflections.all, hasLength(8));
      expect(
        MoonReflections.all.map((r) => r.phase).toList(),
        MoonPhase.values,
      );
    });

    test('every phase can be looked up', () {
      for (final phase in MoonPhase.values) {
        expect(MoonReflections.forPhase(phase).phase, phase);
      }
    });

    test('every one has real content in every field', () {
      for (final reflection in MoonReflections.all) {
        final id = reflection.phase.name;

        expect(reflection.theme.trim(), isNotEmpty, reason: id);
        expect(reflection.theme.length, lessThan(40), reason: id);

        expect(reflection.explanation.trim(), isNotEmpty, reason: id);
        expect(reflection.explanation.length, greaterThan(60), reason: id);
        expect(reflection.explanation, endsWith('.'), reason: id);

        expect(reflection.words, hasLength(4), reason: id);
        for (final word in reflection.words) {
          expect(word.trim(), isNotEmpty, reason: id);
        }
        expect(reflection.wordLine, contains(' · '), reason: id);

        expect(
          reflection.practices.length,
          greaterThanOrEqualTo(4),
          reason: id,
        );
        expect(
          reflection.practices.toSet(),
          hasLength(reflection.practices.length),
          reason: id,
        );
      }
    });

    test('every theme is distinct: eight phases, eight ideas', () {
      expect(MoonReflections.all.map((r) => r.theme).toSet(), hasLength(8));
      expect(
        MoonReflections.all.map((r) => r.explanation).toSet(),
        hasLength(8),
      );
    });

    test('every practice has words to show, whatever it opens', () {
      for (final practice in MoonPractice.values) {
        expect(practice.label.trim(), isNotEmpty, reason: practice.name);
      }
    });

    test('every phase offers a way to Meditation among its practices', () {
      // The guidance is what carries the doorway. If a phase named no
      // destination there would be nothing for the doorway to attach to.
      for (final reflection in MoonReflections.all) {
        expect(
          reflection.destinations,
          contains(FeatureId.meditation),
          reason: reflection.phase.name,
        );
        // Named once, however many practices point there.
        expect(
          reflection.destinations.length,
          reflection.destinations.toSet().length,
          reason: reflection.phase.name,
        );
      }
    });
  });

  group('the reflective content claims nothing about a body', () {
    /// Everything the Moon and its Meditation suggestion can say.
    List<String> everythingSaid() => [
      ...MoonText.everythingSaid,
      for (final practice in MoonPractice.values) practice.label,
      for (final reflection in MoonReflections.all) ...[
        reflection.theme,
        reflection.explanation,
        ...reflection.words,
      ],
      for (final meditation in MoonMeditations.all) meditation.invitation,
    ];

    test('no biological or hormonal effect', () {
      const forbidden = [
        'hormone',
        'hormonal',
        'oestrogen',
        'estrogen',
        'progesterone',
        'melatonin',
        'cortisol',
        'serotonin',
        'gravitational pull on',
        'affects your body',
        'affects the body',
        'changes your body',
        'water in your body',
        'biological',
        'physiological',
        'immune',
        'nervous system',
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

    test('no menstrual or fertility claim, and no cycle talk at all', () {
      // The moon is astronomy; a cycle is something the user recorded.
      // The Moon page does not mention one, let alone claim the other
      // moves it.
      const forbidden = [
        'menstrual',
        'menstruation',
        'period',
        'ovulat',
        'fertile',
        'fertility',
        'conceive',
        'womb',
        'bleed',
        'luteal',
        'follicular',
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

    test('no guaranteed emotional or personality effect', () {
      const forbidden = [
        'will make you feel',
        'makes you feel',
        'will feel',
        'causes you to',
        'you will be',
        'makes people',
        'your personality',
        'people born under',
        'your star sign',
        'determines',
        'controls your',
        'controls the',
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

    test('no medical or therapeutic claim', () {
      const forbidden = [
        'cure',
        // Narrowed from a bare 'treat'. The harm is a claim to treat a
        // condition; "in some traditions this is treated as the tending
        // part of the month" is a sentence about a tradition. The same
        // class of false positive as the Cookbook's red wine vinegar.
        'treats ',
        'treatment',
        'used to treat',
        'heals',
        'diagnos',
        'symptom',
        'disorder',
        'anxiety',
        'depression',
        'insomnia',
        'clinically',
        'proven',
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

    test('it offers rather than instructs', () {
      // Every explanation hedges, or names the tradition it comes from.
      for (final reflection in MoonReflections.all) {
        final lower = reflection.explanation.toLowerCase();
        expect(
          lower.contains('can be used') ||
              lower.contains('may be') ||
              lower.contains('you might') ||
              lower.contains('traditions'),
          isTrue,
          reason: '${reflection.phase.name}: "${reflection.explanation}"',
        );
      }
    });

    test('it never tells anybody they must do anything', () {
      const forbidden = [
        'you must',
        'you should',
        'you need to',
        'make sure you',
        'do not forget to',
        'required',
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

    test('the reflective half is framed, not disclaimed', () {
      // Named once, as an invitation into a way of reading — not as a
      // warning about what the writing is not.
      expect(MoonText.reflectiveFraming, startsWith('In some modern'));
      expect(MoonText.reflectiveFraming, contains('spiritual traditions'));
      expect(MoonText.reflectiveFraming, contains('reflection'));
    });

    test('and the old disclaimer sentence is gone', () {
      // It read as a policy document rather than an almanac. Nothing
      // the app can say contains it any more.
      for (final said in everythingSaid()) {
        for (final disclaimer in [
          'not a physical effect',
          'is not a physical',
          'no scientific',
          'not scientifically',
          'this is not medical',
          'does not affect',
        ]) {
          expect(
            said.toLowerCase().contains(disclaimer),
            isFalse,
            reason: '"$said" contains "$disclaimer"',
          );
        }
      }
    });

    test('and the tradition is named once, not paragraph by paragraph', () {
      // Said at the top of the reflective passage, so every phase
      // underneath can simply be written.
      final naming = [
        MoonText.reflectiveFraming,
        for (final reflection in MoonReflections.all) reflection.explanation,
      ].where((said) => said.toLowerCase().contains('spiritual traditions'));

      expect(naming, hasLength(1));
      expect(naming.single, MoonText.reflectiveFraming);
    });

    test('the factual and reflective halves stay distinct', () {
      // The factual half states what the moon is doing; the reflective
      // half offers. Neither leaks into the other.
      for (final factual in [
        MoonText.title,
        MoonText.illumination(34),
        for (final phase in MoonPhase.values) MoonText.direction(phase),
        for (final phase in MoonPhase.values) phase.label,
      ]) {
        final lower = factual.toLowerCase();
        for (final reflective in [
          'you might',
          'traditions',
          'can be used',
          'may be',
          'reflect',
        ]) {
          expect(
            lower.contains(reflective),
            isFalse,
            reason: 'factual "$factual" reads as reflective',
          );
        }
      }

      // And the reflective half never states a measurement.
      for (final reflection in MoonReflections.all) {
        expect(reflection.explanation, isNot(contains('%')));
        expect(
          reflection.explanation.toLowerCase(),
          isNot(contains('illuminated')),
          reason: reflection.phase.name,
        );
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
        'complete',
        'goal',
        'rank',
        // Narrowed from a bare 'level': "a longer, level breath" is a
        // description of breathing, not a game mechanic.
        'level up',
        'next level',
        'unlock',
      ];

      for (final said in everythingSaid()) {
        expect(
          phrasesIn(said, gamified),
          isEmpty,
          reason: '"$said" reads like a game',
        );
      }
    });
  });

  group("Meditation's answer to a moon", () {
    test('covers all eight phases, once each', () {
      expect(MoonMeditations.all, hasLength(8));
      expect(
        MoonMeditations.all.map((m) => m.phase).toList(),
        MoonPhase.values,
      );
    });

    test('every phase points at a practice that already exists', () {
      for (final phase in MoonPhase.values) {
        final technique = MoonMeditations.techniqueFor(phase);
        // Not a ninth pattern invented for the moon: one of the four.
        expect(MeditationTechniques.all, contains(technique));
        expect(technique.pattern.steps, isNotEmpty);
      }
    });

    test('and all four practices remain reachable on their own', () {
      expect(MeditationTechniques.all, hasLength(4));
      expect(MeditationTechniques.all.map((t) => t.name).toSet(), {
        'Focus',
        'Sleep',
        'Balance',
        'Release Tension',
      });
    });

    test('every invitation is a line about the practice', () {
      for (final meditation in MoonMeditations.all) {
        expect(
          meditation.invitation.trim(),
          isNotEmpty,
          reason: meditation.phase.name,
        );
        expect(
          meditation.invitation,
          endsWith('.'),
          reason: meditation.phase.name,
        );
        expect(
          meditation.invitation.length,
          lessThan(120),
          reason: meditation.phase.name,
        );
      }
    });

    test('the suggestion is deterministic', () {
      for (final phase in MoonPhase.values) {
        expect(
          MoonMeditations.forPhase(phase),
          MoonMeditations.forPhase(phase),
        );
      }
    });
  });
}
