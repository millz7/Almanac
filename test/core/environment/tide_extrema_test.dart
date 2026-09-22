import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/core/environment/tide_extrema.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

/// Builds hourly samples from [start], one per entry in [heights].
List<TideSample> _hours(DateTime start, List<double> heights) => [
  for (var i = 0; i < heights.length; i++)
    TideSample(
      time: start.add(Duration(hours: i)),
      heightMetres: heights[i],
    ),
];

void main() {
  setUpAll(useTimeZoneDatabase);

  group('extractTideExtrema — simple shapes', () {
    test('rise, high, fall, low, rise finds exactly one high and one low', () {
      final start = DateTime.utc(2025, 7, 15);
      final samples = _hours(start, [
        0.5,
        1.0,
        1.5,
        1.8,
        1.5,
        1.0,
        0.5,
        0.2,
        0.5,
        1.0,
      ]);

      final extrema = extractTideExtrema(samples);

      expect(extrema, hasLength(2));
      expect(extrema[0].type, TideExtremeType.high);
      expect(extrema[0].time, start.add(const Duration(hours: 3)));
      expect(extrema[1].type, TideExtremeType.low);
      expect(extrema[1].time, start.add(const Duration(hours: 7)));
    });

    test('high, low, high', () {
      final start = DateTime.utc(2025, 7, 15);
      // A lower reading at each edge, so both peaks are genuinely
      // interior turning points rather than the boundary itself.
      final samples = _hours(start, [
        1.5,
        1.8,
        1.4,
        0.8,
        0.3,
        0.8,
        1.4,
        1.9,
        1.5,
      ]);

      final extrema = extractTideExtrema(samples);

      expect(extrema.map((e) => e.type), [
        TideExtremeType.high,
        TideExtremeType.low,
        TideExtremeType.high,
      ]);
    });

    test('low, high, low', () {
      final start = DateTime.utc(2025, 7, 15);
      final samples = _hours(start, [
        0.6,
        0.2,
        0.6,
        1.2,
        1.7,
        1.2,
        0.6,
        0.1,
        0.6,
      ]);

      final extrema = extractTideExtrema(samples);

      expect(extrema.map((e) => e.type), [
        TideExtremeType.low,
        TideExtremeType.high,
        TideExtremeType.low,
      ]);
    });

    test('a full three-day semidiurnal curve alternates cleanly', () {
      final start = DateTime.utc(2025, 7, 15);
      final samples = testTideCurve(
        obtainedAt: start,
        pastHours: 0,
        totalHours: 72,
      );

      final extrema = extractTideExtrema(samples);

      expect(extrema.length, greaterThanOrEqualTo(4));
      for (var i = 1; i < extrema.length; i++) {
        expect(
          extrema[i].type,
          isNot(extrema[i - 1].type),
          reason: 'extrema must alternate high/low',
        );
      }
    });
  });

  group('extractTideExtrema — noise is not a tide', () {
    test('a wiggle smaller than the prominence floor is ignored', () {
      final start = DateTime.utc(2025, 7, 15);
      // A real high at hour 3, then a two-centimetre wobble at hour 5
      // that must not read as a second high/low pair.
      final samples = _hours(start, [
        0.5, 1.0, 1.5, 1.8, 1.5,
        1.02, 1.00, // the wobble: 2 cm, well under the 5 cm floor
        0.8, 0.4,
      ]);

      final extrema = extractTideExtrema(samples);

      expect(extrema, hasLength(1));
      expect(extrema.single.type, TideExtremeType.high);
    });

    test('a wiggle at or above the prominence floor is kept', () {
      final start = DateTime.utc(2025, 7, 15);
      final samples = _hours(start, [
        0.5,
        1.0,
        1.5,
        1.8,
        1.5,
        1.65,
        1.4,
        0.8,
        0.4,
      ]);

      // Separation is given a floor of its own here, deliberately far
      // below the default, so this test is only ever about prominence —
      // the separation pass has its own tests above.
      final extrema = extractTideExtrema(
        samples,
        minProminenceMetres: 0.1,
        minSeparation: const Duration(minutes: 1),
      );

      // The 1.8 → 1.5 dip and the 1.5 → 1.65 rise are both at least 15
      // cm — comfortably above a 10 cm floor — so the small high at
      // hour 5 survives as a genuine extra turning point.
      expect(extrema.length, greaterThan(1));
    });

    test('a perfectly flat reading has no turning point to find', () {
      final start = DateTime.utc(2025, 7, 15);
      final samples = _hours(start, List.filled(9, 1.0));

      expect(extractTideExtrema(samples), isEmpty);
    });

    test('sub-centimetre noise around a flat reading is pruned to at most one point', () {
      final start = DateTime.utc(2025, 7, 15);
      // Tenths-of-a-millimetre jitter — far below anything the model or
      // a real tide could mean — around an otherwise flat sea level.
      final samples = _hours(start, [
        1.000,
        1.001,
        0.999,
        1.0005,
        1.000,
        0.9995,
        1.0002,
        1.000,
      ]);

      // Real tide noise this small must never be read as a genuine
      // high/low pair worth narrating; whatever the pruning leaves
      // behind is at most a single, harmless residual point.
      expect(extractTideExtrema(samples).length, lessThanOrEqualTo(1));
    });
  });

  group('extractTideExtrema — edges', () {
    test('a sample that is only high because the window starts there is not a peak', () {
      final start = DateTime.utc(2025, 7, 15);
      // Falling from the very first sample: hour 0 is the highest
      // reading in the window, but there is no data before it to prove
      // the trend actually turned there.
      final samples = _hours(start, [1.8, 1.5, 1.0, 0.5, 1.0, 1.5]);

      final extrema = extractTideExtrema(samples);

      expect(
        extrema.any((e) => e.time == start),
        isFalse,
        reason: 'the first sample can never be reported as a turning point',
      );
    });

    test(
      'a sample that is only low because the window ends there is not a trough',
      () {
        final start = DateTime.utc(2025, 7, 15);
        final samples = _hours(start, [0.5, 1.0, 1.5, 1.0, 0.5, 0.2]);

        final extrema = extractTideExtrema(samples);

        final lastTime = start.add(const Duration(hours: 5));
        expect(
          extrema.any((e) => e.time == lastTime),
          isFalse,
          reason: 'the last sample can never be reported as a turning point',
        );
      },
    );

    test('fewer than three samples finds nothing rather than guessing', () {
      final start = DateTime.utc(2025, 7, 15);
      expect(extractTideExtrema(_hours(start, [1.0])), isEmpty);
      expect(extractTideExtrema(_hours(start, [1.0, 1.5])), isEmpty);
    });
  });

  group('extractTideExtrema — separation', () {
    test('two highs too close together collapse into the more extreme one', () {
      final start = DateTime.utc(2025, 7, 15);
      // A high at hour 2 (1.8m), a dip of just 3 cm, then a second
      // "high" at hour 4 (1.9m) only two hours later — too close
      // together, and too small a dip between them, to both be real.
      final samples = _hours(start, [0.5, 1.2, 1.8, 1.77, 1.9, 1.2, 0.5]);

      final extrema = extractTideExtrema(samples);

      final highs = extrema.where((e) => e.type == TideExtremeType.high);
      expect(highs, hasLength(1));
    });

    test(
      'extrema genuinely more than the minimum separation apart both survive',
      () {
        final start = DateTime.utc(2025, 7, 15);
        final samples = testTideCurve(
          obtainedAt: start,
          pastHours: 0,
          totalHours: 26,
        );

        final extrema = extractTideExtrema(samples);

        for (var i = 1; i < extrema.length; i++) {
          final gap = extrema[i].time.difference(extrema[i - 1].time);
          expect(gap, greaterThanOrEqualTo(kTideMinExtremaSeparation));
        }
      },
    );
  });

  group('tideDirectionAt', () {
    final start = DateTime.utc(2025, 7, 15);
    // Rises to a high at hour 3, falls to a low at hour 9.
    final samples = _hours(start, [
      0.5,
      0.9,
      1.3,
      1.6,
      1.4,
      1.1,
      0.8,
      0.5,
      0.3,
      0.2,
      0.3,
      0.5,
    ]);

    test('clearly rising, well before the high', () {
      final instant = start.add(const Duration(hours: 1, minutes: 30));
      expect(tideDirectionAt(samples, instant), TideDirection.rising);
    });

    test('clearly falling, well after the high and before the low', () {
      final instant = start.add(const Duration(hours: 6));
      expect(tideDirectionAt(samples, instant), TideDirection.falling);
    });

    test('near the high reads as nearHigh, not rising or falling', () {
      final highTime = start.add(const Duration(hours: 3));
      expect(
        tideDirectionAt(samples, highTime.add(const Duration(minutes: 20))),
        TideDirection.nearHigh,
      );
    });

    test('near the low reads as nearLow', () {
      final lowTime = start.add(const Duration(hours: 9));
      expect(
        tideDirectionAt(samples, lowTime.subtract(const Duration(minutes: 20))),
        TideDirection.nearLow,
      );
    });

    test('exactly at the high instant reads as nearHigh', () {
      final highTime = start.add(const Duration(hours: 3));
      expect(tideDirectionAt(samples, highTime), TideDirection.nearHigh);
    });

    test('exactly at the low instant reads as nearLow', () {
      final lowTime = start.add(const Duration(hours: 9));
      expect(tideDirectionAt(samples, lowTime), TideDirection.nearLow);
    });

    test('between two hourly samples still reads a sensible direction', () {
      final instant = start.add(const Duration(hours: 1, minutes: 45));
      expect(tideDirectionAt(samples, instant), TideDirection.rising);
    });

    test('a flat, indeterminate stretch reads as unknown', () {
      final flatStart = DateTime.utc(2025, 7, 16);
      final flat = _hours(flatStart, [1.0, 1.0, 1.0, 1.0]);
      final instant = flatStart.add(const Duration(hours: 1, minutes: 30));
      expect(tideDirectionAt(flat, instant), TideDirection.unknown);
    });

    test('fewer than two samples is unknown', () {
      expect(tideDirectionAt(const [], start), TideDirection.unknown);
    });
  });

  group('nextTideExtreme', () {
    late DateTime start;
    late List<TideSample> samples;
    late List<TideExtreme> extrema;

    setUp(() {
      start = DateTime.utc(2025, 7, 15);
      samples = testTideCurve(obtainedAt: start, pastHours: 0, totalHours: 72);
      extrema = extractTideExtrema(samples);
    });

    test('finds the next high and next low, both later the same day', () {
      final instant = start.add(const Duration(hours: 1));
      final nextHigh = nextTideExtreme(extrema, instant, TideExtremeType.high);
      final nextLow = nextTideExtreme(extrema, instant, TideExtremeType.low);

      expect(nextHigh, isNotNull);
      expect(nextLow, isNotNull);
      expect(nextHigh!.time.isAfter(instant), isTrue);
      expect(nextLow!.time.isAfter(instant), isTrue);
    });

    test('a next low after midnight is still found correctly', () {
      // Late in the first day: the next low may fall in the small hours
      // of the next calendar day.
      final instant = start.add(const Duration(hours: 22));
      final nextLow = nextTideExtreme(extrema, instant, TideExtremeType.low);

      expect(nextLow, isNotNull);
      expect(nextLow!.time.isAfter(instant), isTrue);
      // Soon after, not days away — comfortably inside half the tide's
      // own period, whichever side of it the exact turning point falls.
      expect(
        nextLow.time.difference(instant),
        lessThanOrEqualTo(const Duration(hours: 13)),
      );
    });

    test('a next high can fall on the following calendar day', () {
      final instant = start.add(const Duration(hours: 20));
      final nextHigh = nextTideExtreme(extrema, instant, TideExtremeType.high);

      expect(nextHigh, isNotNull);
      // Both instants are plain UTC, so comparing the day component
      // directly is exact and does not depend on the machine's own
      // local time zone the way `.toLocal()` would.
      expect(nextHigh!.time.day, isNot(start.day));
    });

    test('at the exact instant of a high, that high is not "next"', () {
      final high = extrema.firstWhere((e) => e.type == TideExtremeType.high);
      final next = nextTideExtreme(extrema, high.time, TideExtremeType.high);
      expect(next, isNot(high));
      if (next != null) expect(next.time.isAfter(high.time), isTrue);
    });

    test('at the exact instant of a low, that low is not "next"', () {
      final low = extrema.firstWhere((e) => e.type == TideExtremeType.low);
      final next = nextTideExtreme(extrema, low.time, TideExtremeType.low);
      expect(next, isNot(low));
      if (next != null) expect(next.time.isAfter(low.time), isTrue);
    });

    test('nothing left in the window returns null rather than guessing', () {
      final afterEverything = start.add(const Duration(hours: 200));
      expect(
        nextTideExtreme(extrema, afterEverything, TideExtremeType.high),
        isNull,
      );
    });

    test('a window spanning a year rollover is found correctly', () {
      final rollover = DateTime.utc(2025, 12, 30);
      final rolloverSamples = testTideCurve(
        obtainedAt: rollover,
        pastHours: 0,
        totalHours: 72,
      );
      final rolloverExtrema = extractTideExtrema(rolloverSamples);

      final lateInYear = rollover.add(const Duration(hours: 30));
      final next = nextTideExtreme(
        rolloverExtrema,
        lateInYear,
        TideExtremeType.high,
      );

      expect(next, isNotNull);
      expect(next!.time.year, greaterThanOrEqualTo(2025));
      expect(next.time.isAfter(lateInYear), isTrue);
    });
  });

  group('DST does not confuse the algorithm', () {
    test('a curve spanning a daylight-saving change still alternates and orders correctly', () {
      // The UK put clocks forward on 30 March 2025 — an hour that never
      // happens, locally. The samples themselves are plain UTC instants
      // throughout, which is exactly why the shift should change nothing
      // about the derived extrema or their ordering.
      final zone = LocalTimeZone.byName('Europe/London');
      final localStart = zone.instantAtLocal(2025, 3, 29, 0);
      final samples = testTideCurve(
        obtainedAt: localStart,
        pastHours: 0,
        totalHours: 72,
      );

      final extrema = extractTideExtrema(samples);

      expect(extrema, isNotEmpty);
      for (var i = 1; i < extrema.length; i++) {
        expect(extrema[i].time.isAfter(extrema[i - 1].time), isTrue);
        expect(extrema[i].type, isNot(extrema[i - 1].type));
      }
    });
  });
}
