import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  // A day with sunrise at 06:00 and sunset at 20:00 UTC.
  final events = SolarEvents(
    sunrise: DateTime.utc(2025, 6, 15, 6),
    sunset: DateTime.utc(2025, 6, 15, 20),
  );

  DayNightState at(DateTime instant) =>
      resolveDayNight(instant: instant, events: events);

  group('phases', () {
    test('well before sunrise is night', () {
      final state = at(DateTime.utc(2025, 6, 15, 3));

      expect(state.phase, DayPhase.night);
      expect(state.daylight, 0);
      expect(state.isDaytime, isFalse);
    });

    test('the middle of the day is full daylight', () {
      final state = at(DateTime.utc(2025, 6, 15, 13));

      expect(state.phase, DayPhase.day);
      expect(state.daylight, 1);
      expect(state.isDaytime, isTrue);
    });

    test('well after sunset is night again', () {
      final state = at(DateTime.utc(2025, 6, 15, 22));

      expect(state.phase, DayPhase.night);
      expect(state.daylight, 0);
      expect(state.isDaytime, isFalse);
    });

    test('sunrise itself is the midpoint of dawn', () {
      final state = at(events.sunrise);

      expect(state.phase, DayPhase.dawn);
      expect(state.daylight, closeTo(0.5, 0.01));
    });

    test('sunset itself is the midpoint of dusk', () {
      final state = at(events.sunset);

      expect(state.phase, DayPhase.dusk);
      expect(state.daylight, closeTo(0.5, 0.01));
    });

    test('a fixed clock hour is not what decides day or night', () {
      // 21:00 is night on the day above, but broad daylight if the sun
      // sets later — which a clock-hour rule could never express.
      final lateSunset = SolarEvents(
        sunrise: DateTime.utc(2025, 6, 15, 4),
        sunset: DateTime.utc(2025, 6, 15, 23),
      );
      final state = resolveDayNight(
        instant: DateTime.utc(2025, 6, 15, 21),
        events: lateSunset,
      );

      expect(state.phase, DayPhase.day);
      expect(at(DateTime.utc(2025, 6, 15, 21)).phase, DayPhase.night);
    });
  });

  group('transitions', () {
    test('daylight rises steadily through dawn', () {
      final start = events.sunrise.subtract(kTwilightWindow ~/ 2);
      final readings = [
        for (var minutes = 0; minutes <= 45; minutes += 5)
          at(start.add(Duration(minutes: minutes))).daylight,
      ];

      expect(readings.first, closeTo(0, 0.01));
      expect(readings.last, closeTo(1, 0.01));
      for (var i = 1; i < readings.length; i++) {
        expect(
          readings[i],
          greaterThanOrEqualTo(readings[i - 1]),
          reason: 'daylight should never go backwards during dawn',
        );
      }
    });

    test('daylight falls steadily through dusk', () {
      final start = events.sunset.subtract(kTwilightWindow ~/ 2);
      final first = at(start).daylight;
      final middle = at(start.add(const Duration(minutes: 22))).daylight;
      final last = at(start.add(const Duration(minutes: 45))).daylight;

      expect(first, closeTo(1, 0.01));
      expect(middle, lessThan(first));
      expect(last, closeTo(0, 0.01));
    });

    test('only dawn and dusk report themselves as transitioning', () {
      expect(at(DateTime.utc(2025, 6, 15, 3)).isTransitioning, isFalse);
      expect(at(DateTime.utc(2025, 6, 15, 13)).isTransitioning, isFalse);
      expect(at(events.sunrise).isTransitioning, isTrue);
      expect(at(events.sunset).isTransitioning, isTrue);
    });

    test('a wider twilight window stretches the blend', () {
      final wide = resolveDayNight(
        instant: events.sunrise.add(const Duration(minutes: 40)),
        events: events,
        twilight: const Duration(hours: 3),
      );

      expect(wide.phase, DayPhase.dawn);
      expect(wide.daylight, lessThan(1));
    });
  });

  group('next change', () {
    test('night points at the start of dawn', () {
      final state = at(DateTime.utc(2025, 6, 15, 3));

      expect(state.nextChangeAt, events.sunrise.subtract(kTwilightWindow ~/ 2));
    });

    test('day points at the start of dusk', () {
      final state = at(DateTime.utc(2025, 6, 15, 13));

      expect(state.nextChangeAt, events.sunset.subtract(kTwilightWindow ~/ 2));
    });

    test('after dusk there is nothing left today', () {
      expect(at(DateTime.utc(2025, 6, 15, 22)).nextChangeAt, isNull);
    });
  });

  group('placeholder solar service', () {
    test('produces sunrise and sunset in the local day', () async {
      const service = PlaceholderSolarService();
      const timeZone = TestTimeZones.wellington;
      final result = await service.eventsFor(
        instant: DateTime.utc(2025, 6, 15, 2),
        timeZone: timeZone,
      );

      final localSunrise = timeZone.wallTimeAt(result.sunrise);
      final localSunset = timeZone.wallTimeAt(result.sunset);

      expect(localSunrise.hour, 6);
      expect(localSunrise.minute, 30);
      expect(localSunset.hour, 20);
      expect(localSunset.minute, 30);
      expect(result.sunrise.isBefore(result.sunset), isTrue);
    });

    test('needs only a time zone, so it works without any location', () async {
      const service = PlaceholderSolarService();
      final withLocation = await service.eventsFor(
        instant: DateTime.utc(2025, 6, 15, 2),
        timeZone: TestTimeZones.wellington,
        location: TestLocations.wellington,
      );
      final withoutLocation = await service.eventsFor(
        instant: DateTime.utc(2025, 6, 15, 2),
        timeZone: TestTimeZones.wellington,
      );

      expect(withoutLocation.sunrise, withLocation.sunrise);
      expect(withoutLocation.sunset, withLocation.sunset);
    });
  });
}
