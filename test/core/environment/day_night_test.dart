import 'package:almanac/core/environment/day_night.dart';
import 'package:almanac/core/environment/solar_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_environment_services.dart';

void main() {
  setUpAll(useTimeZoneDatabase);

  // A day with sunrise at 06:00 and sunset at 20:00 UTC.
  final events = SolarEvents.risesAndSets(
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
      final state = at(events.sunrise!);

      expect(state.phase, DayPhase.dawn);
      expect(state.daylight, closeTo(0.5, 0.01));
    });

    test('sunset itself is the midpoint of dusk', () {
      final state = at(events.sunset!);

      expect(state.phase, DayPhase.dusk);
      expect(state.daylight, closeTo(0.5, 0.01));
    });

    test('real events are reported as such', () {
      expect(
        at(DateTime.utc(2025, 6, 15, 13)).accuracy,
        DayNightAccuracy.fromSolarEvents,
      );
    });

    test('a fixed clock hour is not what decides day or night', () {
      // 21:00 is night on the day above, but broad daylight if the sun
      // sets later — which a clock-hour rule could never express.
      final lateSunset = SolarEvents.risesAndSets(
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
      final start = events.sunrise!.subtract(kTwilightWindow ~/ 2);
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
      final start = events.sunset!.subtract(kTwilightWindow ~/ 2);
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
      expect(at(events.sunrise!).isTransitioning, isTrue);
      expect(at(events.sunset!).isTransitioning, isTrue);
    });

    test('a wider twilight window stretches the blend', () {
      final wide = resolveDayNight(
        instant: events.sunrise!.add(const Duration(minutes: 40)),
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

      expect(
        state.nextChangeAt,
        events.sunrise!.subtract(kTwilightWindow ~/ 2),
      );
    });

    test('day points at the start of dusk', () {
      final state = at(DateTime.utc(2025, 6, 15, 13));

      expect(state.nextChangeAt, events.sunset!.subtract(kTwilightWindow ~/ 2));
    });

    test('after dusk there is nothing left today', () {
      expect(at(DateTime.utc(2025, 6, 15, 22)).nextChangeAt, isNull);
    });
  });

  group('polar days', () {
    test('midnight sun is permanent daylight, at any hour', () {
      for (final hour in [0, 3, 12, 23]) {
        final state = resolveDayNight(
          instant: DateTime.utc(2025, 6, 21, hour),
          events: const SolarEvents.sunNeverSets(),
        );

        expect(state.phase, DayPhase.day);
        expect(state.daylight, 1);
        expect(state.isDaytime, isTrue);
      }
    });

    test('polar night is permanent night, at any hour', () {
      for (final hour in [0, 3, 12, 23]) {
        final state = resolveDayNight(
          instant: DateTime.utc(2025, 12, 21, hour),
          events: const SolarEvents.sunNeverRises(),
        );

        expect(state.phase, DayPhase.night);
        expect(state.daylight, 0);
        expect(state.isDaytime, isFalse);
      }
    });

    test('neither reports a next change, since none comes today', () {
      expect(
        resolveDayNight(
          instant: DateTime.utc(2025, 6, 21, 12),
          events: const SolarEvents.sunNeverSets(),
        ).nextChangeAt,
        isNull,
      );
    });
  });

  group('without coordinates', () {
    // The app cannot know sunrise, but it still needs a day/night value
    // to theme by. It estimates from the local clock and says so.
    DayNightState estimate(DateTime instant) => resolveDayNight(
      instant: instant,
      events: const SolarEvents.locationRequired(),
      timeZone: TestTimeZones.wellington,
    );

    test('local daytime is estimated as day, and flagged as an estimate', () {
      final noon = TestTimeZones.wellington.instantAtLocal(2025, 7, 15, 12);
      final state = estimate(noon);

      expect(state.phase, DayPhase.day);
      expect(state.daylight, 1);
      expect(state.accuracy, DayNightAccuracy.estimatedWithoutLocation);
    });

    test('the small hours are estimated as night', () {
      final threeAm = TestTimeZones.wellington.instantAtLocal(2025, 7, 15, 3);
      final state = estimate(threeAm);

      expect(state.phase, DayPhase.night);
      expect(state.daylight, 0);
      expect(state.accuracy, DayNightAccuracy.estimatedWithoutLocation);
    });

    test('the estimate follows the local zone, not UTC', () {
      // 02:00 UTC is the afternoon in Wellington, so an estimate anchored
      // to UTC would wrongly call this night.
      final state = estimate(DateTime.utc(2025, 7, 15, 2));

      expect(state.isDaytime, isTrue);
    });

    test('with no zone either, it falls back to daylight', () {
      final state = resolveDayNight(
        instant: DateTime.utc(2025, 7, 15, 12),
        events: const SolarEvents.locationRequired(),
      );

      expect(state.daylight, 1);
      expect(state.accuracy, DayNightAccuracy.estimatedWithoutLocation);
    });
  });

  group('real solar service', () {
    const service = AstronomicalSolarService();

    test('reports that it needs a location when it has none', () async {
      final events = await service.eventsFor(
        instant: DateTime.utc(2025, 7, 15, 12),
        timeZone: TestTimeZones.wellington,
      );

      expect(events.hasTimes, isFalse);
      expect(events.sunrise, isNull);
      expect(events.sunset, isNull);
    });

    test('calculates real times when it has coordinates', () async {
      final events = await service.eventsFor(
        instant: TestTimeZones.wellington.instantAtLocal(2025, 7, 15, 12),
        timeZone: TestTimeZones.wellington,
        location: TestLocations.wellington,
      );

      expect(events.hasTimes, isTrue);
      expect(events.sunrise!.isBefore(events.sunset!), isTrue);
      expect(events.sunrise!.isUtc, isTrue);
    });

    test('uses the local calendar day, not the UTC one', () async {
      // 20:00 UTC on 14 July is already midday on 15 July in Wellington,
      // so the events should belong to the 15th locally.
      final events = await service.eventsFor(
        instant: DateTime.utc(2025, 7, 14, 20),
        timeZone: TestTimeZones.wellington,
        location: TestLocations.wellington,
      );

      final localSunrise = TestTimeZones.wellington.wallTimeAt(events.sunrise!);
      expect(localSunrise.day, 15);
    });
  });

  group('solarDayProgress', () {
    // A different quantity from `daylight`, and the reason it exists: the
    // sun's position through the day, for drawing it on an arc.
    double? progressAt(DateTime instant) =>
        solarDayProgress(instant: instant, events: events);

    test('is 0 at sunrise and 1 at sunset', () {
      expect(progressAt(DateTime.utc(2025, 6, 15, 6)), 0);
      expect(progressAt(DateTime.utc(2025, 6, 15, 20)), 1);
    });

    test('is halfway at solar midday', () {
      expect(progressAt(DateTime.utc(2025, 6, 15, 13)), closeTo(0.5, 1e-9));
    });

    test('keeps moving through the middle of the day, unlike daylight', () {
      // The whole point of the separation: daylight has already reached
      // 1.0 by breakfast and stays there, so it cannot place the sun.
      final morning = DateTime.utc(2025, 6, 15, 9);
      final afternoon = DateTime.utc(2025, 6, 15, 17);

      expect(at(morning).daylight, 1);
      expect(at(afternoon).daylight, 1);

      expect(progressAt(morning)!, lessThan(progressAt(afternoon)!));
    });

    test('rises monotonically across the day', () {
      var previous = -1.0;
      for (var hour = 6; hour <= 20; hour++) {
        final value = progressAt(DateTime.utc(2025, 6, 15, hour))!;
        expect(value, greaterThan(previous));
        previous = value;
      }
    });

    test('is null before sunrise and after sunset', () {
      expect(progressAt(DateTime.utc(2025, 6, 15, 5, 59)), isNull);
      expect(progressAt(DateTime.utc(2025, 6, 15, 20, 1)), isNull);
    });

    test('is null on a polar day, rather than inventing a position', () {
      expect(
        solarDayProgress(
          instant: DateTime.utc(2025, 7, 1, 12),
          events: const SolarEvents.sunNeverSets(),
        ),
        isNull,
      );
      expect(
        solarDayProgress(
          instant: DateTime.utc(2025, 1, 5, 12),
          events: const SolarEvents.sunNeverRises(),
        ),
        isNull,
      );
    });

    test('is null when no position has been shared', () {
      expect(
        solarDayProgress(
          instant: DateTime.utc(2025, 6, 15, 12),
          events: const SolarEvents.locationRequired(),
        ),
        isNull,
      );
    });
  });
}
