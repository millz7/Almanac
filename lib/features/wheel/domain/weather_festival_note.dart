import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';

/// A gentle, weather-shaped nudge to how a festival might be marked —
/// never to which festival it is, its date, its meaning, or which
/// hemisphere it belongs to. Those stay exactly what `FestivalCalendar`
/// says regardless of the forecast; this only ever adjusts the idea of
/// *where* to celebrate.
enum FestivalWeatherCue { outdoorEasier, bringInside }

abstract final class WeatherFestivalNotes {
  static FestivalWeatherCue? cueFor(CurrentWeather weather) {
    if (weather.condition.isPrecipitating ||
        windFeelOf(weather.windSpeedKmh) != WindFeel.calm) {
      return FestivalWeatherCue.bringInside;
    }
    if (weather.condition.isOpenSky) return FestivalWeatherCue.outdoorEasier;
    return null;
  }

  static String noteFor(FestivalWeatherCue cue) => switch (cue) {
    FestivalWeatherCue.outdoorEasier =>
      'Settled weather today can make an outdoor celebration easier.',
    FestivalWeatherCue.bringInside =>
      'Rain or wind today? The season can just as easily come inside — '
          'through food, greenery, candles or something handmade.',
  };
}
