import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/meditation/domain/meditation_technique.dart';
import 'package:almanac/features/meditation/domain/weather_meditation.dart';
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
    test('rain wins over everything else', () {
      final weather = _weather(
        condition: WeatherCondition.rain,
        windSpeedKmh: 30,
      );
      expect(WeatherMeditations.cueFor(weather), WeatherMeditationCue.rain);
    });

    test('a breezy, dry day suggests wind', () {
      final weather = _weather(
        condition: WeatherCondition.cloudy,
        windSpeedKmh: 25,
      );
      expect(WeatherMeditations.cueFor(weather), WeatherMeditationCue.wind);
    });

    test('a calm, open sky suggests settled', () {
      final weather = _weather(
        condition: WeatherCondition.clear,
        windSpeedKmh: 5,
      );
      expect(WeatherMeditations.cueFor(weather), WeatherMeditationCue.settled);
    });

    test('an ordinary calm, overcast day suggests nothing', () {
      final weather = _weather(
        condition: WeatherCondition.cloudy,
        windSpeedKmh: 5,
      );
      expect(WeatherMeditations.cueFor(weather), isNull);
    });
  });

  group('mapping to the four existing practices', () {
    test('every cue maps to one of the four techniques, no fifth', () {
      for (final cue in WeatherMeditationCue.values) {
        final id = WeatherMeditations.techniqueFor(cue);
        expect(MeditationTechniques.all.map((t) => t.id), contains(id));
      }
    });
  });

  group('wording', () {
    test('no invitation ever names weather as causing a mental state', () {
      for (final cue in WeatherMeditationCue.values) {
        final text = WeatherMeditations.invitationFor(cue).toLowerCase();
        expect(text, isNot(contains('makes you')));
        expect(text, isNot(contains('because')));
        expect(text, isNot(contains('will')));
      }
    });
  });
}
