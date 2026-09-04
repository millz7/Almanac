import 'dart:math' as math;

import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/solar_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  /// Published sunrise/sunset times are quoted to the minute, and the
  /// algorithm claims about a minute of accuracy, so allow a small margin
  /// either way. Anything broken would be out by hours, not minutes.
  const tolerance = Duration(minutes: 3);

  /// Asserts that a calculated instant reads as the expected local
  /// clock time in the given zone.
  void expectLocalTime(
    DateTime? actual,
    LocalTimeZone zone,
    int hour,
    int minute, {
    required String label,
  }) {
    expect(actual, isNotNull, reason: '$label should have a time');
    final local = zone.wallTimeAt(actual!);
    final expected = zone.instantAtLocal(
      local.year,
      local.month,
      local.day,
      hour,
      minute,
    );
    final difference = actual.difference(expected).abs();

    expect(
      difference,
      lessThan(tolerance),
      reason:
          '$label: expected about '
          '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} local, got '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')} '
          '(off by $difference)',
    );
  }

  /// Day length from the closed-form sunrise hour-angle equation:
  ///
  ///     cos H = cos(z) / (cos φ · cos δ) − tan φ · tan δ
  ///
  /// with z the 90.833° sunrise zenith. Day length is then 2H/15 hours.
  ///
  /// This is an independent check on the calculator — a different route to
  /// the same answer, written out here rather than reusing any of the
  /// production code — so it catches an error in the calculator's own
  /// bookkeeping rather than just restating its output.
  Duration dayLengthFromHourAngle({
    required double latitude,
    required double declinationDegrees,
  }) {
    double radians(double degrees) => degrees * math.pi / 180;

    final cosHourAngle =
        math.cos(radians(90.833)) /
            (math.cos(radians(latitude)) *
                math.cos(radians(declinationDegrees))) -
        math.tan(radians(latitude)) * math.tan(radians(declinationDegrees));

    final hourAngleDegrees = math.acos(cosHourAngle) * 180 / math.pi;
    return Duration(
      milliseconds: (2 * hourAngleDegrees / 15 * Duration.millisecondsPerHour)
          .round(),
    );
  }

  void expectDayLengthMatchesHourAngle(
    SolarTimes times, {
    required double latitude,
    required double declinationDegrees,
    required String label,
  }) {
    final actual = times.sunset!.difference(times.sunrise!);
    final expected = dayLengthFromHourAngle(
      latitude: latitude,
      declinationDegrees: declinationDegrees,
    );

    expect(
      (actual - expected).abs(),
      lessThan(const Duration(minutes: 5)),
      reason:
          '$label: calculated day length ${actual.inMinutes} min, '
          'hour-angle formula gives ${expected.inMinutes} min',
    );
  }

  group('Wellington, New Zealand (southern hemisphere)', () {
    // -41.2866, 174.7756. Reference times from NOAA's solar calculator.
    SolarTimes on(int month, int day) => SolarCalculator.forDate(
      year: 2025,
      month: month,
      day: day,
      latitude: TestLocations.wellington.latitude,
      longitude: TestLocations.wellington.longitude,
    );

    test('midwinter: a short day around the June solstice', () {
      final times = on(6, 21);
      final zone = TestTimeZones.wellington;

      // NZST (UTC+12) in June — no daylight saving.
      expectLocalTime(times.sunrise, zone, 7, 47, label: 'winter sunrise');
      expectLocalTime(times.sunset, zone, 16, 58, label: 'winter sunset');
    });

    test('midsummer: a long day around the December solstice', () {
      final times = on(12, 21);
      final zone = TestTimeZones.wellington;

      // NZDT (UTC+13) in December — daylight saving in effect, which the
      // zone handles rather than this test.
      expectLocalTime(times.sunrise, zone, 5, 44, label: 'summer sunrise');

      // The sunset is pinned by day length rather than by a quoted time:
      // see the independent hour-angle cross-check below, which derives
      // the expected length from first principles instead of trusting a
      // remembered table.
      expectDayLengthMatchesHourAngle(
        times,
        latitude: TestLocations.wellington.latitude,
        declinationDegrees: -23.43,
        label: 'Wellington December solstice',
      );
    });

    test('the equinox gives a day close to twelve hours', () {
      final times = on(9, 22);
      final dayLength = times.sunset!.difference(times.sunrise!);

      expect(dayLength.inMinutes, closeTo(12 * 60, 15));
    });

    test('midsummer days are much longer than midwinter days', () {
      final winter = on(6, 21);
      final summer = on(12, 21);

      final winterLength = winter.sunset!.difference(winter.sunrise!);
      final summerLength = summer.sunset!.difference(summer.sunrise!);

      expect(summerLength, greaterThan(winterLength));
      // Wellington's day length swings by roughly six hours.
      expect((summerLength - winterLength).inHours, closeTo(6, 1));
    });
  });

  group('London (northern hemisphere)', () {
    // 51.5074, -0.1278. The same algorithm, the opposite seasons.
    SolarTimes on(int month, int day) => SolarCalculator.forDate(
      year: 2025,
      month: month,
      day: day,
      latitude: TestLocations.london.latitude,
      longitude: TestLocations.london.longitude,
    );

    test('midsummer: a long day around the June solstice', () {
      final times = on(6, 21);
      final zone = TestTimeZones.london;

      // BST (UTC+1) in June.
      expectLocalTime(times.sunrise, zone, 4, 43, label: 'summer sunrise');
      expectLocalTime(times.sunset, zone, 21, 21, label: 'summer sunset');
    });

    test('midwinter: a short day around the December solstice', () {
      final times = on(12, 21);
      final zone = TestTimeZones.london;

      // GMT (UTC+0) in December.
      expectLocalTime(times.sunrise, zone, 8, 3, label: 'winter sunrise');
      expectLocalTime(times.sunset, zone, 15, 53, label: 'winter sunset');
    });

    test('the seasons run opposite to Wellington', () {
      final londonJune = on(6, 21);
      final londonDecember = on(12, 21);
      final londonJuneLength = londonJune.sunset!.difference(
        londonJune.sunrise!,
      );
      final londonDecemberLength = londonDecember.sunset!.difference(
        londonDecember.sunrise!,
      );

      // June is London's long day; in Wellington it is the short one.
      expect(londonJuneLength, greaterThan(londonDecemberLength));

      final wellingtonJune = SolarCalculator.forDate(
        year: 2025,
        month: 6,
        day: 21,
        latitude: TestLocations.wellington.latitude,
        longitude: TestLocations.wellington.longitude,
      );
      final wellingtonJuneLength = wellingtonJune.sunset!.difference(
        wellingtonJune.sunrise!,
      );
      expect(wellingtonJuneLength, lessThan(londonJuneLength));
    });
  });

  group('the equator', () {
    test('day and night stay near twelve hours all year', () {
      for (final month in [3, 6, 9, 12]) {
        final times = SolarCalculator.forDate(
          year: 2025,
          month: month,
          day: 21,
          latitude: TestLocations.equator.latitude,
          longitude: TestLocations.equator.longitude,
        );

        expect(times.kind, SolarDayKind.risesAndSets);
        final dayLength = times.sunset!.difference(times.sunrise!);
        expect(
          dayLength.inMinutes,
          closeTo(12 * 60, 20),
          reason: 'month $month should be close to a twelve-hour day',
        );
      }
    });
  });

  group('polar edge cases', () {
    // Tromsø, 69.65°N, is inside the Arctic circle.
    SolarTimes tromsoOn(int month, int day) => SolarCalculator.forDate(
      year: 2025,
      month: month,
      day: day,
      latitude: TestLocations.tromso.latitude,
      longitude: TestLocations.tromso.longitude,
    );

    test('midnight sun in midsummer, with no times invented', () {
      final times = tromsoOn(6, 21);

      expect(times.kind, SolarDayKind.sunNeverSets);
      expect(times.sunrise, isNull);
      expect(times.sunset, isNull);
    });

    test('polar night in midwinter, with no times invented', () {
      final times = tromsoOn(12, 21);

      expect(times.kind, SolarDayKind.sunNeverRises);
      expect(times.sunrise, isNull);
      expect(times.sunset, isNull);
    });

    test('ordinary days either side of the polar seasons', () {
      // At the equinoxes even the Arctic has a normal sunrise.
      expect(tromsoOn(3, 21).kind, SolarDayKind.risesAndSets);
      expect(tromsoOn(9, 21).kind, SolarDayKind.risesAndSets);
    });

    test('the poles themselves do not crash', () {
      for (final latitude in [90.0, -90.0]) {
        for (final month in [1, 6, 12]) {
          final times = SolarCalculator.forDate(
            year: 2025,
            month: month,
            day: 15,
            latitude: latitude,
            longitude: 0,
          );
          // Whatever it says, it must not throw and must not invent a
          // time it cannot justify.
          if (times.kind != SolarDayKind.risesAndSets) {
            expect(times.sunrise, isNull);
            expect(times.sunset, isNull);
          }
        }
      }
    });

    test('the southern polar seasons are the mirror image', () {
      // Antarctica: midnight sun in December, polar night in June.
      SolarTimes antarcticaOn(int month) => SolarCalculator.forDate(
        year: 2025,
        month: month,
        day: 21,
        latitude: -75,
        longitude: 0,
      );

      expect(antarcticaOn(12).kind, SolarDayKind.sunNeverSets);
      expect(antarcticaOn(6).kind, SolarDayKind.sunNeverRises);
    });
  });

  group('general properties', () {
    test('sunrise always precedes sunset, worldwide, across the year', () {
      for (final latitude in [-60.0, -33.9, 0.0, 35.7, 51.5, 64.1]) {
        for (final longitude in [-157.9, -74.0, 0.0, 18.9, 151.2, 174.8]) {
          for (final month in [1, 4, 7, 10]) {
            final times = SolarCalculator.forDate(
              year: 2025,
              month: month,
              day: 15,
              latitude: latitude,
              longitude: longitude,
            );
            if (times.kind != SolarDayKind.risesAndSets) continue;

            expect(
              times.sunrise!.isBefore(times.sunset!),
              isTrue,
              reason: 'at $latitude,$longitude in month $month',
            );
            expect(times.sunrise!.isUtc, isTrue);
          }
        }
      }
    });

    test('a day is never longer than 24 hours', () {
      for (final latitude in [-66.0, -20.0, 20.0, 66.0]) {
        for (final month in [1, 6, 12]) {
          final times = SolarCalculator.forDate(
            year: 2025,
            month: month,
            day: 21,
            latitude: latitude,
            longitude: 0,
          );
          if (times.kind != SolarDayKind.risesAndSets) continue;

          final length = times.sunset!.difference(times.sunrise!);
          expect(length, lessThanOrEqualTo(const Duration(hours: 24)));
          expect(length, greaterThan(Duration.zero));
        }
      }
    });

    test('sunrise moves later as you go west within a zone', () {
      // Four degrees of longitude is about sixteen minutes of time.
      final east = SolarCalculator.forDate(
        year: 2025,
        month: 3,
        day: 21,
        latitude: 51.5,
        longitude: 0,
      );
      final west = SolarCalculator.forDate(
        year: 2025,
        month: 3,
        day: 21,
        latitude: 51.5,
        longitude: -4,
      );

      final gap = west.sunrise!.difference(east.sunrise!);
      expect(gap.inMinutes, closeTo(16, 2));
    });
  });
}
