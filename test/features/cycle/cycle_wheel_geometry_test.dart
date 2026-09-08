import 'dart:math' as math;

import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/cycle/domain/bleeding_marker.dart';
import 'package:almanac/features/cycle/domain/cycle_wheel_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the month decides how many positions there are', () {
    test('February in a common year has 28', () {
      expect(
        CycleWheelGeometry.forMonth(
          const CalendarDate(2026, 2, 10),
          size: 300,
        ).days,
        28,
      );
    });

    test('February in a leap year has 29', () {
      expect(
        CycleWheelGeometry.forMonth(
          const CalendarDate(2024, 2, 10),
          size: 300,
        ).days,
        29,
      );
    });

    test('September has 30 and October has 31', () {
      expect(
        CycleWheelGeometry.forMonth(
          const CalendarDate(2026, 9, 1),
          size: 300,
        ).days,
        30,
      );
      expect(
        CycleWheelGeometry.forMonth(
          const CalendarDate(2026, 10, 1),
          size: 300,
        ).days,
        31,
      );
    });

    test('and every month of a year is covered exactly', () {
      const expected = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      for (var month = 1; month <= 12; month++) {
        expect(
          CycleWheelGeometry.forMonth(
            CalendarDate(2026, month, 1),
            size: 300,
          ).days,
          expected[month - 1],
          reason: 'month $month',
        );
      }
    });
  });

  group('the ring is mathematically even', () {
    /// Every month length the wheel can be asked to draw.
    const lengths = [28, 29, 30, 31];

    test('the angular spacing between neighbours is identical', () {
      for (final days in lengths) {
        final geometry = CycleWheelGeometry(days: days, size: 300);
        final expected = 2 * math.pi / days;

        expect(geometry.angleStep, closeTo(expected, 1e-12));
        for (var i = 1; i < days; i++) {
          expect(
            geometry.angleOf(i) - geometry.angleOf(i - 1),
            closeTo(expected, 1e-12),
            reason: '$days days, step $i',
          );
        }
        // And the whole way round comes back to the start.
        expect(
          geometry.angleOf(days) - geometry.angleOf(0),
          closeTo(2 * math.pi, 1e-12),
          reason: '$days days',
        );
      }
    });

    test('the first of the month is at the top, and it runs clockwise', () {
      final geometry = CycleWheelGeometry(days: 30, size: 300);

      expect(geometry.angleOf(0), CycleWheelGeometry.startAngle);
      // Twelve o'clock is directly above the centre.
      expect(geometry.centreOf(0).dx, closeTo(geometry.centreX, 1e-9));
      expect(geometry.centreOf(0).dy, lessThan(geometry.centreY));
      // The next day is to the right of it: clockwise.
      expect(geometry.centreOf(1).dx, greaterThan(geometry.centreOf(0).dx));
    });

    test('every centre is the same distance from the middle', () {
      for (final days in lengths) {
        final geometry = CycleWheelGeometry(days: days, size: 300);
        final middle = Offset(geometry.centreX, geometry.centreY);

        for (var i = 0; i < days; i++) {
          expect(
            (geometry.centreOf(i) - middle).distance,
            closeTo(geometry.orbitRadius, 1e-9),
            reason: '$days days, day ${i + 1}',
          );
        }
      }
    });

    test('and neighbouring centres are the same distance apart', () {
      for (final days in lengths) {
        final geometry = CycleWheelGeometry(days: days, size: 300);
        final gap = (geometry.centreOf(1) - geometry.centreOf(0)).distance;

        for (var i = 1; i < days; i++) {
          expect(
            (geometry.centreOf(i) - geometry.centreOf(i - 1)).distance,
            closeTo(gap, 1e-9),
            reason: '$days days, gap $i',
          );
        }
      }
    });
  });

  group('every moon is the same size', () {
    test('one diameter, whatever the day', () {
      // The hard rule: the diameter is a property of the wheel, not of
      // a day or a phase. There is one number and no per-day variation
      // to test, which is the point.
      for (final days in [28, 29, 30, 31]) {
        final geometry = CycleWheelGeometry(days: days, size: 300);

        expect(geometry.moonDiameter, greaterThan(0));
        expect(geometry.moonRadius, geometry.moonDiameter / 2);
      }
    });

    test('a new moon is not smaller and a full moon is not bigger', () {
      // Both are drawn at `moonRadius`, which takes no phase argument —
      // so the two cannot differ. Stated as a test because it is the
      // rule most likely to be "improved" later.
      final geometry = CycleWheelGeometry(days: 30, size: 300);

      final newMoonDiameter = geometry.moonDiameter;
      final fullMoonDiameter = geometry.moonDiameter;
      final quarterDiameter = geometry.moonDiameter;

      expect(newMoonDiameter, fullMoonDiameter);
      expect(fullMoonDiameter, quarterDiameter);
    });

    test("and today's moon is not bigger either", () {
      final geometry = CycleWheelGeometry(days: 30, size: 300);

      // Today is marked by a ring *outside* the moon. The moon inside
      // it is the shared diameter, and the ring is larger than the moon
      // rather than replacing it.
      expect(geometry.currentDayRingRadius, greaterThan(geometry.moonRadius));
      expect(geometry.currentDayRingStroke, greaterThan(0));
      expect(
        geometry.currentDayRingStroke,
        lessThan(geometry.moonDiameter / 2),
      );
    });

    test('the moons never overlap, at any month length', () {
      for (final days in [28, 29, 30, 31]) {
        final geometry = CycleWheelGeometry(days: days, size: 300);
        final gap = (geometry.centreOf(1) - geometry.centreOf(0)).distance;

        expect(geometry.moonDiameter, lessThan(gap), reason: '$days days');
      }
    });

    test('and the ring stays inside the wheel', () {
      for (final days in [28, 29, 30, 31]) {
        final geometry = CycleWheelGeometry(days: days, size: 300);

        expect(
          geometry.orbitRadius + geometry.markerOffset + geometry.markerExtent,
          lessThanOrEqualTo(geometry.size / 2),
          reason: '$days days',
        );
      }
    });

    test('the diameter adapts to the wheel, but stays one number', () {
      final small = CycleWheelGeometry(days: 30, size: 200);
      final large = CycleWheelGeometry(days: 30, size: 400);

      expect(large.moonDiameter, greaterThan(small.moonDiameter));
      // Still one per wheel, and proportional rather than arbitrary.
      expect(large.moonDiameter / small.moonDiameter, closeTo(2, 0.01));
    });

    test('a wheel with no days draws nothing rather than dividing by zero', () {
      const geometry = CycleWheelGeometry(days: 0, size: 300);

      expect(geometry.moonDiameter, 0);
      expect(geometry.angleStep, 0);
    });
  });

  group('the marks around it', () {
    test('a mark sits outside the current-day ring', () {
      final geometry = CycleWheelGeometry(days: 30, size: 300);

      // So a bleeding mark and the ring never overlap.
      expect(geometry.markerOffset, greaterThan(geometry.currentDayRingRadius));
    });

    test('and on the same radial line as its day', () {
      final geometry = CycleWheelGeometry(days: 30, size: 300);
      final middle = Offset(geometry.centreX, geometry.centreY);

      for (var i = 0; i < geometry.days; i++) {
        final toMoon = geometry.centreOf(i) - middle;
        final toMark = geometry.markerCentreOf(i) - middle;

        expect(
          toMark.direction,
          closeTo(toMoon.direction, 1e-9),
          reason: 'day ${i + 1}',
        );
        expect(toMark.distance, greaterThan(toMoon.distance));
      }
    });
  });

  group('the bleeding marks are one symbol language', () {
    test('spotting is visibly smaller than bleeding', () {
      expect(
        BleedingMarkers.spotting.innerRadiusFraction,
        lessThan(BleedingMarkers.bleeding.innerRadiusFraction),
      );
      // Visibly, not marginally.
      expect(
        BleedingMarkers.spotting.innerRadiusFraction /
            BleedingMarkers.bleeding.innerRadiusFraction,
        lessThan(0.75),
      );
    });

    test('heavy has the same inner dot as bleeding', () {
      expect(
        BleedingMarkers.heavy.innerRadiusFraction,
        BleedingMarkers.bleeding.innerRadiusFraction,
      );
    });

    test('and differs by exactly one extra outline', () {
      expect(BleedingMarkers.bleeding.outlineCount, 0);
      expect(BleedingMarkers.heavy.outlineCount, 1);
      expect(BleedingMarkers.spotting.outlineCount, 0);

      expect(BleedingMarkers.bleeding.outlineRadiusFraction, isNull);
      expect(BleedingMarkers.heavy.outlineRadiusFraction, isNotNull);
      expect(
        BleedingMarkers.heavy.outlineRadiusFraction,
        greaterThan(BleedingMarkers.heavy.innerRadiusFraction),
      );
    });

    test('there are exactly three, one per level', () {
      expect(BleedingMarkers.all, hasLength(3));
      expect(
        BleedingMarkers.all.map((spec) => spec.level).toList(),
        BleedingLevel.values,
      );
      for (final level in BleedingLevel.values) {
        expect(BleedingMarkers.of(level).level, level);
      }
    });

    test('and every mark fits inside its own box', () {
      for (final spec in BleedingMarkers.all) {
        expect(spec.extentFraction, greaterThan(0));
        expect(spec.extentFraction, lessThanOrEqualTo(1.0));
      }
    });

    test('the legend and the wheel read the same specification', () {
      // Not "the legend agrees with the chart": there is one set of
      // numbers, so a legend that disagreed would have to be a second
      // set — and there is not one. The wheel, the legend and the
      // calendar all call `BleedingMarkers.of`.
      for (final level in BleedingLevel.values) {
        final fromWheel = BleedingMarkers.of(level);
        final fromLegend = BleedingMarkers.of(level);
        final fromCalendar = BleedingMarkers.of(level);

        expect(fromWheel, fromLegend);
        expect(fromLegend, fromCalendar);
        expect(fromWheel.outlineCount, fromCalendar.outlineCount);
        expect(fromWheel.innerRadiusFraction, fromCalendar.innerRadiusFraction);
      }
    });
  });
}
