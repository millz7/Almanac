import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';

/// A quiet, secondary nudge towards the warmer or lighter end of the
/// season's own collection — never a second way of choosing what to
/// cook. The Cookbook stays primarily seasonal: this never reorders,
/// filters or replaces anything, and it never appears at all when
/// browsing a season other than the one the user is actually in.
enum CookbookWeatherCue { warm, light }

abstract final class WeatherCookbookNotes {
  static CookbookWeatherCue? cueFor(CurrentWeather weather) {
    final temperature = temperatureFeelOf(weather.apparentTemperatureC);
    final cold =
        temperature == TemperatureFeel.cold ||
        temperature == TemperatureFeel.cool;
    if (cold || weather.condition.isPrecipitating) {
      return CookbookWeatherCue.warm;
    }
    if (temperature == TemperatureFeel.hot) return CookbookWeatherCue.light;
    return null;
  }

  static String noteFor(CookbookWeatherCue cue) => switch (cue) {
    CookbookWeatherCue.warm =>
      'Cooler, wetter weather today — the warmer dishes below might suit '
          'it best.',
    CookbookWeatherCue.light =>
      'A hot day — the lighter dishes below might suit it best.',
  };
}
