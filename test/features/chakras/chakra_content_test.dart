import 'package:almanac/features/chakras/domain/chakras.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everything the feature can say, in one list — the catalogue plus the
/// two pieces of framing copy the screens show. The wording tests below
/// read this rather than the widgets, so a new sentence has to be added
/// here to be shown at all.
List<String> everythingSaid() => [
  ChakraCatalogue.introduction,
  ChakraCatalogue.reflectionNote,
  for (final chakra in ChakraCatalogue.all) ...[
    chakra.name,
    chakra.sanskrit,
    chakra.place,
    ...chakra.associations,
    chakra.prompt,
    chakra.traditionSentence,
    chakra.semanticLabel,
  ],
];

void main() {
  group('the seven', () {
    test('are seven, and no more', () {
      expect(ChakraCatalogue.all, hasLength(7));
      expect(ChakraId.values, hasLength(7));
    });

    test('are in traditional order, from the base upwards', () {
      expect(ChakraCatalogue.all.map((c) => c.id), [
        ChakraId.root,
        ChakraId.sacral,
        ChakraId.solarPlexus,
        ChakraId.heart,
        ChakraId.throat,
        ChakraId.thirdEye,
        ChakraId.crown,
      ]);
      expect(ChakraCatalogue.all.map((c) => c.name), [
        'Root',
        'Sacral',
        'Solar Plexus',
        'Heart',
        'Throat',
        'Third Eye',
        'Crown',
      ]);
    });

    test('are numbered one to seven, in that order', () {
      expect(ChakraCatalogue.all.map((c) => c.position), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('have no duplicate ids', () {
      final ids = ChakraCatalogue.all.map((c) => c.id).toSet();
      expect(ids, hasLength(ChakraCatalogue.all.length));
    });

    test('can each be found by id', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(ChakraCatalogue.byId(chakra.id), same(chakra));
      }
    });
  });

  group('every chakra', () {
    test('has a name, a transliteration and a place on the body', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.name, isNotEmpty, reason: '${chakra.id}');
        expect(chakra.sanskrit, isNotEmpty, reason: '${chakra.id}');
        expect(chakra.place, isNotEmpty, reason: '${chakra.id}');
      }
    });

    test('has its own transliteration', () {
      final names = ChakraCatalogue.all.map((c) => c.sanskrit).toSet();
      expect(names, hasLength(7));
      expect(names, contains('Muladhara'));
      expect(names, contains('Sahasrara'));
    });

    test('has its own traditional colour, named in words as well', () {
      final hues = ChakraCatalogue.all.map((c) => c.hue).toSet();
      expect(hues, hasLength(7));
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.hue.label, isNotEmpty);
      }
      expect(ChakraCatalogue.root.hue.label, 'red');
      expect(ChakraCatalogue.crown.hue.label, 'violet');
    });

    test('has three associations', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.associations, hasLength(3), reason: '${chakra.id}');
        for (final association in chakra.associations) {
          expect(association, isNotEmpty);
          // Lower case, because they are read inside a sentence.
          expect(association, association.toLowerCase());
        }
      }
    });

    test('has a reflection prompt, and it is a question', () {
      final prompts = ChakraCatalogue.all.map((c) => c.prompt).toSet();
      expect(prompts, hasLength(7));
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.prompt, endsWith('?'), reason: '${chakra.id}');
      }
    });

    test('has a symbol with points to draw', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.points, greaterThan(1), reason: '${chakra.id}');
        // A ring of more than this stops reading as separate points.
        expect(chakra.points, lessThanOrEqualTo(24), reason: '${chakra.id}');
      }
      // The traditional petal counts, where they can be drawn.
      expect(ChakraCatalogue.root.points, 4);
      expect(ChakraCatalogue.throat.points, 16);
      expect(ChakraCatalogue.thirdEye.points, 2);
    });
  });

  group('the wording', () {
    test('reads as a tradition, not as a fact about the body', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(
          chakra.traditionSentence,
          startsWith('Traditionally associated with'),
        );
        expect(chakra.semanticLabel, startsWith('${chakra.name} chakra.'));
      }
      expect(ChakraCatalogue.introduction, contains('In some traditions'));
      expect(
        ChakraCatalogue.root.semanticLabel,
        'Root chakra. Traditionally associated with grounding, stability '
        'and belonging.',
      );
    });

    test('makes no medical or clinical claim', () {
      // The line this feature must never cross: it describes a
      // tradition, it does not describe the body, and it never offers to
      // fix anything.
      const clinical = [
        'cure',
        'heal',
        'treat',
        'therapy',
        'therapeutic',
        'diagnos',
        'disease',
        'illness',
        'symptom',
        'hormone',
        'immune',
        'blocked',
        'blockage',
        'unblock',
        'detox',
        'anxiety',
        'depression',
        'insomnia',
        'proven',
        'scientific',
      ];

      for (final said in everythingSaid()) {
        final lower = said.toLowerCase();
        for (final word in clinical) {
          expect(
            lower.contains(word),
            isFalse,
            reason: '"$said" contains "$word"',
          );
        }
      }
    });

    test('makes nothing into a game or a workout', () {
      const gamified = [
        'streak',
        'score',
        'level',
        'badge',
        'achievement',
        'unlock',
        'reward',
        'challenge',
        'goal',
        'progress',
        'rank',
        'leaderboard',
        'workout',
        'calorie',
        'quiz',
        'test',
      ];

      for (final said in everythingSaid()) {
        final lower = said.toLowerCase();
        for (final word in gamified) {
          expect(
            lower.contains(word),
            isFalse,
            reason: '"$said" contains "$word"',
          );
        }
      }
    });

    test('is short enough to sit on a phone screen', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.prompt.length, lessThan(60), reason: '${chakra.id}');
        expect(
          chakra.traditionSentence.length,
          lessThan(90),
          reason: '${chakra.id}',
        );
      }
      expect(ChakraCatalogue.introduction.length, lessThan(200));
    });
  });

  group('the transliterations', () {
    test('are plain ASCII, so no font has to carry the marks', () {
      // A deliberate choice rather than an oversight: IAST diacritics
      // (Mūlādhāra) would be more correct and are worth revisiting, but
      // they would depend on every font in the app rendering combining
      // marks. If they are ever added, this test is the reminder to
      // check that first.
      for (final chakra in ChakraCatalogue.all) {
        for (final unit in chakra.sanskrit.codeUnits) {
          expect(
            unit,
            lessThan(128),
            reason: '${chakra.sanskrit} is not plain ASCII',
          );
        }
      }
    });

    test('survive a round trip through the phrases that use them', () {
      for (final chakra in ChakraCatalogue.all) {
        expect(chakra.sanskrit.trim(), chakra.sanskrit);
        expect(chakra.sanskrit.runes.length, chakra.sanskrit.length);
      }
    });
  });
}
