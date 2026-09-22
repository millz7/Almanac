import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/environment/presentation/weather_narrative.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// A snapshot builder that takes only what a test actually varies, and
/// fills in a plausible rest — a moderate, unremarkable day — so every
/// test reads as "this, specifically, is different" rather than
/// constructing five fields it does not care about.
WeatherSnapshot _snapshot({
  required tz.TZDateTime now,
  double apparentC = 15,
  double temperatureC = 15,
  WeatherCondition condition = WeatherCondition.partlyCloudy,
  double precipitationMm = 0,
  double cloudCoverPercent = 40,
  double windSpeedKmh = 8,
  List<HourlyWeather> hourly = const [],
}) => WeatherSnapshot(
  location: const GeoLocation(latitude: 51.5, longitude: -0.1),
  obtainedAt: now.toUtc(),
  current: CurrentWeather(
    temperatureC: temperatureC,
    apparentTemperatureC: apparentC,
    condition: condition,
    precipitationMm: precipitationMm,
    cloudCoverPercent: cloudCoverPercent,
    windSpeedKmh: windSpeedKmh,
  ),
  today: const DailySummary(
    highC: 18,
    lowC: 9,
    precipitationProbabilityPercent: 10,
  ),
  hourly: hourly,
);

/// A run of hourly forecasts, one per hour starting at [from], all
/// sharing the same reading except where a test overrides it.
List<HourlyWeather> _hours(
  tz.TZDateTime from,
  int count, {
  WeatherCondition condition = WeatherCondition.partlyCloudy,
  double temperatureC = 15,
  double precipitationProbabilityPercent = 0,
  double windSpeedKmh = 8,
}) => [
  for (var i = 0; i < count; i++)
    HourlyWeather(
      time: from.toUtc().add(Duration(hours: i)),
      condition: condition,
      temperatureC: temperatureC,
      precipitationProbabilityPercent: precipitationProbabilityPercent,
      windSpeedKmh: windSpeedKmh,
    ),
];

void main() {
  final zone = LocalTimeZone.utc;
  tz.TZDateTime local(int hour) => zone.instantAtLocal(2026, 4, 27, hour);

  group('daypart voice', () {
    test('a cool, damp morning', () {
      final now = local(7);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 9,
          condition: WeatherCondition.drizzle,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.drizzle,
            temperatureC: 9,
          ),
        ),
        localNow: now,
      );
      expect(text, 'A cool, damp morning.');
    });

    test('a bright, mild, calm morning names only the sky', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 16,
          condition: WeatherCondition.mostlyClear,
          windSpeedKmh: 5,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.mostlyClear,
            windSpeedKmh: 5,
          ),
        ),
        localNow: now,
      );
      expect(text, 'A bright morning.');
    });

    test('a mild, breezy morning names temperature and wind together', () {
      final now = local(9);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 16,
          windSpeedKmh: 25,
          condition: WeatherCondition.cloudy,
          hourly: _hours(now, 9, windSpeedKmh: 25),
        ),
        localNow: now,
      );
      expect(text, 'A mild, breezy morning.');
    });

    test('rain leading an afternoon sentence', () {
      final now = local(13);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          condition: WeatherCondition.rain,
          hourly: _hours(now, 8, condition: WeatherCondition.rain),
        ),
        localNow: now,
      );
      expect(text, 'Rain this afternoon.');
    });

    test('a warm, settled evening', () {
      final now = local(18);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 24,
          condition: WeatherCondition.clear,
          windSpeedKmh: 5,
          hourly: _hours(
            now,
            11,
            condition: WeatherCondition.clear,
            windSpeedKmh: 5,
            temperatureC: 24,
          ),
        ),
        localNow: now,
      );
      expect(text, 'A warm, clear evening.');
    });

    test('an evening with rain developing overnight', () {
      final now = local(19);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          condition: WeatherCondition.cloudy,
          hourly: _hours(
            now,
            11,
            condition: WeatherCondition.rain,
            precipitationProbabilityPercent: 70,
          ),
        ),
        localNow: now,
      );
      expect(text, 'A cloudy evening, with showers developing overnight.');
    });

    test('a cold, still night', () {
      final now = local(22);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 2,
          windSpeedKmh: 4,
          condition: WeatherCondition.cloudy,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.cloudy,
            temperatureC: 2,
            windSpeedKmh: 4,
          ),
        ),
        localNow: now,
      );
      expect(text, contains('cold'));
      expect(text, contains('night'));
    });

    test('rain easing before dawn, on a night that started wet', () {
      final now = local(23);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          condition: WeatherCondition.rain,
          hourly: _hours(now, 9, condition: WeatherCondition.clear),
        ),
        localNow: now,
      );
      expect(text, 'Rain tonight, easing before dawn.');
    });

    test('a clear, calm night names only the sky', () {
      final now = local(23);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 14,
          condition: WeatherCondition.clear,
          windSpeedKmh: 4,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.clear,
            windSpeedKmh: 4,
            temperatureC: 14,
          ),
        ),
        localNow: now,
      );
      expect(text, 'A clear night.');
    });
  });

  group('trivial changes are never narrated', () {
    test('cloud cover drifting a couple of points says nothing about it', () {
      final now = local(9);
      // "Now" and every forecast hour share the same sky *bucket*
      // (overcast, dry) even though the raw cloud-cover percentage
      // wobbles from 49 down to 47 — and the narrative never even reads
      // that field, only the condition enum, so a change clause like
      // "clearing later" must never appear.
      String textAt(double cloudCoverPercent) => describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 15,
          condition: WeatherCondition.partlyCloudy,
          cloudCoverPercent: cloudCoverPercent,
          hourly: _hours(now, 9, condition: WeatherCondition.partlyCloudy),
        ),
        localNow: now,
      );

      final before = textAt(49);
      final after = textAt(47);

      expect(before, isNot(contains('clear')));
      expect(after, isNot(contains('clear')));
      expect(before, isNot(contains('with')));
      expect(after, isNot(contains('with')));
      // The raw percentage plays no part at all: identical sentences.
      expect(before, after);
    });

    test(
      'a one-hour blip in an otherwise dry afternoon is not "rain later"',
      () {
        final now = local(13);
        final hours = _hours(now, 8, condition: WeatherCondition.partlyCloudy);
        // A single stray hour of drizzle among seven dry ones — the
        // dominant bucket stays "open", so nothing about rain is said.
        final blip = hours[3];
        final withBlip = [
          ...hours.sublist(0, 3),
          HourlyWeather(
            time: blip.time,
            condition: WeatherCondition.drizzle,
            temperatureC: blip.temperatureC,
            precipitationProbabilityPercent: 20,
            windSpeedKmh: blip.windSpeedKmh,
          ),
          ...hours.sublist(4),
        ];
        final text = describeWeather(
          weather: _snapshot(
            now: now,
            condition: WeatherCondition.partlyCloudy,
            hourly: withBlip,
          ),
          localNow: now,
        );
        expect(text, isNot(contains('rain')));
        expect(text, isNot(contains('shower')));
      },
    );
  });

  group('precipitation probability thresholds', () {
    // A forecast hour's *condition* already precipitating (drizzle, in
    // these fixtures) puts it in the "wet" bucket unconditionally — see
    // `_bucketOf` — and the wording is then decided purely by the
    // probability attached to it, which is what these three vary.
    test('below chanceFrom says nothing about rain developing', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          condition: WeatherCondition.partlyCloudy,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.drizzle,
            precipitationProbabilityPercent: 20,
          ),
        ),
        localNow: now,
      );
      expect(text, isNot(contains('rain')));
      expect(text, isNot(contains('shower')));
    });

    test('at chanceFrom it is only ever "a chance"', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          condition: WeatherCondition.partlyCloudy,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.drizzle,
            precipitationProbabilityPercent: 35,
          ),
        ),
        localNow: now,
      );
      expect(text, contains('a chance of showers'));
    });

    test('at likelyFrom it reads as developing, not a bare chance', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          condition: WeatherCondition.partlyCloudy,
          hourly: _hours(
            now,
            9,
            condition: WeatherCondition.drizzle,
            precipitationProbabilityPercent: 75,
          ),
        ),
        localNow: now,
      );
      expect(text, contains('showers developing'));
      expect(text, isNot(contains('a chance of')));
    });

    test(
      'rain actually falling now is described directly, not as a chance',
      () {
        final now = local(8);
        final text = describeWeather(
          weather: _snapshot(now: now, condition: WeatherCondition.rain),
          localNow: now,
        );
        expect(text, startsWith('Rain'));
        expect(text, isNot(contains('chance')));
      },
    );
  });

  group('wind language', () {
    test('a genuinely still day is never called "light winds"', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          windSpeedKmh: 3,
          condition: WeatherCondition.partlyCloudy,
          hourly: _hours(now, 9, windSpeedKmh: 3),
        ),
        localNow: now,
      );
      expect(text, isNot(contains('wind')));
      expect(text, isNot(contains('breez')));
    });

    test('wind picking up later is named as a change', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          windSpeedKmh: 5,
          condition: WeatherCondition.partlyCloudy,
          hourly: _hours(now, 9, windSpeedKmh: 30),
        ),
        localNow: now,
      );
      expect(text, contains('wind picking up'));
    });

    test('a blustery now that settles later says the wind is easing', () {
      final now = local(8);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          windSpeedKmh: 45,
          condition: WeatherCondition.partlyCloudy,
          hourly: _hours(now, 9, windSpeedKmh: 5),
        ),
        localNow: now,
      );
      expect(text, contains('windy'));
      expect(text, contains('wind easing'));
    });
  });

  group('never a numerical report', () {
    test('the sentence never contains a degree sign or a percent sign', () {
      final now = local(13);
      final text = describeWeather(
        weather: _snapshot(
          now: now,
          apparentC: 14,
          condition: WeatherCondition.rain,
          hourly: _hours(
            now,
            8,
            condition: WeatherCondition.rain,
            precipitationProbabilityPercent: 80,
          ),
        ),
        localNow: now,
      );
      expect(text, isNot(contains('°')));
      expect(text, isNot(contains('%')));
      // Never a bare number standing in for a reading either.
      expect(RegExp(r'\d').hasMatch(text), isFalse);
    });
  });
}
