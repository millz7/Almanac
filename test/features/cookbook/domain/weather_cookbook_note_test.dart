import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/cookbook/domain/weather_cookbook_note.dart';
import 'package:flutter_test/flutter_test.dart';

CurrentWeather _weather({
  double apparentC = 15,
  WeatherCondition condition = WeatherCondition.partlyCloudy,
}) => CurrentWeather(
  temperatureC: apparentC,
  apparentTemperatureC: apparentC,
  condition: condition,
  precipitationMm: 0,
  cloudCoverPercent: 40,
  windSpeedKmh: 8,
);

void main() {
  group('cueFor', () {
    test('a cold day suggests the warmer dishes', () {
      expect(
        WeatherCookbookNotes.cueFor(_weather(apparentC: 4)),
        CookbookWeatherCue.warm,
      );
    });

    test('a wet day suggests the warmer dishes even if mild', () {
      expect(
        WeatherCookbookNotes.cueFor(_weather(condition: WeatherCondition.rain)),
        CookbookWeatherCue.warm,
      );
    });

    test('a hot day suggests the lighter dishes', () {
      expect(
        WeatherCookbookNotes.cueFor(_weather(apparentC: 30)),
        CookbookWeatherCue.light,
      );
    });

    test('an ordinary mild, dry day suggests nothing', () {
      expect(WeatherCookbookNotes.cueFor(_weather()), isNull);
    });
  });

  group('wording stays secondary', () {
    test('a note never names a specific recipe or dish', () {
      for (final cue in CookbookWeatherCue.values) {
        final text = WeatherCookbookNotes.noteFor(cue);
        expect(text, contains('below'));
      }
    });
  });
}
