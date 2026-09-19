import 'package:almanac/core/context/festival_id.dart';
import 'package:almanac/core/environment/astronomical_seasons.dart';
import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/wheel/domain/festival_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final utc = LocalTimeZone.utc;

  /// The real astronomical instant, as the calendar date it falls on in
  /// UTC — what [FestivalCalendar.dateOf] should agree with for whichever
  /// festival is pinned to [term].
  CalendarDate dateOfTerm(int year, SolarTerm term) =>
      CalendarDate.from(utc.wallTimeAt(solarTermInstant(year, term)));

  group('the four astronomical festivals: northern hemisphere', () {
    test('winter solstice is Yule', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.yule,
          2025,
          Hemisphere.northern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.decemberSolstice),
      );
    });

    test('spring equinox is Ostara', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.ostara,
          2025,
          Hemisphere.northern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.marchEquinox),
      );
    });

    test('summer solstice is Litha', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.litha,
          2025,
          Hemisphere.northern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.juneSolstice),
      );
    });

    test('autumn equinox is Mabon', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.mabon,
          2025,
          Hemisphere.northern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.septemberEquinox),
      );
    });
  });

  group('the four astronomical festivals: southern hemisphere', () {
    test('summer solstice is Litha', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.litha,
          2025,
          Hemisphere.southern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.decemberSolstice),
      );
    });

    test('autumn equinox is Mabon', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.mabon,
          2025,
          Hemisphere.southern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.marchEquinox),
      );
    });

    test('winter solstice is Yule', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.yule,
          2025,
          Hemisphere.southern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.juneSolstice),
      );
    });

    test('spring equinox is Ostara', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.ostara,
          2025,
          Hemisphere.southern,
          utc,
        ),
        dateOfTerm(2025, SolarTerm.septemberEquinox),
      );
    });
  });

  group('the real astronomical instant never depends on hemisphere', () {
    test('the December solstice is the same day for Yule and Litha', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.yule,
          2025,
          Hemisphere.northern,
          utc,
        ),
        FestivalCalendar.dateOf(
          FestivalId.litha,
          2025,
          Hemisphere.southern,
          utc,
        ),
      );
    });

    test('the June solstice is the same day for Litha and Yule', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.litha,
          2025,
          Hemisphere.northern,
          utc,
        ),
        FestivalCalendar.dateOf(
          FestivalId.yule,
          2025,
          Hemisphere.southern,
          utc,
        ),
      );
    });

    test('the March equinox is the same day for Ostara and Mabon', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.ostara,
          2025,
          Hemisphere.northern,
          utc,
        ),
        FestivalCalendar.dateOf(
          FestivalId.mabon,
          2025,
          Hemisphere.southern,
          utc,
        ),
      );
    });

    test('the September equinox is the same day for Mabon and Ostara', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.mabon,
          2025,
          Hemisphere.northern,
          utc,
        ),
        FestivalCalendar.dateOf(
          FestivalId.ostara,
          2025,
          Hemisphere.southern,
          utc,
        ),
      );
    });
  });

  group('the four cross-quarter festivals: northern hemisphere', () {
    test('the documented v1 dates', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.imbolc,
          2025,
          Hemisphere.northern,
          utc,
        ),
        const CalendarDate(2025, 2, 1),
      );
      expect(
        FestivalCalendar.dateOf(
          FestivalId.beltane,
          2025,
          Hemisphere.northern,
          utc,
        ),
        const CalendarDate(2025, 5, 1),
      );
      expect(
        FestivalCalendar.dateOf(
          FestivalId.lughnasadh,
          2025,
          Hemisphere.northern,
          utc,
        ),
        const CalendarDate(2025, 8, 1),
      );
      expect(
        FestivalCalendar.dateOf(
          FestivalId.samhain,
          2025,
          Hemisphere.northern,
          utc,
        ),
        const CalendarDate(2025, 11, 1),
      );
    });
  });

  group('the four cross-quarter festivals: southern hemisphere', () {
    test('shifted exactly six months, keeping the same seasonal meaning', () {
      expect(
        FestivalCalendar.dateOf(
          FestivalId.imbolc,
          2025,
          Hemisphere.southern,
          utc,
        ),
        const CalendarDate(2025, 8, 1),
      );
      expect(
        FestivalCalendar.dateOf(
          FestivalId.beltane,
          2025,
          Hemisphere.southern,
          utc,
        ),
        const CalendarDate(2025, 11, 1),
      );
      expect(
        FestivalCalendar.dateOf(
          FestivalId.lughnasadh,
          2025,
          Hemisphere.southern,
          utc,
        ),
        const CalendarDate(2025, 2, 1),
      );
      expect(
        FestivalCalendar.dateOf(
          FestivalId.samhain,
          2025,
          Hemisphere.southern,
          utc,
        ),
        const CalendarDate(2025, 5, 1),
      );
    });
  });

  group('a full year, in wheel order', () {
    test('northern hemisphere dates run in calendar order across the year', () {
      final year = FestivalCalendar.yearOf(2025, Hemisphere.northern, utc);
      expect(year.map((occurrence) => occurrence.id).toList(), [
        FestivalId.yule,
        FestivalId.imbolc,
        FestivalId.ostara,
        FestivalId.beltane,
        FestivalId.litha,
        FestivalId.lughnasadh,
        FestivalId.mabon,
        FestivalId.samhain,
      ]);

      // Yule in January (last December's solstice, carried into this
      // year) sorts first; the rest of the wheel runs forward from there.
      final rest = year.skip(1).map((occurrence) => occurrence.date).toList();
      for (var i = 1; i < rest.length; i++) {
        expect(rest[i - 1].isBefore(rest[i]), isTrue, reason: '$rest');
      }
    });

    test(
      'southern hemisphere dates are a full year and in wheel order too',
      () {
        final year = FestivalCalendar.yearOf(2025, Hemisphere.southern, utc);
        expect(year.length, 8);
        expect(
          year.map((occurrence) => occurrence.id).toSet(),
          FestivalId.values.toSet(),
        );
      },
    );
  });

  group('next()', () {
    test('finds the nearest upcoming festival within the year', () {
      final occurrences = FestivalCalendar.occurrencesNear(
        const CalendarDate(2025, 4, 1),
        Hemisphere.northern,
        utc,
      );
      final next = FestivalCalendar.next(
        const CalendarDate(2025, 4, 1),
        occurrences,
      );
      expect(next.id, FestivalId.beltane);
      expect(next.date, const CalendarDate(2025, 5, 1));
    });

    test('today counts: on the festival day itself, next is today', () {
      final occurrences = FestivalCalendar.occurrencesNear(
        const CalendarDate(2025, 5, 1),
        Hemisphere.northern,
        utc,
      );
      final next = FestivalCalendar.next(
        const CalendarDate(2025, 5, 1),
        occurrences,
      );
      expect(next.id, FestivalId.beltane);
      expect(next.date, const CalendarDate(2025, 5, 1));
    });

    group('year rollover', () {
      test('late December looks forward into next year for Imbolc', () {
        final today = const CalendarDate(2025, 12, 25);
        final occurrences = FestivalCalendar.occurrencesNear(
          today,
          Hemisphere.northern,
          utc,
        );
        final next = FestivalCalendar.next(today, occurrences);

        expect(next.id, FestivalId.imbolc);
        expect(next.date.year, 2026);
        expect(next.date, const CalendarDate(2026, 2, 1));
      });

      test('the day after Yule looks forward to next year, not backward', () {
        final yule = FestivalCalendar.dateOf(
          FestivalId.yule,
          2025,
          Hemisphere.northern,
          utc,
        );
        final dayAfter = yule.addDays(1);
        final occurrences = FestivalCalendar.occurrencesNear(
          dayAfter,
          Hemisphere.northern,
          utc,
        );
        final next = FestivalCalendar.next(dayAfter, occurrences);

        expect(next.date.isAfter(dayAfter), isTrue);
        expect(next.id, FestivalId.imbolc);
      });

      test('1 January still belongs to the Yule that started in December', () {
        // Yule itself has already passed by New Year's Day (the December
        // solstice is always well before the 31st), so the very next
        // festival from January 1st is Imbolc, not a second Yule.
        final today = const CalendarDate(2025, 1, 1);
        final occurrences = FestivalCalendar.occurrencesNear(
          today,
          Hemisphere.northern,
          utc,
        );
        final next = FestivalCalendar.next(today, occurrences);
        expect(next.id, FestivalId.imbolc);
      });

      test('leap years do not disturb the festival order', () {
        final occurrences = FestivalCalendar.occurrencesNear(
          const CalendarDate(2024, 2, 20),
          Hemisphere.northern,
          utc,
        );
        final next = FestivalCalendar.next(
          const CalendarDate(2024, 2, 20),
          occurrences,
        );
        expect(next.id, FestivalId.ostara);
      });
    });
  });

  group('wheelPosition()', () {
    test('is exactly 0.0 on Yule itself', () {
      final yule = FestivalCalendar.dateOf(
        FestivalId.yule,
        2025,
        Hemisphere.northern,
        utc,
      );
      final occurrences = FestivalCalendar.occurrencesNear(
        yule,
        Hemisphere.northern,
        utc,
      );
      expect(FestivalCalendar.wheelPosition(yule, occurrences), 0.0);
    });

    test('is exactly 0.5 on Litha, the opposite side of the wheel', () {
      final litha = FestivalCalendar.dateOf(
        FestivalId.litha,
        2025,
        Hemisphere.northern,
        utc,
      );
      final occurrences = FestivalCalendar.occurrencesNear(
        litha,
        Hemisphere.northern,
        utc,
      );
      expect(FestivalCalendar.wheelPosition(litha, occurrences), 0.5);
    });

    test('moves monotonically forward between one Yule and the next', () {
      // A "wheel year" rather than a calendar year, so the walk never
      // crosses the one point where the position legitimately resets
      // from just under 1.0 back to exactly 0.0.
      final thisYule = FestivalCalendar.dateOf(
        FestivalId.yule,
        2025,
        Hemisphere.northern,
        utc,
      );
      final nextYule = FestivalCalendar.dateOf(
        FestivalId.yule,
        2026,
        Hemisphere.northern,
        utc,
      );
      final occurrences = FestivalCalendar.occurrencesNear(
        const CalendarDate(2026, 6, 15),
        Hemisphere.northern,
        utc,
      );

      var previousPosition = -1.0;
      var day = thisYule;
      while (day.isBefore(nextYule)) {
        final position = FestivalCalendar.wheelPosition(day, occurrences);
        expect(position, greaterThanOrEqualTo(previousPosition));
        expect(position, greaterThanOrEqualTo(0.0));
        expect(position, lessThan(1.0));
        previousPosition = position;
        day = day.addDays(1);
      }
    });

    test('is deterministic: the same date always gives the same position', () {
      final occurrences = FestivalCalendar.occurrencesNear(
        const CalendarDate(2025, 7, 4),
        Hemisphere.northern,
        utc,
      );
      final a = FestivalCalendar.wheelPosition(
        const CalendarDate(2025, 7, 4),
        occurrences,
      );
      final b = FestivalCalendar.wheelPosition(
        const CalendarDate(2025, 7, 4),
        occurrences,
      );
      expect(a, b);
    });
  });
}
