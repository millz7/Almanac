import '../../../core/environment/daypart.dart';
import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';

/// A quiet, weather-shaped prompt for what might be worth noticing —
/// never a claim about what is actually out there. The Nature Book's own
/// regional coverage rules decide which *species* the app will name;
/// this only ever points at a category already in the book (birds,
/// fungi, plants) or at the ground and sky themselves, and always in
/// "can be"/"may"/"look for"/"notice" language, never "you will see X".
enum NatureWeatherCue { lightRain, afterRain, windy, brightMorning, clearNight }

abstract final class WeatherNatureNotes {
  /// The cue today's weather and time of day suggest, checked in this
  /// order — rain, whether falling now or recently stopped, is the most
  /// noticeable thing about a walk outside, so it is checked before wind
  /// or a plain bright/clear reading. At most one cue is ever returned.
  static NatureWeatherCue? cueFor(CurrentWeather weather, Daypart? daypart) {
    if (weather.condition == WeatherCondition.drizzle) {
      return NatureWeatherCue.lightRain;
    }
    // Open-Meteo's `current` precipitation is a short recent-past
    // window, not a forecast — see `CurrentWeather.precipitationMm` — so
    // rain having fallen without the sky still reading as precipitating
    // is a genuine "just after the rain" moment, not a stale reading.
    if (weather.precipitationMm > 0 && !weather.condition.isPrecipitating) {
      return NatureWeatherCue.afterRain;
    }
    if (windFeelOf(weather.windSpeedKmh) != WindFeel.calm &&
        !weather.condition.isPrecipitating) {
      return NatureWeatherCue.windy;
    }
    if (daypart == Daypart.morning && weather.condition.isOpenSky) {
      return NatureWeatherCue.brightMorning;
    }
    if (daypart == Daypart.night &&
        weather.condition == WeatherCondition.clear) {
      return NatureWeatherCue.clearNight;
    }
    return null;
  }

  static String noteFor(NatureWeatherCue cue) => switch (cue) {
    NatureWeatherCue.lightRain =>
      'A little rain today — tracks and textures can be easier to spot '
          'on wet ground.',
    NatureWeatherCue.afterRain =>
      'After rain, fungi and snails can be easier to notice.',
    NatureWeatherCue.windy =>
      'A windy day — look for how the plants and trees are moving.',
    NatureWeatherCue.brightMorning =>
      'A bright morning can be a good time to notice birds.',
    NatureWeatherCue.clearNight =>
      'A clear night — worth noticing the sky, and what is moving on '
          'the ground.',
  };
}
