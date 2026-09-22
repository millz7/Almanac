import 'package:almanac/core/environment/geo_location.dart';
import 'package:almanac/core/environment/local_time_zone.dart';
import 'package:almanac/core/environment/weather.dart';
import 'package:almanac/features/chakras/domain/weather_chakra_note.dart';
import 'package:almanac/features/cookbook/domain/weather_cookbook_note.dart';
import 'package:almanac/features/cycle/domain/weather_cycle_note.dart';
import 'package:almanac/features/environment/presentation/weather_narrative.dart';
import 'package:almanac/features/garden/domain/weather_garden_note.dart';
import 'package:almanac/features/meditation/domain/weather_meditation.dart';
import 'package:almanac/features/nature_log/domain/weather_nature_note.dart';
import 'package:almanac/features/wheel/domain/weather_festival_note.dart';
import 'package:almanac/features/yoga/domain/weather_yoga.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every word this test refuses to see in a *weather* sentence, because
/// each one belongs to a different, independent observation about
/// today — the moon, a cycle phase, or a festival — and weather must
/// never be merged with any of them into one combined claim. The
/// forbidden examples straight from the brief this guards against:
/// "Your waning-moon rainy-day energy...", "Because your period is
/// approaching and it is cloudy...", "Beltane rain means...".
const _forbiddenElsewhereWords = [
  // Moon phases.
  'waxing', 'waning', 'new moon', 'full moon', 'crescent', 'gibbous',
  // Cycle phases and anything medical the brief singles out.
  'luteal', 'follicular', 'ovulat', 'menstru', 'period', 'hormone',
  'fertil',
  // Festivals.
  'yule', 'imbolc', 'ostara', 'beltane', 'litha', 'lughnasadh', 'mabon',
  'samhain',
];

void _expectNoElsewhereWords(String text) {
  final lower = text.toLowerCase();
  for (final forbidden in _forbiddenElsewhereWords) {
    expect(
      lower,
      isNot(contains(forbidden)),
      reason: '"$text" contains "$forbidden"',
    );
  }
}

CurrentWeather _current({
  double apparentC = 15,
  WeatherCondition condition = WeatherCondition.rain,
  double windSpeedKmh = 30,
}) => CurrentWeather(
  temperatureC: apparentC,
  apparentTemperatureC: apparentC,
  condition: condition,
  precipitationMm: 2,
  cloudCoverPercent: 80,
  windSpeedKmh: windSpeedKmh,
);

void main() {
  group(
    'the shared TODAY sentence never mentions the moon, a cycle or a festival',
    () {
      test('across a spread of conditions and dayparts', () {
        final zone = LocalTimeZone.utc;
        for (final hour in [7, 13, 19, 23]) {
          for (final condition in WeatherCondition.values) {
            final local = zone.instantAtLocal(2026, 4, 27, hour);
            final snapshot = WeatherSnapshot(
              location: const GeoLocation(latitude: 51.5, longitude: -0.1),
              obtainedAt: local.toUtc(),
              current: _current(condition: condition),
              today: const DailySummary(
                highC: 18,
                lowC: 9,
                precipitationProbabilityPercent: 40,
              ),
              hourly: const [],
            );
            final text = describeWeather(weather: snapshot, localNow: local);
            _expectNoElsewhereWords(text);
          }
        }
      });
    },
  );

  group(
    'every cross-feature weather suggestion stays a separate observation',
    () {
      test('Meditation', () {
        for (final cue in WeatherMeditationCue.values) {
          _expectNoElsewhereWords(WeatherMeditations.invitationFor(cue));
        }
      });

      test('Yoga', () {
        for (final cue in WeatherYogaCue.values) {
          _expectNoElsewhereWords(WeatherYoga.invitationFor(cue));
        }
      });

      test('Nature Log', () {
        for (final cue in NatureWeatherCue.values) {
          _expectNoElsewhereWords(WeatherNatureNotes.noteFor(cue));
        }
      });

      test('Garden', () {
        for (final cue in GardenWeatherCue.values) {
          _expectNoElsewhereWords(WeatherGardenNotes.noteFor(cue));
        }
      });

      test('Cookbook', () {
        for (final cue in CookbookWeatherCue.values) {
          _expectNoElsewhereWords(WeatherCookbookNotes.noteFor(cue));
        }
      });

      test('Cycle — the one feature this rule exists for by name', () {
        for (final cue in CycleWeatherCue.values) {
          _expectNoElsewhereWords(WeatherCycleNotes.noteFor(cue));
        }
      });

      test('Chakras', () {
        for (final cue in ChakraWeatherCue.values) {
          _expectNoElsewhereWords(WeatherChakraNotes.noteFor(cue));
        }
      });

      test(
        'the Wheel of the Year — weather never renames or redates a festival',
        () {
          for (final cue in FestivalWeatherCue.values) {
            _expectNoElsewhereWords(WeatherFestivalNotes.noteFor(cue));
          }
        },
      );
    },
  );
}
