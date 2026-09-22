import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';

/// A single, quiet reflective line for today's weather — never a claim
/// that weather affects, measures or activates any chakra. Shown on the
/// overview of all seven rather than inside any one chakra's own detail,
/// so it is never read as being about a particular one of them.
enum ChakraWeatherCue { windy, wet, settled }

abstract final class WeatherChakraNotes {
  static ChakraWeatherCue? cueFor(CurrentWeather weather) {
    if (windFeelOf(weather.windSpeedKmh) != WindFeel.calm) {
      return ChakraWeatherCue.windy;
    }
    if (weather.condition.isPrecipitating) return ChakraWeatherCue.wet;
    if (weather.condition.isOpenSky) return ChakraWeatherCue.settled;
    return null;
  }

  static String noteFor(ChakraWeatherCue cue) => switch (cue) {
    ChakraWeatherCue.windy =>
      'A windy day can be a simple prompt to return to a grounding '
          'practice.',
    ChakraWeatherCue.wet =>
      'A rainy day can be a quiet prompt to slow down and turn inward.',
    ChakraWeatherCue.settled =>
      'A calm, clear day can be a simple invitation to notice how you '
          'feel.',
  };
}
