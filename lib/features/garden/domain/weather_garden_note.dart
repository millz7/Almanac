import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';

/// A quiet, weather-shaped prompt about routine garden care — never a
/// planting instruction and never specific to a crop. Those stay the
/// Garden's own regional rules; this only ever nudges the ordinary
/// business of watering, weeding and keeping pots out of the worst of a
/// day.
enum GardenWeatherCue { veryCold, rainExpected, hotDry, windy, recentRain }

abstract final class WeatherGardenNotes {
  /// The cue today's weather suggests, checked in this order — a very
  /// cold reading is the one worth acting on before anything else, then
  /// whether watering is even needed today, then heat, then wind, and
  /// last the gentler opportunity a recent shower leaves behind. At most
  /// one cue is ever returned.
  static GardenWeatherCue? cueFor(WeatherSnapshot weather) {
    final current = weather.current;
    final temperature = temperatureFeelOf(current.apparentTemperatureC);

    if (temperature == TemperatureFeel.cold) return GardenWeatherCue.veryCold;

    if (weather.today.precipitationProbabilityPercent >=
        WeatherThresholds.likelyFrom) {
      return GardenWeatherCue.rainExpected;
    }

    if (temperature == TemperatureFeel.hot &&
        !current.condition.isPrecipitating) {
      return GardenWeatherCue.hotDry;
    }

    if (windFeelOf(current.windSpeedKmh) != WindFeel.calm &&
        !current.condition.isPrecipitating) {
      return GardenWeatherCue.windy;
    }

    // Open-Meteo's `current` precipitation is a short recent-past
    // window, not a forecast, so rain having fallen without the sky
    // still reading as precipitating is a genuine "just after" moment.
    if (current.precipitationMm > 0 && !current.condition.isPrecipitating) {
      return GardenWeatherCue.recentRain;
    }

    return null;
  }

  static String noteFor(GardenWeatherCue cue) => switch (cue) {
    GardenWeatherCue.veryCold =>
      'A very cold day — tender pots and young seedlings may need extra '
          'shelter.',
    GardenWeatherCue.rainExpected =>
      'Rain looks likely today, so watering may not be needed.',
    GardenWeatherCue.hotDry =>
      'Hot and dry — pots and containers are worth keeping an eye on.',
    GardenWeatherCue.windy =>
      'A windy day — pots can dry out faster than usual.',
    GardenWeatherCue.recentRain =>
      'After the recent rain, the ground may be good for weeding or '
          'mulching.',
  };
}
