import 'package:almanac/core/environment/season.dart';
import 'package:almanac/features/today/presentation/today_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  group('formatLongDate', () {
    test('reads as a date a person would write', () {
      final local = TestTimeZones.london.wallTimeAt(
        DateTime.utc(2025, 7, 15, 12),
      );
      expect(formatLongDate(local), 'Tuesday 15 July');
    });

    test('is the local date, even when UTC disagrees', () {
      // Still the 14th in UTC; already the 15th in Wellington.
      final local = TestTimeZones.wellington.wallTimeAt(
        DateTime.utc(2025, 7, 14, 20),
      );
      expect(formatLongDate(local), 'Tuesday 15 July');
    });

    test('handles the first and last day of a year', () {
      final zone = TestTimeZones.utc;
      expect(
        formatLongDate(zone.wallTimeAt(DateTime.utc(2025, 1, 1, 12))),
        'Wednesday 1 January',
      );
      expect(
        formatLongDate(zone.wallTimeAt(DateTime.utc(2025, 12, 31, 12))),
        'Wednesday 31 December',
      );
    });
  });

  group('formatSpan', () {
    test('counts hours and minutes', () {
      expect(
        formatSpan(const Duration(hours: 15, minutes: 29)),
        '15 hours 29 minutes',
      );
    });

    test('drops the minutes when there are none', () {
      expect(formatSpan(const Duration(hours: 12)), '12 hours');
    });

    test('gets the singulars right', () {
      expect(
        formatSpan(const Duration(hours: 1, minutes: 1)),
        '1 hour 1 minute',
      );
    });

    test('a short polar day is still a span', () {
      expect(formatSpan(const Duration(minutes: 43)), '0 hours 43 minutes');
    });
  });

  group('describeSeason', () {
    final summer = SeasonState(
      season: Season.summer,
      startedAt: DateTime.utc(2025, 6, 21),
      endsAt: DateTime.utc(2025, 9, 22),
    );

    test('is early near the solstice', () {
      expect(describeSeason(summer, DateTime.utc(2025, 6, 25)), 'Early summer');
    });

    test('is just the season in the middle', () {
      expect(describeSeason(summer, DateTime.utc(2025, 8, 5)), 'Summer');
    });

    test('is late near the equinox', () {
      expect(describeSeason(summer, DateTime.utc(2025, 9, 18)), 'Late summer');
    });
  });

  group('describeNextSeason', () {
    final summer = SeasonState(
      season: Season.summer,
      startedAt: DateTime.utc(2025, 6, 21),
      endsAt: DateTime.utc(2025, 9, 22, 18),
    );

    test('counts the days to the next turning point', () {
      expect(
        describeNextSeason(summer, DateTime.utc(2025, 7, 15)),
        'Autumn arrives in 69 days',
      );
    });

    test('says tomorrow rather than "in 1 days"', () {
      expect(
        describeNextSeason(summer, DateTime.utc(2025, 9, 21, 12)),
        'Autumn arrives tomorrow',
      );
    });

    test('says today on the day itself', () {
      expect(
        describeNextSeason(summer, DateTime.utc(2025, 9, 22, 12)),
        'Autumn arrives today',
      );
    });

    test('follows the cycle, so winter follows autumn', () {
      final autumn = SeasonState(
        season: Season.autumn,
        startedAt: DateTime.utc(2025, 9, 22),
        endsAt: DateTime.utc(2025, 12, 21),
      );
      expect(
        describeNextSeason(autumn, DateTime.utc(2025, 10, 1)),
        startsWith('Winter arrives'),
      );
    });
  });
}
