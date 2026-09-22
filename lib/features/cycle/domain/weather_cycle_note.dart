import '../../../core/environment/weather.dart';

/// The one, deliberately narrow thing Cycle is allowed to say about
/// weather: a generic comfort or activity note, never anything about
/// hormones, fertility or the timing of a period, and never combined
/// with a phase into one claim. A cycle phase is calculated the same
/// way with or without this — see `_WeatherComfort` in `cycle_screen.dart`
/// for how the two are kept apart.
enum CycleWeatherCue { wet }

abstract final class WeatherCycleNotes {
  static CycleWeatherCue? cueFor(CurrentWeather weather) {
    if (weather.condition.isPrecipitating) return CycleWeatherCue.wet;
    return null;
  }

  static String noteFor(CycleWeatherCue cue) => switch (cue) {
    CycleWeatherCue.wet => 'A wet day may make an indoor option easier today.',
  };
}
