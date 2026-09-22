import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/chakras/domain/weather_chakra_note.dart';
import 'package:flutter_test/flutter_test.dart';

CurrentWeather _weather({
  WeatherCondition condition = WeatherCondition.cloudy,
  double windSpeedKmh = 8,
}) => CurrentWeather(
  temperatureC: 15,
  apparentTemperatureC: 15,
  condition: condition,
  precipitationMm: 0,
  cloudCoverPercent: 40,
  windSpeedKmh: windSpeedKmh,
);

void main() {
  group('cueFor', () {
    test('wind wins over everything else', () {
      final weather = _weather(
        condition: WeatherCondition.rain,
        windSpeedKmh: 30,
      );
      expect(WeatherChakraNotes.cueFor(weather), ChakraWeatherCue.windy);
    });

    test('a calm, wet day suggests turning inward', () {
      final weather = _weather(condition: WeatherCondition.rain);
      expect(WeatherChakraNotes.cueFor(weather), ChakraWeatherCue.wet);
    });

    test('a calm, clear day suggests noticing how you feel', () {
      final weather = _weather(condition: WeatherCondition.clear);
      expect(WeatherChakraNotes.cueFor(weather), ChakraWeatherCue.settled);
    });

    test('a calm, overcast day suggests nothing', () {
      final weather = _weather();
      expect(WeatherChakraNotes.cueFor(weather), isNull);
    });
  });

  group('never a causal claim about a chakra', () {
    test('no note claims weather affects, measures or activates anything', () {
      for (final cue in ChakraWeatherCue.values) {
        final text = WeatherChakraNotes.noteFor(cue).toLowerCase();
        expect(text, isNot(contains('activat')));
        expect(text, isNot(contains('affect')));
        expect(text, isNot(contains('measur')));
        expect(text, contains('can be'));
      }
    });
  });
}
