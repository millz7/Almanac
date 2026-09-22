import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/wheel/domain/weather_festival_note.dart';
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
    test('rain suggests bringing the celebration inside', () {
      final weather = _weather(condition: WeatherCondition.rain);
      expect(
        WeatherFestivalNotes.cueFor(weather),
        FestivalWeatherCue.bringInside,
      );
    });

    test('a windy day suggests the same, even when dry', () {
      final weather = _weather(windSpeedKmh: 30);
      expect(
        WeatherFestivalNotes.cueFor(weather),
        FestivalWeatherCue.bringInside,
      );
    });

    test('a calm, clear day suggests an outdoor celebration is easier', () {
      final weather = _weather(condition: WeatherCondition.clear);
      expect(
        WeatherFestivalNotes.cueFor(weather),
        FestivalWeatherCue.outdoorEasier,
      );
    });

    test('a calm, overcast day suggests nothing', () {
      expect(WeatherFestivalNotes.cueFor(_weather()), isNull);
    });
  });

  group('never changes which festival it is', () {
    test('a note never names a festival, a date or a hemisphere', () {
      for (final cue in FestivalWeatherCue.values) {
        final text = WeatherFestivalNotes.noteFor(cue).toLowerCase();
        for (final forbidden in [
          'yule',
          'imbolc',
          'ostara',
          'beltane',
          'litha',
          'lughnasadh',
          'mabon',
          'samhain',
          'northern',
          'southern',
          'hemisphere',
        ]) {
          expect(text, isNot(contains(forbidden)), reason: '"$text"');
        }
      }
    });
  });
}
