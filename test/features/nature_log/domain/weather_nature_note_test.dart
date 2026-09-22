import 'package:almanac/core/environment/daypart.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/nature_log/domain/weather_nature_note.dart';
import 'package:flutter_test/flutter_test.dart';

CurrentWeather _weather({
  WeatherCondition condition = WeatherCondition.partlyCloudy,
  double precipitationMm = 0,
  double windSpeedKmh = 8,
}) => CurrentWeather(
  temperatureC: 15,
  apparentTemperatureC: 15,
  condition: condition,
  precipitationMm: precipitationMm,
  cloudCoverPercent: 40,
  windSpeedKmh: windSpeedKmh,
);

void main() {
  group('cueFor', () {
    test('drizzle suggests tracks and textures', () {
      final weather = _weather(condition: WeatherCondition.drizzle);
      expect(
        WeatherNatureNotes.cueFor(weather, Daypart.afternoon),
        NatureWeatherCue.lightRain,
      );
    });

    test('rain having just stopped suggests fungi and snails', () {
      final weather = _weather(
        condition: WeatherCondition.cloudy,
        precipitationMm: 1.4,
      );
      expect(
        WeatherNatureNotes.cueFor(weather, Daypart.morning),
        NatureWeatherCue.afterRain,
      );
    });

    test('a dry, windy day suggests plant movement', () {
      final weather = _weather(windSpeedKmh: 30);
      expect(
        WeatherNatureNotes.cueFor(weather, Daypart.afternoon),
        NatureWeatherCue.windy,
      );
    });

    test('a bright morning suggests birds', () {
      final weather = _weather(condition: WeatherCondition.clear);
      expect(
        WeatherNatureNotes.cueFor(weather, Daypart.morning),
        NatureWeatherCue.brightMorning,
      );
    });

    test('the same clear sky in the afternoon suggests nothing', () {
      final weather = _weather(condition: WeatherCondition.clear);
      expect(WeatherNatureNotes.cueFor(weather, Daypart.afternoon), isNull);
    });

    test('a clear night suggests the sky and the ground', () {
      final weather = _weather(condition: WeatherCondition.clear);
      expect(
        WeatherNatureNotes.cueFor(weather, Daypart.night),
        NatureWeatherCue.clearNight,
      );
    });

    test('an ordinary overcast, calm, dry day suggests nothing', () {
      final weather = _weather(condition: WeatherCondition.cloudy);
      expect(WeatherNatureNotes.cueFor(weather, Daypart.afternoon), isNull);
    });
  });

  group('wording never claims a sighting', () {
    test('every note uses tentative language, never "you will see"', () {
      for (final cue in NatureWeatherCue.values) {
        final text = WeatherNatureNotes.noteFor(cue).toLowerCase();
        expect(text, isNot(contains('you will see')));
        expect(
          RegExp('can be|may|look for|notic').hasMatch(text),
          isTrue,
          reason: 'expected tentative wording in "$text"',
        );
      }
    });
  });
}
