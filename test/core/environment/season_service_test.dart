import 'package:almanac/core/environment/astronomical_seasons.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/season.dart';
import 'package:almanac/core/environment/season_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  const service = AstronomicalSeasonService();

  group('solarTermInstant', () {
    // Published equinox/solstice times (UTC). If the implementation ever
    // degraded into a month-range approximation these would be out by days,
    // so the tolerance below is deliberately tight.
    const tolerance = Duration(minutes: 10);

    void expectInstant(int year, SolarTerm term, DateTime expected) {
      final actual = solarTermInstant(year, term);
      final difference = actual.difference(expected).abs();
      expect(
        difference,
        lessThan(tolerance),
        reason:
            '${term.name} $year: expected ~$expected, got $actual '
            '(off by $difference)',
      );
    }

    test('matches published 2024 instants', () {
      expectInstant(
        2024,
        SolarTerm.marchEquinox,
        DateTime.utc(2024, 3, 20, 3, 6),
      );
      expectInstant(
        2024,
        SolarTerm.juneSolstice,
        DateTime.utc(2024, 6, 20, 20, 51),
      );
      expectInstant(
        2024,
        SolarTerm.septemberEquinox,
        DateTime.utc(2024, 9, 22, 12, 44),
      );
      expectInstant(
        2024,
        SolarTerm.decemberSolstice,
        DateTime.utc(2024, 12, 21, 9, 20),
      );
    });

    test('matches published 2025 instants', () {
      expectInstant(
        2025,
        SolarTerm.marchEquinox,
        DateTime.utc(2025, 3, 20, 9, 1),
      );
      expectInstant(
        2025,
        SolarTerm.decemberSolstice,
        DateTime.utc(2025, 12, 21, 15, 3),
      );
    });

    test('returns UTC instants', () {
      expect(solarTermInstant(2025, SolarTerm.juneSolstice).isUtc, isTrue);
    });
  });

  group('northern hemisphere', () {
    Season seasonOn(DateTime instant) =>
        service.seasonAt(instant, Hemisphere.northern).season;

    test('mid-month dates land in the expected seasons', () {
      expect(seasonOn(DateTime.utc(2025, 1, 15)), Season.winter);
      expect(seasonOn(DateTime.utc(2025, 4, 15)), Season.spring);
      expect(seasonOn(DateTime.utc(2025, 7, 15)), Season.summer);
      expect(seasonOn(DateTime.utc(2025, 10, 15)), Season.autumn);
    });

    test('June solstice starts summer, not the 1st of the month', () {
      // The solstice is on the 21st, so mid-June is still spring.
      expect(seasonOn(DateTime.utc(2025, 6, 1)), Season.spring);
      expect(seasonOn(DateTime.utc(2025, 6, 30)), Season.summer);
    });
  });

  group('southern hemisphere', () {
    Season seasonOn(DateTime instant) =>
        service.seasonAt(instant, Hemisphere.southern).season;

    test('seasons are the opposite of the north on the same dates', () {
      expect(seasonOn(DateTime.utc(2025, 1, 15)), Season.summer);
      expect(seasonOn(DateTime.utc(2025, 4, 15)), Season.autumn);
      expect(seasonOn(DateTime.utc(2025, 7, 15)), Season.winter);
      expect(seasonOn(DateTime.utc(2025, 10, 15)), Season.spring);
    });

    test('Christmas in New Zealand is summer, and in London winter', () {
      final christmas = DateTime.utc(2025, 12, 25, 12);

      expect(
        service.seasonAt(christmas, TestLocations.wellington.hemisphere).season,
        Season.summer,
      );
      expect(
        service.seasonAt(christmas, TestLocations.london.hemisphere).season,
        Season.winter,
      );
    });

    test('Sydney in July is winter', () {
      expect(
        service
            .seasonAt(
              DateTime.utc(2025, 7, 10),
              TestLocations.sydney.hemisphere,
            )
            .season,
        Season.winter,
      );
    });
  });

  group('season boundaries', () {
    test('the season flips across the solstice instant, not the date', () {
      final solstice = solarTermInstant(2025, SolarTerm.juneSolstice);
      final justBefore = solstice.subtract(const Duration(minutes: 1));
      final justAfter = solstice.add(const Duration(minutes: 1));

      expect(
        service.seasonAt(justBefore, Hemisphere.northern).season,
        Season.spring,
      );
      expect(
        service.seasonAt(justAfter, Hemisphere.northern).season,
        Season.summer,
      );
    });

    test('reports when the current season began and ends', () {
      final state = service.seasonAt(
        DateTime.utc(2025, 7, 15),
        Hemisphere.northern,
      );

      expect(state.startedAt, solarTermInstant(2025, SolarTerm.juneSolstice));
      expect(state.endsAt, solarTermInstant(2025, SolarTerm.septemberEquinox));
      expect(state.startedAt.isBefore(state.endsAt), isTrue);
    });

    test('January belongs to the quarter that began last December', () {
      final state = service.seasonAt(
        DateTime.utc(2025, 1, 15),
        Hemisphere.northern,
      );

      expect(state.season, Season.winter);
      expect(
        state.startedAt,
        solarTermInstant(2024, SolarTerm.decemberSolstice),
      );
      expect(state.endsAt, solarTermInstant(2025, SolarTerm.marchEquinox));
    });

    test(
      'a local date either side of the equinox agrees across time zones',
      () {
        // The March 2025 equinox is at 09:01 UTC on the 20th. In Wellington
        // (+13) that is 22:01 local on the 20th, so 12:00 local on the 20th
        // in Wellington is still the previous season, while the same local
        // clock time in London is already the new one.
        final equinox = solarTermInstant(2025, SolarTerm.marchEquinox);
        final wellingtonNoon = TestLocations.wellington.toInstant(
          DateTime.utc(2025, 3, 20, 12),
        );
        final londonNoon = TestLocations.london.toInstant(
          DateTime.utc(2025, 3, 20, 12),
        );

        expect(wellingtonNoon.isBefore(equinox), isTrue);
        expect(londonNoon.isAfter(equinox), isTrue);

        expect(
          service.seasonAt(wellingtonNoon, Hemisphere.southern).season,
          Season.summer,
        );
        expect(
          service.seasonAt(londonNoon, Hemisphere.northern).season,
          Season.spring,
        );
      },
    );
  });
}
