import 'package:almanac/features/meditation/domain/festival_meditation.dart';
import 'package:almanac/features/wheel/domain/festival.dart';
import 'package:almanac/features/yoga/domain/festival_yoga.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the catalogue', () {
    test('holds exactly the eight festivals, in wheel order', () {
      expect(
        WheelOfYear.festivals.map((f) => f.id).toList(),
        FestivalId.values,
      );
    });

    test('every festival has real content in every section', () {
      for (final festival in WheelOfYear.festivals) {
        expect(festival.name, isNotEmpty, reason: festival.id.name);
        expect(festival.seasonalPosition, isNotEmpty, reason: festival.id.name);
        expect(festival.theme, isNotEmpty, reason: festival.id.name);
        expect(festival.about, isNotEmpty, reason: festival.id.name);
        expect(festival.prepare, isNotEmpty, reason: festival.id.name);
        expect(festival.celebrate, isNotEmpty, reason: festival.id.name);
        expect(festival.food.meal, isNotEmpty, reason: festival.id.name);
        expect(festival.food.treat, isNotEmpty, reason: festival.id.name);
        expect(festival.food.drink, isNotEmpty, reason: festival.id.name);
        expect(festival.reflection, isNotEmpty, reason: festival.id.name);
        expect(festival.nature, isNotEmpty, reason: festival.id.name);
      }
    });

    test('byId is total and returns the matching festival', () {
      for (final id in FestivalId.values) {
        expect(WheelOfYear.byId(id).id, id);
      }
    });

    test('does not claim the eight-festival wheel is one unbroken ancient '
        'tradition', () {
      for (final festival in WheelOfYear.festivals) {
        final words = festival.about.join(' ').toLowerCase();
        expect(
          words,
          isNot(contains('always celebrated')),
          reason: festival.id.name,
        );
        expect(
          words,
          isNot(contains('ancient celtic holiday')),
          reason: festival.id.name,
        );
        expect(
          words,
          isNot(contains('unchanged for thousands of years')),
          reason: festival.id.name,
        );
      }
    });
  });

  group('Meditation owns a total mapping', () {
    test('every festival maps to one of the four existing practices', () {
      for (final id in FestivalId.values) {
        final meditation = FestivalMeditations.forFestival(id);
        expect(meditation.festival, id);
        expect(meditation.invitation, isNotEmpty);
      }
    });
  });

  group('Yoga owns a total mapping', () {
    test('every festival maps to one of the three existing practices', () {
      for (final id in FestivalId.values) {
        final suggestion = FestivalYoga.forFestival(id);
        expect(suggestion.festival, id);
        expect(suggestion.invitation, isNotEmpty);
      }
    });
  });
}
