import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/garden/domain/weather_garden_note.dart';
import 'package:flutter_test/flutter_test.dart';

WeatherSnapshot _snapshot({
  double apparentC = 15,
  WeatherCondition condition = WeatherCondition.partlyCloudy,
  double precipitationMm = 0,
  double windSpeedKmh = 8,
  double dailyRainChancePercent = 10,
}) => WeatherSnapshot(
  location: const GeoLocation(latitude: 51.5, longitude: -0.1),
  obtainedAt: DateTime.utc(2025, 7, 15, 12),
  current: CurrentWeather(
    temperatureC: apparentC,
    apparentTemperatureC: apparentC,
    condition: condition,
    precipitationMm: precipitationMm,
    cloudCoverPercent: 40,
    windSpeedKmh: windSpeedKmh,
  ),
  today: DailySummary(
    highC: 18,
    lowC: 9,
    precipitationProbabilityPercent: dailyRainChancePercent,
  ),
  hourly: const [],
);

void main() {
  group('cueFor', () {
    test('a very cold reading wins over everything else', () {
      final weather = _snapshot(apparentC: 2, dailyRainChancePercent: 80);
      expect(WeatherGardenNotes.cueFor(weather), GardenWeatherCue.veryCold);
    });

    test('rain likely today suggests skipping the watering', () {
      final weather = _snapshot(dailyRainChancePercent: 70);
      expect(WeatherGardenNotes.cueFor(weather), GardenWeatherCue.rainExpected);
    });

    test('a hot, dry day suggests watching pots and containers', () {
      final weather = _snapshot(apparentC: 30);
      expect(WeatherGardenNotes.cueFor(weather), GardenWeatherCue.hotDry);
    });

    test('a dry, windy day suggests pots drying out faster', () {
      final weather = _snapshot(windSpeedKmh: 30);
      expect(WeatherGardenNotes.cueFor(weather), GardenWeatherCue.windy);
    });

    test('rain having just fallen suggests weeding or mulching', () {
      final weather = _snapshot(
        condition: WeatherCondition.cloudy,
        precipitationMm: 2,
      );
      expect(WeatherGardenNotes.cueFor(weather), GardenWeatherCue.recentRain);
    });

    test('an ordinary mild, calm, dry day suggests nothing', () {
      final weather = _snapshot();
      expect(WeatherGardenNotes.cueFor(weather), isNull);
    });
  });

  group('wording never gives a planting instruction', () {
    test('no note names a crop or a specific plant', () {
      for (final cue in GardenWeatherCue.values) {
        final text = WeatherGardenNotes.noteFor(cue).toLowerCase();
        expect(text, isNot(contains('sow')));
        expect(text, isNot(contains('plant ')));
        expect(text, isNot(contains('harvest')));
      }
    });
  });
}
