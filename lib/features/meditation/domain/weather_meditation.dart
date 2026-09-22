import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';
import 'meditation_technique.dart';

/// What today's weather suggests about which of the four practices might
/// suit it — the same shape as `FestivalMeditation`, `MoonMeditation` and
/// `CycleMeditation`, and just as independent: a fourth, separate
/// observation about today, never merged with the others into one claim.
/// Nothing here says weather changes how a session feels or works —
/// only that a rainy hour and a bright, still one suggest a different
/// door into the same four practices.
///
/// Distinctive weather only. A day that is neither wet, nor windy, nor
/// clear and calm — an ordinary cloudy afternoon — has nothing
/// particular to suggest, and [WeatherMeditations.forWeather] returns
/// null rather than reaching for something to say.
enum WeatherMeditationCue { rain, wind, settled }

abstract final class WeatherMeditations {
  /// The cue today's weather suggests, checked in this order —
  /// precipitation is the most noticeable thing about a day, so it wins
  /// over a merely breezy reading; a genuinely calm, open sky is only
  /// worth naming when neither of the others applies.
  static WeatherMeditationCue? cueFor(CurrentWeather weather) {
    if (weather.condition.isPrecipitating) return WeatherMeditationCue.rain;
    if (windFeelOf(weather.windSpeedKmh) != WindFeel.calm) {
      return WeatherMeditationCue.wind;
    }
    if (weather.condition.isOpenSky) return WeatherMeditationCue.settled;
    return null;
  }

  static TechniqueId techniqueFor(WeatherMeditationCue cue) => switch (cue) {
    WeatherMeditationCue.rain => TechniqueId.sleep,
    WeatherMeditationCue.wind => TechniqueId.balance,
    WeatherMeditationCue.settled => TechniqueId.focus,
  };

  static String invitationFor(WeatherMeditationCue cue) => switch (cue) {
    WeatherMeditationCue.rain =>
      'A slower practice, for a quiet, rainy stretch of the day.',
    WeatherMeditationCue.wind =>
      'An even, steady breath, side to side, for a blustery day.',
    WeatherMeditationCue.settled =>
      'A calm, open day for a calm, steady breath.',
  };

  static String headingFor(WeatherMeditationCue cue) => switch (cue) {
    WeatherMeditationCue.rain => 'Rain today',
    WeatherMeditationCue.wind => 'Wind today',
    WeatherMeditationCue.settled => 'Settled weather',
  };
}
