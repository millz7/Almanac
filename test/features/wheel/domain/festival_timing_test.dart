import 'package:almanac/core/time/calendar_date.dart';
import 'package:almanac/features/wheel/domain/festival_timing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const festival = CalendarDate(2025, 5, 1);

  group('timingStateFor', () {
    test('more than 7 days before is normal', () {
      expect(
        timingStateFor(festival, festival.addDays(-8)),
        FestivalTimingState.normal,
      );
      expect(
        timingStateFor(festival, festival.addDays(-30)),
        FestivalTimingState.normal,
      );
    });

    test('exactly 7 days before is approaching', () {
      expect(
        timingStateFor(festival, festival.addDays(-7)),
        FestivalTimingState.approaching,
      );
    });

    test('1 day before is approaching', () {
      expect(
        timingStateFor(festival, festival.addDays(-1)),
        FestivalTimingState.approaching,
      );
    });

    test('every day of the seven-day window is approaching', () {
      for (var daysBefore = 1; daysBefore <= 7; daysBefore++) {
        expect(
          timingStateFor(festival, festival.addDays(-daysBefore)),
          FestivalTimingState.approaching,
          reason: '$daysBefore days before should be approaching',
        );
      }
    });

    test('the festival date itself is today', () {
      expect(timingStateFor(festival, festival), FestivalTimingState.today);
    });

    test('the day after is normal again — no afterglow', () {
      expect(
        timingStateFor(festival, festival.addDays(1)),
        FestivalTimingState.normal,
      );
    });

    test('a week after is still normal', () {
      expect(
        timingStateFor(festival, festival.addDays(7)),
        FestivalTimingState.normal,
      );
    });
  });
}
