import 'package:almanac/features/nature_log/domain/nature_book.dart';
import 'package:almanac/features/nature_log/presentation/nature_log_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/culinary_words.dart';

void main() {
  group('the Nature Book', () {
    test('is a modest shelf, not a field guide to everything', () {
      expect(NatureBook.all.length, greaterThanOrEqualTo(40));
      expect(NatureBook.all.length, lessThanOrEqualTo(70));
    });

    test('has all five categories, in book order', () {
      expect(
        NatureBook.all.map((i) => i.category).toSet(),
        NatureCategory.values.toSet(),
      );
      expect(NatureBook.all.first.category, NatureCategory.bird);
      expect(NatureBook.all.last.category, NatureCategory.other);

      for (final category in NatureCategory.values) {
        expect(
          NatureBook.ofCategory(category),
          isNotEmpty,
          reason: category.plural,
        );
      }
    });

    test('has unique ids and unique primary names', () {
      final ids = NatureBook.all.map((i) => i.id).toSet();
      final names = NatureBook.all.map((i) => i.primaryName).toSet();

      expect(ids, hasLength(NatureBook.all.length));
      expect(names, hasLength(NatureBook.all.length));
    });

    test('ids are stable, readable and lower case', () {
      for (final item in NatureBook.all) {
        expect(
          item.id,
          matches(RegExp(r'^[a-z]+(-[a-z]+)*$')),
          reason: item.id,
        );
        expect(NatureBook.byId(item.id), same(item));
        expect(NatureBook.contains(item.id), isTrue);
      }
    });

    test('an unknown id is a null, not a crash', () {
      expect(NatureBook.tryFind('moa'), isNull);
      expect(NatureBook.contains('moa'), isFalse);
    });

    test('is ordered alphabetically within each shelf, every time', () {
      for (final category in NatureCategory.values) {
        final names = NatureBook.ofCategory(category).map((i) => i.primaryName);
        expect(names, orderedEquals([...names]..sort()));
        expect(
          NatureBook.ofCategory(category).map((i) => i.id),
          NatureBook.ofCategory(category).map((i) => i.id),
        );
      }
    });
  });

  group('every entry', () {
    test('has a name and something worth reading', () {
      for (final item in NatureBook.all) {
        expect(item.primaryName.trim(), isNotEmpty, reason: item.id);
        expect(item.primaryName, item.primaryName.trim());
        expect(item.description.trim(), isNotEmpty, reason: item.id);
        expect(item.description, endsWith('.'), reason: item.id);
        expect(item.description.length, lessThan(180), reason: item.id);
      }
    });

    test('keeps its names clean, and neither is empty', () {
      for (final item in NatureBook.all) {
        if (item.alternateName case final other?) {
          expect(other.trim(), isNotEmpty, reason: item.id);
          expect(other, other.trim(), reason: item.id);
          // Two names, not the same name twice.
          expect(other, isNot(item.primaryName), reason: item.id);
        }
        if (item.scientificName case final latin?) {
          expect(latin.trim(), isNotEmpty, reason: item.id);
          // A genus, and usually a species: never a common name in
          // disguise.
          expect(latin, matches(RegExp(r'^[A-Z][a-z]+')), reason: item.id);
        }
      }
    });

    test('leads with a Māori name where there is one, without forcing an '
        'English one', () {
      // Both shapes are legitimate: some entries carry two names, some
      // only one, and the model does not insist.
      expect(NatureBook.byId('tui').primaryName, 'Tūī');
      expect(NatureBook.byId('tui').alternateName, isNull);
      expect(NatureBook.byId('piwakawaka').primaryName, 'Pīwakawaka');
      expect(NatureBook.byId('piwakawaka').alternateName, 'Fantail');
      expect(NatureBook.byId('piwakawaka').displayName, 'Pīwakawaka · Fantail');
      expect(
        NatureBook.byId('piwakawaka').spokenName,
        'Pīwakawaka, Fantail. Bird.',
      );
    });

    test('has seasonal notes that are real windows', () {
      for (final item in NatureBook.all) {
        for (final note in item.notes) {
          expect(note.text.trim(), isNotEmpty, reason: item.id);
          expect(note.text, endsWith('.'), reason: item.id);
          expect(note.window.from, inInclusiveRange(1, 12), reason: item.id);
          expect(note.window.to, inInclusiveRange(1, 12), reason: item.id);
          expect(note.window.length, inInclusiveRange(1, 12), reason: item.id);
          expect(NatureNoteKind.values, contains(note.kind));
        }
      }
    });

    test('has notes only about noticing', () {
      // Nothing about touching, feeding, keeping or taking anything.
      const forbidden = [
        'touch',
        'handle',
        'hold',
        'feed the',
        'feeding station',
        'catch',
        'collect',
        'pick up',
        'nest box',
        // The harm is telling somebody to disturb a nest. A fantail
        // following you for the insects you disturb as you walk is a
        // description of a bird, not an instruction — the same class of
        // false positive as a naive word blacklist in the Cookbook.
        'disturb the nest',
        'disturb a nest',
        'disturb nests',
        'take home',
        'keep one',
      ];

      for (final item in NatureBook.all) {
        for (final line in [
          item.description,
          ...item.notes.map((n) => n.text),
        ]) {
          for (final phrase in forbidden) {
            expect(
              line.toLowerCase().contains(phrase),
              isFalse,
              reason: '${item.id}: "$line" contains "$phrase"',
            );
          }
        }
      }
    });
  });

  group('the fungi shelf', () {
    test('says nothing about eating anything', () {
      const foraging = [
        'edible',
        'inedible',
        'safe to eat',
        'poisonous',
        'toxic',
        'deadly',
        'delicious',
        'tastes',
        'cook',
        'forage',
        'harvest',
        'pick',
      ];

      for (final item in NatureBook.ofCategory(NatureCategory.fungi)) {
        for (final line in [
          item.description,
          ...item.notes.map((n) => n.text),
        ]) {
          for (final word in foraging) {
            expect(
              line.toLowerCase().contains(word),
              isFalse,
              reason: '${item.id}: "$line" contains "$word"',
            );
          }
        }
      }
    });

    test('and the app says so out loud', () {
      expect(NatureLogText.fungiNote, contains('not to foraging'));
      expect(NatureLogText.fungiNote, contains('says nothing'));
    });
  });

  group('the wording', () {
    List<String> everythingSaid() => [
      ...NatureLogText.everythingSaid,
      for (final item in NatureBook.all) ...[
        item.primaryName,
        ?item.alternateName,
        item.description,
        for (final note in item.notes) note.text,
      ],
    ];

    test('never says anybody will see anything', () {
      const certainty = [
        'you will see',
        'you will hear',
        'guaranteed',
        'guarantee',
        'is here now',
        'definitely',
        'always present',
        'certain to',
      ];

      for (final said in everythingSaid()) {
        for (final claim in certainty) {
          expect(
            said.toLowerCase().contains(claim),
            isFalse,
            reason: '"$said" contains "$claim"',
          );
        }
      }
    });

    test('offers rather than asserts', () {
      // Every seasonal note is phrased as something that often happens
      // or is worth looking or listening for.
      for (final item in NatureBook.all) {
        for (final note in item.notes) {
          final lower = note.text.toLowerCase();
          expect(
            lower.contains('often') ||
                lower.contains('worth') ||
                lower.contains('may ') ||
                lower.contains('can '),
            isTrue,
            reason: '${item.id}: "${note.text}"',
          );
        }
      }
    });

    test('keeps no score', () {
      const gamified = [
        'streak',
        'badge',
        'points',
        'xp',
        'achievement',
        'reward',
        'challenge',
        'rare',
        'rarity',
        'complete',
        'goal',
        'rank',
        'collected',
      ];

      for (final said in everythingSaid()) {
        expect(
          phrasesIn(said, gamified),
          isEmpty,
          reason: '"$said" reads like a game',
        );
      }
    });

    test('does not moralise about what belongs here', () {
      // Introduced species sit in the book beside native ones, and the
      // book does not editorialise.
      const loaded = [
        'pest',
        'invasive',
        'weed',
        'vermin',
        'should be removed',
        'does not belong',
        'harmful',
      ];

      for (final item in NatureBook.all) {
        for (final line in [
          item.description,
          ...item.notes.map((n) => n.text),
        ]) {
          for (final word in loaded) {
            expect(
              line.toLowerCase().contains(word),
              isFalse,
              reason: '${item.id}: "$line" contains "$word"',
            );
          }
        }
      }
    });
  });
}
