import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/time_zone_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  group('lookup', () {
    test('finds a zone by IANA identifier', () {
      expect(LocalTimeZone.byName('Pacific/Auckland').id, 'Pacific/Auckland');
      expect(LocalTimeZone.byName('Europe/London').id, 'Europe/London');
    });

    test('tryByName returns null for an identifier it does not know', () {
      expect(LocalTimeZone.tryByName('Middle/Earth'), isNull);
      expect(LocalTimeZone.tryByName(''), isNull);
    });

    test('UTC is always available, and never shifts', () {
      // The package names it "Etc/UTC"; what matters is that it is UTC.
      expect(LocalTimeZone.utc.id, contains('UTC'));
      for (final month in [1, 4, 7, 10]) {
        expect(
          LocalTimeZone.utc.offsetAt(DateTime.utc(2025, month, 15)),
          Duration.zero,
        );
        expect(
          LocalTimeZone.utc.isDaylightSavingAt(DateTime.utc(2025, month, 15)),
          isFalse,
        );
      }
    });

    test('link names the platform may report also resolve', () {
      // Android reports whatever the system is set to, which is often a
      // database link rather than a canonical zone. If these failed the
      // user would be silently dropped to UTC.
      for (final id in [
        'Europe/Oslo',
        'Europe/Stockholm',
        'Asia/Calcutta',
        'US/Pacific',
      ]) {
        expect(
          LocalTimeZone.tryByName(id),
          isNotNull,
          reason: '$id is a real identifier a device could report',
        );
      }
    });

    test('zones compare by identifier', () {
      expect(
        TestTimeZones.wellington,
        LocalTimeZone.byName('Pacific/Auckland'),
      );
      expect(TestTimeZones.wellington, isNot(TestTimeZones.london));
    });
  });

  group('daylight saving in Pacific/Auckland', () {
    final zone = TestTimeZones.wellington;

    // New Zealand moves to NZDT at 02:00 local on the last Sunday of
    // September, and back at 03:00 local on the first Sunday of April.
    // In 2025 that is 28 September and 6 April.

    test('is UTC+12 in winter and UTC+13 in summer', () {
      expect(
        zone.offsetAt(DateTime.utc(2025, 7, 1)),
        const Duration(hours: 12),
      );
      expect(
        zone.offsetAt(DateTime.utc(2025, 1, 1)),
        const Duration(hours: 13),
      );
    });

    test('reports whether daylight saving is in effect', () {
      expect(zone.isDaylightSavingAt(DateTime.utc(2025, 7, 1)), isFalse);
      expect(zone.isDaylightSavingAt(DateTime.utc(2025, 1, 1)), isTrue);
    });

    test('the offset changes across the September transition', () {
      // 28 September 2025, 02:00 NZST = 14:00 UTC on the 27th.
      final beforeChange = DateTime.utc(2025, 9, 27, 13);
      final afterChange = DateTime.utc(2025, 9, 27, 15);

      expect(zone.offsetAt(beforeChange), const Duration(hours: 12));
      expect(zone.offsetAt(afterChange), const Duration(hours: 13));
    });

    test('local wall time is correct on both sides of the transition', () {
      // An hour before the switch: 01:00 local on 28 September.
      final before = DateTime.utc(2025, 9, 27, 13);
      final beforeLocal = zone.wallTimeAt(before);
      expect(beforeLocal.day, 28);
      expect(beforeLocal.hour, 1);

      // An hour after the switch the clock has jumped from 02:00 to
      // 03:00, so 14:00 UTC reads as 03:00 local, not 02:00.
      final after = DateTime.utc(2025, 9, 27, 14);
      final afterLocal = zone.wallTimeAt(after);
      expect(afterLocal.day, 28);
      expect(afterLocal.hour, 3);
    });

    test('a fixed offset could not do this', () {
      // The whole reason for using a real zone: the offset that applies
      // depends on the instant, not on the place alone.
      final january = zone.offsetAt(DateTime.utc(2025, 1, 15));
      final july = zone.offsetAt(DateTime.utc(2025, 7, 15));

      expect(january, isNot(july));
      expect(january - july, const Duration(hours: 1));
    });

    test('local midnight is right on the day the clocks go forward', () {
      // 28 September 2025 is 23 hours long in Auckland. Midnight local
      // must still be midnight local, not "midnight minus an offset".
      final duringThatDay = DateTime.utc(2025, 9, 27, 20); // 09:00 local
      final midnight = zone.midnightOf(duringThatDay);
      final midnightLocal = zone.wallTimeAt(midnight);

      expect(midnightLocal.year, 2025);
      expect(midnightLocal.month, 9);
      expect(midnightLocal.day, 28);
      expect(midnightLocal.hour, 0);
      expect(midnightLocal.minute, 0);
    });

    test('that short day really is 23 hours long', () {
      final start = zone.instantAtLocal(2025, 9, 28);
      final nextDay = zone.instantAtLocal(2025, 9, 29);

      expect(nextDay.difference(start), const Duration(hours: 23));
    });

    test('and the April day when clocks go back is 25 hours long', () {
      final start = zone.instantAtLocal(2025, 4, 6);
      final nextDay = zone.instantAtLocal(2025, 4, 7);

      expect(nextDay.difference(start), const Duration(hours: 25));
    });
  });

  group('daylight saving in Europe/London', () {
    final zone = TestTimeZones.london;

    test('is UTC+0 in winter and UTC+1 in summer', () {
      expect(zone.offsetAt(DateTime.utc(2025, 1, 15)), Duration.zero);
      expect(
        zone.offsetAt(DateTime.utc(2025, 7, 15)),
        const Duration(hours: 1),
      );
    });

    test('the March transition is handled', () {
      // BST starts at 01:00 UTC on 30 March 2025.
      expect(zone.offsetAt(DateTime.utc(2025, 3, 30, 0)), Duration.zero);
      expect(
        zone.offsetAt(DateTime.utc(2025, 3, 30, 2)),
        const Duration(hours: 1),
      );
    });
  });

  group('local dates', () {
    test('the local date can differ from the UTC date', () {
      // 20:00 UTC is already the next day in Auckland.
      final instant = DateTime.utc(2025, 7, 14, 20);

      expect(TestTimeZones.wellington.localDateOf(instant), (
        year: 2025,
        month: 7,
        day: 15,
      ));
      expect(TestTimeZones.london.localDateOf(instant), (
        year: 2025,
        month: 7,
        day: 14,
      ));
    });

    test('instantAtLocal and wallTimeAt are inverses', () {
      final instant = TestTimeZones.wellington.instantAtLocal(
        2025,
        11,
        3,
        14,
        30,
      );
      final local = TestTimeZones.wellington.wallTimeAt(instant);

      expect(local.year, 2025);
      expect(local.month, 11);
      expect(local.day, 3);
      expect(local.hour, 14);
      expect(local.minute, 30);
    });
  });

  group('time zone service', () {
    test('a fixed service reports the zone it was given', () async {
      final service = FixedTimeZoneService(TestTimeZones.wellington);

      expect((await service.currentTimeZone()).id, 'Pacific/Auckland');
    });
  });
}
