import 'package:almanac/core/environment/daypart.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/yoga/domain/weather_yoga.dart';
import 'package:almanac/features/yoga/domain/yoga_practice.dart';
import 'package:flutter_test/flutter_test.dart';

CurrentWeather _weather({
  double apparentC = 15,
  double windSpeedKmh = 8,
  WeatherCondition condition = WeatherCondition.partlyCloudy,
}) => CurrentWeather(
  temperatureC: apparentC,
  apparentTemperatureC: apparentC,
  condition: condition,
  precipitationMm: 0,
  cloudCoverPercent: 40,
  windSpeedKmh: windSpeedKmh,
);

void main() {
  group('cueFor', () {
    test('rain suggests indoor, whatever the hour', () {
      final weather = _weather(condition: WeatherCondition.rain);
      expect(
        WeatherYoga.cueFor(weather, Daypart.morning),
        WeatherYogaCue.indoor,
      );
      expect(
        WeatherYoga.cueFor(weather, Daypart.evening),
        WeatherYogaCue.indoor,
      );
    });

    test('a windy day suggests indoor even when dry', () {
      final weather = _weather(windSpeedKmh: 30);
      expect(
        WeatherYoga.cueFor(weather, Daypart.afternoon),
        WeatherYogaCue.indoor,
      );
    });

    test('a cool, calm morning suggests a slower practice', () {
      final weather = _weather(
        apparentC: 8,
        condition: WeatherCondition.cloudy,
      );
      expect(
        WeatherYoga.cueFor(weather, Daypart.morning),
        WeatherYogaCue.coolMorning,
      );
    });

    test('the same cool reading in the evening suggests nothing', () {
      final weather = _weather(
        apparentC: 8,
        condition: WeatherCondition.cloudy,
      );
      expect(WeatherYoga.cueFor(weather, Daypart.evening), isNull);
    });

    test('a settled, mild, open day suggests an easier practice', () {
      final weather = _weather(
        apparentC: 20,
        condition: WeatherCondition.clear,
      );
      expect(
        WeatherYoga.cueFor(weather, Daypart.afternoon),
        WeatherYogaCue.settled,
      );
    });

    test('with no known daypart, only the weather-only cues can fire', () {
      final calm = _weather(apparentC: 8, condition: WeatherCondition.cloudy);
      expect(WeatherYoga.cueFor(calm, null), isNull);

      final settled = _weather(
        apparentC: 20,
        condition: WeatherCondition.clear,
      );
      expect(WeatherYoga.cueFor(settled, null), WeatherYogaCue.settled);
    });
  });

  group('mapping to the three existing practices', () {
    test('every cue maps to one of the three practices, no fourth', () {
      for (final cue in WeatherYogaCue.values) {
        final id = WeatherYoga.practiceFor(cue);
        expect(YogaPracticeId.values, contains(id));
      }
    });
  });

  group('wording', () {
    test('no invitation claims weather determines what a body needs', () {
      for (final cue in WeatherYogaCue.values) {
        final text = WeatherYoga.invitationFor(cue).toLowerCase();
        expect(text, isNot(contains('need')));
        expect(text, isNot(contains('must')));
      }
    });
  });
}
