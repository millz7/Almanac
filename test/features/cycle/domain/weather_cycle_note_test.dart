import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/cycle/domain/weather_cycle_note.dart';
import 'package:flutter_test/flutter_test.dart';

CurrentWeather _weather({
  WeatherCondition condition = WeatherCondition.partlyCloudy,
}) => CurrentWeather(
  temperatureC: 15,
  apparentTemperatureC: 15,
  condition: condition,
  precipitationMm: 0,
  cloudCoverPercent: 40,
  windSpeedKmh: 8,
);

void main() {
  group('cueFor', () {
    test('rain suggests an indoor option', () {
      expect(
        WeatherCycleNotes.cueFor(_weather(condition: WeatherCondition.rain)),
        CycleWeatherCue.wet,
      );
    });

    test('a dry day suggests nothing', () {
      expect(WeatherCycleNotes.cueFor(_weather()), isNull);
    });
  });

  group('the one cue is generic comfort, never anything else', () {
    test('the wording never mentions a cycle, a phase or a body process', () {
      for (final cue in CycleWeatherCue.values) {
        final text = WeatherCycleNotes.noteFor(cue).toLowerCase();
        for (final forbidden in [
          'luteal',
          'follicular',
          'ovulat',
          'menstru',
          'period',
          'hormone',
          'fertil',
        ]) {
          expect(
            text,
            isNot(contains(forbidden)),
            reason: '"$text" must never mention "$forbidden"',
          );
        }
      }
    });
  });
}
