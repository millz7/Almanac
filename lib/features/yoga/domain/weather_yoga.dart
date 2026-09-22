import '../../../core/environment/daypart.dart';
import '../../../core/environment/weather.dart';
import '../../../core/environment/weather_feel.dart';
import 'yoga_practice.dart';

/// What today's weather suggests about which of the three practices
/// might suit it — the same shape as `FestivalYoga` and `CycleYoga`, and
/// just as independent: one more observation about today, never a claim
/// that weather determines what a body needs or can do.
enum WeatherYogaCue { indoor, coolMorning, settled }

abstract final class WeatherYoga {
  /// The cue today's weather suggests, or null on an ordinary day with
  /// nothing distinctive to say.
  ///
  /// Checked in this order: rain or a genuinely breezy/windy reading
  /// suggests staying in and grounding down, whatever the hour or the
  /// temperature — it wins over the other two. A cool, calm morning
  /// suggests taking it slow. A settled, open, mild-or-warmer day at any
  /// hour suggests an easier practice with room to move.
  static WeatherYogaCue? cueFor(CurrentWeather weather, Daypart? daypart) {
    final wind = windFeelOf(weather.windSpeedKmh);
    if (weather.condition.isPrecipitating || wind != WindFeel.calm) {
      return WeatherYogaCue.indoor;
    }

    final temperature = temperatureFeelOf(weather.apparentTemperatureC);
    if (daypart == Daypart.morning &&
        (temperature == TemperatureFeel.cold ||
            temperature == TemperatureFeel.cool)) {
      return WeatherYogaCue.coolMorning;
    }

    if (weather.condition.isOpenSky &&
        (temperature == TemperatureFeel.mild ||
            temperature == TemperatureFeel.warm ||
            temperature == TemperatureFeel.hot)) {
      return WeatherYogaCue.settled;
    }

    return null;
  }

  static YogaPracticeId practiceFor(WeatherYogaCue cue) => switch (cue) {
    WeatherYogaCue.indoor => YogaPracticeId.ground,
    WeatherYogaCue.coolMorning => YogaPracticeId.unwind,
    WeatherYogaCue.settled => YogaPracticeId.morning,
  };

  static String invitationFor(WeatherYogaCue cue) => switch (cue) {
    WeatherYogaCue.indoor =>
      'Rain or wind outside today — a grounded practice that stays in.',
    WeatherYogaCue.coolMorning =>
      'A cool morning, and a slower practice to start it.',
    WeatherYogaCue.settled =>
      'Settled weather, and an easier practice with room to move.',
  };

  static String headingFor(WeatherYogaCue cue) => switch (cue) {
    WeatherYogaCue.indoor => 'Weather today',
    WeatherYogaCue.coolMorning => 'This morning',
    WeatherYogaCue.settled => 'Weather today',
  };
}
